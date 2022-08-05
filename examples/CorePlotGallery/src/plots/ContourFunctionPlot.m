//
//  ContourFunctionPlot.m
//  CorePlotGallery
//
//  Created by Steve Wainwright on 14/12/2020.
//

#import "ContourFunctionPlot.h"

#import "PiNumberFormatter.h"

// These affect the transparency of the heatmap
// Colder areas will be more transparent
// Currently the alpha is a two piece linear function of the value
// Play with the pivot point and max alpha to affect the look of the heatmap

// This number should be between 0 and 1
static const CGFloat kSBAlphaPivotX = 0.333;

// This number should be between 0 and MAX_ALPHA
static const CGFloat kSBAlphaPivotY = 0.5;

// This number should be between 0 and 1
static const CGFloat kSBMaxAlpha = 0.85;

@interface ContourFunctionPlot()

@property (nonatomic, readwrite, strong, nullable) CPTGraph *graph;

@property (nonatomic, readwrite, strong) NSMutableSet<CPTFieldFunctionDataSource *> *dataSources;

#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
typedef UIFont CPTFont;
#else
typedef NSFont CPTFont;
#endif

-(nullable CPTFont *)italicFontForFont:(nonnull CPTFont *)oldFont;

@end

@implementation ContourFunctionPlot

@synthesize graph;
@synthesize dataSources;

+(void)load
{
    [super registerPlotItem:self];
}

-(nonnull instancetype)init
{
    if ( (self = [super init]) ) {
        graph    = nil;
        dataSources = [[NSMutableSet alloc] init];

        self.title   = @"Contour Function Plot";
        self.section = kFieldsPlots;
    }

    return self;
}

-(void)killGraph
{
    [self.dataSources removeAllObjects];

    [super killGraph];
}

-(void)renderInGraphHostingView:(nonnull CPTGraphHostingView *)hostingView withTheme:(nullable CPTTheme *)theme animated:(BOOL)animated
{
    
#if TARGET_OS_SIMULATOR || TARGET_OS_IPHONE
    CGRect bounds = hostingView.bounds;
#else
    CGRect bounds = NSRectToCGRect(hostingView.bounds);
#endif

    CPTXYGraph *newGraph = [[CPTXYGraph alloc] initWithFrame:bounds];
    self.graph = newGraph;

    [self addGraph:newGraph toHostingView:hostingView];
    [self applyTheme:theme toGraph:newGraph withDefault:[CPTTheme themeNamed:kCPTDarkGradientTheme]];

    newGraph.plotAreaFrame.masksToBorder = NO;

    // Instructions
    CPTMutableTextStyle *textStyle = [CPTMutableTextStyle textStyle];
    textStyle.color    = [CPTColor whiteColor];
    textStyle.fontName = @"Helvetica";
    textStyle.fontSize = self.titleSize * CPTFloat(0.5);

    CGFloat ratio = self.graph.bounds.size.width / self.graph.bounds.size.height;
    
    // Setup scatter plot space
    CPTXYPlotSpace *plotSpace = (CPTXYPlotSpace *)newGraph.defaultPlotSpace;
    if (ratio > 1) {
        plotSpace.yRange = [CPTPlotRange plotRangeWithLocation:@(-2.0 * M_PI) length:@(4.0 * M_PI)];
        CPTMutablePlotRange *xRange = [CPTMutablePlotRange plotRangeWithLocation:@(-2.0 * M_PI) length:@(4.0 * M_PI)];
        [xRange expandRangeByFactor:@(ratio)];
        plotSpace.xRange = xRange;
    }
    else {
        plotSpace.xRange = [CPTPlotRange plotRangeWithLocation:@(-2.0 * M_PI) length:@(4.0 * M_PI)];
        CPTMutablePlotRange *yRange = [CPTMutablePlotRange plotRangeWithLocation:@(-2.0 * M_PI) length:@(4.0 * M_PI)];
        [yRange expandRangeByFactor:@(1 / ratio)];
        plotSpace.yRange = yRange;
    }
//    if (ratio > 1) {
//        plotSpace.yRange = [CPTPlotRange plotRangeWithLocation:@(-1.5 * M_PI) length:@(3.0 * M_PI)];
//        CPTMutablePlotRange *xRange = [CPTMutablePlotRange plotRangeWithLocation:@(-1.5 * M_PI) length:@(3.0 * M_PI)];
//        [xRange expandRangeByFactor:@(ratio)];
//        plotSpace.xRange = xRange;
//    }
//    else {
//        plotSpace.xRange = [CPTPlotRange plotRangeWithLocation:@(-1.5 * M_PI) length:@(3.0 * M_PI)];
//        CPTMutablePlotRange *yRange = [CPTMutablePlotRange plotRangeWithLocation:@(-1.5 * M_PI) length:@(3.0 * M_PI)];
//        [yRange expandRangeByFactor:@(1 / ratio)];
//        plotSpace.yRange = yRange;
//    }

    PiNumberFormatter *formatter = [[PiNumberFormatter alloc] init];
    formatter.multiplier = @4;
    
    // Axes
    CPTXYAxisSet *axisSet = (CPTXYAxisSet *)newGraph.axisSet;
    CPTXYAxis *x          = axisSet.xAxis;
    x.majorIntervalLength   = @(M_PI / 2.0);
    x.orthogonalPosition    = @(0.0);
    x.minorTicksPerInterval = 3;
    x.labelFormatter = formatter;

    CPTXYAxis *y = axisSet.yAxis;
    y.majorIntervalLength   = @(M_PI / 2.0);
    y.minorTicksPerInterval = 3;
    y.orthogonalPosition    = @(0.0);
    y.labelFormatter = formatter;

    // Contour properties
    
    // Create some function plots
    NSString *titleString          = /*@"sin(x)sin(y)";*/@"0.5*(cos(x + π/4)+sin(y + π/4))";/*@"0.5*(cos(x)+sin(y))"*/;
    CPTContourDataSourceBlock block       = ^(double xVal, double yVal) {
//        return 0.5*(cos(xVal)+sin(yVal));
        return 0.5*(cos(xVal + M_PI_4)+sin(yVal + M_PI_4));
//        return sin(xVal) * sin(yVal);
    };
        
    // Create a plot that uses the data source method
    CPTContourPlot *contourPlot = [[CPTContourPlot alloc] init];
    contourPlot.identifier = [NSString stringWithFormat:@"Function Contour Plot %lu", (unsigned long)(1)];

    CPTDictionary *textAttributes = x.titleTextStyle.attributes;

    NSMutableAttributedString *title = [[NSMutableAttributedString alloc] initWithString:NSLocalizedString(titleString, "") attributes:textAttributes];

    CPTFont *fontAttribute = textAttributes[NSFontAttributeName];
    if ( fontAttribute ) {
        CPTFont *italicFont = [self italicFontForFont:fontAttribute];

        [title addAttribute:NSFontAttributeName
                      value:italicFont
                      range:NSMakeRange(0, 1)];
        [title addAttribute:NSFontAttributeName
                      value:italicFont
                      range:NSMakeRange(8, 1)];
    }

    CPTFont *labelFont = [CPTFont fontWithName:@"Helvetica" size:self.titleSize * CPTFloat(0.5)];
    [title addAttribute:NSFontAttributeName
                  value:labelFont
                  range:NSMakeRange(0, title.length)];

    contourPlot.attributedTitle = title;

    contourPlot.interpolation = CPTContourPlotInterpolationCurved;//CPTContourPlotInterpolationLinear;
    contourPlot.curvedInterpolationOption = CPTContourPlotCurvedInterpolationHermiteCubic;
//   contourPlot.isoCurveLineStyle = nil;
    contourPlot.alignsPointsToPixels = YES;

    CPTFieldFunctionDataSource *plotDataSource = [CPTFieldFunctionDataSource dataSourceForPlot:contourPlot withBlock:block];

    CGFloat resolution;
    if(ratio < 1.0) {
        resolution = self.graph.plotAreaFrame.plotArea.bounds.size.height * 0.02;
    }
    else {
        resolution = self.graph.plotAreaFrame.plotArea.bounds.size.width * 0.02;
    }
    plotDataSource.resolutionX = resolution;
    plotDataSource.resolutionY = resolution;

    [self.dataSources addObject:plotDataSource];
    
    contourPlot.noIsoCurves = 21;
    contourPlot.showLabels = NO;
    contourPlot.showIsoCurvesLabels = YES;
    contourPlot.functionPlot = YES;
    
    contourPlot.dataSource = plotDataSource;
    contourPlot.appearanceDataSource = self;
    contourPlot.delegate     = self;
    
    // isoCurve label appearance
    CPTMutableTextStyle *labelTextstyle = [[CPTMutableTextStyle alloc] init];
    labelTextstyle.fontName = @"Helvetica";
    labelTextstyle.fontSize = 12.0;
    labelTextstyle.textAlignment = CPTTextAlignmentCenter;
    labelTextstyle.color = nil;//[CPTColor lightGrayColor];
    contourPlot.isoCurvesLabelTextStyle = labelTextstyle;
    NSNumberFormatter *labelFormatter = [[NSNumberFormatter alloc] init];
    labelFormatter.maximumFractionDigits = 1;
    contourPlot.isoCurvesLabelFormatter = labelFormatter;
    
    contourPlot.limits = [CPTMutableNumberArray arrayWithObjects: [NSNumber numberWithDouble:-2.0 * M_PI], [NSNumber numberWithDouble:2.0 * M_PI], [NSNumber numberWithDouble:-2.0 * M_PI], [NSNumber numberWithDouble:2.0 * M_PI], nil];
//    contourPlot.limits = [CPTMutableNumberArray arrayWithObjects: [NSNumber numberWithDouble:-M_PI], [NSNumber numberWithDouble: M_PI], [NSNumber numberWithDouble:-M_PI], [NSNumber numberWithDouble:M_PI], nil];

    // Add plot
    [newGraph addPlot:contourPlot];
 //   newGraph.defaultPlotSpace.delegate = self;

    // Add legend
    newGraph.legend                    = [CPTLegend legendWithGraph:newGraph];
    newGraph.legend.textStyle          = x.titleTextStyle;
    newGraph.legend.fill               = [CPTFill fillWithColor:[CPTColor clearColor]];
    newGraph.legend.borderLineStyle    = x.axisLineStyle;
    newGraph.legend.cornerRadius       = 5.0;
    newGraph.legend.swatchCornerRadius = 3.0;
    newGraph.legendAnchor              = CPTRectAnchorTop;
    newGraph.legendDisplacement        = CGPointMake(0.0, self.titleSize * CPTFloat(-2.0) - CPTFloat(12.0) );
}


#pragma mark -
#pragma mark Plot Space Delegate Methods

-(BOOL)plotSpace:(nonnull CPTPlotSpace *)space shouldHandlePointingDeviceUpEvent:(nonnull CPTNativeEvent *)event atPoint:(CGPoint)point {
    return NO;
}

#pragma mark -
#pragma mark Plot Delegate Methods

-(void)contourPlot:(nonnull CPTContourPlot *)plot contourWasSelectedAtRecordIndex:(NSUInteger)index {
    NSLog(@"Range for '%@' was selected at index %d.", plot.identifier, (int)index);
    CPTContourPlot* contourPlot = (CPTContourPlot*)plot;
    contourPlot.noIsoCurves = (contourPlot.noIsoCurves == 21) ? 20 : 21;
    [contourPlot reloadData];
}

#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
-(nullable UIFont *)italicFontForFont:(nonnull UIFont *)oldFont {
    NSString *italicName = nil;

    CPTStringArray *fontNames = [UIFont fontNamesForFamilyName:oldFont.familyName];

    for ( NSString *fontName in fontNames ) {
        NSString *upperCaseFontName = fontName.uppercaseString;
        if ( [upperCaseFontName rangeOfString:@"ITALIC"].location != NSNotFound ) {
            italicName = fontName;
            break;
        }
    }
    if ( !italicName ) {
        for ( NSString *fontName in fontNames ) {
            NSString *upperCaseFontName = fontName.uppercaseString;
            if ( [upperCaseFontName rangeOfString:@"OBLIQUE"].location != NSNotFound ) {
                italicName = fontName;
                break;
            }
        }
    }

    UIFont *italicFont = nil;
    if ( italicName ) {
        italicFont = [UIFont fontWithName:italicName
                                     size:oldFont.pointSize];
    }
    return italicFont;
}

#else
-(nullable NSFont *)italicFontForFont:(nonnull NSFont *)oldFont {
    return [[NSFontManager sharedFontManager] convertFont:oldFont
                                              toHaveTrait:NSFontItalicTrait];
}

#endif

#pragma mark -
#pragma mark Plot Appearance Source Methods

-(nullable CPTLineStyle *)lineStyleForContourPlot:(nonnull CPTContourPlot *)plot isoCurveIndex:(NSUInteger)idx {
    
    CPTMutableLineStyle *linestyle = [plot.isoCurveLineStyle mutableCopy];
    linestyle.lineWidth = 2.0;

    CGFloat red = 0;
    CGFloat green = 0;
    CGFloat blue = 0;
    CGFloat alpha = 0.7;
    
    NSUInteger noIsoCurveValues = [[plot getIsoCurveValues] count];
    double value = (double)(idx + 1) / (double)(noIsoCurveValues + 2);
    blue = MIN(MAX(1.5 - 4.0 * fabs(value - 0.25), 0.0), 1.0);
    green = MIN(MAX(1.5 - 4.0 * fabs(value - 0.5), 0.0), 1.0);
    red  = MIN(MAX(1.5 - 4.0 * fabs(value - 0.75), 0.0), 1.0);
    linestyle.lineColor = [CPTColor colorWithComponentRed:red green:green blue:blue alpha:alpha];
    
//    double value = (double)(idx - plot.noIsoCurves / 2 + 1) / (double)(plot.noIsoCurves+1);;
//    [self diffColorForValue:value red:&red green:&green blue:&blue alpha:&alpha];
//    double value = (double)(idx+1) / (double)(plot.noIsoCurves+1);
//    [self diffColorForValue:value red:&red green:&green blue:&blue alpha:&alpha];
//    linestyle.lineColor = [CPTColor colorWithComponentRed:red/255.0 green:green/255.0 blue:blue/255.0 alpha:alpha/255.0];
    
    return linestyle;
}

-(nullable CPTFill *)fillForContourPlot:(CPTContourPlot *)plot isoCurveIndex:(NSUInteger)idx {
    CGFloat red = 0;
    CGFloat green = 0;
    CGFloat blue = 0;
    CGFloat alpha = 0.7;
    
//    let value: CGFloat = CGFloat(idx+1) / CGFloat(noIsoCurveValues+2)
//
//    blue = min(max(1.5 - 4.0 * abs(value - 0.25), 0.0), 1.0)
//    green = min(max(1.5 - 4.0 * abs(value - 0.5), 0.0), 1.0)
//    red  = min(max(1.5 - 4.0 * abs(value - 0.75), 0.0), 1.0)
//    let colour = CPTColor(componentRed: red, green: green, blue: blue, alpha: 0.7)
    
//    double value = (double)(idx - plot.noIsoCurves / 2 + 1) / (double)(plot.noIsoCurves+1);;
//    [self diffColorForValue:value red:&red green:&green blue:&blue alpha:&alpha];
    NSUInteger noIsoCurveValues = [[plot getIsoCurveValues] count];
    double value = (double)(idx + 1) / (double)(noIsoCurveValues + 2);
    blue = MIN(MAX(1.5 - 4.0 * fabs(value - 0.25), 0.0), 1.0);
    green = MIN(MAX(1.5 - 4.0 * fabs(value - 0.5), 0.0), 1.0);
    red  = MIN(MAX(1.5 - 4.0 * fabs(value - 0.75), 0.0), 1.0);
    CPTColor *fillColour = [CPTColor colorWithComponentRed:red green:green blue:blue alpha:alpha];
//    [self colorForValue:value red:&red green:&green blue:&blue alpha:&alpha];
//    CPTColor *fillColour = [CPTColor colorWithComponentRed:red/255.0 green:green/255.0 blue:blue/255.0 alpha:alpha/255.0];
    CPTFill *fill = [CPTFill fillWithColor:fillColour];

    return fill;
}

-(nullable CPTLayer *)isoCurveLabelForPlot:(CPTContourPlot *)plot isoCurveIndex:(NSUInteger)idx {
    static CPTMutableTextStyle *darkGrayText = nil;
    static dispatch_once_t darkGrayOnceToken      = 0;
    
    dispatch_once(&darkGrayOnceToken, ^{
        darkGrayText          = [[CPTMutableTextStyle alloc] init];
        darkGrayText.color    = [CPTColor whiteColor];
        darkGrayText.fontSize = self.titleSize * CPTFloat(0.5);
    });
    
    CPTTextLayer *newLayer    = nil;
    CPTNumberArray *isoCurveValues = [plot getIsoCurveValues];
    if( isoCurveValues != nil && idx < isoCurveValues.count ) {
        NSNumberFormatter *formatter = (NSNumberFormatter*)plot.isoCurvesLabelFormatter;
        NSString *labelString = [formatter stringForObjectValue: isoCurveValues[idx]];
//        if (plot.isoCurvesLabelTextStyle != nil) {
//            if ( plot.isoCurvesLabelTextStyle.color == nil ) {
//                CPTMutableTextStyle *mutLabelTextStyle = [CPTMutableTextStyle textStyleWithStyle: plot.isoCurvesLabelTextStyle];
//                mutLabelTextStyle.color = [CPTColor colorWithComponentRed:(CGFloat)((float)idx / (float)([plot getIsoCurveValues].count)) green:(CGFloat)(1.0f - (float)idx / (float)([plot getIsoCurveValues].count)) blue:0.0 alpha:1.0];
//                newLayer = [[CPTTextLayer alloc] initWithText:labelString style:mutLabelTextStyle];
//            }
//            else {
//                newLayer = [[CPTTextLayer alloc] initWithText:labelString style:plot.isoCurvesLabelTextStyle];
//            }
//        }
//        else {
            newLayer = [[CPTTextLayer alloc] initWithText:labelString style:darkGrayText];
//        }
    }

    return newLayer;
}

- (NSUInteger)numberOfRecordsForPlot:(nonnull CPTPlot *)plot {
    return 0;
}


#pragma mark -
#pragma mark Colour Provider

//  DTMHeatmap
//  Created by Bryan Oltman on 1/8/15.
//  Copyright (c) 2015 Dataminr. All rights reserved.

- (void)colorForValue:(double)value red:(CGFloat *)red green:(CGFloat *)green blue:(CGFloat *)blue alpha:(CGFloat *)alpha
{
    static int maxVal = 255;
    if (value > 1) {
        value = 1;
    }
  
    value = sqrt(value);
  
    if (value < kSBAlphaPivotY) {
        *alpha = value * kSBAlphaPivotY / kSBAlphaPivotX;
    } else {
        *alpha = kSBAlphaPivotY + ((kSBMaxAlpha - kSBAlphaPivotY) / (1 - kSBAlphaPivotX)) * (value - kSBAlphaPivotX);
    }
  
    //formula converts a number from 0 to 1.0 to an rgb color.
    //uses MATLAB/Octave colorbar code
    if (value <= 0) {
        *red = *green = *blue = *alpha = 0;
    } else if (value < 0.125) {
        *red = *green = 0;
        *blue = 4 * (value + 0.125);
    } else if (value < 0.375) {
        *red = 0;
        *green = 4 * (value - 0.125);
        *blue = 1;
    } else if (value < 0.625) {
        *red = 4 * (value - 0.375);
        *green = 1;
        *blue = 1 - 4 * (value - 0.375);
    } else if (value < 0.875) {
        *red = 1;
        *green = 1 - 4 * (value - 0.625);
        *blue = 0;
    } else {
        *red = MAX(1 - 4 * (value - 0.875), 0.5);
        *green = *blue = 0;
    }
  
    *alpha *= maxVal;
    *blue *= *alpha;
    *green *= *alpha;
    *red *= *alpha;
}

- (void)diffColorForValue:(double)value
                  red:(CGFloat *)red
                green:(CGFloat *)green
                 blue:(CGFloat *)blue
                alpha:(CGFloat *)alpha
{
    static int maxVal = 255;
    
    if (value == 0) {
        return;
    }
    
    BOOL isNegative = value < 0;
    value = sqrt(MIN(ABS(value), 1));
    if (value < kSBAlphaPivotY) {
        *alpha = value * kSBAlphaPivotY / kSBAlphaPivotX;
    } else {
        *alpha = kSBAlphaPivotY + ((kSBMaxAlpha - kSBAlphaPivotY) / (1 - kSBAlphaPivotX)) * (value - kSBAlphaPivotX);
    }
    
    if (isNegative) {
        *red = 0;
        if (value <= 0) {
            *green = *blue = *alpha = 0;
        } else if (value < 0.125) {
            *green = 0;
            *blue = 2 * (value + 0.125);
        } else if (value < 0.375) {
            *blue = 2 * (value + 0.125);
            *green = 4 * (value - 0.125);
        } else if (value < 0.625) {
            *blue = 4 * (value - 0.375);
            *green = 1;
        } else if (value < 0.875) {
            *blue = 1;
            *green = 1 - 4 * (value - 0.625);
        } else {
            *blue = MAX(1 - 4 * (value - 0.875), 0.5);
            *green = 0;
        }
    } else {
        *blue = 0;
        if (value <= 0) {
            *red = *green = *alpha = 0;
        } else if (value < 0.125) {
            *green = value;
            *red = (value);
        } else if (value < 0.375) {
            *red = (value + 0.125);
            *green = value;
        } else if (value < 0.625) {
            *red = (value + 0.125);
            *green = value;
        } else if (value < 0.875) {
            *red = (value + 0.125);
            *green = 1 - 4 * (value - 0.625);
        } else {
            *green = 0;
            *red = MAX(1 - 4 * (value - 0.875), 0.5);
        }
    }
    
    *alpha *= maxVal;
    *blue *= *alpha;
    *green *= *alpha;
    *red *= *alpha;
}


@end
