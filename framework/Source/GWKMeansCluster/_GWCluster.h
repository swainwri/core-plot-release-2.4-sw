//
//  GWCluster.h
//  GWCluster
//
//  Created by Gordon Wintrob on 1/20/13.
//  Copyright (c) 2013 Gordon Wintrob. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "_GWClusterObject.h"

@interface _GWCluster : NSObject

@property (nonatomic) NSUInteger numIterations;
@property (nonatomic, retain) NSMutableArray *clusters;
@property (nonatomic, retain) NSMutableArray *means;
@property (nonatomic, retain) NSArray *objects;

typedef _GWClusterObject * (^ClusterBlock)(NSArray *);
@property (nonatomic, copy) ClusterBlock averageCluster;

- (void)resetClusters;
- (id)initWithObjects:(NSArray *)initObjects means:(NSArray *)initMeans averageCluster:(ClusterBlock)block;
- (NSArray *)run;

@end
