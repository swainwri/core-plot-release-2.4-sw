//
//  CGPathImage.m
//  CGPathIntersections
//
//  Created by Cal Stephens on 11/13/16.
//  Copyright © 2016 Cal Stephens. All rights reserved.
//  Converted to objective c by Steve Wainwright on 27/05/2022.
//

#import "CGPathImage.h"
#import "NSMutableArray+CoalescePoints.h"


@implementation CGPathImage

@synthesize path;
@synthesize boundingBox;
@synthesize cgImage;
@synthesize image;
@synthesize rawImage;

static RawImage rrawImage;
static CFDataRef pixelData;

CGRect CGRectInImageFromRectAndRect(CGRect rect1, CGRect rect2);

-(nonnull instancetype)initFromPath:(CGPathRef)_path {
    if ( (self = [super init]) ) {
        self.path = _path;
        
        // Perfectly-straight lines have a width or height of zero,
        // but to create a useful image we have to have at least one row/column of pixels.
        CGRect absoluteBoundingBox = CGPathGetBoundingBox(_path);
        CGRect aboundingBox = CGRectMake(absoluteBoundingBox.origin.x, absoluteBoundingBox.origin.y, MAX(absoluteBoundingBox.size.width, 1), MAX(absoluteBoundingBox.size.height, 1));
        
        void(^drawToContext)(CGContextRef) = ^(CGContextRef context) {
            CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceRGB();
            const CGFloat components[4] = { 0, 0, 0, 0.5 };
            CGColorRef rgba = CGColorCreate(colorspace, components);
            CGContextSetStrokeColorWithColor(context, rgba);
            CGContextSetLineWidth(context, 1.0);
            CGContextSetAllowsAntialiasing(context, NO);
            CGContextSetShouldAntialias(context, NO);
            CGAffineTransform translationToOrigin = CGAffineTransformMakeTranslation(-CGRectGetMinX(aboundingBox), -CGRectGetMinY(aboundingBox));
            
            CGPathRef pathAtOrigin = CGPathCreateCopyByTransformingPath(self.path, &translationToOrigin);
            CGContextAddPath(context, pathAtOrigin);
            CGContextDrawPath(context,  kCGPathStroke);
            CGPathRelease(pathAtOrigin);
            CGColorRelease(rgba);
            CGColorSpaceRelease(colorspace);
        };
        
        PlatformImage *anImage = [PlatformImage renderImageWithSize:aboundingBox.size draw:drawToContext];
        
        self.boundingBox = aboundingBox;
        self.image = anImage;
        self.cgImage = anImage.CGImage;
        
        [self setRrawImage];
        self.rawImage = rrawImage;
    }
    return self;
}

- (void)dealloc {
    self.cgImage = nil;
    
//#if TARGET_OS_OSX
//    
//#else
//    if ( pixelData != NULL ) {
//        CFRelease(pixelData);
//    }
//#endif
//    
    
}

-(void)setRrawImage {
    if ( self.image.CGImage == nil ) {
        return;
    }
    
    CGImageRef aCGImage = self.image.CGImage;
    CGRect aboundingBox = CGRectMake((NSInteger)self.boundingBox.origin.x, (NSInteger)self.boundingBox.origin.y, CGImageGetWidth(aCGImage), CGImageGetHeight(aCGImage));
    
    rrawImage.options.bounds = aboundingBox;
    rrawImage.options.bytesPerRow = CGImageGetBytesPerRow(aCGImage);
    rrawImage.options.bitsPerComponent = CGImageGetBitsPerComponent(aCGImage);
    
#if TARGET_OS_OSX
    NSData *tiffRep = [self.image TIFFRepresentation];
    NSBitmapImageRep *bitmapRep = [NSBitmapImageRep imageRepWithData:tiffRep];
    rrawImage.bitmapRep = bitmapRep;
#else
    pixelData = CGDataProviderCopyData(CGImageGetDataProvider(aCGImage));
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wcast-qual"
    rrawImage.pixels = (UInt8*)(CFDataGetBytePtr(pixelData));
#pragma clang diagnostic pop
#endif
}

-(RawImage)getRawImage {
    return rrawImage;
}


#pragma mark - Calculate Intersections

-(BOOL)intersectsPath:(CGPathImage*)cgpath {
    return [[self intersectionPointsWithOther:cgpath] count] > 0;
}

-(NSArray<NSValue*>*)intersectionPointsWithOther:(CGPathImage*)other {
    RawImage image1Raw = self.rawImage;
    RawImage image2Raw = other.rawImage;
#if TARGET_OS_OSX
    if ( image1Raw.bitmapRep == nil && image2Raw.bitmapRep == nil ) {
        return nil;
    }
#else
    if ( image1Raw.pixels == nil && image2Raw.pixels == nil ) {
        return nil;
    }
#endif
    NSMutableArray<NSValue*>* intersectionPixels = [[NSMutableArray alloc] init];
    CGRect intersectionRect = CGRectIntersection(self.boundingBox, other.boundingBox);
    if ( CGRectIsNull(intersectionRect) ) {
        return nil;
    }
    //iterate over intersection of bounding boxes
    for( NSInteger x = (NSInteger)(floor(CGRectGetMinX(intersectionRect))); x < (NSInteger)(floor(CGRectGetMaxX(intersectionRect))); x++) {
        for( NSInteger y = (NSInteger)(floor(CGRectGetMinY(intersectionRect))); y < (NSInteger)(floor(CGRectGetMaxY(intersectionRect))); y++) {
            CGColorRef color1 = CGColorCreateSRGB(0, 0, 0, 0);
            CGColorRef color2 = CGColorCreateSRGB(0, 0, 0, 0);
            [self colorOfRawImage:image1Raw atX:x y:y color:&color1];
            [self colorOfRawImage:image2Raw atX:x y:y color:&color2];
            if ( CGColorGetAlpha(color1) > 0.05 && CGColorGetAlpha(color2) > 0.05 ) {
                NSValue *value;
#if TARGET_OS_OSX
                value = [NSValue valueWithPoint:(NSPoint)CGPointMake((CGFloat)x, (CGFloat)y)];
#else
                value = [NSValue valueWithCGPoint:CGPointMake((CGFloat)x, (CGFloat)y)];
#endif
                [intersectionPixels addObject:value];
            }
            CGColorRelease(color1);
            CGColorRelease(color2);
        }
    }
    if ( [intersectionPixels count] <= 1 ) {
        return intersectionPixels;
    }
    else {
        return [intersectionPixels coalescePoints];
    }
}

#pragma mark: - Debugging Helpers

/// Renders an image displaying the two `CGPath`s,
/// and highlighting their `intersectionPoints`

-(PlatformImage*)intersectionsImageWithImage:(CGPathImage*)other {
    
    __block CGRect totalBoundingBox =  CGRectUnion(self.boundingBox, other.boundingBox);

    void(^drawToContext)(CGContextRef)  = ^void (CGContextRef context) {
        CGContextSetAllowsAntialiasing(context, NO);
        CGContextSetShouldAntialias(context, NO);

        CGImageRef image1 = self.cgImage;
        CGImageRef image2 = other.cgImage;
        if ( image1 == nil && image2 == nil ) {
            return;
        }

        CGContextDrawImage(context, self.boundingBox, image1);
        CGContextDrawImage(context, other.boundingBox, image2);

        CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceRGB();
        const CGFloat components[4] = { 1, 0, 0, 1 };
        CGColorRef rgba = CGColorCreate(colorspace, components);
        CGContextSetFillColorWithColor(context, rgba);

        NSArray<NSValue*>* values = [self intersectionPointsWithOther:other];
        CGPoint point;
        CGRect rect;
        for( NSValue *value in values ) {
#if TARGET_OS_OSX
            point = (CGPoint)[value pointValue];
#else
            point = [value CGPointValue];
#endif
            rect = CGRectInset(CGRectMake(point.x, point.y, 0, 0), -20, -20);
            CGContextBeginPath(context);
            CGContextAddEllipseInRect(context, CGRectInImageFromRectAndRect(rect, totalBoundingBox));
            CGContextClosePath(context);
            CGContextDrawPath(context, kCGPathFill);
        }
        CGColorRelease(rgba);
        CGColorSpaceRelease(colorspace);
    };
    
    return [PlatformImage renderImageWithSize:totalBoundingBox.size draw:drawToContext];
}
    

CGRect CGRectInImageFromRectAndRect(CGRect rect1, CGRect rect2) {
    return CGRectMake(rect1.origin.x - CGRectGetMinX(rect2), rect1.origin.y - CGRectGetMinY(rect2), rect1.size.width, rect1.size.height);
}

/// Renders an image by round-tripping each pixel through the `colorAt(x:y:)` method

-(PlatformImage*)rawPixelImage {
    void(^drawToContext)(CGContextRef) = ^void (CGContextRef context) {

#if TARGET_OS_OSX
        if ( self.rawImage.bitmapRep == nil ) {
            return;
        }
#else
        if ( self.rawImage.pixels == nil ) {
            return;
        }
#endif
        
        CGRect bounds = self.rawImage.options.bounds;
        
        for( NSInteger x = (NSInteger)(floor(CGRectGetMinX(bounds))); x < (NSInteger)(floor(CGRectGetMaxX(bounds))); x++) {
            for( NSInteger y = (NSInteger)(floor(CGRectGetMinY(bounds))); y < (NSInteger)(floor(CGRectGetMaxY(bounds))); y++) {
                CGColorRef pixel = CGColorCreateSRGB(0, 0, 0, 0);
                [self colorOfRawImage:self.rawImage atX:x y:y color:&pixel];
                const CGFloat *components = CGColorGetComponents(pixel);
                CGColorRef color = CGColorCreateGenericRGB(components[0], components[1], components[2], components[3]);
                CGContextSetFillColorWithColor(context, color);
                CGContextBeginPath(context);
                CGContextAddRect(context, CGRectMake(x - (NSInteger)(floor(CGRectGetMinY(bounds))) - 5, y - (NSInteger)(floor(CGRectGetMinY(bounds))) - 5, 10, 10));
                CGContextClosePath(context);
                CGContextDrawPath(context, kCGPathFill);
                CGColorRelease(color);
                CGColorRelease(pixel);
            }
        }
    };

    return [PlatformImage renderImageWithSize:self.boundingBox.size draw:drawToContext];
}

#if TARGET_OS_OSX

-(void)colorOfRawImage:(RawImage)__rawImage atX:(NSInteger)x y:(NSInteger)y color:(CGColorRef*)color {
    NSColor *nsColor = [__rawImage.bitmapRep colorAtX:x - (NSInteger)(floor(CGRectGetMinX(self.rawImage.options.bounds))) y:y - (NSInteger)(floor(CGRectGetMaxY(self.rawImage.options.bounds))) - 1];
    
    if ( nsColor == nil ) {
        *color = CGColorCreateGenericRGB(0, 0, 0, 0);
    }
    else {
        CGFloat red = 0, green = 0, blue = 0, alpha = 0;
        [nsColor getRed:&red green: &green blue: &blue alpha: &alpha];
        *color = CGColorCreateGenericRGB(red, green, blue, alpha);
    }
}
#else
-(void)colorOfRawImage:(RawImage)__rawImage atX:(NSInteger)x y:(NSInteger)y color:(CGColorRef*)color {
    // rows in memory are always powers of two, leaving empty bytes to pad as necessary.
    NSInteger rowWidth = (NSInteger)__rawImage.options.bytesPerRow / 4;
    NSInteger pixelPointer = ((rowWidth * (y - (NSInteger)(floor(CGRectGetMinY(__rawImage.options.bounds))))) + (x - (NSInteger)(floor(CGRectGetMinX(__rawImage.options.bounds))))) * 4;
   
    // buffer in BGRA format
    *color = CGColorCreateGenericRGB([self byteForRawImage:__rawImage offset:2 pixelPointer:pixelPointer], [self byteForRawImage:__rawImage offset:1 pixelPointer:pixelPointer], [self byteForRawImage:__rawImage offset:0 pixelPointer:pixelPointer], [self byteForRawImage:__rawImage offset:3 pixelPointer:pixelPointer]);
}

// data[pixelInfo] is a pointer to the first in a series of four UInt8s (r, g, b, a)
-(CGFloat)byteForRawImage:(RawImage)__rawImage offset:(NSInteger)offset pixelPointer:(NSInteger)pixelPointer {
    if ( pixelPointer < 0 ) {
        return 0;
    }
    return (CGFloat)__rawImage.pixels[pixelPointer + offset] / 256.0;
}
#endif

@end
