//
//  GWPoint.m
//  GWCluster
//
//  Created by Gordon Wintrob on 2/27/13.
//  Copyright (c) 2013 Wintrob. All rights reserved.
//

#import "_GWPoint.h"

@implementation _GWPoint

@synthesize /*color,*/point;

- (id)initWithPoint:(CGPoint)newPoint {
    self = [super init];
    
    if (self) {
        [self setPoint:newPoint];
//        [self setColor:[UIColor blackColor]];
    }
    
    return self;
}

+ (double)distanceBetweenPoint:(CGPoint)p1 point:(CGPoint)p2 {
    double xDist = (p2.x - p1.x);
    double yDist = (p2.y - p1.y);
    return sqrt((xDist * xDist) + (yDist * yDist));
}

+ (double)averageVals:(double *)vals valsSize:(size_t)count {
    
    double total = 0;
    
    for(NSUInteger i = 0; i < count; i++) {
        total += vals[i];
    }
    
    return total / count;
}

- (double)calculatePenaltyAgainstObject:(_GWClusterObject *)otherPoint {
    return [_GWPoint distanceBetweenPoint:self.point point:((_GWPoint*)otherPoint).point];
}

+ (_GWPoint *)calculateMeanOfPoints:(NSArray *)points {
    NSUInteger count = [points count];
    double *xVals = (double*)calloc(count, sizeof(double));
    double *yVals = (double*)calloc(count, sizeof(double));
    
    for(NSUInteger i = 0; i < count; i++) {
        CGPoint p = ((_GWPoint *)points[i]).point;
        xVals[i] = p.x;
        yVals[i] = p.y;
    }
    
    double x = [_GWPoint averageVals:xVals valsSize:count];
    double y = [_GWPoint averageVals:yVals valsSize:count];
    
    free(xVals);
    free(yVals);
    
    CGPoint newPoint = CGPointMake(x, y);
    return [[_GWPoint alloc] initWithPoint:newPoint];
}

- (NSString *)description {
//    return [[NSString alloc] initWithFormat:@"<GWPoint: %.0f,%.0f (%@)>", self.point.x, self.point.y, self.color, nil];
    return [[NSString alloc] initWithFormat:@"<GWPoint: %.0f,%.0f>", self.point.x, self.point.y, nil];
}

@end
