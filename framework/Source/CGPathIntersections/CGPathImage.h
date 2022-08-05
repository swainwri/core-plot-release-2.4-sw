//
//  CGPathImage.h
//  CGPathIntersections
//
//  Created by Steve Wainwright on 27/05/2022.
//


#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import "PlatformImage+CGContext.h"

NS_ASSUME_NONNULL_BEGIN


typedef struct {
    CGRect bounds;
    size_t bytesPerRow;
    size_t bitsPerComponent;
} Options;

typedef struct {
#if TARGET_OS_OSX
    // On macOS we can just call `NSBitmapImageRep.colorAt(x:y)`
    NSBitmapImageRep *bitmapRep;
#else
    // On iOS we have to access the pixel data manually by computing
    // the correct offset in the image data's buffer
    UInt8 *pixels;
#endif
    Options options;
} RawImage;

@interface CGPathImage : NSObject

@property (nonatomic, readwrite, assign) CGPathRef _Nonnull path;
@property (nonatomic, readwrite, assign) CGRect boundingBox;
@property (nonatomic, readwrite, assign) CGImageRef _Nullable cgImage;
@property (nonatomic, readwrite, retain) PlatformImage *image;
@property (nonatomic, readwrite, assign) RawImage rawImage;

-(nonnull instancetype)initFromPath:(CGPathRef)_path;
-(BOOL)intersectsPath:(CGPathImage*)path;
-(nullable NSArray<NSValue*>*)intersectionPointsWithOther:(CGPathImage*)other;

@end

NS_ASSUME_NONNULL_END
