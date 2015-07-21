//
//  SPRectangleTest.m
//  Sparrow
//
//  Created by Daniel Sperl on 25.04.09.
//  Copyright 2011-2014 Gamua. All rights reserved.
//
//  This program is free software; you can redistribute it and/or modify
//  it under the terms of the Simplified BSD License.
//

#import "SPTestCase.h"

@interface SPRectangleTest : SPTestCase

@end

@implementation SPRectangleTest

- (void)testInit
{
    SPRectangle *rect = [[SPRectangle alloc] initWithX:10 y:20 width:30 height:40];
    XCTAssertTrue(SPIsFloatEqual(10, rect.x), @"wrong x");
    XCTAssertTrue(SPIsFloatEqual(20, rect.y), @"wrong y");
    XCTAssertTrue(SPIsFloatEqual(30, rect.width), @"wrong width");
    XCTAssertTrue(SPIsFloatEqual(40, rect.height), @"wrong height");    
}

- (void)testSides
{
    SPRectangle *rect = [SPRectangle rectangleWithX:5 y:10 width:5 height:2];
    XCTAssertEqualWithAccuracy(rect.x, rect.left, E, @"wrong left property");
    XCTAssertEqualWithAccuracy(rect.y, rect.top, E, @"wrong top property");
    XCTAssertEqualWithAccuracy(rect.x + rect.width, rect.right, E, @"wrong right property");
    XCTAssertEqualWithAccuracy(rect.y + rect.height, rect.bottom, E, @"wrong bottom property");
}

- (void)testChangeSides
{
    SPRectangle *rect = [SPRectangle rectangleWithX:5 y:10 width:5 height:2];
    
    rect.right = 11.0f;
    XCTAssertEqualWithAccuracy(11.0f, rect.right, E, @"wrong right property");
    XCTAssertEqualWithAccuracy( 6.0f, rect.width, E, @"wrong width");
    
    rect.bottom = 11.0f;
    XCTAssertEqualWithAccuracy(11.0f, rect.bottom, E, @"wrong bottom property");
    XCTAssertEqualWithAccuracy( 1.0f, rect.height, E, @"wrong height");
}

- (void)testBorderPoints
{
    SPRectangle *rect = [SPRectangle rectangleWithX:5 y:10 width:5 height:2];
    
    SPPoint *topLeft = rect.topLeft;
    XCTAssertEqualWithAccuracy(rect.x, topLeft.x, E, @"wrong topLeft.x property");
    XCTAssertEqualWithAccuracy(rect.y, topLeft.y, E, @"wrong topLeft.y property");
    
    SPPoint *bottomRight = rect.bottomRight;
    XCTAssertEqualWithAccuracy(rect.right, bottomRight.x,  E, @"wrong bottomRight.x property");
    XCTAssertEqualWithAccuracy(rect.bottom, bottomRight.y, E, @"wrong bottomRight.y property");

    SPPoint *size = rect.size;
    XCTAssertEqualWithAccuracy(rect.width, size.x,  E, @"wrong size.x property");
    XCTAssertEqualWithAccuracy(rect.height, size.y, E, @"wrong size.y property");
}

- (void)testContainsPoint
{
    SPRectangle *rect = [SPRectangle rectangleWithX:10 y:20 width:30 height:40];
    XCTAssertFalse([rect containsPoint:[SPPoint pointWithX:0 y:0]], @"point inside");
    XCTAssertTrue([rect containsPoint:[SPPoint pointWithX:15 y:25]], @"point not inside");
    XCTAssertTrue([rect containsPoint:[SPPoint pointWithX:10 y:20]], @"point not inside");
    XCTAssertTrue([rect containsPoint:[SPPoint pointWithX:40 y:60]], @"point not inside");
}

- (void)testContainsRect
{
    SPRectangle *rect = [SPRectangle rectangleWithX:-5 y:-10 width:10 height:20];
    
    SPRectangle *overlapRect = [SPRectangle rectangleWithX:-10 y:-15 width:10 height:10];
    SPRectangle *identRect = [SPRectangle rectangleWithX:-5 y:-10 width:10 height:20];
    SPRectangle *outsideRect = [SPRectangle rectangleWithX:10 y:10 width:10 height:10];
    SPRectangle *touchingRect = [SPRectangle rectangleWithX:5 y:0 width:10 height:10];
    SPRectangle *insideRect = [SPRectangle rectangleWithX:0 y:0 width:1 height:2];
    
    XCTAssertFalse([rect containsRectangle:overlapRect], @"overlapping, not inside");
    XCTAssertTrue([rect containsRectangle:identRect], @"identical, should be inside");
    XCTAssertFalse([rect containsRectangle:outsideRect], @"should be outside");
    XCTAssertFalse([rect containsRectangle:touchingRect], @"touching, should be outside");
    XCTAssertTrue([rect containsRectangle:insideRect], @"should be inside");    
}

- (void)testIntersectionWithRectangle
{
    SPRectangle *expectedRect;
    SPRectangle *rect = [SPRectangle rectangleWithX:-5 y:-10 width:10 height:20];

    SPRectangle *overlapRect = [SPRectangle rectangleWithX:-10 y:-15 width:10 height:10];
    SPRectangle *identRect = [SPRectangle rectangleWithX:-5 y:-10 width:10 height:20];
    SPRectangle *outsideRect = [SPRectangle rectangleWithX:10 y:10 width:10 height:10];
    SPRectangle *touchingRect = [SPRectangle rectangleWithX:5 y:0 width:10 height:10];
    SPRectangle *insideRect = [SPRectangle rectangleWithX:0 y:0 width:1 height:2];
    
    expectedRect = [SPRectangle rectangleWithX:-5 y:-10 width:5 height:5];
    XCTAssertTrue([[rect intersectionWithRectangle:overlapRect] isEqualToRectangle:expectedRect],
                  @"wrong intersection shape");
    
    expectedRect = rect;
    XCTAssertTrue([[rect intersectionWithRectangle:identRect] isEqualToRectangle:expectedRect],
                 @"wrong intersection shape");

    expectedRect = [SPRectangle rectangleWithX:0 y:0 width:0 height:0];
    XCTAssertTrue([[rect intersectionWithRectangle:outsideRect] isEqualToRectangle:expectedRect],
                 @"intersection should be empty");
    
    expectedRect = [SPRectangle rectangleWithX:5 y:0 width:0 height:10];
    XCTAssertTrue([[rect intersectionWithRectangle:touchingRect] isEqualToRectangle:expectedRect],
                 @"wrong intersection shape");

    expectedRect = insideRect;
    XCTAssertTrue([[rect intersectionWithRectangle:insideRect] isEqualToRectangle:expectedRect],
                 @"wrong intersection shape");
}

- (void)testUniteWithRectangle
{
    SPRectangle *expectedRect;
    SPRectangle *rect = [SPRectangle rectangleWithX:-5 y:-10 width:10 height:20];
    
    SPRectangle *topLeftRect = [SPRectangle rectangleWithX:-15 y:-20 width:5 height:5];
    SPRectangle *innerRect = [SPRectangle rectangleWithX:-5 y:-5 width:10 height:10];
    
    expectedRect = [SPRectangle rectangleWithX:-15 y:-20 width:20 height:30];
    XCTAssertTrue([[rect uniteWithRectangle:topLeftRect] isEqualToRectangle:expectedRect], @"wrong union");
    XCTAssertTrue([[rect uniteWithRectangle:innerRect] isEqualToRectangle:rect], @"wrong union");
}

- (void)testNilArguments
{
    SPRectangle *rect = [SPRectangle rectangleWithX:0 y:0 width:10 height:20];
    XCTAssertFalse([rect intersectsRectangle:nil], @"could not deal with nil argument");
    XCTAssertNil([rect intersectionWithRectangle:nil], @"could not deal with nil argument");

    XCTAssertTrue([[rect uniteWithRectangle:nil] isEqualToRectangle:rect], @"could not deal with nil argument");
}

@end