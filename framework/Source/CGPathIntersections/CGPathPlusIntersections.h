//
//  CGPathPlusIntersections.h
//  CGPathIntersections
//
//  Created by Cal Stephens on 11/13/16.
//  Copyright © 2016 Cal Stephens. All rights reserved.
//  ported to objective c by Steve Wainwright on 27/05/2022.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

#if TARGET_OS_OSX

#pragma mark macOS
#pragma mark -

#import <AppKit/AppKit.h>

#else

#pragma mark - iOS, tvOS, Mac Catalyst
#pragma mark -

#import <UIKit/UIKit.h>

#endif


NS_ASSUME_NONNULL_BEGIN

BOOL CGPathIntersectsPathWithOther(CGPathRef path1, CGPathRef path2);
NSUInteger CGPathCountIntersectionPointsWithOther(CGPathRef path1, CGPathRef path2);
CGPoint CGPathIntersectionPointWithOtherAtIndex(CGPathRef path1, CGPathRef path2, size_t index);

NS_ASSUME_NONNULL_END

