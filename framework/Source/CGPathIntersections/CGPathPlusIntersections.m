//
//  CGPathPlusIntersections.m
//  CGPathIntersections
//
//  Created by Cal Stephens on 11/13/16.
//  Copyright © 2016 Cal Stephens. All rights reserved.
//  ported to objc by Steve Wainwright on 27/05/2022.
//

#import "CGPathPlusIntersections.h"
#import "CGPathImage.h"


BOOL CGPathIntersectsPathWithOther(CGPathRef path1, CGPathRef path2) {
    return CGPathCountIntersectionPointsWithOther(path1, path2) > 0;
}

NSUInteger CGPathCountIntersectionPointsWithOther(CGPathRef path1, CGPathRef path2) {
    CGPathImage *pathImage1 = [[CGPathImage alloc] initFromPath:path1];
    CGPathImage *pathImage2 = [[CGPathImage alloc] initFromPath:path2];
    
    
    return [[pathImage1 intersectionPointsWithOther:pathImage2] count];
}

CGPoint CGPathIntersectionPointWithOtherAtIndex(CGPathRef path1, CGPathRef path2, size_t index) {
    CGPathImage *pathImage1 = [[CGPathImage alloc] initFromPath:path1];
    CGPathImage *pathImage2 = [[CGPathImage alloc] initFromPath:path2];
        
    NSArray<NSValue*> *values = [pathImage1 intersectionPointsWithOther:pathImage2];
    if ( /*index < 0 &&*/ index > values.count - 1 ) {
        return CGPointMake(-0.0, -0.0);
    }
    
    CGPoint point;
#if TARGET_OS_OSX
    point = (CGPoint)[[values objectAtIndex:index] pointValue];
#else
    point = [[values objectAtIndex:index] CGPointValue];
#endif
    return point;
}
