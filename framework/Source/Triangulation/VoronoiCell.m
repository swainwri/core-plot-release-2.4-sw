//
//  VoronoiCell.m
//  DelaunayTest
//
//  Created by Mike Rotondo on 7/21/11.
//  Copyright 2011 Stanford. All rights reserved.
//

#import "VoronoiCell.h"
#import "DelaunayPoint.h"

@implementation VoronoiCell
@synthesize site;
@synthesize nodes;

+ (VoronoiCell *)voronoiCellAtSite:(DelaunayPoint *)site withNodes:(NSArray *)nodes {
    VoronoiCell *cell = [[self alloc] init];
    
    cell.site = site;
    cell.nodes = nodes;
    
    return cell;
}


- (void)drawInContext:(CGContextRef)ctx {
    NSValue *prevPoint = [self.nodes lastObject];
#if TARGET_OS_OSX
    NSPoint p = [prevPoint pointValue];
#else
    CGPoint p = [prevPoint CGPointValue];
#endif
    CGContextMoveToPoint(ctx, p.x, p.y);
    for ( NSValue *point in self.nodes) {
#if TARGET_OS_OSX
        p = [point pointValue];
#else
        p = [point CGPointValue];
#endif
        CGContextAddLineToPoint(ctx, p.x, p.y);        
    }
}

- (CGFloat)area {
    CGFloat xys = 0.0;
    CGFloat yxs = 0.0;
    
    NSValue *prevPoint = [self.nodes objectAtIndex:0];
#if TARGET_OS_OSX
    NSPoint prevP = [prevPoint pointValue];
#else
    CGPoint prevP = [prevPoint CGPointValue];
#endif
    for ( NSValue *point in [self.nodes reverseObjectEnumerator]) {
#if TARGET_OS_OSX
        NSPoint p = [point pointValue];
#else
        CGPoint p = [point CGPointValue];
#endif
        xys += prevP.x * p.y;
        yxs += prevP.y * p.x;
        prevP = p;
    }
    
    return (xys - yxs) * 0.5;
}

@end
