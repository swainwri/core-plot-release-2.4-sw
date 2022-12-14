//
//  DelaunayEdge.h
//  DelaunayTest
//
//  Created by Mike Rotondo on 7/20/11.
//  Copyright 2011 Stanford. All rights reserved.
//

#import <Foundation/Foundation.h>

@class DelaunayTriangle;
@class DelaunayPoint;

@interface DelaunayEdge : NSObject

@property (nonatomic, strong) NSMutableSet *triangles;
@property (nonatomic, strong) NSArray *points;

+ (DelaunayEdge *)edgeWithPoints:(NSArray *)points;
- (DelaunayTriangle *)neighborOf:(DelaunayTriangle *)triangle;
- (DelaunayPoint *)otherPoint:(DelaunayPoint *)point;
- (BOOL)pointOnLeft:(DelaunayPoint*)point withStartPoint:(DelaunayPoint *)startPoint;
- (DelaunayTriangle *)sharedTriangleWithEdge:(DelaunayEdge *)otherEdge;
- (CGFloat)length;

- (BOOL)isEqual:(id)object;
- (NSUInteger)hash;

@end
