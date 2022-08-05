//
//  CPTHull.h
//  CorePlot
//
//  Created by Steve Wainwright on 01/06/2022.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CPTHull : NSObject

/**
 The concavity paramater for the hull function, 20 is the default
 CGFLOAT_MAX for convex , 1 forthin shape
*/
@property (nonatomic, readwrite) CGFloat concavity;
@property (nonatomic, readonly) NSArray<NSValue*> *hullPoints;

-(void)quickConvexHullOnViewPoints:( NSArray<NSValue*>*)points;
-(void)concaveHullOnViewPoints:( NSArray<NSValue*>*)points;

@end

NS_ASSUME_NONNULL_END
