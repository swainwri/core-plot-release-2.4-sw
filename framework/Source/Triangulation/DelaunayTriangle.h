//
//  DelaunayTriangle.h
//  DelaunayTest
//
//  Created by Mike Rotondo on 7/17/11.
//  Copyright 2011 Stanford. All rights reserved.
//

#import <Foundation/Foundation.h>

@class DelaunayPoint;
@class DelaunayEdge;
@class DelaunayTriangulation;

@interface DelaunayTriangle : NSObject

@property (nonatomic, readonly) NSArray<DelaunayEdge*> *edges;
@property (nonatomic, strong) DelaunayPoint *startPoint;
#if TARGET_OS_OSX
@property (nonatomic, strong) NSColor *color;
#else
@property (nonatomic, strong) UIColor *color;
#endif
@property (nonatomic, readonly) NSArray<DelaunayPoint*> *points;

#if TARGET_OS_OSX
+ (DelaunayTriangle *) triangleWithEdges:(NSArray<DelaunayEdge*>*)edges andStartPoint:(DelaunayPoint *)startPoint andColor:(NSColor *)color;
#else
+ (DelaunayTriangle *) triangleWithEdges:(NSArray<DelaunayEdge*>*)edges andStartPoint:(DelaunayPoint *)startPoint andColor:(UIColor *)color;
#endif
- (BOOL)containsPoint:(DelaunayPoint *)point;
- (CGPoint)circumcenter;
- (BOOL)inFrameTriangleOfTriangulation:(DelaunayTriangulation *)triangulation;
- (void)drawInContext:(CGContextRef)ctx;
- (NSSet *)neighbors;
- (DelaunayPoint *)pointNotInEdge:(DelaunayEdge *)edge;
- (DelaunayEdge *)edgeStartingWithPoint:(DelaunayPoint *)point;
- (DelaunayEdge *)edgeEndingWithPoint:(DelaunayPoint *)point;
- (DelaunayPoint *)startPointOfEdge:(DelaunayEdge *)edgeInQuestion;
- (DelaunayPoint *)endPointOfEdge:(DelaunayEdge *)edgeInQuestion;

@end
