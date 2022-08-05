//
//  ContourRawDataPlot.m
//  CorePlotGallery
//
//  Created by Steve Wainwright on 25/01/2022.
//

#import "ContourRawDataPlot.h"

#import <CorePlot/DelaunayTriangulation.h>
#import <CorePlot/DelaunayTriangle.h>
#import <CorePlot/DelaunayPoint.h>

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

@interface ContourRawDataPlot()

@property (nonatomic, readwrite, strong, nullable) CPTGraph *graph;
@property (nonatomic, readwrite, strong, nonnull) NSArray<NSDictionary *> *plotData;
@property (nonatomic, readwrite, strong) NSMutableSet<CPTFieldFunctionDataSource *> *dataSources;
@property (nonatomic, readwrite, strong) CPTAnnotation *colourCodeAnnotation;
@property (nonatomic) BOOL contourFill;

#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
typedef UIFont CPTFont;
#else
typedef NSFont CPTFont;
#endif

-(nullable CPTFont *)italicFontForFont:(nonnull CPTFont *)oldFont;

@end

@implementation ContourRawDataPlot

@synthesize graph;
@synthesize plotData;
@synthesize dataSources;
@synthesize colourCodeAnnotation;
@synthesize contourFill;

+(void)load
{
    [super registerPlotItem:self];
}

-(nonnull instancetype)init
{
    if ( (self = [super init]) ) {
        graph    = nil;
        dataSources = [[NSMutableSet alloc] init];

        self.title   = @"Contour Raw Data Plot";
        self.section = kFieldsPlots;
    }

    return self;
}

-(void)killGraph
{
    [self.dataSources removeAllObjects];

    [super killGraph];
}

-(void)generateData {
    if ( self.plotData.count == 0 ) {
        NSMutableArray<NSDictionary *> *contentArray = [NSMutableArray array];
        [contentArray addObject:@{ @"x": @875.0, @"y": @3375.0, @"z": @632.0 }];
        [contentArray addObject:@{ @"x": @500.0, @"y": @4000.0, @"z": @634.0 }];
        [contentArray addObject:@{ @"x": @2250.0, @"y": @1250.0, @"z": @654.2 }];
        [contentArray addObject:@{ @"x": @3000.0, @"y": @875.0, @"z": @646.4 }];
        [contentArray addObject:@{ @"x": @2560.0, @"y": @1187.0, @"z": @641.5 }];
        [contentArray addObject:@{ @"x": @1000.0, @"y": @750.0, @"z": @650.0 }];
        [contentArray addObject:@{ @"x": @2060.0, @"y": @1560.0, @"z": @634.0 }];
        [contentArray addObject:@{ @"x": @3000.0, @"y": @1750.0, @"z": @643.3 }];
        [contentArray addObject:@{ @"x": @2750.0, @"y": @2560.0, @"z": @639.4 }];
        [contentArray addObject:@{ @"x": @1125.0, @"y": @2500.0, @"z": @630.1 }];
        [contentArray addObject:@{ @"x": @875.0, @"y": @3125.0, @"z": @638.0 }];
        [contentArray addObject:@{ @"x": @1000.0, @"y": @3375.0, @"z": @632.3 }];
        [contentArray addObject:@{ @"x": @1060.0, @"y": @3500.0, @"z": @630.8 }];
        [contentArray addObject:@{ @"x": @1250.0, @"y": @3625.0, @"z": @635.8 }];
        [contentArray addObject:@{ @"x": @750.0, @"y": @3375.0, @"z": @625.6 }];
        [contentArray addObject:@{ @"x": @560.0, @"y": @4125.0, @"z": @632.0 }];
        [contentArray addObject:@{ @"x": @185.0, @"y": @3625.0, @"z": @624.2 }];
        self.plotData = contentArray;
    }
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
        plotSpace.yRange = [CPTPlotRange plotRangeWithLocation:@(0.0) length:@(4000.0)];
        CPTMutablePlotRange *xRange = [CPTMutablePlotRange plotRangeWithLocation:@(0.0) length:@(4000.0)];
        [xRange expandRangeByFactor:@(ratio)];
        plotSpace.xRange = xRange;
    }
    else {
        plotSpace.xRange = [CPTPlotRange plotRangeWithLocation:@(0.0) length:@(4000.0)];
        CPTMutablePlotRange *yRange = [CPTMutablePlotRange plotRangeWithLocation:@(0.0) length:@(4000.0)];
        [yRange expandRangeByFactor:@(1 / ratio)];
        plotSpace.yRange = yRange;
    }
    
    // Axes
    CPTXYAxisSet *axisSet = (CPTXYAxisSet *)newGraph.axisSet;
    CPTXYAxis *x          = axisSet.xAxis;
    x.majorIntervalLength   = @(500.0);
    x.orthogonalPosition    = @(0.0);
    x.minorTicksPerInterval = 4;

    CPTXYAxis *y = axisSet.yAxis;
    y.majorIntervalLength   = @(500.0);
    y.minorTicksPerInterval = 4;
    y.orthogonalPosition    = @(0.0);
    y.labelOffset = -45.0;

    // Contour properties
    
    // Create some function plots
    NSString *titleString          = @"Contour Raw Data";
        
    // Create a plot that uses the data source method
    CPTContourPlot *contourPlot = [[CPTContourPlot alloc] init];
    contourPlot.identifier = [NSString stringWithFormat:@"Function Raw Data Plot %lu", (unsigned long)(1)];

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
    
    CPTMutableLineStyle *linestyle = [CPTMutableLineStyle lineStyle];
    linestyle.lineWidth = 1.5;
    linestyle.lineColor = [CPTColor blueColor];
    contourPlot.isoCurveLineStyle = linestyle;
    contourPlot.alignsPointsToPixels = YES;
    
    contourPlot.noIsoCurves = 21;
    contourPlot.showLabels = NO;
    contourPlot.showIsoCurvesLabels = YES;
    contourPlot.functionPlot = NO;
    
    contourPlot.minFunctionValue = 630.0;
    contourPlot.maxFunctionValue = 655.0;
    contourPlot.limits = [CPTMutableNumberArray arrayWithObjects:@0, @3500, @0, @4000, nil];
    contourPlot.extrapolateToLimits = YES;
    
    CPTFieldFunctionDataSource *plotDataSource = [self generateInterpolatedDataForContoursUsingDelaunayForPlot:contourPlot];
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
    
    contourPlot.dataSource = self;
    contourPlot.dataSourceBlock = plotDataSource.dataSourceBlock;
    contourPlot.appearanceDataSource = self;
    contourPlot.delegate     = self;
    
    // isoCurve label appearance
    CPTMutableTextStyle *labelTextstyle = [[CPTMutableTextStyle alloc] init];
    labelTextstyle.fontName = @"Helvetica";
    labelTextstyle.fontSize = 10.0;
    labelTextstyle.textAlignment = CPTTextAlignmentCenter;
    labelTextstyle.color = nil;//[CPTColor lightGrayColor];
    contourPlot.isoCurvesLabelTextStyle = labelTextstyle;
    NSNumberFormatter *labelFormatter = [[NSNumberFormatter alloc] init];
    labelFormatter.maximumFractionDigits = 1;
    contourPlot.isoCurvesLabelFormatter = labelFormatter;
    
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
    
    self.contourFill = NO;
}


#pragma mark -
#pragma mark Plot Data Source Methods

-(NSUInteger)numberOfRecordsForPlot:(nonnull CPTPlot *__unused)plot {
    return self.plotData.count;
}

-(nullable id)numberForPlot:(nonnull CPTPlot *__unused)plot field:(NSUInteger)fieldEnum recordIndex:(NSUInteger)index {
    NSString *key;
    if ( fieldEnum == CPTContourPlotFieldX ) {
        key = @"x";
    }
    else if ( fieldEnum == CPTContourPlotFieldY ) {
        key = @"y";
    }
    else {
        key = @"z";
    }
    NSNumber *num = self.plotData[index][key];
    return num;
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
    
    if ( contourPlot.noIsoCurves == 20 ) {
        [self showColourCodeAnnotation:contourPlot];
    }
    else {
        [self removeColourCodeAnnotation];
    }
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
        darkGrayText.color    = [CPTColor blackColor];
        darkGrayText.fontSize = self.titleSize * CPTFloat(0.4);
    });
    
    CPTTextLayer *newLayer    = nil;
    CPTNumberArray *isoCurveValues = [plot getIsoCurveValues];
    if( isoCurveValues != nil && idx < isoCurveValues.count ) {
        NSNumberFormatter *formatter = (NSNumberFormatter*)plot.isoCurvesLabelFormatter;
        NSString *labelString = [formatter stringForObjectValue: isoCurveValues[idx]];
        newLayer = [[CPTTextLayer alloc] initWithText:labelString style:darkGrayText];
    }

    return newLayer;
}

#pragma mark -
#pragma mark CPTLegendDelegate method

-(nullable CPTLineStyle *)legend:(CPTLegend *)legend lineStyleForEntryAtIndex:(NSUInteger)idx forPlot:(CPTPlot *)plot {
    CPTContourPlot *contourPlot = (CPTContourPlot*)plot;
    CPTLineStyleArray *_isoCurveLineStyles = [contourPlot getIsoCurveLineStyles];
    if ( _isoCurveLineStyles.count > 0 && idx < _isoCurveLineStyles.count ) {
        return _isoCurveLineStyles[idx];
    }
    else {
        return nil;
    }
}

-(nullable CPTFill *)legend:(nonnull CPTLegend *)legend fillForSwatchAtIndex:(NSUInteger)idx forPlot:(nullable CPTPlot *)plot {
    CPTContourPlot *contourPlot = (CPTContourPlot*)plot;
    CPTMutableFillArray *_isoCurveFills = [contourPlot getIsoCurveFills];
    if ( _isoCurveFills.count > 0 && idx < _isoCurveFills.count ) {
        return _isoCurveFills[idx];
    }
    else {
        return nil;
    }
}

#pragma mark -
#pragma mark Generate Interpolated Data ForContours Using Delaunay Triangles

-(CPTFieldFunctionDataSource*) generateInterpolatedDataForContoursUsingDelaunayForPlot:(CPTContourPlot*)plot {
    
    CGRect triangulationRect = CGRectInset(CGRectMake(0.0, 0.0, 3500.0, 4000.0), 0, 0);
    DelaunayTriangulation *_triangulation = [DelaunayTriangulation triangulationWithRect:triangulationRect];
//    DelaunayTriangulation *_triangulation = [DelaunayTriangulation triangulation];
    
    for ( NSDictionary *dict in self.plotData ) {
        DelaunayPoint *newPoint = [DelaunayPoint pointAtX:(CGFloat)[(NSNumber*)dict[@"x"] doubleValue] andY:(CGFloat)[(NSNumber*)dict[@"y"] doubleValue]];
        newPoint.contribution = (CGFloat)[(NSNumber*)dict[@"z"] doubleValue];
        [_triangulation addPoint:newPoint withColor:nil];
    }
    
    if (plot.extrapolateToLimits) {
        NSMutableArray<DelaunayPoint*> *edgePoints = [NSMutableArray arrayWithCapacity:12];
        [edgePoints addObject:[DelaunayPoint pointAtX:0.0 andY:0.0]];
        [edgePoints addObject:[DelaunayPoint pointAtX:0.0 andY:4000.0/3.0]];
        [edgePoints addObject:[DelaunayPoint pointAtX:0.0 andY:8000.0/3.0]];
        [edgePoints addObject:[DelaunayPoint pointAtX:0.0 andY:4000.0]];
        [edgePoints addObject:[DelaunayPoint pointAtX:3500.0/3.0 andY:4000.0]];
        [edgePoints addObject:[DelaunayPoint pointAtX:7000.0/3.0 andY:4000.0]];
        [edgePoints addObject:[DelaunayPoint pointAtX:3500.0 andY:4000.0]];
        [edgePoints addObject:[DelaunayPoint pointAtX:3500.0 andY:8000.0/3.0]];
        [edgePoints addObject:[DelaunayPoint pointAtX:3500.0 andY:4000.0/3.0]];
        [edgePoints addObject:[DelaunayPoint pointAtX:3500.0 andY:0.0]];
        [edgePoints addObject:[DelaunayPoint pointAtX:7000.0/3.0 andY:0.0]];
        [edgePoints addObject:[DelaunayPoint pointAtX:3500.0/3.0 andY:0.0]];
        
        CGPoint _point;
        NSUInteger nearestPointPosition1, nearestPointPosition2;
        for ( DelaunayPoint *point in edgePoints ) {
            _point = CGPointMake(point.x, point.y);
            [self findNearest2PointsToPoint:_point nearestPosition1:&nearestPointPosition1 nearestPosition2:&nearestPointPosition2];
            double p1[2] = { (CGFloat)[self.plotData[nearestPointPosition1][@"x"] doubleValue], (CGFloat)[self.plotData[nearestPointPosition1][@"y"] doubleValue] };
            double p2[2] = { (CGFloat)[self.plotData[nearestPointPosition2][@"x"] doubleValue], (CGFloat)[self.plotData[nearestPointPosition2][@"y"] doubleValue] };
            double pI[2] = { _point.x, _point.y };
            point.contribution = [_triangulation triangle_extrapolate_linear_singletonForP1:p1 p2:p2 p:pI v1:[self.plotData[nearestPointPosition1][@"z"] doubleValue] v2:[self.plotData[nearestPointPosition2][@"z"] doubleValue]];
        }
        for ( DelaunayPoint *point in edgePoints ) {
            [_triangulation addPoint:point withColor:nil];
        }
    }
    
    CPTFieldFunctionDataSource *plotDataSource = [CPTFieldFunctionDataSource dataSourceForPlot:plot withBlock: ^(double xVal, double yVal) {
        double functionValue = 0.0;
        DelaunayPoint *point = [DelaunayPoint pointAtX:(CGFloat)xVal andY:(CGFloat)yVal];
        double *v = (double*)calloc((size_t)(1), sizeof(double));
        for(DelaunayTriangle *triangle in _triangulation.triangles) {
            if ( [triangle containsPoint:point] ) {
                double p1[2] = { triangle.points[0].x, triangle.points[0].y };
                double p2[2] = { triangle.points[1].x, triangle.points[1].y };
                double p3[2] = { triangle.points[2].x, triangle.points[2].y };
                double v1[1] = { triangle.points[0].contribution };
                double v2[1] = { triangle.points[1].contribution };
                double v3[1] = { triangle.points[2].contribution };
                double pI[2] = { (CGFloat)xVal, (CGFloat)yVal };
                [_triangulation  triangle_interpolate_linearForM:1 n:1 p1:p1 p2:p2 p3:p3 p:pI v1:v1 v2:v2 v3:v3 v:&v size:1];
                functionValue = v[0];
                break;
            }
        }
        free(v);
        return functionValue;
    }]; 
    
    return plotDataSource;
}

-(void)findNearest2PointsToPoint:(CGPoint)point nearestPosition1:(NSUInteger*)nearestPosition1 nearestPosition2:(NSUInteger*)nearestPosition2 {
    NSMutableArray<NSDictionary *> *plotDataCopy = [NSMutableArray arrayWithArray:self.plotData];
    
    *nearestPosition1 = [self positionOfNearestPoint:plotDataCopy toPoint:point];
    [plotDataCopy removeObjectAtIndex:*nearestPosition1];
    *nearestPosition2 = [self positionOfNearestPoint:plotDataCopy toPoint:point];
    if ( *nearestPosition2 >= *nearestPosition1 ) {
        *nearestPosition2 = *nearestPosition2 + 1;
    }
}

-(NSUInteger)positionOfNearestPoint:(NSMutableArray<NSDictionary *>*)data toPoint:(CGPoint)point  {
    NSUInteger position = NSNotFound, count = 0;
    CGFloat minDistance = CGFLOAT_MAX, workingDistance;
    CGPoint nextPoint;
    
    for ( NSDictionary *dict in data ) {
        nextPoint = CGPointMake((CGFloat)[(NSNumber*)dict[@"x"] doubleValue], (CGFloat)[(NSNumber*)dict[@"y"] doubleValue]);
        workingDistance = sqrt(pow(nextPoint.x - point.x, 2.0) + pow(nextPoint.y - point.y, 2.0));
        if ( workingDistance < minDistance ) {
            minDistance = workingDistance;
            position = count;
        }
        count++;
    }
    return position;
}

#pragma mark -
#pragma mark Manage Colour Code Annotations

-(void) showColourCodeAnnotation:(nonnull CPTContourPlot *)plot {
    self.colourCodeAnnotation = [[CPTAnnotation alloc] init];
        
    CPTNumberArray *_isoCurveValues = [plot getIsoCurveValues];
    
    CPTMutableLineStyle *borderLineStyle = [CPTMutableLineStyle lineStyle];
    borderLineStyle.lineColor = [CPTColor blackColor];
    borderLineStyle.lineWidth = 0.5;
    CPTMutableTextStyle *textStyle = [CPTMutableTextStyle textStyle];
    textStyle.fontName = @"Helvetica";
#if TARGET_OS_OSX
    textStyle.fontSize = 11;
#else
    textStyle.fontSize = [[UIDevice currentDevice] userInterfaceIdiom] ==  UIUserInterfaceIdiomPhone ?  8.0 : 11.0;
#endif
    CPTLegend *colorCodeLegend = [[CPTLegend alloc] init];
    colorCodeLegend.fill = [CPTFill fillWithColor:[[CPTColor colorWithGenericGray:0.95] colorWithAlphaComponent:0.6]];
    colorCodeLegend.borderLineStyle = borderLineStyle;
    
    if ( self.contourFill ) {
        CPTMutableFillArray *_isoCurveFills = [plot getIsoCurveFills];
        NSUInteger noContourFillColours = [_isoCurveFills count];
        
        colorCodeLegend.numberOfColumns = noContourFillColours / 5;
        if (noContourFillColours % 5 > 0 ) {
            colorCodeLegend.numberOfColumns = colorCodeLegend.numberOfColumns + 1;
        }
        colorCodeLegend.numberOfRows = noContourFillColours > 5 ? 5 : noContourFillColours;
        
        double firstValue = [_isoCurveValues[0] doubleValue];
        CPTMutableLegendEntryArray *legendEntries = [[CPTMutableLegendEntryArray alloc] initWithCapacity:noContourFillColours];
        CPTLegendEntry *legendEntry0 = [[CPTLegendEntry alloc] init];
        legendEntry0.indexCustomised = 0;
        legendEntry0.plotCustomised = plot;
        legendEntry0.textStyle = textStyle;
        legendEntry0.titleCustomised = [NSString stringWithFormat:@"<%0.2f", [_isoCurveValues[0] doubleValue]];
        [legendEntries addObject:legendEntry0];
        for ( NSUInteger i = 1; i < noContourFillColours-1; i++ ) {
            CPTLegendEntry *legendEntry = [[CPTLegendEntry alloc] init];
            legendEntry.indexCustomised = i;
            legendEntry.plotCustomised = plot;
            legendEntry.textStyle = textStyle;
            legendEntry.titleCustomised = [NSString stringWithFormat:@"%0.2f - %0.2f", firstValue, [_isoCurveValues[i] doubleValue]];
            firstValue = [_isoCurveValues[i] doubleValue];
            [legendEntries addObject:legendEntry];
        }
        CPTLegendEntry *legendEntry1 = [[CPTLegendEntry alloc] init];
        legendEntry1.indexCustomised = noContourFillColours-1;
        legendEntry1.plotCustomised = plot;
        legendEntry1.textStyle = textStyle;
        legendEntry1.titleCustomised = [NSString stringWithFormat:@">%0.2f", [_isoCurveValues[_isoCurveValues.count-1] doubleValue]];
        [legendEntries addObject:legendEntry1];
            
        [colorCodeLegend setNewLegendEntries:legendEntries];
        colorCodeLegend.swatchSize = CGSizeMake(25.0, 16.0);
    }
    else {
        CPTLineStyleArray *_isoCurveLineStyles = [plot getIsoCurveLineStyles];
        NSUInteger noContourLineStyles = [_isoCurveLineStyles count];
        
        colorCodeLegend.numberOfColumns = noContourLineStyles / 5;
        if (noContourLineStyles % 5 > 0 ) {
            colorCodeLegend.numberOfColumns = colorCodeLegend.numberOfColumns + 1;
        }
        colorCodeLegend.numberOfRows = noContourLineStyles > 5 ? 5 : noContourLineStyles;
        
        CPTMutableLegendEntryArray *legendEntries = [[CPTMutableLegendEntryArray alloc] initWithCapacity:noContourLineStyles];
        for ( NSUInteger i = 0; i < noContourLineStyles; i++ ){
            CPTLegendEntry *legendEntry = [[CPTLegendEntry alloc] init];
            legendEntry.indexCustomised = i;
            legendEntry.plotCustomised = plot;
            legendEntry.textStyle = textStyle;
            legendEntry.titleCustomised = [NSString stringWithFormat:@"%0.2f", [_isoCurveValues[i] doubleValue]];
            legendEntry.lineStyleCustomised = _isoCurveLineStyles[i];
            [legendEntries addObject:legendEntry];
        }
        [colorCodeLegend setNewLegendEntries:legendEntries];
    }
    colorCodeLegend.cornerRadius = 5.0;
    colorCodeLegend.rowMargin = 5.0;
    colorCodeLegend.paddingLeft = 6.0;
    colorCodeLegend.paddingTop = 6.0;
    colorCodeLegend.paddingRight = 6.0;
    colorCodeLegend.paddingBottom = 6.0;
    colorCodeLegend.delegate = self;
    self.colourCodeAnnotation.contentLayer = colorCodeLegend;
    [colorCodeLegend setLayoutChanged];
    [self.graph.plotAreaFrame.plotArea addAnnotation:self.colourCodeAnnotation];
    colorCodeLegend.position = CGPointMake(self.graph.plotAreaFrame.plotArea.bounds.size.width * 0.5, 75.0);
}

-(void) removeColourCodeAnnotation {
    if( [self.graph.plotAreaFrame.plotArea.annotations containsObject:self.colourCodeAnnotation] ) {
        [self.graph.plotAreaFrame.plotArea removeAnnotation:self.colourCodeAnnotation];
    }
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
