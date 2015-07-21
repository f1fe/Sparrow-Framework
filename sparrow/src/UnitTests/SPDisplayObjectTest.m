//
//  SPDisplayObjectTest.h
//  Sparrow
//
//  Created by Daniel Sperl on 13.04.09.
//  Copyright 2011-2014 Gamua. All rights reserved.
//
//  This program is free software; you can redistribute it and/or modify
//  it under the terms of the Simplified BSD License.
//

#import "SPTestCase.h"

@interface SPDisplayObjectTest : SPTestCase

@end

@implementation SPDisplayObjectTest

- (void)testBase
{
    SPSprite *base = [[SPSprite alloc] init];
    SPSprite *child = [[SPSprite alloc] init];
    SPSprite *grandChild = [[SPSprite alloc] init];
    
    [base addChild:child];
    [child addChild:grandChild];
    
    XCTAssertEqualObjects(base, grandChild.base, @"wrong base");
}

- (void)testRoot
{
    SPStage  *stage = [[SPStage alloc] init];
    SPSprite *root = [[SPSprite alloc] init];
    SPSprite *child = [[SPSprite alloc] init];
    SPSprite *grandChild = [[SPSprite alloc] init];
    
    [stage addChild:root];
    [root addChild:child];
    [child addChild:grandChild];
    
    XCTAssertEqualObjects(root, grandChild.root, @"wrong root");
}

- (void)testTransformationMatrixToSpace
{
    SPSprite *sprite = [SPSprite sprite];
    SPSprite *child = [SPSprite sprite];
    child.x = 30;
    child.y = 20;
    child.scaleX = 1.2f;
    child.scaleY = 1.5f;
    child.rotation = PI/4.0f;    
    [sprite addChild:child];
    
    SPMatrix *matrix = [sprite transformationMatrixToSpace:child];    
    SPMatrix *expectedMatrix = child.transformationMatrix;
    [expectedMatrix invert];
    XCTAssertTrue([matrix isEqualToMatrix:expectedMatrix], @"wrong matrix");

    matrix = [child transformationMatrixToSpace:sprite];
    XCTAssertTrue([child.transformationMatrix isEqualToMatrix:matrix], @"wrong matrix");
    
    // more is tested indirectly via 'testBoundsInSpace' in DisplayObjectContainerTest
}

- (void)testTransformationMatrix
{
    SPSprite *sprite = [[SPSprite alloc] init];
    sprite.x = 50;
    sprite.y = 100;
    sprite.rotation = PI / 4;
    sprite.scaleX = 0.5;
    sprite.scaleY = 1.5;
    
    SPMatrix *matrix = [[SPMatrix alloc] init];
    [matrix scaleXBy:sprite.scaleX yBy:sprite.scaleY];
    [matrix rotateBy:sprite.rotation];
    [matrix translateXBy:sprite.x yBy:sprite.y];
    
    XCTAssertTrue([sprite.transformationMatrix isEqualToMatrix:matrix], @"wrong matrix");
}

- (void)testSetTransformationMatrix
{
    float x = 50;
    float y = 100;
    float scaleX = 0.5f;
    float scaleY = 1.5f;
    float rotation = PI / 4.0f;
    
    SPMatrix *matrix = [[SPMatrix alloc] init];
    [matrix scaleXBy:scaleX yBy:scaleY];
    [matrix rotateBy:rotation];
    [matrix translateXBy:x yBy:y];
    
    SPSprite *sprite = [[SPSprite alloc] init];
    sprite.transformationMatrix = matrix;
    
    XCTAssertEqualWithAccuracy(x, sprite.x, E, @"wrong x coord");
    XCTAssertEqualWithAccuracy(y, sprite.y, E, @"wrong y coord");
    XCTAssertEqualWithAccuracy(scaleX, sprite.scaleX, E, @"wrong scaleX");
    XCTAssertEqualWithAccuracy(scaleY, sprite.scaleY, E, @"wrong scaleY");
    XCTAssertEqualWithAccuracy(rotation, sprite.rotation, E, @"wrong rotation");
}

- (void)testSetTransformationMatrixWithRightAngle
{
    SPSprite *sprite = [[SPSprite alloc] init];
    float angles[] = { PI_HALF, -PI_HALF };
    NSArray *matrices = @[
        [SPMatrix matrixWithA:0 b: 1 c:-1 d:0 tx:0 ty:0],
        [SPMatrix matrixWithA:0 b:-1 c: 1 d:0 tx:0 ty:0]
    ];

    for (int i=0; i<2; ++i)
    {
        float angle = angles[i];
        SPMatrix *matrix = matrices[i];
        sprite.transformationMatrix = matrix;

        XCTAssertEqualWithAccuracy(0.0f, sprite.x, E, @"wrong x coord");
        XCTAssertEqualWithAccuracy(0.0f, sprite.y, E, @"wrong y coord");
        XCTAssertEqualWithAccuracy(1.0f, sprite.scaleX, E, @"wrong scaleX");
        XCTAssertEqualWithAccuracy(1.0f, sprite.scaleY, E, @"wrong scaleY");
        XCTAssertEqualWithAccuracy(angle, sprite.rotation, E, @"wrong rotation");
    }
}

- (void)testSetTransformationMatrixWithZeroValues
{
    SPMatrix *matrix = [SPMatrix matrixWithA:0 b:0 c:0 d:0 tx:0 ty:0];
    SPSprite *sprite = [[SPSprite alloc] init];
    sprite.transformationMatrix = matrix;

    XCTAssertEqual(0.0f, sprite.x, @"wrong x");
    XCTAssertEqual(0.0f, sprite.y, @"wrong y");
    XCTAssertEqual(0.0f, sprite.scaleX, @"wrong scaleX");
    XCTAssertEqual(0.0f, sprite.scaleY, @"wrong scaleY");
    XCTAssertEqual(0.0f, sprite.rotation, @"wrong rotation");
    XCTAssertEqual(0.0f, sprite.skewX, @"wrong skewX");
    XCTAssertEqual(0.0f, sprite.skewY, @"wrong skewY");
}

- (void)testBounds
{
    SPQuad *quad = [[SPQuad alloc] initWithWidth:10 height:20];
    quad.x = -10;
    quad.y = 10;
    quad.rotation = PI_HALF;
    SPRectangle *bounds = quad.bounds;
    
    XCTAssertTrue(SPIsFloatEqual(-30, bounds.x), @"wrong bounds.x: %f", bounds.x);
    XCTAssertTrue(SPIsFloatEqual(10, bounds.y), @"wrong bounds.y: %f", bounds.y);
    XCTAssertTrue(SPIsFloatEqual(20, bounds.width), @"wrong bounds.width: %f", bounds.width);
    XCTAssertTrue(SPIsFloatEqual(10, bounds.height), @"wrong bounds.height: %f", bounds.height);
    
    bounds = [quad boundsInSpace:quad];
    XCTAssertTrue(SPIsFloatEqual(0, bounds.x), @"wrong inner bounds.x: %f", bounds.x);
    XCTAssertTrue(SPIsFloatEqual(0, bounds.y), @"wrong inner bounds.y: %f", bounds.y);
    XCTAssertTrue(SPIsFloatEqual(10, bounds.width), @"wrong inner bounds.width: %f", bounds.width);
    XCTAssertTrue(SPIsFloatEqual(20, bounds.height), @"wrong innter bounds.height: %f", bounds.height);
}

- (void)testZeroSize
{
    SPSprite *sprite = [SPSprite sprite];
    XCTAssertEqualWithAccuracy(1.0f, sprite.scaleX, E, @"wrong scaleX value");
    XCTAssertEqualWithAccuracy(1.0f, sprite.scaleY, E, @"wrong scaleY value");
    
    // sprite is empty, scaling should thus have no effect!
    sprite.width = 100;
    sprite.height = 200;
    XCTAssertEqualWithAccuracy(1.0f, sprite.scaleX, E, @"wrong scaleX value");
    XCTAssertEqualWithAccuracy(1.0f, sprite.scaleY, E, @"wrong scaleY value");
    XCTAssertEqualWithAccuracy(0.0f, sprite.width,  E, @"wrong width");
    XCTAssertEqualWithAccuracy(0.0f, sprite.height, E, @"wrong height");
    
    // setting a value to zero should be no problem -- and the original size should be remembered.
    SPQuad *quad = [SPQuad quadWithWidth:100 height:200];
    quad.scaleX = 0.0f;
    quad.scaleY = 0.0f;
    XCTAssertEqualWithAccuracy(0.0f, quad.width,  E, @"wrong width");
    XCTAssertEqualWithAccuracy(0.0f, quad.height, E, @"wrong height");

    quad.scaleX = 1.0f;
    quad.scaleY = 1.0f;
    XCTAssertEqualWithAccuracy(100.0f, quad.width,  E, @"wrong width");
    XCTAssertEqualWithAccuracy(200.0f, quad.height, E, @"wrong height");
    XCTAssertEqualWithAccuracy(1.0f, quad.scaleX,   E, @"wrong scaleX value");
    XCTAssertEqualWithAccuracy(1.0f, quad.scaleY,   E, @"wrong scaleY value");
}

- (void)testLocalToGlobal
{
    SPSprite *root = [[SPSprite alloc] init];
    SPSprite *sprite = [[SPSprite alloc] init];
    sprite.x = 10;
    sprite.y = 20;
    [root addChild:sprite];
    SPSprite *sprite2 = [[SPSprite alloc] init];
    sprite2.x = 150;
    sprite2.y = 200;    
    [sprite addChild:sprite2];
    
    SPPoint *localPoint = [SPPoint pointWithX:0 y:0];
    SPPoint *globalPoint = [sprite2 localToGlobal:localPoint];
    SPPoint *expectedPoint = [SPPoint pointWithX:160 y:220];    
    XCTAssertTrue([globalPoint isEqualToPoint:expectedPoint], @"wrong global point");
    
    // the position of the root object should be irrelevant -- we want the coordinates
    // *within* the root coordinate system!
    root.x = 50;
    globalPoint = [sprite2 localToGlobal:localPoint];
    XCTAssertTrue([globalPoint isEqualToPoint:expectedPoint], @"wrong global point");
}

- (void)testLocalToGlobalWithPivot
{
    SPSprite *sprite = [SPSprite sprite];
    SPQuad *quad = [SPQuad quadWithWidth:40 height:30];
    quad.x = 10;
    quad.y = 20;
    quad.pivotX = quad.width;
    quad.pivotY = quad.height;
    [sprite addChild:quad];
    SPPoint *point = [SPPoint pointWithX:0.0f y:0.0f];
    
    SPPoint *globalPoint = [quad localToGlobal:point];
    XCTAssertEqualWithAccuracy(-30.0f, globalPoint.x, E, @"wrong global point with pivot");
    XCTAssertEqualWithAccuracy(-10.0f, globalPoint.y, E, @"wrong global point with pivot");
}

- (void)testGlobalToLocal
{
    SPSprite *root = [[SPSprite alloc] init];
    SPSprite *sprite = [[SPSprite alloc] init];
    sprite.x = 10;
    sprite.y = 20;
    [root addChild:sprite];
    SPSprite *sprite2 = [[SPSprite alloc] init];
    sprite2.x = 150;
    sprite2.y = 200;    
    [sprite addChild:sprite2];
    
    SPPoint *globalPoint = [SPPoint pointWithX:160 y:220];
    SPPoint *localPoint = [sprite2 globalToLocal:globalPoint];
    SPPoint *expectedPoint = [SPPoint pointWithX:0 y:0];    
    XCTAssertTrue([localPoint isEqualToPoint:expectedPoint], @"wrong local point");
    
    // the position of the root object should be irrelevant -- we want the coordinates
    // *within* the root coordinate system!
    root.x = 50;
    localPoint = [sprite2 globalToLocal:globalPoint];
    XCTAssertTrue([localPoint isEqualToPoint:expectedPoint], @"wrong local point");
}

- (void)testHitTestPoint
{
    SPQuad *quad = [[SPQuad alloc] initWithWidth:25 height:10];
    
    XCTAssertNotNil([quad hitTestPoint:[SPPoint pointWithX:15 y:5]], 
                   @"point should be inside");
    XCTAssertNotNil([quad hitTestPoint:[SPPoint pointWithX:0 y:0]],
                   @"point should be inside");
    XCTAssertNotNil([quad hitTestPoint:[SPPoint pointWithX:25 y:0]], 
                   @"point should be inside");
    XCTAssertNotNil([quad hitTestPoint:[SPPoint pointWithX:25 y:10]], 
                   @"point should be inside");
    XCTAssertNotNil([quad hitTestPoint:[SPPoint pointWithX:0 y:10]], 
                   @"point should be inside");
    XCTAssertNil([quad hitTestPoint:[SPPoint pointWithX:-1 y:-1]], 
                @"point should be outside");    
    XCTAssertNil([quad hitTestPoint:[SPPoint pointWithX:26 y:11]], 
                @"point should be outside");

    quad.visible = NO;
    XCTAssertNil([quad hitTestPoint:[SPPoint pointWithX:15 y:5]], 
                @"hitTest should fail, object invisible");
        
    quad.visible = YES;
    quad.touchable = NO;
    XCTAssertNil([quad hitTestPoint:[SPPoint pointWithX:15 y:5]], 
                @"hitTest should fail, object untouchable");    
}

- (void)testRotation
{
    SPQuad *quad = [SPQuad quadWithWidth:100 height:100];
    
    quad.rotation = SPDegreesToRadians(400);  
    XCTAssertEqualWithAccuracy(SPDegreesToRadians(40.0f), quad.rotation, E, @"wrong angle");    
    quad.rotation = SPDegreesToRadians(220); 
    XCTAssertEqualWithAccuracy(SPDegreesToRadians(-140.0f), quad.rotation, E, @"wrong angle");    
    quad.rotation = SPDegreesToRadians(180);  
    XCTAssertEqualWithAccuracy(SPDegreesToRadians(180.0f), quad.rotation, E, @"wrong angle");    
    quad.rotation = SPDegreesToRadians(-90); 
    XCTAssertEqualWithAccuracy(SPDegreesToRadians(-90.0f), quad.rotation, E, @"wrong angle");    
    quad.rotation = SPDegreesToRadians(-179); 
    XCTAssertEqualWithAccuracy(SPDegreesToRadians(-179.0f), quad.rotation, E, @"wrong angle");    
    quad.rotation = SPDegreesToRadians(-180); 
    XCTAssertEqualWithAccuracy(SPDegreesToRadians(-180.0f), quad.rotation, E, @"wrong angle");    
    quad.rotation = SPDegreesToRadians(-181); 
    XCTAssertEqualWithAccuracy(SPDegreesToRadians(179.0f), quad.rotation, E, @"wrong angle");    
    quad.rotation = SPDegreesToRadians(-300); 
    XCTAssertEqualWithAccuracy(SPDegreesToRadians(60.0f), quad.rotation, E, @"wrong angle");    
    quad.rotation = SPDegreesToRadians(-370); 
    XCTAssertEqualWithAccuracy(SPDegreesToRadians(-10.0f), quad.rotation, E, @"wrong angle");
}

- (void)testPivotPoint
{
    float width = 100.0f;
    float height = 150.0f;
    
    // a quad with a pivot point should behave exactly as a quad without 
    // pivot point inside a sprite
    
    SPSprite *sprite = [SPSprite sprite];
    SPQuad *innerQuad = [SPQuad quadWithWidth:width height:height];
    [sprite addChild:innerQuad];
    
    SPQuad *quad = [SPQuad quadWithWidth:width height:height];
    
    XCTAssertTrue([sprite.bounds isEqualToRectangle:quad.bounds], @"Bounds are not equal (no pivot)");
   
    innerQuad.x = -50;
    quad.pivotX = 50;
    
    innerQuad.y = -20;
    quad.pivotY = 20;
    
    XCTAssertTrue([sprite.bounds isEqualToRectangle:quad.bounds], @"Bounds are not equal (pivot)");
    
    sprite.rotation = SPDegreesToRadians(45);
    quad.rotation = SPDegreesToRadians(45);
    
    XCTAssertTrue([sprite.bounds isEqualToRectangle:quad.bounds], @"Bounds are not equal (pivot, rotation)");

    sprite.scaleX = 1.5f;
    quad.scaleX = 1.5f;
    
    XCTAssertTrue([sprite.bounds isEqualToRectangle:quad.bounds], @"Bounds are not equal (pivot, scaleX");
    
    sprite.scaleY = 0.6f;
    quad.scaleY = 0.6f;
    
    XCTAssertTrue([sprite.bounds isEqualToRectangle:quad.bounds], @"Bounds are not equal (pivot, scaleY");

    sprite.x = 5.0f;
    sprite.y = 20.0f;
    
    quad.x = 5.0f;
    quad.y = 20.0f;
    
    XCTAssertTrue([sprite.bounds isEqualToRectangle:quad.bounds], @"Bounds are not equal (pivot, translation");
}
 
- (void)testName
{
    SPSprite *sprite = [SPSprite sprite];
    XCTAssertNil(sprite.name, @"name not nil after initialization");
    
    sprite.name = @"hugo";
    XCTAssertEqualObjects(@"hugo", sprite.name, @"wrong name");
}

@end