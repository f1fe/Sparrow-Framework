//
//  SPRenderContext.m
//  Sparrow
//
//  Created by Daniel Sperl on 28.09.09.
//  Copyright 2009 Incognitek. All rights reserved.
//
//  This program is free software; you can redistribute it and/or modify
//  it under the terms of the Simplified BSD License.
//

#import "SPRenderSupport.h"
#import "SPTexture.h"

#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES1/gl.h>
#import <OpenGLES/ES1/glext.h>

@implementation SPRenderSupport

@synthesize usingPremultipliedAlpha = mPremultipliedAlpha;

- (id)init
{
    if (self = [super init])
    {
        mBoundTextureID = UINT_MAX;
        mPremultipliedAlpha = YES;
        [self bindTexture:nil];        
    }
    return self;
}

- (void)bindTexture:(SPTexture *)texture
{
    uint newTextureID = texture.textureID;
    BOOL newPMA = texture.hasPremultipliedAlpha;
    
    if (newTextureID != mBoundTextureID)
    {
        mBoundTextureID = newTextureID;
        glBindTexture(GL_TEXTURE_2D, mBoundTextureID);        
    }        
    
    if (newPMA != mPremultipliedAlpha)
    {
        mPremultipliedAlpha = newPMA;
        if (newPMA) glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
        else        glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    }    
}

@end
