//
//  SPBaseEffect.m
//  Sparrow
//
//  Created by Daniel Sperl on 12.03.13.
//  Copyright 2011-2014 Gamua. All rights reserved.
//
//  This program is free software; you can redistribute it and/or modify
//  it under the terms of the Simplified BSD License.
//

#import <Sparrow/SparrowClass.h>
#import <Sparrow/SPBaseEffect.h>
#import <Sparrow/SPMatrix.h>
#import <Sparrow/SPNSExtensions.h>
#import <Sparrow/SPOpenGL.h>
#import <Sparrow/SPProgram.h>
#import <Sparrow/SPTexture.h>

// --- private interface ---------------------------------------------------------------------------

@interface SPBaseEffect ()

- (NSString *)vertexShaderForTexture:(SPTexture *)texture;
- (NSString *)fragmentShaderForTexture:(SPTexture *)texture;

@end


// --- class implementation ------------------------------------------------------------------------

@implementation SPBaseEffect
{
    SPMatrix  *_mvpMatrix;
    SPTexture *_texture;
    float _alpha;
    BOOL _premultipliedAlpha;
    
    SPProgram *_program;
    int _aPosition;
    int _aColor;
    int _aTexCoords;
    int _uMvpMatrix;
    int _uAlpha;
}

@synthesize attribPosition = _aPosition;
@synthesize attribColor = _aColor;
@synthesize attribTexCoords = _aTexCoords;

#pragma mark Initialization

- (instancetype)init
{
    if ((self = [super init]))
    {
        _mvpMatrix = [[SPMatrix alloc] init];
        _premultipliedAlpha = NO;
        _alpha = 1.0f;
    }
    return self;
}

- (void)dealloc
{
    [_mvpMatrix release];
    [_texture release];
    [_program release];
    [super dealloc];
}

#pragma mark Methods

- (void)prepareToDraw
{
    BOOL hasTexture = _texture != nil;

    if (!_program)
    {
        NSString *programName = hasTexture ? @"SPQuad#11" : @"SPQuad#01";

        _program = [[Sparrow.currentController programByName:programName] retain];
        
        if (!_program)
        {
            NSString *vertexShader   = [self vertexShaderForTexture:_texture];
            NSString *fragmentShader = [self fragmentShaderForTexture:_texture];
            _program = [[SPProgram alloc] initWithVertexShader:vertexShader fragmentShader:fragmentShader];
            [Sparrow.currentController registerProgram:_program name:programName];
        }
        
        _aPosition  = [_program attributeByName:@"aPosition"];
        _aColor     = [_program attributeByName:@"aColor"];
        _aTexCoords = [_program attributeByName:@"aTexCoords"];
        _uMvpMatrix = [_program uniformByName:@"uMvpMatrix"];
        _uAlpha     = [_program uniformByName:@"uAlpha"];
    }
#if SP_ENABLE_GL_STATE_CACHE

    glUseProgram(_program.name);
    sglUniformMatrix4fvMvpMatrix(_uMvpMatrix, _mvpMatrix);
    
    if (_premultipliedAlpha) sglUniform4fAlpha(_uAlpha, _alpha, _alpha, _alpha, _alpha);
    else                     sglUniform4fAlpha(_uAlpha, 1.0f, 1.0f, 1.0f, _alpha);
#else 
    GLKMatrix4 glkMvpMatrix = [_mvpMatrix convertToGLKMatrix4];
    
    glUseProgram(_program.name);
    glUniformMatrix4fv(_uMvpMatrix, 1, NO, glkMvpMatrix.m);
    
    if (_premultipliedAlpha) glUniform4f(_uAlpha, _alpha, _alpha, _alpha, _alpha);
    else                     glUniform4f(_uAlpha, 1.0f, 1.0f, 1.0f, _alpha);

#endif
    if (hasTexture)
    {
        glActiveTexture(GL_TEXTURE0);
        glBindTexture(GL_TEXTURE_2D, _texture.name);
    }
}

#pragma mark Properties

- (void)setMvpMatrix:(SPMatrix *)value
{
    [_mvpMatrix copyFromMatrix:value];
}

- (void)setAlpha:(float)value
{
    if ((value >= 1.0f && _alpha < 1.0f) || (value < 1.0f && _alpha >= 1.0f))
        SP_RELEASE_AND_NIL(_program);

    _alpha = value;
}

- (void)setTexture:(SPTexture *)value
{
    if ((_texture && !value) || (!_texture && value))
        SP_RELEASE_AND_NIL(_program);

    SP_RELEASE_AND_RETAIN(_texture, value);
}

#pragma mark Private

- (NSString *)vertexShaderForTexture:(SPTexture *)texture
{
    BOOL hasTexture = texture != nil;
    NSMutableString *source = [NSMutableString string];
    
    // variables
    
    [source appendLine:@"attribute vec4 aPosition;"];
    [source appendLine:@"attribute vec4 aColor;"];
    if (hasTexture) [source appendLine:@"attribute vec2 aTexCoords;"];

    [source appendLine:@"uniform mat4 uMvpMatrix;"];
    [source appendLine:@"uniform vec4 uAlpha;"];
    
    [source appendLine:@"varying lowp vec4 vColor;"];
    if (hasTexture) [source appendLine:@"varying lowp vec2 vTexCoords;"];
    
    // main
    
    [source appendLine:@"void main() {"];
    
    [source appendLine:@"  gl_Position = uMvpMatrix * aPosition;"];
    [source appendLine:@"  vColor = aColor * uAlpha;"];
    if (hasTexture) [source appendLine:@"  vTexCoords  = aTexCoords;"];
    
    [source appendString:@"}"];
    
    return source;
}

- (NSString *)fragmentShaderForTexture:(SPTexture *)texture
{
    BOOL hasTexture = texture != nil;
    NSMutableString *source = [NSMutableString string];
    
    // variables
    
        [source appendLine:@"varying lowp vec4 vColor;"];
    
    if (hasTexture)
    {
        [source appendLine:@"varying lowp vec2 vTexCoords;"];
        [source appendLine:@"uniform lowp sampler2D uTexture;"];
    }
    
    // main
    
    [source appendLine:@"void main() {"];
    
    if (hasTexture)
    {
        [source appendLine:@"  gl_FragColor = texture2D(uTexture, vTexCoords) * vColor;"];
    }
    else
        [source appendLine:@"  gl_FragColor = vColor;"];
    
    [source appendString:@"}"];
    
    return source;
}

@end
