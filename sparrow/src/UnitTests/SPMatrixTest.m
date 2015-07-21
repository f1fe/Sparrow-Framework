//
//  SPMatrixTest.m
//  Sparrow
//
//  Created by Daniel Sperl on 26.03.09.
//  Copyright 2011-2014 Gamua. All rights reserved.
//
//  This program is free software; you can redistribute it and/or modify
//  it under the terms of the Simplified BSD License.
//

#import "SPTestCase.h"

@interface SPMatrixTest : SPTestCase 

@end

@implementation SPMatrixTest
{
    SPMatrix *countMatrix;
    SPMatrix *identMatrix;
}

- (void) setUp
{
    countMatrix = [[SPMatrix alloc] initWithA:1 b:2 c:3 d:4 tx:5 ty:6];
    identMatrix = [[SPMatrix alloc] init];
}

- (void)testInit
{
    BOOL isEqual = [self checkMatrixValues:countMatrix a:1.0f b:2.0f c:3.0f d:4.0f tx:5.0f ty:6.0f];
    XCTAssertTrue(isEqual, @"wrong matrix: %@", countMatrix);
    isEqual = [self checkMatrixValues:identMatrix a:1.0f b:0.0f c:0.0f d:1.0f tx:0.0f ty:0.0f];
    XCTAssertTrue(isEqual, @"wrong matrix: %@", identMatrix);
}

- (void)testCopy
{
    SPMatrix *copy = [countMatrix copy];
    XCTAssertTrue([countMatrix isEqualToMatrix:copy], @"copy not equal: %@", copy);
    XCTAssertFalse(countMatrix == copy, @"copy is identical");
}

- (void)testAppendMatrix
{
    SPMatrix *copy = [countMatrix copy];
    [copy appendMatrix:identMatrix];
    XCTAssertTrue([countMatrix isEqualToMatrix:copy], @"multiplication with identity modified matrix");
    copy = [identMatrix copy];
    [copy appendMatrix:countMatrix];
    XCTAssertTrue([countMatrix isEqualToMatrix:copy], @"multiplication with identity modified matrix");
    
    SPMatrix *countDownMatrix = [[SPMatrix alloc] initWithA:9 b:8 c:7 d:6 tx:5 ty:4];
    [copy appendMatrix:countDownMatrix];
    XCTAssertTrue([self checkMatrixValues:copy a:23 b:20 c:55 d:48 tx:92 ty:80], 
                 @"wrong matrix: %@", copy);
    [countDownMatrix appendMatrix:countMatrix];
    XCTAssertTrue([self checkMatrixValues:countDownMatrix a:33 b:50 c:25 d:38 tx:22 ty:32],
                 @"wrong matrix: %@", copy);  
}

- (void)testInvert
{
    [countMatrix invert];
    XCTAssertTrue([self checkMatrixValues:countMatrix a:-2 b:1 c:3.0f/2.0f d:-0.5f tx:1 ty:-2],
                 @"invert produced wrong result: %@", countMatrix);
    
    SPMatrix *translateMatrix = [SPMatrix matrixWithIdentity];
    [translateMatrix translateXBy:20 yBy:40];
    [translateMatrix invert];
    
    XCTAssertTrue([self checkMatrixValues:translateMatrix a:1 b:0 c:0 d:1 tx:-20 ty:-40],
                @"invert produced wrong result: %@", translateMatrix);
}

- (void)testTranslate
{
    [identMatrix translateXBy:5 yBy:7];
    SPPoint *point = [[SPPoint alloc] initWithX:10 y:20];
    SPPoint *tPoint = [identMatrix transformPoint:point];
    XCTAssertTrue(SPIsFloatEqual(15, tPoint.x), @"wrong x value: %f", tPoint.x);
    XCTAssertTrue(SPIsFloatEqual(27, tPoint.y), @"wrong y value: %f", tPoint.y);    
}

- (void)testRotate
{
    [identMatrix rotateBy:PI/2.0f];
    SPPoint *point = [[SPPoint alloc] initWithX:10 y:0];
    SPPoint *rPoint = [identMatrix transformPoint:point];
    XCTAssertTrue(SPIsFloatEqual(0, rPoint.x), @"wrong x value: %f", rPoint.x);
    XCTAssertTrue(SPIsFloatEqual(10, rPoint.y), @"wrong y value: %f", rPoint.y);
    
    [identMatrix identity];
    [identMatrix rotateBy:PI];
    point.y = 20;
    rPoint = [identMatrix transformPoint:point];
    XCTAssertTrue(SPIsFloatEqual(-10, rPoint.x), @"wrong x value: %f", rPoint.x);
    XCTAssertTrue(SPIsFloatEqual(-20, rPoint.y), @"wrong y value: %f", rPoint.y);
}

- (void)testScale
{
    [identMatrix scaleXBy:2.0 yBy:0.5];
    SPPoint *point = [[SPPoint alloc] initWithX:10 y:20];
    SPPoint *sPoint = [identMatrix transformPoint:point];
    XCTAssertTrue(SPIsFloatEqual(20.0f, sPoint.x), @"wrong x value: %f", sPoint.x);
    XCTAssertTrue(SPIsFloatEqual(10.0f, sPoint.y), @"wrong y value: %f", sPoint.y);    
}

- (void)testConcatenatedTransformations
{
    [identMatrix rotateBy:PI/2.0f];    
    [identMatrix scaleBy:0.5f];
    [identMatrix translateXBy:0.0f yBy:5.0];
    SPPoint *ctPoint = [identMatrix transformPointWithX:10 y:0];
    XCTAssertTrue(SPIsFloatEqual(0.0f, ctPoint.x), @"wrong x value: %f", ctPoint.x);
    XCTAssertTrue(SPIsFloatEqual(10.0f, ctPoint.y), @"wrong y value: %f", ctPoint.y);    
}

- (BOOL)checkMatrixValues:(SPMatrix *)matrix a:(float)a b:(float)b c:(float)c d:(float)d 
                       tx:(float)tx ty:(float)ty
{
    return SPIsFloatEqual(a, matrix.a) && SPIsFloatEqual(b, matrix.b) &&
           SPIsFloatEqual(b, matrix.b) && SPIsFloatEqual(c, matrix.c) &&
           SPIsFloatEqual(tx, matrix.tx) && SPIsFloatEqual(ty, matrix.ty);
}

@end