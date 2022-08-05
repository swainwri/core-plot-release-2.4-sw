//
//  _CPTHull.h
//  CorePlot
//
//  Created by Steve Wainwright on 13/05/2022.
//

#import <Foundation/Foundation.h>

#import "_CPTContourMemoryManagement.h"

NS_ASSUME_NONNULL_BEGIN

typedef struct {
    CGPoint point;
    NSUInteger index;
} HullPoint;

typedef struct {
    HullPoint * _Nullable array;
    size_t used;
    size_t size;
} HullPoints;

typedef struct {
    NSInteger index;
    NSInteger jndex;
    HullPoints hullpoints;
} HullCell;

typedef struct {
    HullCell * _Nullable array;
    size_t used;
    size_t size;
} HullCells;

@interface _CPTHull : NSObject
/**
 The concavity paramater for the hull function, 20 is the default
*/
@property (nonatomic, readwrite) CGFloat concavity;

-(nonnull instancetype)initWithConcavity:(CGFloat)concavity;

-(HullPoints*)hullpoints;
-(nullable HullPoint*)hullpointsArray;
-(NSUInteger)hullpointsCount;
-(void)sortHullpointsByIndex;

-(void)quickConvexHullOnViewPoints:(CGPoint*)viewPoints dataCount:(NSUInteger)dataCount;
-(void)quickConvexHullOnIntersections:(Intersections*)pIntersections;
-(void)quickConvexHullOnBorderStrips:(Strips*)pBorderStrips;
-(void)quickConvexHullOnBorderIndices:(BorderIndices*)pBorderIndices;
-(void)concaveHullOnViewPoints:(CGPoint*)viewPoints dataCount:(NSUInteger)dataCount;

@end

NS_ASSUME_NONNULL_END
