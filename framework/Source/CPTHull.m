//
//  CPTHull.m
//  CorePlot
//
//  Created by Steve Wainwright on 01/06/2022.
//

#import "CPTHull.h"

#import "_CPTHull.h"

@interface CPTHull()

@property (nonatomic, strong) _CPTHull *hullEngine;
@property (nonatomic, readwrite) NSMutableArray<NSValue*> *holdHullPoints;

@end

@implementation CPTHull

@synthesize concavity;
@synthesize hullEngine;
@synthesize holdHullPoints;

- (instancetype)init {
    self = [super init];
    if (self) {
        self.hullEngine = [[_CPTHull alloc] initWithConcavity:20];
    }
    return self;
}

- (instancetype)initWithCapacity {
    self = [super init];
    if (self) {
        self.hullEngine = [[_CPTHull alloc] initWithConcavity:self.concavity];
    }
    return self;
}

-(NSArray<NSValue*>*)hullPoints {
    return self.holdHullPoints;
}

-(void)setHullPointsArray {
    NSUInteger noHullPoints = [self.hullEngine hullpointsCount];
    self.holdHullPoints = [[NSMutableArray alloc] initWithCapacity:noHullPoints];
    for ( NSUInteger i = 0; i < noHullPoints; i++ ) {
        HullPoint hullpt = [self.hullEngine hullpointsArray][i];
        CGPoint point = CGPointMake(hullpt.point.x, hullpt.point.y);
        NSValue *value;
#if TARGET_OS_OSX
        value = [NSValue valueWithPoint:(NSPoint)point];
#else
        value = [NSValue valueWithCGPoint:point];
#endif
        [self.holdHullPoints addObject:value];
    }
}


-(void)quickConvexHullOnViewPoints:( NSArray<NSValue*>*)points {
    CGPoint *cgPoints = (CGPoint*)calloc((size_t)points.count, sizeof(CGPoint));
    size_t i = 0;
    for ( NSValue *value in points ) {
#if TARGET_OS_OSX
        cgPoints[i] = (CGPoint)[value pointValue];
#else
        cgPoints[i] = [value CGPointValue];
#endif
        i++;
    }
    [self.hullEngine quickConvexHullOnViewPoints:cgPoints dataCount:points.count];
    free(cgPoints);
    [self setHullPointsArray];
}


-(void)concaveHullOnViewPoints:( NSArray<NSValue*>*)points {
    CGPoint *cgPoints = (CGPoint*)calloc((size_t)points.count, sizeof(CGPoint));
    size_t i = 0;
    for ( NSValue *value in points ) {
#if TARGET_OS_OSX
        cgPoints[i] = (CGPoint)[value pointValue];
#else
        cgPoints[i] = [value CGPointValue];
#endif
        i++;
    }
    [self.hullEngine concaveHullOnViewPoints:cgPoints dataCount:points.count];
    free(cgPoints);
    [self setHullPointsArray];
}

@end
