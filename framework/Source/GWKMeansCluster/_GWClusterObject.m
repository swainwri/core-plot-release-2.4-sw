//
//  GWClusterObject.m
//  GWCluster
//
//  Created by Gordon Wintrob on 1/20/13.
//  Copyright (c) 2013 Gordon Wintrob. All rights reserved.
//

#import "_GWClusterObject.h"

@implementation _GWClusterObject

- (double)calculatePenaltyAgainstObject:(_GWClusterObject *)object
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)]
                                 userInfo:nil];
}

@end
