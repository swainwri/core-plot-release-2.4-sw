//
//  DelaunayTriangulation.m
//  DelaunayTest
//
//  Created by Mike Rotondo on 7/17/11.
//  Copyright 2011 Stanford. All rights reserved.
//

#import "DelaunayTriangulation.h"
#import "DelaunayPoint.h"
#import "DelaunayEdge.h"
#import "DelaunayTriangle.h"
#import "VoronoiCell.h"

@interface DelaunayTriangulation ()

- (void)removeTriangle:(DelaunayTriangle *)triangle;

@end

@implementation DelaunayTriangulation
@synthesize points;
@synthesize edges;
@synthesize triangles;
@synthesize frameTrianglePoints;

+ (DelaunayTriangulation *)triangulation
{
    return [DelaunayTriangulation triangulationWithSize:CGSizeMake(20000, 20000)];
}

+ (DelaunayTriangulation *)triangulationWithSize:(CGSize)size
{
    return [DelaunayTriangulation triangulationWithRect:CGRectMake(0, 0, size.width, size.height)];
}

+ (DelaunayTriangulation *)triangulationWithRect:(CGRect)rect
{
    DelaunayTriangulation *dt = [[self alloc] init];
    
    // ADD FRAME TRIANGLE
    CGFloat w = rect.size.width;
    CGFloat h = rect.size.height;
    CGFloat x = rect.origin.x;
    CGFloat y = rect.origin.y;

    DelaunayPoint *p1 = [DelaunayPoint pointAtX:x andY:y];
    DelaunayPoint *p2 = [DelaunayPoint pointAtX:x andY:h * 2];
    DelaunayPoint *p3 = [DelaunayPoint pointAtX:w * 2 andY:y];

    DelaunayEdge *e1 = [DelaunayEdge edgeWithPoints:@[p1, p2]];
    DelaunayEdge *e2 = [DelaunayEdge edgeWithPoints:@[p2, p3]];
    DelaunayEdge *e3 = [DelaunayEdge edgeWithPoints:@[p3, p1]];
    
    DelaunayTriangle *triangle = [DelaunayTriangle triangleWithEdges:@[e1, e2, e3] andStartPoint:p1 andColor:nil];
    dt.frameTrianglePoints = [NSSet setWithObjects:p1, p2, p3, nil];
    
    dt.triangles = [NSMutableSet setWithObject:triangle];
    dt.edges = [NSMutableSet setWithObjects:e1, e2, e3, nil];
    dt.points = [NSMutableSet setWithObjects:p1, p2, p3, nil];
    
    return dt;
}

- (id)copyWithZone:(NSZone *)zone
{
    DelaunayTriangulation *dt = [[DelaunayTriangulation alloc] init];
    
    NSMutableSet *triangleCopies = [NSMutableSet setWithCapacity: [self.triangles count]];
    NSMutableSet *edgeCopies = [NSMutableSet setWithCapacity: [self.edges count]];
    NSMutableSet *pointCopies = [NSMutableSet setWithCapacity: [self.points count]];
    
    for (DelaunayPoint *point in self.points)
    {
        [pointCopies addObject:[point copy]];
    }
    
    for (DelaunayEdge *edge in self.edges)
    {
        DelaunayPoint *p1 = [pointCopies member:[edge.points objectAtIndex:0]];
        DelaunayPoint *p2 = [pointCopies member:[edge.points objectAtIndex:1]];
        [edgeCopies addObject:[DelaunayEdge edgeWithPoints:@[p1, p2]]];
    }
    
    for (DelaunayTriangle *triangle in self.triangles)
    {
        DelaunayEdge *e1 = [edgeCopies member:[triangle.edges objectAtIndex:0]];
        DelaunayEdge *e2 = [edgeCopies member:[triangle.edges objectAtIndex:1]];
        DelaunayEdge *e3 = [edgeCopies member:[triangle.edges objectAtIndex:2]];
        DelaunayTriangle *triangleCopy = [DelaunayTriangle triangleWithEdges:@[e1, e2, e3] andStartPoint:[pointCopies member:triangle.startPoint] andColor:triangle.color];
        [triangleCopies addObject:triangleCopy];
    }

    dt.triangles = triangleCopies;
    dt.edges = edgeCopies;
    dt.points = pointCopies;
    NSMutableSet *frameTrianglePointsCopy = [NSMutableSet setWithCapacity:3];
    for ( DelaunayPoint *frameTrianglePoint in self.frameTrianglePoints ) {
        id point = [pointCopies member:frameTrianglePoint];
        if( point != nil ) {
            [frameTrianglePointsCopy addObject:point];
        }
    }
    dt.frameTrianglePoints = frameTrianglePointsCopy;
    
    return dt;
}

- (void)removeTriangle:(DelaunayTriangle *)triangle
{
    for (DelaunayEdge *edge in triangle.edges)
    {
        [edge.triangles removeObject:triangle];
    }
    [self.triangles removeObject:triangle];
}

- (void)removeEdge:(DelaunayEdge *)edge
{
    assert([edge.triangles count] == 0);
    for (DelaunayPoint *point in edge.points)
    {
        [point.edges removeObject:edge];
    }
    [self.edges removeObject:edge];
}
#if TARGET_OS_OSX
- (BOOL)addPoint:(DelaunayPoint *)newPoint withColor:(NSColor *)color
#else
- (BOOL)addPoint:(DelaunayPoint *)newPoint withColor:(UIColor *)color
#endif
{
    // TODO(mrotondo): Mirror the points into the 8 surrounding regions to fix up interpolation around the edges.
    DelaunayTriangle * triangle = [self triangleContainingPoint:newPoint];
    if (triangle != nil)
    {
        [self.points addObject:newPoint];
        
        [self removeTriangle:triangle];
        
        DelaunayEdge *e1 = [triangle.edges objectAtIndex:0];
        DelaunayEdge *e2 = [triangle.edges objectAtIndex:1];
        DelaunayEdge *e3 = [triangle.edges objectAtIndex:2];

        DelaunayPoint *edgeStartPoint = triangle.startPoint;
        DelaunayEdge *new1 = [DelaunayEdge edgeWithPoints:@[edgeStartPoint, newPoint]];
        edgeStartPoint = [e1 otherPoint:edgeStartPoint];
        DelaunayEdge *new2 = [DelaunayEdge edgeWithPoints:@[edgeStartPoint, newPoint]];
        edgeStartPoint = [e2 otherPoint:edgeStartPoint];
        DelaunayEdge *new3 = [DelaunayEdge edgeWithPoints:@[edgeStartPoint, newPoint]];
        
        [self.edges addObject:new1];
        [self.edges addObject:new2];
        [self.edges addObject:new3];
        
        // Use start point and counter-clockwise ordered edges to enforce counter-clockwiseness in point-containment checking
        DelaunayTriangle * e1Triangle = [DelaunayTriangle triangleWithEdges:@[new1, e1, new2]
                                                              andStartPoint:newPoint 
                                                                   andColor:color];
        DelaunayTriangle * e2Triangle = [DelaunayTriangle triangleWithEdges:@[new2, e2, new3]
                                                              andStartPoint:newPoint
                                                                   andColor:color];
        DelaunayTriangle * e3Triangle = [DelaunayTriangle triangleWithEdges:@[new3, e3, new1]
                                                              andStartPoint:newPoint
                                                                   andColor:color];
        
        [self.triangles addObject:e1Triangle];        
        [self.triangles addObject:e2Triangle];        
        [self.triangles addObject:e3Triangle];

        [self enforceDelaunayProperty];
//        [self enforceDelaunayPropertyStartingWithTriangles:@[e1Triangle, e2Triangle, e3Triangle]];
        
        return YES;
    }
    return NO;
}

- (DelaunayTriangle *)triangleContainingPoint:(DelaunayPoint *)point
{
    for (DelaunayTriangle* triangle in self.triangles)
    {
        if ([triangle containsPoint:point])
        {
            return triangle;
        }
    }
    return nil;
}

//- (void)enforceDelaunayPropertyStartingWithTriangles:(NSArray *)initialTriangles
//{
//    NSMutableSet *trianglesToCheck = [NSMutableSet setWithArray:initialTriangles];
//    
//    while ([trianglesToCheck count])
//    {
//        // Flip all non-Delaunay edges
//        DelaunayTriangle *triangle = [trianglesToCheck anyObject];
//        [trianglesToCheck removeObject:triangle];
//        
////        NSLog(@"Looking at triangle %@ (there are %d left)", triangle, [trianglesToCheck count]);
//        if (![self.triangles containsObject:triangle])
//        {
//            NSLog(@"This is not in self.triangles!");
//        }
//        
//        CGPoint circumcenter = [triangle circumcenter];
//        
//        float radius = sqrtf(powf(triangle.startPoint.x - circumcenter.x, 2) + powf(triangle.startPoint.y - circumcenter.y, 2));
//        
//        for (DelaunayEdge *sharedEdge in triangle.edges)
//        {
//            DelaunayTriangle *neighborTriangle = [sharedEdge neighborOf:triangle];
//            if (neighborTriangle != nil)
//            {
////                NSLog(@"Looking at neighbor %@ via edge %@", neighborTriangle, sharedEdge);
//                if (![self.triangles containsObject:neighborTriangle])
//                {
//                    NSLog(@"THIS IS NOT IN SELF.TRIANGLES");
//                }
//                if (![self.edges containsObject:sharedEdge])
//                {
//                    NSLog(@"THIS IS NOT IN SELF.EDGES");
//                }
//                
//                // Find the non-shared point in the other triangle
//                DelaunayPoint *ourNonSharedPoint = [triangle pointNotInEdge:sharedEdge];
//                DelaunayPoint *theirNonSharedPoint = [neighborTriangle pointNotInEdge:sharedEdge];
//                if (sqrtf(powf(theirNonSharedPoint.x - circumcenter.x, 2) + powf(theirNonSharedPoint.y - circumcenter.y, 2)) < radius )
//                {
//                    NSLog(@"Flipping!!!!!!!!!!!!!!");
//
////                    NSLog(@"NOPE");
////                    continue;
//
//                    // If the non-shared point is within the circumcircle of this triangle, flip to share the other two points
//                    [self removeTriangle:triangle];
//                    [self removeTriangle:neighborTriangle];
//                    [trianglesToCheck removeObject:triangle];
//                    [trianglesToCheck removeObject:neighborTriangle];
//
//                    // Get the edges before & after the shared edge in the triangle
//                    DelaunayEdge *beforeEdge = [triangle edgeStartingWithPoint:ourNonSharedPoint];
//                    DelaunayEdge *afterEdge = [triangle edgeEndingWithPoint:ourNonSharedPoint];
//                    
//                    DelaunayEdge *newEdge = [DelaunayEdge edgeWithPoints:[NSArray arrayWithObjects:theirNonSharedPoint, ourNonSharedPoint, nil]];
//                    [self.edges addObject:newEdge];
//                    
//                    // Get the edges before & after the shared edge in the neighbor triangle
//                    DelaunayEdge *neighborBeforeEdge = [neighborTriangle edgeStartingWithPoint:theirNonSharedPoint];
//                    DelaunayEdge *neighborAfterEdge = [neighborTriangle edgeEndingWithPoint:theirNonSharedPoint];
//                    
//                    DelaunayTriangle *newTriangle1 = [DelaunayTriangle triangleWithEdges:[NSArray arrayWithObjects:newEdge, beforeEdge, neighborAfterEdge, nil]
//                                                                           andStartPoint:theirNonSharedPoint
//                                                                                andColor:triangle.color];
//                    
//                    NSLog(@"SANITY CHECK:\n%@", newTriangle1);
//                    
//                    DelaunayTriangle *newTriangle2 = [DelaunayTriangle triangleWithEdges:[NSArray arrayWithObjects:neighborBeforeEdge, afterEdge, newEdge, nil]
//                                                                           andStartPoint:theirNonSharedPoint
//                                                                                andColor:neighborTriangle.color];
//
//                    
//                    NSLog(@"SANITY CHECK:\n%@", newTriangle2);
//
//                    [self.triangles addObject:newTriangle1];
//                    [self.triangles addObject:newTriangle2];
//
//                    [trianglesToCheck addObject:newTriangle1];
//                    [trianglesToCheck addObject:newTriangle2];
//                    [trianglesToCheck unionSet:[newTriangle1 neighbors]];
//                    [trianglesToCheck unionSet:[newTriangle2 neighbors]];
//                }
//            }
//        }
//    }
//}

- (void)enforceDelaunayProperty
{
    bool hadToFlip;
    
    do {
        hadToFlip = NO;
        
        NSMutableSet *trianglesToRemove = [NSMutableSet set];
        NSMutableSet *edgesToRemove = [NSMutableSet set];
        NSMutableSet *trianglesToAdd = [NSMutableSet set];
        
        // Flip all non-Delaunay edges
        for (DelaunayTriangle * __strong triangle in self.triangles) {
            CGPoint circumcenter = [triangle circumcenter];
            CGFloat radius = sqrt(pow(triangle.startPoint.x - circumcenter.x, 2) + pow(triangle.startPoint.y - circumcenter.y, 2));
            
            for (DelaunayEdge *sharedEdge in triangle.edges)
            {
                DelaunayTriangle *neighborTriangle = [sharedEdge neighborOf:triangle];
                if (neighborTriangle != nil)
                {
                    // Find the non-shared point in the other triangle
                    DelaunayPoint *ourNonSharedPoint = [triangle pointNotInEdge:sharedEdge];
                    DelaunayPoint *theirNonSharedPoint = [neighborTriangle pointNotInEdge:sharedEdge];
                    if (sqrt(pow(theirNonSharedPoint.x - circumcenter.x, 2) + pow(theirNonSharedPoint.y - circumcenter.y, 2)) < radius )
                    {
                        // If the non-shared point is within the circumcircle of this triangle, flip to share the other two points
                        [trianglesToRemove addObject:triangle];
                        [trianglesToRemove addObject:neighborTriangle];
                        [edgesToRemove addObject:sharedEdge];
                        
                        // Get the edges before & after the shared edge in the triangle
                        DelaunayEdge *beforeEdge = [triangle edgeStartingWithPoint:ourNonSharedPoint];
                        DelaunayEdge *afterEdge = [triangle edgeEndingWithPoint:ourNonSharedPoint];
                        
                        DelaunayEdge *newEdge = [DelaunayEdge edgeWithPoints:@[theirNonSharedPoint, ourNonSharedPoint]];
                        [self.edges addObject:newEdge];
                        
                        // Get the edges before & after the shared edge in the neighbor triangle
                        DelaunayEdge *neighborBeforeEdge = [neighborTriangle edgeStartingWithPoint:theirNonSharedPoint];
                        DelaunayEdge *neighborAfterEdge = [neighborTriangle edgeEndingWithPoint:theirNonSharedPoint];
                        
                        DelaunayTriangle *newTriangle1 = [DelaunayTriangle triangleWithEdges:@[newEdge, beforeEdge, neighborAfterEdge]
                                                                               andStartPoint:theirNonSharedPoint
                                                                                    andColor:triangle.color];
                        
                        DelaunayTriangle *newTriangle2 = [DelaunayTriangle triangleWithEdges:@[neighborBeforeEdge, afterEdge, newEdge]
                                                                               andStartPoint:theirNonSharedPoint
                                                                                    andColor:neighborTriangle.color];
                        
                        [trianglesToAdd addObject:newTriangle1];
                        [trianglesToAdd addObject:newTriangle2];
//                        [self removeEdge:sharedEdge];
                        hadToFlip = YES;
                        break;
                    }
                }
            }
            if (hadToFlip)
            {
                break;
            }
        }
        
        for (DelaunayTriangle* triangleToRemove in trianglesToRemove)
        {
            [self removeTriangle:triangleToRemove];
        }
        for (DelaunayEdge *edgeToRemove in edgesToRemove)
        {
            [self removeEdge:edgeToRemove];
        }
        for (DelaunayTriangle* triangleToAdd in trianglesToAdd)
        {
            [self.triangles addObject:triangleToAdd];
        }
    } while (hadToFlip);
}

- (NSDictionary*)voronoiCells
{
    NSMutableDictionary *cells = [NSMutableDictionary dictionary];
    for (DelaunayPoint *point in self.points)
    {
        // Don't add voronoi cells at the frame triangle points
        if ([self.frameTrianglePoints containsObject:point])
            continue;
        
        NSArray *pointEdges = [point counterClockwiseEdges];
        NSMutableArray *nodes = [NSMutableArray arrayWithCapacity:[pointEdges count]];
        DelaunayEdge *prevEdge = [pointEdges lastObject];
        for (DelaunayEdge *edge in pointEdges)
        {
            DelaunayTriangle *sharedTriangle = [edge sharedTriangleWithEdge:prevEdge];
#if TARGET_OS_OSX
            [nodes addObject:[NSValue valueWithPoint:[sharedTriangle circumcenter]]];
#else
            [nodes addObject:[NSValue valueWithCGPoint:[sharedTriangle circumcenter]]];
#endif
            
            prevEdge = edge;
        }
        //[cells addObject:[VoronoiCell voronoiCellAtSite:point withNodes:nodes]];
        [cells setObject:[VoronoiCell voronoiCellAtSite:point withNodes:nodes] forKey:point.idNumber];
    }
    return cells;
}

- (void)interpolateWeightsWithPoint:(DelaunayPoint *)point
{
    DelaunayTriangulation *testTriangulation = [self copy];//[[self copy] autorelease];
    BOOL added = [testTriangulation addPoint:point withColor:nil];
    // TODO(mrotondo): Special-case touches right on top of existing points here.
    if (added)
    {
        NSDictionary *voronoiCells = [self voronoiCells];
        // TODO(mrotondo): Interpolate by adding and removing a point instead of copying the whole triangulation
        NSDictionary *testVoronoiCells = [testTriangulation voronoiCells];
        CGFloat fractionSum = 0.0;
        NSMutableDictionary *fractions = [NSMutableDictionary dictionaryWithCapacity:[voronoiCells count]];
        for ( NSNumber *pointIDNumber in [voronoiCells keyEnumerator] )
        {
            VoronoiCell *cell = [voronoiCells objectForKey:pointIDNumber];
            VoronoiCell *testCell = [testVoronoiCells objectForKey:pointIDNumber];
            CGFloat fractionalChange = 0.0;
            if ( [cell area] > 0.0 )
                fractionalChange = 1.0 - MAX(MIN([testCell area] / [cell area], 1.0), 0.0);
            fractionSum += fractionalChange;
            [fractions setObject:[NSNumber numberWithDouble:(double)fractionalChange] forKey:pointIDNumber];
        }
        if (fractionSum > 0.0)
        {
            for ( NSNumber *pointIDNumber in [voronoiCells keyEnumerator] )
            {
                VoronoiCell *cell = [voronoiCells objectForKey:pointIDNumber];
                NSNumber *fractionalChange = [fractions objectForKey:pointIDNumber];
                cell.site.contribution = (CGFloat)[fractionalChange floatValue] / fractionSum;
            }
        }
    }
}

#pragma mark -
#pragma mark Triangular Interpolation

-(double)triangle_areaForP1X:(double)p1x p1y:(double)p1y p2x:(double)p2x p2y:(double)p2y p3x:(double)p3x p3y:(double)p3y {
    //****************************************************************************80
    //
    //  Purpose:
    //
    //    TRIANGLE_AREA computes the area of a triangle in 2D.
    //
    //  Discussion:
    //
    //    If the triangle's vertices are given in counter clockwise order,
    //    the area will be positive.  If the triangle's vertices are given
    //    in clockwise order, the area will be negative!
    //
    //    An earlier version of this routine always returned the absolute
    //    value of the computed area.  I am convinced now that that is
    //    a less useful result!  For instance, by returning the signed
    //    area of a triangle, it is possible to easily compute the area
    //    of a nonconvex polygon as the sum of the (possibly negative)
    //    areas of triangles formed by node 1 and successive pairs of vertices.
    //
    //  Licensing:
    //
    //    This code is distributed under the GNU LGPL license.
    //
    //  Modified:
    //
    //    17 October 2005
    //
    //  Author:
    //
    //    John Burkardt
    //
    //  Parameters:
    //
    //    Input, double P1X, P1Y, P2X, P2Y, P3X, P3Y, the coordinates
    //    of the vertices P1, P2, and P3.
    //
    //    Output, double TRIANGLE_AREA, the area of the triangle.
    //
    return 0.5 * ( p1x * ( p2y - p3y ) + p2x * ( p3y - p1y ) + p3x * ( p1y - p2y ) );
}

// then zero sign value denotes that point lies exactly on the edge.
//(More exactly - on the line containing edge. Signs for two other edges show whether point is between vertices)
-(double) sign:(double)p1x p1y:(double)p1y p2x:(double)p2x p2y:(double )p2y p3x:(double)p3x p3y:(double)p3y {
    return (p1x - p3x) * (p2y - p3y) - (p2x - p3x) * (p1y - p3y);
}

-(void)triangle_interpolate_linearForM:(NSInteger)m n:(NSInteger)n p1:(double*)p1 p2:(double*)p2 p3:(double*)p3 p:(double*)p v1:(double*)v1 v2:(double*)v2 v3:(double*)v3 v:(double**)v size:(size_t)size {

//****************************************************************************80
//
//  Purpose:
//
//    TRIANGLE_INTERPOLATE_LINEAR interpolates data given on a triangle's vertices.
//
//  Licensing:
//
//    This code is distributed under the GNU LGPL license.
//
//  Modified:
//
//    19 January 2015
//
//  Author:
//
//    John Burkardt
//
//  Parameters:
//
//    Input, int M, the dimension of the quantity.
//
//    Input, int N, the number of points.
//
//    Input, double P1[2], P2[2], P3[2], the vertices of the triangle,
//    in counterclockwise order.
//
//    Input, double P[2*N], the point at which the interpolant is desired.
//
//    Input, double V1[M], V2[M], V3[M], the value of some quantity at the vertices.
//
//    Output, double TRIANGLE_INTERPOLATE_LINEAR[M,N], the interpolated value
//    of the quantity at P.
//
    double abc = [self triangle_areaForP1X:p1[0] p1y:p1[1] p2x:p2[0] p2y:p2[1] p3x:p3[0] p3y:p3[1]];
    double apc, abp, pbc;
    
    NSAssert(v != NULL, @"Interpolated Array has to be allocated prior to calling this routine");
    
    if ( (size_t)(m * n) > size ) {
        *v = (double*)realloc(*v, (size_t)(m * n) * sizeof(double));
    }
    for( NSInteger j = 0; j < n; j++) {
        pbc = [self triangle_areaForP1X:p[0+j*2] p1y:p[1+j*2] p2x:p2[0] p2y:p2[1] p3x:p3[0] p3y:p3[1]];
        apc = [self triangle_areaForP1X:p1[0] p1y:p1[1] p2x:p[0+j*2] p2y:p[1+j*2] p3x:p3[0] p3y:p3[1]];
        abp = [self triangle_areaForP1X:p1[0] p1y:p1[1] p2x:p2[0] p2y:p2[1] p3x:p[0+j*2] p3y:p[1+j*2]];
        for( NSInteger i = 0; i < m; i++) {
            *(*v + i + j * m) = ( pbc * v1[i] + apc * v2[i] + abp * v3[i] ) / abc;
        }
    }
    
}

//    double LinearInterpolate( double y1,double y2, double mu) {
//       return(y1*(1-mu)+y2*mu);
//    }
//
//    double CosineInterpolate( double y1,double y2, double mu) {
//       double mu2;
//
//       mu2 = (1-cos(mu*PI))/2;
//       return(y1*(1-mu2)+y2*mu2);
//    }
//
//    double CubicInterpolate( double y0,double y1, double y2,double y3, double mu) {
//       double a0,a1,a2,a3,mu2;
//
//       mu2 = mu*mu;
//       a0 = y3 - y2 - y0 + y1;
//       a1 = y0 - y1 - a0;
//       a2 = y2 - y0;
//       a3 = y1;
//
//       return(a0*mu*mu2+a1*mu2+a2*mu+a3);
//    }
//
//    /*
//       Tension: 1 is high, 0 normal, -1 is low
//       Bias: 0 is even,
//             positive is towards first segment,
//             negative towards the other
//    */
//    double HermiteInterpolate( double y0,double y1, double y2,double y3, double mu, double tension, double bias) {
//       double m0,m1,mu2,mu3;
//       double a0,a1,a2,a3;
//
//        mu2 = mu * mu;
//        mu3 = mu2 * mu;
//       m0  = (y1-y0)*(1+bias)*(1-tension)/2;
//       m0 += (y2-y1)*(1-bias)*(1-tension)/2;
//       m1  = (y2-y1)*(1+bias)*(1-tension)/2;
//       m1 += (y3-y2)*(1-bias)*(1-tension)/2;
//       a0 =  2*mu3 - 3*mu2 + 1;
//       a1 =    mu3 - 2*mu2 + mu;
//       a2 =    mu3 -   mu2;
//       a3 = -2*mu3 + 3*mu2;
//
//       return(a0*y1+a1*m0+a2*m1+a3*y2);
//    }

-(BOOL)isInsideTriangleForPx:(double)px py:(double)py p1x:(double)p1x p1y:(double)p1y p2x:(double)p2x p2y:(double)p2y  p3x:(double)p3x p3y:(double)p3y {
    
    double Area = [self triangle_areaForP1X:p1x p1y:p1y p2x:p2x p2y:p2y p3x:p3x p3y:p3y];
    double s = (p1y * p3x - p1x * p3y + (p3y - p1y) * px + (p1x - p3x) * py) / (2 * Area);
    double t = (p1x * p2y - p1y * p2x + (p1y - p2y) * px + (p2x - p1x) * py) / (2 * Area);
   // where Area is the (signed) area of the triangle:

    if ( s > 0 && t > 0 && 1 - s - t > 0 ) {
        return YES;
    }
    else {
        return NO;
    }
}

-(double)triangle_extrapolate_linear_singletonForP1:(double*)p1 p2:(double*)p2 p:(double*)p v1:(double)v1 v2:(double)v2 {

    double sx = p[0] - p1[0];
    double sy = p[1] - p1[1];
        
    double ax = p2[0] - p1[0];
    double ay = p2[1] - p1[1];
    double az = v2 - v1;
        
    double t = (sx * ax + sy * ay) / (ax * ax + ay * ay);
    double z;
    if ( t <= 0 ) {
        z = v1;
//            nx = 0
//            ny = 0
//            nz = 1
    }
    else if ( t >= 1 ) {
        z = v2;
//            nx = 0
//            ny = 0
//            nz = 1
    }
    else {
        z = t * az + v1;
//            nx = -az * ax;
//            ny = -az * ay;
//            nz = ax * ax + ay * ay;
    }
    return z;
}

@end
