#import "CPTColorSpaceTests.h"

#import "CPTColorSpace.h"

@implementation CPTColorSpaceTests

#pragma mark -
#pragma mark NSCoding Methods

-(void)testKeyedArchivingRoundTrip
{
    CPTColorSpace *colorSpace = [CPTColorSpace genericRGBSpace];

    CPTColorSpace *newColorSpace = [self archiveRoundTrip:colorSpace];

    CFDataRef iccProfile    = NULL;
    CFDataRef newIccProfile = NULL;

    iccProfile    = CGColorSpaceCopyICCData(colorSpace.cgColorSpace);
    newIccProfile = CGColorSpaceCopyICCData(newColorSpace.cgColorSpace);

    if ( iccProfile && newIccProfile ) {
        XCTAssertTrue([(__bridge NSData *) iccProfile isEqualToData:(__bridge NSData *)newIccProfile], @"Color spaces not equal");
    }

    if ( iccProfile ) {
        CFRelease(iccProfile);
    }
    if ( newIccProfile ) {
        CFRelease(newIccProfile);
    }
}

@end
