//
//  PlatformImage+CGContext.m
//  CGPathIntersections
//
//  Created by Cal Stephens on 11/13/16.
//  Copyright © 2016 Cal Stephens. All rights reserved.
//  Converted to objective c by Steve Wainwright on 27/05/2022.
//


#import "PlatformImage+CGContext.h"
#if TARGET_OS_OSX
#import <objc/runtime.h>

static CGImageRef _cgImage;

@implementation NSImage (CGContext)

-(CGImageRef)CGImage {
    return _cgImage;
}

-(void)setCGImage:(CGImageRef)newCgImage {
    _cgImage = newCgImage;
}

#else
@implementation UIImage (CGContext)
#endif
// Renders an image of the given size, using the created `CGContext`
//+(PlatformImage*) platformImageWithSize:(CGSize)size renderer:(void (^)(CGContextRef context))draw {
+(PlatformImage*) renderImageWithSize:(CGSize)size draw:(drawToContext)draw {
#if TARGET_OS_OSX
    NSBitmapImageRep *imageRepresentation = [[NSBitmapImageRep alloc]  initWithBitmapDataPlanes:nil pixelsWide:(NSInteger)size.width pixelsHigh:(NSInteger)size.height bitsPerSample:8 samplesPerPixel:4 hasAlpha:YES isPlanar:NO colorSpaceName:NSCalibratedRGBColorSpace bytesPerRow:0 bitsPerPixel:0];
    

    NSGraphicsContext *graphicsContext = [NSGraphicsContext graphicsContextWithBitmapImageRep:imageRepresentation];
    
    draw([graphicsContext CGContext]);
   
    PlatformImage *image = [[NSImage alloc] initWithSize:size];
    [image addRepresentation:imageRepresentation];
    _cgImage = [image CGImageForProposedRect:nil context:nil hints:nil];
    return image;
#else
    UIGraphicsBeginImageContextWithOptions(size, NO, 1.0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    draw(context);
    
    PlatformImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
#endif
}

@end
