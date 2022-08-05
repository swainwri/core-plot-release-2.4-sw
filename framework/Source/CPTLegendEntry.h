#import "CPTDefinitions.h"

/// @file

@class CPTLegendEntry;
@class CPTPlot;
@class CPTTextStyle;
@class CPTLineStyle; //  S.Wainwright 21/03/21

/**
 *  @brief An array of CPTLegendEntry objects.
 **/
typedef NSArray<CPTLegendEntry *> CPTLegendEntryArray;

/**
 *  @brief A mutable array of CPTLegendEntry objects.
 **/
typedef NSMutableArray<CPTLegendEntry *> CPTMutableLegendEntryArray;

@interface CPTLegendEntry : NSObject<NSCoding, NSSecureCoding>

/// @name Plot Info
/// @{
@property (nonatomic, readwrite, cpt_weak_property, nullable) CPTPlot *plot;
@property (nonatomic, readwrite, nullable) CPTPlot *plotCustomised; //  S.Wainwright 21/03/21
@property (nonatomic, readwrite, assign) NSUInteger index;
@property (nonatomic, readwrite, assign) NSUInteger indexCustomised; //  S.Wainwright 22/03/21
/// @}

// added S.Wainwright 19/03/21
/// @name Customised Titles
/// @{
@property (nonatomic, readwrite, nullable) NSString *titleCustomised;  //  S.Wainwright 19/03/21
@property (nonatomic, readwrite, nullable) NSAttributedString *attributedTitleCustomised; //  S.Wainwright 19/03/21
/// @}

/// @name Formatting
/// @{
@property (nonatomic, readwrite, strong, nullable) CPTTextStyle *textStyle;
@property (nonatomic, readwrite, strong, nullable) CPTLineStyle *lineStyleCustomised; //  S.Wainwright 21/03/21
/// @}

/// @name Layout
/// @{
@property (nonatomic, readwrite, assign) NSUInteger row;
@property (nonatomic, readwrite, assign) NSUInteger column;
@property (nonatomic, readonly) CGSize titleSize;
/// @}

/// @name Drawing
/// @{
-(void)drawTitleInRect:(CGRect)rect inContext:(nonnull CGContextRef)context scale:(CGFloat)scale;
/// @}

@end
