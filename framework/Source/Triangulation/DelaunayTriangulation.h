//
//  DelaunayTriangulation.h
//  DelaunayTest
//
//  Created by Mike Rotondo on 7/17/11.
//  Copyright 2011 Stanford. All rights reserved.
//

#import <Foundation/Foundation.h>

@class DelaunayPoint;
@class DelaunayTriangle;

@interface DelaunayTriangulation : NSObject <NSCopying> 

@property (nonatomic, strong) NSMutableSet *points;
@property (nonatomic, strong) NSMutableSet *edges;
@property (nonatomic, strong) NSMutableSet *triangles;
@property (nonatomic, strong) NSSet *frameTrianglePoints;

+ (DelaunayTriangulation *)triangulation;
+ (DelaunayTriangulation *)triangulationWithSize:(CGSize)size;
+ (DelaunayTriangulation *)triangulationWithRect:(CGRect)rect;
#if TARGET_OS_OSX
- (BOOL)addPoint:(DelaunayPoint *)newPoint withColor:(NSColor *)color;
#else
- (BOOL)addPoint:(DelaunayPoint *)newPoint withColor:(UIColor *)color;
#endif
- (DelaunayTriangle *)triangleContainingPoint:(DelaunayPoint *)point;
- (void)enforceDelaunayProperty;
- (NSDictionary*)voronoiCells;
- (void)interpolateWeightsWithPoint:(DelaunayPoint *)point;

-(void)triangle_interpolate_linearForM:(NSInteger)m n:(NSInteger)n p1:(double*)p1 p2:(double*)p2 p3:(double*)p3 p:(double*)p v1:(double*)v1 v2:(double*)v2 v3:(double*)v3 v:(double**)v size:(size_t)size;
-(double)triangle_extrapolate_linear_singletonForP1:(double*)p1 p2:(double*)p2 p:(double*)p v1:(double)v1 v2:(double)v2;
@end
