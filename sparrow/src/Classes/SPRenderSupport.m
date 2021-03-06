//
//  SPRenderSupport.m
//  Sparrow
//
//  Created by Daniel Sperl on 28.09.09.
//  Copyright 2011-2014 Gamua. All rights reserved.
//
//  This program is free software; you can redistribute it and/or modify
//  it under the terms of the Simplified BSD License.
//

#import <Sparrow/SparrowClass.h>
#import <Sparrow/SPBlendMode.h>
#import <Sparrow/SPContext.h>
#import <Sparrow/SPDisplayObject.h>
#import <Sparrow/SPMacros.h>
#import <Sparrow/SPMatrix.h>
#import <Sparrow/SPOpenGL.h>
#import <Sparrow/SPPoint.h>
#import <Sparrow/SPQuad.h>
#import <Sparrow/SPQuadBatch.h>
#import <Sparrow/SPRectangle.h>
#import <Sparrow/SPRenderSupport.h>
#import <Sparrow/SPTexture.h>
#import <Sparrow/SPVertexData.h>
#import <Sparrow/SPQuadBatchStack.h>

#pragma mark - SPRenderState

@interface SPRenderState : NSObject
@end

@implementation SPRenderState
{
  @package
    SPMatrix *_modelviewMatrix;
    float _alpha;
    uint _blendMode;
}

#pragma mark Initialization

- (instancetype)init
{
    if ((self = [super init]))
    {
        _modelviewMatrix = [[SPMatrix alloc] init];
        _alpha = 1.0f;
        _blendMode = SPBlendModeNormal;
    }
    return self;
}

- (void)dealloc
{
    [_modelviewMatrix release];
    [super dealloc];
}

+ (instancetype)renderState
{
    return [[[self alloc] init] autorelease];
}

#pragma mark Methods

- (void)setupDerivedFromState:(SPRenderState *)state withModelviewMatrix:(SPMatrix *)matrix
                        alpha:(float)alpha blendMode:(uint)blendMode
{
    _alpha = alpha * state->_alpha;
    _blendMode = blendMode == SPBlendModeAuto ? state->_blendMode : blendMode;

    [_modelviewMatrix copyFromMatrix:state->_modelviewMatrix];
    [_modelviewMatrix prependMatrix:matrix];
}

@end


#pragma mark - SPRenderSupport

@implementation SPRenderSupport
{
    SPMatrix *_projectionMatrix;
    SPMatrix *_mvpMatrix;

#if SP_ENABLE_DRAW_COUNT
    int _numDrawCalls;
#endif
    
    NSMutableArray *_stateStack;
    SPRenderState *_stateStackTop;
    int _stateStackIndex;
    int _stateStackSize;

    SPQuadBatchStack *_texturedQuadBatchStack;
    SPQuadBatchStack *_nonTexturedQuadBatchStack;
    SPQuadBatchStack *_primaryQuadBatchStack;

    NSMutableArray *_clipRectStack;
    int _clipRectStackSize;
}

#pragma mark Initialization

- (instancetype)init
{
    if ((self = [super init]))
    {
        _projectionMatrix = [[SPMatrix alloc] init];
        _mvpMatrix        = [[SPMatrix alloc] init];

        _stateStack = [[NSMutableArray alloc] initWithObjects:[SPRenderState renderState], nil];
        _stateStackIndex = 0;
        _stateStackSize = 1;
        _stateStackTop = _stateStack[0];

        _texturedQuadBatchStack = [SPQuadBatchStack newStack];
        _nonTexturedQuadBatchStack = [SPQuadBatchStack newStack];
        _primaryQuadBatchStack = _texturedQuadBatchStack;
        
        _clipRectStack = [[NSMutableArray alloc] init];
        _clipRectStackSize = 0;

        [self setupOrthographicProjectionWithLeft:0 right:320 top:0 bottom:480];
    }
    return self;
}

- (void)dealloc
{
    [_projectionMatrix release];
    [_mvpMatrix release];
    [_stateStack release];
    [_texturedQuadBatchStack release];
    [_nonTexturedQuadBatchStack release];
    [_clipRectStack release];
    [super dealloc];
}

#pragma mark Methods

- (void)purgeBuffers
{
    [_texturedQuadBatchStack purgeBuffers];
    [_nonTexturedQuadBatchStack purgeBuffers];
}

- (void)clear
{
    [SPRenderSupport clearWithColor:0 alpha:0];
}

- (void)clearWithColor:(uint)color
{
    [SPRenderSupport clearWithColor:color alpha:1];
}

- (void)clearWithColor:(uint)color alpha:(float)alpha
{
    [SPRenderSupport clearWithColor:color alpha:alpha];
}

+ (void)clearWithColor:(uint)color alpha:(float)alpha;
{
#if SP_ENABLE_GL_STATE_CACHE
    sglClearColor(color, alpha);
#else
    float red   = SPColorGetRed(color)   / 255.0f;
    float green = SPColorGetGreen(color) / 255.0f;
    float blue  = SPColorGetBlue(color)  / 255.0f;

    glClearColor(red, green, blue, alpha);
#endif
    glClear(GL_COLOR_BUFFER_BIT);
}

+ (uint)checkForOpenGLError
{
    GLenum error;
    while ((error = glGetError())) NSLog(@"There was an OpenGL error: %s", sglGetErrorString(error));
    return error;
}

#if SP_ENABLE_DRAW_COUNT

- (void)addDrawCalls:(int)count
{
    _numDrawCalls += count;
}

#endif

- (void)setupOrthographicProjectionWithLeft:(float)left right:(float)right
                                        top:(float)top bottom:(float)bottom;
{
    [_projectionMatrix setA:2.0f/(right-left) b:0.0f c:0.0f d:2.0f/(top-bottom)
                         tx:-(right+left) / (right-left)
                         ty:-(top+bottom) / (top-bottom)];
    [self applyClipRect];
}

#pragma mark Rendering

- (void)nextFrame
{
    [self trimQuadBatches];
    [_nonTexturedQuadBatchStack prepForNextFrame];
    [_texturedQuadBatchStack prepForNextFrame];

    _clipRectStackSize = 0;
    _stateStackIndex = 0;
#if SP_ENABLE_DRAW_COUNT
    _numDrawCalls = 0;
#endif
    _stateStackTop = _stateStack[0];
}

- (void)trimQuadBatches
{
    [_texturedQuadBatchStack trimQuadBatches];
    [_nonTexturedQuadBatchStack trimQuadBatches];
}

- (void)batchQuad:(SPQuad *)quad
{
    float alpha = _stateStackTop->_alpha;
    uint blendMode = _stateStackTop->_blendMode;
    SPMatrix *modelviewMatrix = _stateStackTop->_modelviewMatrix;

    SPTexture *quadTexture = quad.texture;
    if( quadTexture ) {
        if( _primaryQuadBatchStack != _texturedQuadBatchStack ) {
            [_primaryQuadBatchStack finishQuadBatch: _projectionMatrix];
            _primaryQuadBatchStack = _texturedQuadBatchStack;
        }
    } else {
        if( _primaryQuadBatchStack != _nonTexturedQuadBatchStack ) {
            [_primaryQuadBatchStack finishQuadBatch: _projectionMatrix];
            _primaryQuadBatchStack = _nonTexturedQuadBatchStack;
        }
    }
    
    if ([_primaryQuadBatchStack -> _quadBatchTop isStateChangeWithTexture: quadTexture
                                                       premultipliedAlpha: quad.premultipliedAlpha
                                                                blendMode: blendMode
                                                                 numQuads:1])
    {
        [self finishQuadBatch]; // next batch
    }

    [_primaryQuadBatchStack -> _quadBatchTop addQuad:quad alpha:alpha blendMode:blendMode matrix:modelviewMatrix];
}

- (void)finishQuadBatch
{
    [_primaryQuadBatchStack finishQuadBatch: _projectionMatrix];
#if SP_ENABLE_DRAW_COUNT
    ++_numDrawCalls;
#endif
}

#pragma mark State Manipulation

- (void)pushStateWithMatrix:(SPMatrix *)matrix alpha:(float)alpha blendMode:(uint)blendMode
{
    SPRenderState *previousState = _stateStackTop;

    if (_stateStackSize == _stateStackIndex + 1)
    {
        [_stateStack addObject:[SPRenderState renderState]];
        ++_stateStackSize;
    }

    _stateStackTop = _stateStack[++_stateStackIndex];

    [_stateStackTop setupDerivedFromState:previousState withModelviewMatrix:matrix
                                    alpha:alpha blendMode:blendMode];
}

- (void)popState
{
    if (_stateStackIndex == 0)
        [NSException raise:SPExceptionInvalidOperation format:@"The state stack must not be empty"];

    _stateStackTop = _stateStack[--_stateStackIndex];
}

- (void)applyBlendModeForPremultipliedAlpha:(BOOL)pma
{
    [SPBlendMode applyBlendFactorsForBlendMode:_stateStackTop->_blendMode premultipliedAlpha:pma];
}

#pragma mark Clipping

- (SPRectangle *)pushClipRect:(SPRectangle *)clipRect
{
    if (_clipRectStack.count < _clipRectStackSize + 1)
        [_clipRectStack addObject:[SPRectangle rectangle]];

    SPRectangle* rectangle = _clipRectStack[_clipRectStackSize];
    [rectangle copyFromRectangle:clipRect];

    // intersect with the last pushed clip rect
    if (_clipRectStackSize > 0)
        rectangle = [rectangle intersectionWithRectangle:_clipRectStack[_clipRectStackSize - 1]];

    ++ _clipRectStackSize;
    [self applyClipRect];

    // return the intersected clip rect so callers can skip draw calls if it's empty
    return rectangle;
}

- (void)popClipRect
{
    if (_clipRectStackSize > 0)
    {
        -- _clipRectStackSize;
        [self applyClipRect];
    }
}

- (void)applyClipRect
{
    [self finishQuadBatch];

    SPContext *context = Sparrow.context;
    if (!context) return;

    if (_clipRectStackSize > 0)
    {
        int width, height;
        SPRectangle *rect = _clipRectStack[_clipRectStackSize-1];
        SPRectangle *clipRect = [SPRectangle rectangle];
        SPTexture *renderTarget = context.renderTarget;

        if (renderTarget)
        {
            width  = renderTarget.nativeWidth;
            height = renderTarget.nativeHeight;
        }
        else
        {
            width  = (int)Sparrow.currentController.view.drawableWidth;
            height = (int)Sparrow.currentController.view.drawableHeight;
        }

        // convert to pixel coordinates (matrix transformation ends up in range [-1, 1])
        SPPoint *topLeft = [_projectionMatrix transformPointWithX:rect.x y:rect.y];
        if (renderTarget) topLeft.y = -topLeft.y;
        clipRect.x = (topLeft.x * 0.5f + 0.5f) * width;
        clipRect.y = (0.5f - topLeft.y * 0.5f) * height;

        SPPoint *bottomRight = [_projectionMatrix transformPointWithX:rect.right y:rect.bottom];
        if (renderTarget) bottomRight.y = -bottomRight.y;
        clipRect.right  = (bottomRight.x * 0.5f + 0.5f) * width;
        clipRect.bottom = (0.5f - bottomRight.y * 0.5f) * height;

        // flip y coordiantes when rendering to backbuffer
        if (!renderTarget) clipRect.y = height - clipRect.y - clipRect.height;

        SPRectangle *bufferRect = [SPRectangle rectangleWithX:0 y:0 width:width height:height];
        SPRectangle *scissorRect = [clipRect intersectionWithRectangle:bufferRect];

        // a negative rectangle is not allowed
        if (scissorRect.width < 0 || scissorRect.height < 0)
            [scissorRect setEmpty];

        context.scissorBox = scissorRect;
    }
    else
    {
        context.scissorBox = nil;
    }
}

#pragma mark Properties

- (void)setProjectionMatrix:(SPMatrix *)projectionMatrix
{
    [_projectionMatrix copyFromMatrix:projectionMatrix];
    [self applyClipRect];
}

- (SPMatrix *)mvpMatrix
{
    [_mvpMatrix copyFromMatrix:_stateStackTop->_modelviewMatrix];
    [_mvpMatrix appendMatrix:_projectionMatrix];
    return _mvpMatrix;
}

- (SPMatrix *)modelviewMatrix
{
    return _stateStackTop->_modelviewMatrix;
}

- (float)alpha
{
    return _stateStackTop->_alpha;
}

- (void)setAlpha:(float)alpha
{
    _stateStackTop->_alpha = alpha;
}

- (uint)blendMode
{
    return _stateStackTop->_blendMode;
}

- (void)setBlendMode:(uint)blendMode
{
    if (blendMode != SPBlendModeAuto)
        _stateStackTop->_blendMode = blendMode;
}

- (SPTexture *)renderTarget
{
    return Sparrow.context.renderTarget;
}

- (void)setRenderTarget:(SPTexture *)renderTarget
{
    [self applyClipRect];

    Sparrow.context.renderTarget = renderTarget;
}

@end
