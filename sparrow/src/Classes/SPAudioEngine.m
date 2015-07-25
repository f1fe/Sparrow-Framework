//
//  SPAudioEngine.m
//  Sparrow
//
//  Created by Daniel Sperl on 14.11.09.
//  Copyright 2011-2014 Gamua. All rights reserved.
//
//  This program is free software; you can redistribute it and/or modify
//  it under the terms of the Simplified BSD License.
//

#import <Sparrow/SPAudioEngine.h>

#import <AudioToolbox/AudioToolbox.h> 
#import <OpenAL/al.h>
#import <OpenAL/alc.h>
#import <UIKit/UIKit.h>
#import <AVFoundation/AVAudioSession.h>

#define SP_DEFAULT_MASTER_VOLUME (1.0f)

// --- notifications -------------------------------------------------------------------------------

NSString *const SPNotificationMasterVolumeChanged       = @"SPNotificationMasterVolumeChanged";
NSString *const SPNotificationAudioInteruptionBegan     = @"SPNotificationAudioInteruptionBegan";
NSString *const SPNotificationAudioInteruptionEnded     = @"SPNotificationAudioInteruptionEnded";
NSString *const SPNotificationMediaServicesWereReset    = @"SPNotificationMediaServicesWereReset";


// --- private interaface --------------------------------------------------------------------------

@interface SPAudioEngine ()
{
    ALCdevice  *device;
    ALCcontext *context;
    SPAudioSessionCategory audioSessionCategory;
    float masterVolume;
    BOOL interrupted;
}

+ (instancetype)defaultAudioEngine;

+ (BOOL)initAudioSession:(SPAudioSessionCategory)category;
+ (BOOL)initOpenAL;

+ (void)beginInterruption;
+ (void)endInterruption;
+ (void)onAppActivated:(NSNotification *)notification;
+ (void)postNotification:(NSString *)name object:(id)object;

+ (void)audioSessionInterrupted: (NSNotification *)notification;
+ (void)mediaServicesWereReset: (NSNotification *)notification;


@end


// --- class implementation ------------------------------------------------------------------------

@implementation SPAudioEngine

// --- C functions ---

static NSString * audioSessionCategoryFromSPAudioSessionCategory( SPAudioSessionCategory audioSessionCategory ) {
    NSString * audioCategory = nil;
    switch (audioSessionCategory) {
        case SPAudioSessionCategory_AmbientSound:
            audioCategory = AVAudioSessionCategoryAmbient;
            break;
        case SPAudioSessionCategory_SoloAmbientSound:
            audioCategory = AVAudioSessionCategorySoloAmbient;
            break;
        case SPAudioSessionCategory_AudioProcessing:
            audioCategory = AVAudioSessionCategoryAudioProcessing;
            break;
        case SPAudioSessionCategory_MediaPlayback:
            audioCategory = AVAudioSessionCategoryPlayback;
            break;
        case SPAudioSessionCategory_PlayAndRecord:
            audioCategory = AVAudioSessionCategoryPlayAndRecord;
            break;
        case SPAudioSessionCategory_RecordAudio:
            audioCategory = AVAudioSessionCategoryRecord;
            break;
        default:
            break;
    }
    return audioCategory;
}

#pragma mark Initialization

+ (instancetype)defaultAudioEngine
{
    static SPAudioEngine *audioEngine = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        audioEngine = [[SPAudioEngine alloc] init];
    });
    return audioEngine;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        masterVolume = SP_DEFAULT_MASTER_VOLUME;
        audioSessionCategory = SPAudioSessionCategory_SoloAmbientSound;
    }
    return self;
}

- (void)dealloc
{
    [[self class] stop];
    [super dealloc];
}

+ (void)audioSessionInterrupted: (NSNotification *)notification
{
    NSDictionary *userInfo = [notification userInfo];
    NSNumber *interruptionType = userInfo[AVAudioSessionInterruptionTypeKey];
    if( interruptionType ) {
        NSUInteger interruptionValue = [interruptionType unsignedIntegerValue];
        if( interruptionValue == AVAudioSessionInterruptionTypeBegan ) {
            [[self class] beginInterruption];
        } else if( interruptionValue == AVAudioSessionInterruptionTypeEnded ) {
            [[self class] endInterruption];
        }
    }
}

+ (void)mediaServicesWereReset:(NSNotification *)notification
{
    [[self class] stop];
    [[self class] start];
    [[self class] postNotification: SPNotificationMediaServicesWereReset object: nil];
}

+ (BOOL)initAudioSession:(SPAudioSessionCategory)category
{
    SPAudioEngine *audioEngine = [[self class] defaultAudioEngine];
    audioEngine -> audioSessionCategory = category;
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    NSError *audioError = nil;
    NSString *audioCategory = audioSessionCategoryFromSPAudioSessionCategory(category);
    BOOL success = [audioSession setCategory: audioCategory
                                       error: &audioError];
    if( audioError ) {
        NSLog(@"Failed to initialize audio session:%@", [audioError localizedDescription] );
    }
    return success;
}

+ (BOOL)initOpenAL
{
    alGetError(); // reset any errors

    SPAudioEngine *audioEngine = [[self class] defaultAudioEngine];
    audioEngine -> device = alcOpenDevice(NULL);
    if (!(audioEngine -> device))
    {
        NSLog(@"Could not open default OpenAL device");
        return NO;
    }
    
    audioEngine -> context = alcCreateContext(audioEngine -> device, 0);
    if (!(audioEngine -> context))
    {
        NSLog(@"Could not create OpenAL context for default device");
        return NO;
    }
    
    BOOL success = alcMakeContextCurrent(audioEngine -> context);
    if (!success)
    {
        NSLog(@"Could not set current OpenAL context");
        return NO;
    }
    
    return YES;
}

#pragma mark Methods

+ (void)start:(SPAudioSessionCategory)category
{
    SPAudioEngine *audioEngine = [[self class] defaultAudioEngine];
    if (!(audioEngine -> device))
    {
        if ([[self class] initAudioSession:category])
            [[self class] initOpenAL];
        
        AVAudioSession *audioSession = [AVAudioSession sharedInstance];
        NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
        [notificationCenter removeObserver:self];
        [notificationCenter addObserver: self
                               selector: @selector(audioSessionInterrupted:)
                                   name: AVAudioSessionInterruptionNotification
                                 object: audioSession];
        [notificationCenter addObserver: self
                               selector: @selector(mediaServicesWereReset:)
                                   name: AVAudioSessionMediaServicesWereResetNotification
                                 object: audioSession];
        
        // A bug introduced in iOS 4 may lead to 'endInterruption' NOT being called in some
        // situations. Thus, we're resuming the audio session manually via the 'DidBecomeActive'
        // notification. Find more information here: http://goo.gl/mr9KS
        
        [notificationCenter addObserver:self
                               selector:@selector(onAppActivated:)
                                   name:UIApplicationDidBecomeActiveNotification
                                 object:nil];
    }
}

+ (void)start
{      
    SPAudioEngine *audioEngine = [[self class] defaultAudioEngine];
    [[self class] start: audioEngine -> audioSessionCategory];
}

+ (void)stop
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    SPAudioEngine *audioEngine = [[self class] defaultAudioEngine];
    alcMakeContextCurrent(NULL);
    alcDestroyContext(audioEngine -> context);
    alcCloseDevice(audioEngine -> device);
    NSError *audioError = nil;
    [[AVAudioSession sharedInstance] setActive: NO error: &audioError];
    if( audioError ) {
        NSLog(@"Could not stop audio:\n%@\n", [audioError localizedDescription] );
    }
    
    audioEngine -> device = NULL;
    audioEngine -> context = NULL;
    audioEngine -> interrupted = NO;
}

+ (float)masterVolume
{
    SPAudioEngine *audioEngine = [[self class] defaultAudioEngine];
    return audioEngine -> masterVolume;
}

+ (void)setMasterVolume:(float)volume
{       
    SPAudioEngine *audioEngine = [[self class] defaultAudioEngine];
    audioEngine -> masterVolume = volume;
    alListenerf(AL_GAIN, volume);
    [[self class] postNotification:SPNotificationMasterVolumeChanged object:nil];
}

#pragma mark Notifications

+ (void)beginInterruption
{
    [[self class] postNotification:SPNotificationAudioInteruptionBegan object:nil];
    alcMakeContextCurrent(NULL);
    NSError *audioError = nil;
    [[AVAudioSession sharedInstance] setActive: NO error: &audioError];
    if( audioError ) {
        NSLog(@"Could not stop audio:\n%@\n", [audioError localizedDescription] );
    }
    SPAudioEngine *audioEngine = [[self class] defaultAudioEngine];
    audioEngine -> interrupted = YES;
}

+ (void)endInterruption
{
    SPAudioEngine *audioEngine = [[self class] defaultAudioEngine];
    audioEngine -> interrupted = NO;
    NSError *audioError = nil;
    [[AVAudioSession sharedInstance] setActive: YES error: &audioError];
    if( audioError ) {
        NSLog(@"Could not stop audio:\n%@\n", [audioError localizedDescription] );
    }
    alcMakeContextCurrent(audioEngine -> context);
    alcProcessContext(audioEngine -> context);
    [[self class] postNotification:SPNotificationAudioInteruptionEnded object:nil];
}

+ (void)onAppActivated:(NSNotification *)notification
{
    SPAudioEngine *audioEngine = [[self class] defaultAudioEngine];
    if (audioEngine -> interrupted) [self endInterruption];
}

+ (void)postNotification:(NSString *)name object:(id)object
{
    [[NSNotificationCenter defaultCenter] postNotification:
     [NSNotification notificationWithName:name object:object]];
}

@end
