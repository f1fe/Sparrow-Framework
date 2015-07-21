//
//  SPPointTest.m
//  Sparrow
//
//  Created by Daniel Sperl on 25.03.09.
//  Copyright 2011-2014 Gamua. All rights reserved.
//
//  This program is free software; you can redistribute it and/or modify
//  it under the terms of the Simplified BSD License.
//

#import "SPTestCase.h"

@interface SPPointTest :  XCTestCase

@end

@implementation SPPointTest
{
    SPPoint *_p1;
    SPPoint *_p2;
}

- (void) setUp
{
    _p1 = [[SPPoint alloc] initWithX:2 y:3];
    _p2 = [[SPPoint alloc] initWithX:4 y:1];    
}

- (void)testInit
{
    SPPoint *point = [[SPPoint alloc] init];
    XCTAssertEqual(0.0f, point.x, @"x is not zero");
    XCTAssertEqual(0.0f, point.y, @"y is not zero");
}

- (void)testInitWithXandY
{
    SPPoint *point = [[SPPoint alloc] initWithX:3 y:4];
    XCTAssertEqual(3.0f, point.x, @"wrong x value");
    XCTAssertEqual(4.0f, point.y, @"wrong y value");
}

- (void)testLength
{
    SPPoint *point = [[SPPoint alloc] initWithX:-4 y:3];
    XCTAssertTrue(SPIsFloatEqual(5.0f, point.length), @"wrong length");
    point.x = 0;
    point.y = 0;
    XCTAssertEqual(0.0f, point.length, @"wrong length");
}

- (void)testLengthSquared
{
    SPPoint *point = [[SPPoint alloc] initWithX:-4 y:3];
    XCTAssertEqualWithAccuracy(25.0f, point.lengthSquared, E, @"wrong squared length");
}

- (void)testAngle
{    
    SPPoint *point = [[SPPoint alloc] initWithX:10 y:0];
    XCTAssertTrue(SPIsFloatEqual(0.0f, point.angle), @"wrong angle: %f", point.angle);
    point.y = 10;
    XCTAssertTrue(SPIsFloatEqual(PI/4.0f, point.angle), @"wrong angle: %f", point.angle);
    point.x = 0;
    XCTAssertTrue(SPIsFloatEqual(PI/2.0f, point.angle), @"wrong angle: %f", point.angle);
    point.x = -10;
    XCTAssertTrue(SPIsFloatEqual(3*PI/4.0f, point.angle), @"wrong angle: %f", point.angle);
    point.y = 0;
    XCTAssertTrue(SPIsFloatEqual(PI, point.angle), @"wrong angle: %f", point.angle);
    point.y = -10;
    XCTAssertTrue(SPIsFloatEqual(-3*PI/4.0f, point.angle), @"wrong angle: %f", point.angle);
    point.x = 0;
    XCTAssertTrue(SPIsFloatEqual(-PI/2.0f, point.angle), @"wrong angle: %f", point.angle);
    point.x = 10;
    XCTAssertTrue(SPIsFloatEqual(-PI/4.0f, point.angle), @"wrong angle: %f", point.angle);
}

- (void)testAddPoint
{
    SPPoint *result = [_p1 addPoint:_p2];
    XCTAssertTrue(SPIsFloatEqual(6.0f, result.x), @"wrong x value");
    XCTAssertTrue(SPIsFloatEqual(4.0f, result.y), @"wrong y value");
}

- (void)testSubtractPoint
{
    SPPoint *result = [_p1 subtractPoint:_p2];
    XCTAssertTrue(SPIsFloatEqual(-2.0f, result.x), @"wrong x value");
    XCTAssertTrue(SPIsFloatEqual(2.0f, result.y), @"wrong y value");
}

- (void)testScale
{
    SPPoint *point = [SPPoint pointWithX:0.0f y:0.0f];
    point = [point scaleBy:100.0f];
    XCTAssertEqualWithAccuracy(point.x, 0.0f, E, @"wrong x value");
    XCTAssertEqualWithAccuracy(point.y, 0.0f, E, @"wrong y value");
    
    point = [SPPoint pointWithX:1.0f y:2.0f];
    float origLength = point.length;
    point = [point scaleBy:2.0f];
    float scaledLength = point.length;
    XCTAssertEqualWithAccuracy(point.x, 2.0f, E, @"wrong x value");
    XCTAssertEqualWithAccuracy(point.y, 4.0f, E, @"wrong y value");
    XCTAssertEqualWithAccuracy(origLength * 2.0f, scaledLength, E, @"wrong length");
}

- (void)testNormalize
{
    SPPoint *result = [_p1 normalize];
    XCTAssertTrue(SPIsFloatEqual(1.0f, result.length), @"wrong length");
    XCTAssertTrue(SPIsFloatEqual(_p1.angle, result.angle), @"wrong angle");
    SPPoint *origin = [[SPPoint alloc] init];
    result  = [origin normalize];
    XCTAssertEqualWithAccuracy(result.length, 1.0f, E, @"wrong length");
}

- (void)testInvert
{
    SPPoint *point = [_p1 invert];
    XCTAssertEqualWithAccuracy(-_p1.x, point.x, E, @"wrong x value");
    XCTAssertEqualWithAccuracy(-_p1.y, point.y, E, @"wrong y value");
}

- (void)testDotProduct
{
    XCTAssertEqualWithAccuracy(11.0f, [_p1 dot:_p2], E, @"wrong dot product");
}

- (void)testRotate
{
    SPPoint *point = [SPPoint pointWithX:0 y:5];
    SPPoint *rPoint = [point rotateBy:PI_HALF];
    XCTAssertEqualWithAccuracy(-5.0f, rPoint.x, E, @"wrong rotation");
    XCTAssertEqualWithAccuracy( 0.0f, rPoint.y, E, @"wrong rotation");
    
    rPoint = [point rotateBy:PI];
    XCTAssertEqualWithAccuracy( 0.0f, rPoint.x, E, @"wrong rotation");
    XCTAssertEqualWithAccuracy(-5.0f, rPoint.y, E, @"wrong rotation");
}

- (void)testClone
{
    SPPoint *result = [_p1 copy];
    XCTAssertEqual(_p1.x, result.x, @"wrong x value");
    XCTAssertEqual(_p1.y, result.y, @"wrong y value");
    XCTAssertFalse(result == _p1, @"object should not be identical");
    XCTAssertTrue([_p1 isEqualToPoint:result], @"objects should be equal");
}

- (void)testIsEqual
{
    XCTAssertFalse([_p1 isEqual:_p2], @"should not be equal");    
    SPPoint *p3 = [[SPPoint alloc] initWithX:_p1.x y:_p1.y];
    XCTAssertTrue([_p1 isEqualToPoint:p3], @"should be equal");
    p3.x += 0.0000001;
    p3.y -= 0.0000001;
    XCTAssertTrue([_p1 isEqualToPoint:p3], @"should be equal, as difference is smaller than epsilon");
}

- (void)testIsOrigin
{
    SPPoint *point = [SPPoint point];
    XCTAssertTrue(point.isOrigin, @"point not indicated as being in the origin");
    
    point.x = 1.0f;
    XCTAssertFalse(point.isOrigin, @"point wrongly indicated as being in the origin");
    
    point.x = 0.0f;
    point.y = 1.0f;
    XCTAssertFalse(point.isOrigin, @"point wrongly indicated as being in the origin");
}

- (void)testDistance
{
    SPPoint *p3 = [[SPPoint alloc] initWithX:5 y:0];
    SPPoint *p4 = [[SPPoint alloc] initWithX:5 y:5];
    float distance = [SPPoint distanceFromPoint:p3 toPoint:p4];
    XCTAssertTrue(SPIsFloatEqual(5.0f, distance), @"wrong distance");
    p3.y = -5;
    distance = [SPPoint distanceFromPoint:p3 toPoint:p4];
    XCTAssertTrue(SPIsFloatEqual(10.0f, distance), @"wrong distance");
}

- (void)testAngleBetweenPoints
{
    SPPoint *p1 = [SPPoint pointWithX:3.0f y:0.0f];
    SPPoint *p2 = [SPPoint pointWithX:0.0f y:1.5f];
    SPPoint *p3 = [SPPoint pointWithX:-2.0f y:0.0f];
    SPPoint *p4 = [SPPoint pointWithX:0.0f y:-4.0f];
    
    XCTAssertEqualWithAccuracy(PI_HALF, [SPPoint angleBetweenPoint:p1 andPoint:p2], E, @"wrong angle");
    XCTAssertEqualWithAccuracy(PI, [SPPoint angleBetweenPoint:p1 andPoint:p3], E, @"wrong angle");
    XCTAssertEqualWithAccuracy(PI_HALF, [SPPoint angleBetweenPoint:p1 andPoint:p4], E, @"wrong angle");
}

- (void)testPolarPoint
{
    float angle = 5.0 * PI / 4.0;
    float negAngle = -(2*PI - angle);
    float length = 2.0f;
    SPPoint *p3 = [SPPoint pointWithPolarLength:length angle:angle];
    XCTAssertTrue(SPIsFloatEqual(length, p3.length), @"wrong length");
    XCTAssertTrue(SPIsFloatEqual(negAngle, p3.angle), @"wrong angle");
    XCTAssertTrue(SPIsFloatEqual(-cosf(angle-PI)*length, p3.x), @"wrong x");
    XCTAssertTrue(SPIsFloatEqual(-sinf(angle-PI)*length, p3.y), @"wrong y");    
}

- (void)testInterpolate
{
    SPPoint *interpolation;
    
    interpolation = [SPPoint interpolateFromPoint:_p1 toPoint:_p2 ratio:0.25f];
    XCTAssertEqualWithAccuracy(interpolation.x, 2.5f, E, @"wrong interpolated x");
    XCTAssertEqualWithAccuracy(interpolation.y, 2.5f, E, @"wrong interpolated y");

    interpolation = [SPPoint interpolateFromPoint:_p1 toPoint:_p2 ratio:-0.25f];
    XCTAssertEqualWithAccuracy(interpolation.x, 1.5f, E, @"wrong interpolated x");
    XCTAssertEqualWithAccuracy(interpolation.y, 3.5f, E, @"wrong interpolated y");

    interpolation = [SPPoint interpolateFromPoint:_p1 toPoint:_p2 ratio:1.25f];
    XCTAssertEqualWithAccuracy(interpolation.x, 4.5f, E, @"wrong interpolated x");
    XCTAssertEqualWithAccuracy(interpolation.y, 0.5f, E, @"wrong interpolated y");
    
    SPPoint *p1 = [SPPoint pointWithX:2.0f y:1.0f];
    SPPoint *p2 = [SPPoint pointWithX:-2.0f y:-1.0f];
    
    interpolation = [SPPoint interpolateFromPoint:p1 toPoint:p2 ratio:0.5f];    
    XCTAssertEqualWithAccuracy(interpolation.x, 0.0f, E, @"wrong interpolated x");
    XCTAssertEqualWithAccuracy(interpolation.y, 0.0f, E, @"wrong interpolated y");
    
    interpolation = [SPPoint interpolateFromPoint:p1 toPoint:p2 ratio:0.0f];
    XCTAssertEqualWithAccuracy(interpolation.x, 2.0f, E, @"wrong interpolated x");
    XCTAssertEqualWithAccuracy(interpolation.y, 1.0f, E, @"wrong interpolated y");
    
    interpolation = [SPPoint interpolateFromPoint:p1 toPoint:p2 ratio:1.0f];
    XCTAssertEqualWithAccuracy(interpolation.x, -2.0f, E, @"wrong interpolated x");
    XCTAssertEqualWithAccuracy(interpolation.y, -1.0f, E, @"wrong interpolated y");
}

@end