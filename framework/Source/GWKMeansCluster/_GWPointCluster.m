//
//  GWPointCluster.m
//  GWCluster
//
//  Created by Gordon Wintrob on 2/27/13.
//  Copyright (c) 2013 Wintrob. All rights reserved.
//

#import "_GWPointCluster.h"

@implementation _GWPointCluster
@synthesize K, points, clusters;

- (id)init {
    if ( (self = [super init]) )    {
        self.points = [[NSMutableArray alloc] init];
    }
    
    return self;
}

- (void)addPoint:(CGPoint)point {
    _GWPoint *gwPoint = [[_GWPoint alloc] initWithPoint:point];
    [self.points addObject:gwPoint];
}

- (void)clusterPoints {
    NSArray *means = [self generateMeans];
    NSLog(@"nMeans %ld", means.count);
    for(_GWPoint *p in means) {
        NSLog(@"%@", p);
    }
    _GWCluster *cluster = [[_GWCluster alloc] initWithObjects:self.points means:means averageCluster:^(NSArray *clusterPoints) {
        return [_GWPoint calculateMeanOfPoints:clusterPoints];
    }];
    [cluster run];
    
    self.clusters = cluster.clusters;
    
//    NSMutableArray *clusters = cluster.clusters;
//    NSArray *colors = [self generateColors];
//    for (NSUInteger i = 0; i < self.K; i++) {
//        for (_GWPoint *point in clusters[i]) {
//            [point setColor:colors[i]];
//        }
//    }
}

- (NSArray *)generateMeans {
    NSMutableArray *means = [[NSMutableArray alloc] initWithCapacity:self.K];
    
    for(NSUInteger i = 0; i < self.K; i++) {
        NSUInteger randomI = arc4random() % self.K;
        _GWPoint *point = self.points[randomI];
        
        while ([means containsObject:point]) {
            randomI = arc4random() % self.K;
            point = self.points[randomI];
        }
                
        [means addObject:point];
    }
    
    return means;
}


//- (NSArray *)generateColors {
//    NSMutableArray *colors = [[NSMutableArray alloc] initWithCapacity:self.K];
//    
//    for(NSUInteger i = 0; i < self.K; i++) {
//        double val = (double)(arc4random() / ARC4RANDOM_MAX);
//        UIColor *color = [UIColor colorWithHue:val saturation:1 brightness:1 alpha:1];
//        [colors addObject:color];
//    }
//    
//    return colors;
//}

@end
