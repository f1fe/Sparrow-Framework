//
//  SPQuadBatchStack.m
//  Sparrow
//
//  Created by Larry Li on 8/10/15.
//  Copyright 2015 Larry Li. All rights reserved.
//
//  This program is free software; you can redistribute it and/or modify
//  it under the terms of the Simplified BSD License.
//

#import "SPQuadBatchStack.h"
#import <Sparrow/SPQuadBatch.h>

@implementation SPQuadBatchStack
{
    NSMutableArray *_quadBatches;
    int _quadBatchIndex;
    int _quadBatchSize;
}

+ (instancetype)newStack
{
    return [[[self class] alloc] init];
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _quadBatches = [[NSMutableArray alloc] initWithObjects:[SPQuadBatch quadBatch], nil];
        _quadBatchIndex = 0;
        _quadBatchSize = 1;
        _quadBatchTop = _quadBatches[0];
    }
    return self;
}

- (void)dealloc
{
    [_quadBatches release];
    [super dealloc];
}

- (SPQuadBatch *)topQuadBatch
{
    return _quadBatchTop;
}

- (void)purgeBuffers
{
    [_quadBatches removeAllObjects];
    
    _quadBatchTop = [SPQuadBatch quadBatch];
    [_quadBatches addObject:_quadBatchTop];
    
    _quadBatchIndex = 0;
    _quadBatchSize = 1;
}

- (void)prepForNextFrame
{
    _quadBatchIndex = 0;
    _quadBatchTop = _quadBatches[0];
}

- (void)trimQuadBatches
{
    int numUsedBatches = _quadBatchIndex + 1;
    if (_quadBatchSize >= 16 && _quadBatchSize > 2 * numUsedBatches)
    {
        int numToRemove = _quadBatchSize - numUsedBatches;
        [_quadBatches removeObjectsInRange:(NSRange){ _quadBatchSize-numToRemove-1, numToRemove }];
        _quadBatchSize = (int)_quadBatches.count;
    }
}

- (void)finishQuadBatch: (SPMatrix *)projectionMatrix
{
    if (_quadBatchTop.numQuads)
    {
        [_quadBatchTop renderWithMvpMatrix:projectionMatrix];
        [_quadBatchTop reset];
        
        if (_quadBatchSize == _quadBatchIndex + 1)
        {
            [_quadBatches addObject:[SPQuadBatch quadBatch]];
            ++_quadBatchSize;
        }
        _quadBatchTop = _quadBatches[++_quadBatchIndex];
    }
}

@end
