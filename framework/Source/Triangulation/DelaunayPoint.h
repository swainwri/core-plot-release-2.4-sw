//
//  DelaunayPoint.h
//  DelaunayTest
//
//  Created by Mike Rotondo on 7/17/11.
//  Copyright 2011 Stanford. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface DelaunayPoint : NSObject <NSCopying>

@property (nonatomic) CGFloat x;
@property (nonatomic) CGFloat y;
@property (nonatomic) CGFloat contribution;
@property (nonatomic, strong) NSNumber * _Nonnull idNumber;
@property (nonatomic, readonly) NSMutableSet * _Nonnull edges;
@property (nonatomic, strong) id _Nonnull value;
#if TARGET_OS_OSX
@property (nonatomic, strong) NSColor * _Nullable color;
#else
@property (nonatomic, strong) UIColor * _Nullable color;
#endif

+ (nonnull DelaunayPoint *)pointAtX:(CGFloat)x andY:(CGFloat)y;
+ (nonnull DelaunayPoint *)pointAtX:(CGFloat)newX andY:(CGFloat)newY withID:(NSNumber * _Nonnull)idNumber;
- (NSArray * _Nonnull)counterClockwiseEdges;

- (BOOL)isEqual:(id _Nonnull )object;
- (NSUInteger)hash;

@end
