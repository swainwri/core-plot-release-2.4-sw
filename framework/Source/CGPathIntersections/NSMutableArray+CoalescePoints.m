//
//  NSMutableArray+CoalescePoints.m
//  CGPathIntersections
//
//  Created by Cal Stephens on 11/13/16.
//  Copyright © 2016 Cal Stephens. All rights reserved.
//  Converted to objective c by Steve Wainwright on 27/05/2022.
//

#import "NSMutableArray+CoalescePoints.h"

int compareDistances(const void *a, const void *b);

int compareDistances(const void *a, const void *b) {
    const CGFloat *aO = (const CGFloat*)a;
    const CGFloat *bO = (const CGFloat*)b;
    
    if (*aO > *bO) {
        return 1;
    }
    else if (*aO < *bO) {
        return -1;
    }
    else {
        return 0;
    }
}


@implementation NSMutableArray (CoalescePoints)

-(NSMutableArray<NSValue*>*)coalescePoints {
    
    if ( ![[self firstObject] isKindOfClass:[NSValue class]] ) {
        return nil;
    }

    CGPoint point;
    size_t groupsCount = 0;
    size_t *subGroupsCount = (size_t*)calloc(1, sizeof(size_t));
    CGPoint **groups = (CGPoint**)calloc(1, sizeof(CGPoint*));
    
    //build groups of nearby pixels
    for ( id object in self ) {
        if([object isKindOfClass:[NSValue class]]) {
#if TARGET_OS_OSX
            point = (CGPoint)[(NSValue *)object pointValue];
#else
            point = [(NSValue *)object CGPointValue];
#endif
            if ( groupsCount == 0 ) {
                *groups = (CGPoint*)calloc(1, sizeof(CGPoint));
                groups[0][0] = point;
                subGroupsCount[0] = 1;
                groupsCount++;
                continue;
            }
            
            BOOL addedToGroup = NO;
            for ( NSUInteger i = 0; i < (NSUInteger)groupsCount; i++ ) {
                CGFloat *distances = (CGFloat*)calloc(subGroupsCount[i], sizeof(CGFloat));
                for ( size_t j = 0; j < (NSUInteger)subGroupsCount[i]; j++ ) {
                    distances[j] = [self distanceFromPoint:groups[i][j] ToPoint:point];
                }
                qsort(distances, subGroupsCount[i], sizeof(CGFloat), compareDistances);
                CGFloat miniumDistanceToGroup = distances[0];
                free(distances);
                
                if ( miniumDistanceToGroup < 6.0 ) {
                    *(groups + i) = (CGPoint*)realloc(*(groups + i), (subGroupsCount[i] + 1) * sizeof(CGPoint));
                    groups[i][subGroupsCount[i]] = point;
                    subGroupsCount[i] = subGroupsCount[i] + 1;
                    addedToGroup = YES;
                    break;
                }
            }
            if ( !addedToGroup ) {
                groups = (CGPoint**)realloc(groups, (groupsCount + 1) * sizeof(CGPoint*));
                subGroupsCount = (size_t*)realloc(subGroupsCount, (groupsCount + 1) * sizeof(size_t));
                subGroupsCount[groupsCount] = 1;
                *(groups + groupsCount) = (CGPoint*)calloc(1, sizeof(CGPoint));
                groups[groupsCount][0] = point;
                groupsCount++;
            }
        }
    }
    NSMutableArray<NSValue*>* _groups = [NSMutableArray new];
    //map groups to average values
    for ( NSInteger i = 0; i < (NSInteger)groupsCount; i++ ) {
        CGFloat xSum = 0, ySum = 0;
        for ( NSInteger j = 0; j < (NSInteger)subGroupsCount[i]; j++ ) {
            xSum+= groups[i][j].x;
            ySum+= groups[i][j].y;
        }
        CGFloat subGroupCount = (CGFloat)subGroupsCount[i];
        point = CGPointMake(lrint(xSum / subGroupCount), lrint(ySum / subGroupCount));
        NSValue *value;
#if TARGET_OS_OSX
        value = [NSValue valueWithPoint:(NSPoint)point];
#else
        value = [NSValue valueWithCGPoint:point];
#endif
        [_groups addObject:value];
    }
    for( NSUInteger i = 0; i < (NSUInteger)groupsCount; i++ ) {
        free(*(groups + i));
    }
    free(groups);
    free(subGroupsCount);
    
    return _groups;
}

-(CGFloat) distanceFromPoint:(CGPoint)point1 ToPoint:(CGPoint)point2 {
    return sqrt(pow(point1.x - point2.x, 2) + pow(point1.y - point2.y, 2));
}

@end

