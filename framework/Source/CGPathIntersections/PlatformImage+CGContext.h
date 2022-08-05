//
//  PlatformImage+CGContext.h
//  CGPathIntersections
//
//  Created by Cal Stephens on 11/13/16.
//  Copyright © 2016 Cal Stephens. All rights reserved.
//  Converted to objective c by Steve Wainwright on 27/05/2022.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

#if TARGET_OS_OSX

#pragma mark macOS
#pragma mark -

#import <AppKit/AppKit.h>

typedef NSImage PlatformImage; ///< Platform-native image.

#else

#pragma mark - iOS, tvOS, Mac Catalyst
#pragma mark -

#import <UIKit/UIKit.h>

typedef UIImage PlatformImage; ///< Platform-native image.

#endif

typedef void (^drawToContext)(CGContextRef _Nonnull);

NS_ASSUME_NONNULL_BEGIN
#if TARGET_OS_OSX
@interface NSImage (CGContext)

@property (nonatomic) CGImageRef CGImage;

#else
@interface UIImage (CGContext)
#endif

+(nonnull PlatformImage *) renderImageWithSize:(CGSize)size draw:(drawToContext)draw;

@end

NS_ASSUME_NONNULL_END
