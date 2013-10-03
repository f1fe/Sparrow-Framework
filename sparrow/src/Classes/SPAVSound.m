//
//  SPAVSound.m
//  Sparrow
//
//  Created by Daniel Sperl on 29.05.10.
//  Copyright 2011 Gamua. All rights reserved.
//
//  This program is free software; you can redistribute it and/or modify
//  it under the terms of the Simplified BSD License.
//

#import "SPAVSound.h"
#import "SPAVSoundChannel.h"
#import "SPMacros.h"
#import "SPUtils.h"

@implementation SPAVSound
{
    NSData *_soundData;
    double _duration;
}

@synthesize duration = _duration;

- (id)init
{
    [self release];
    return nil;
}

- (void)dealloc
{
    [_soundData release];
    [super dealloc];
}

- (id)initWithContentsOfFile:(NSString *)path duration:(double)duration
{
    if ((self = [super init]))
    {
        NSString *fullPath = [SPUtils absolutePathToFile:path];
        _soundData = [[NSData alloc] initWithContentsOfMappedFile:fullPath];
        _duration = duration;
    }
    return self;
}

- (SPSoundChannel *)createChannel
{
    return [[[SPAVSoundChannel alloc] initWithSound:self] autorelease];
}

- (AVAudioPlayer *)createPlayer
{
    NSError *error = nil;    
    AVAudioPlayer *player = [[[AVAudioPlayer alloc] initWithData:_soundData error:&error] autorelease];
    if (error) NSLog(@"Could not create AVAudioPlayer: %@", [error description]);    
    return player;	
}

@end
