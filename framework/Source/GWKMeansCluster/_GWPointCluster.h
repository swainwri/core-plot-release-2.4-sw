//
//  GWPointCluster.h
//  GWCluster
//
//  Created by Gordon Wintrob on 2/27/13.
//  Copyright (c) 2013 Wintrob. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "_GWCluster.h"
#import "_GWPoint.h"
#define ARC4RANDOM_MAX 0x100000000

@interface _GWPointCluster : NSObject


@property (nonatomic) NSUInteger K;
@property (nonatomic, strong) NSMutableArray *points;
@property (nonatomic, strong) NSMutableArray<NSMutableArray*> *clusters;
- (void)addPoint:(CGPoint)point;
- (void)clusterPoints;

@end
