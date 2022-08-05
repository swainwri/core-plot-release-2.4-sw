//
//  GWCluster.m
//  GWCluster
//
//  Created by Gordon Wintrob on 1/20/13.
//  Copyright (c) 2013 Gordon Wintrob. All rights reserved.
//

#import "_GWCluster.h"
#import "_GWPoint.h"

@implementation _GWCluster

@synthesize numIterations, clusters, means, objects;
@synthesize averageCluster;

- (void)resetClusters {
    NSMutableArray *emptyClusters = [[NSMutableArray alloc] initWithCapacity:self.means.count];
    for (NSUInteger i = 0; i <  self.means.count; i++) {
        [emptyClusters addObject:[[NSMutableArray alloc] init]];
    }
    [self setClusters:emptyClusters];
}

- (id)initWithObjects:(NSArray *)initObjects means:(NSArray *)initMeans averageCluster:(ClusterBlock)block
{
    self = [super init];
    if (self) {
        [self setNumIterations:50];
        
        NSMutableArray *initMeansMutable = [[NSMutableArray alloc] initWithCapacity:initMeans.count];
        for (_GWClusterObject *obj in initMeans) {
            [initMeansMutable addObject:obj];
        }
        
        [self setMeans:initMeansMutable];
        [self setObjects:initObjects];
        [self setAverageCluster:block];
        [self resetClusters];
    }
    
    return self;
}

- (NSArray *)run {
    for (NSUInteger iter = 0; iter < self.numIterations; iter++) {
        [self resetClusters];
        for (_GWClusterObject *obj in self.objects) {
            double minPenalty = DBL_MAX;
            NSUInteger bestCluster = 0;
            for (NSUInteger i = 0; i < self.means.count; i++) {
                _GWClusterObject *mean = [self.means objectAtIndex:i];
                double penalty = [obj calculatePenaltyAgainstObject:mean];
                if (penalty <= minPenalty) {
                    bestCluster = i;
                    minPenalty = penalty;
                }
            }

            [self.clusters[bestCluster] addObject:obj];
        }
        
        NSMutableArray *newMeans = [[NSMutableArray alloc] init];
        for (NSUInteger i = 0; i < self.clusters.count; i++) {
            if (((NSArray *)self.clusters[i]).count > 0) {
                _GWClusterObject *newMean = self.averageCluster(self.clusters[i]);
                [newMeans addObject:newMean];
            }
            else {
                [newMeans addObject:[self.means objectAtIndex:i]];
            }
        }
        
        [self setMeans:newMeans];
    }
    
    return self.clusters;
}

@end
