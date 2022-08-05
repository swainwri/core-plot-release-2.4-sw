//
//  CPTContourPlot.h
//  CorePlot Mac
//
//  Created by Steve Wainwright on 19/12/2020.
//

#import "CPTDefinitions.h"
#import "CPTLineStyle.h"
#import "CPTFill.h"
#import "CPTPlot.h"
#import "CPTPlotSymbol.h"
#import "CPTFieldFunctionDataSource.h"

@class CPTFill;
@class CPTContourPlot;


/**
 *  @brief Contour plot bindings.
 **/
typedef NSString *CPTContourPlotBinding cpt_swift_struct;

/// @ingroup plotBindingsContourPlot
/// @{
extern CPTContourPlotBinding __nonnull const CPTContourPlotBindingXValues;
extern CPTContourPlotBinding __nonnull const CPTContourPlotBindingYValues;
extern CPTContourPlotBinding __nonnull const CPTContourPlotBindingFunctionValues;
extern CPTContourPlotBinding __nonnull const CPTContourPlotBindingPlotSymbols;
/// @}

/**
 *  @brief Enumeration of Contourplot data source field types
 **/
typedef NS_ENUM (NSInteger, CPTContourPlotField) {
    CPTContourPlotFieldX,     ///< X values.
    CPTContourPlotFieldY,     ///< Y values.
    CPTContourPlotFieldFunctionValue  ///< function value  values.
};

/**
 *  @brief Enumeration of Contour plot interpolation algorithms
 **/
typedef NS_ENUM (NSInteger, CPTContourPlotInterpolation) {
    CPTContourPlotInterpolationLinear,    ///< Linear interpolation.
    CPTContourPlotInterpolationCurved     ///< Curved interpolation.
};

/**
 *  @brief Enumration of Contour plot curved interpolation style options
 **/
typedef NS_ENUM (NSInteger, CPTContourPlotCurvedInterpolationOption) {
    CPTContourPlotCurvedInterpolationNormal,                ///< Standard Curved Interpolation (Bezier Curve)
    CPTContourPlotCurvedInterpolationCatmullRomUniform,     ///< Catmull-Rom Spline Interpolation with alpha = @num{0.0}.
    CPTContourPlotCurvedInterpolationCatmullRomCentripetal, ///< Catmull-Rom Spline Interpolation with alpha = @num{0.5}.
    CPTContourPlotCurvedInterpolationCatmullRomChordal,     ///< Catmull-Rom Spline Interpolation with alpha = @num{1.0}.
    CPTContourPlotCurvedInterpolationCatmullCustomAlpha,    ///< Catmull-Rom Spline Interpolation with a custom alpha value.
    CPTContourPlotCurvedInterpolationHermiteCubic           ///< Hermite Cubic Spline Interpolation
};

double TestFunction(double x,double y);



#pragma mark -

/**
 *  @brief A Contour plot data source.
 **/
@protocol CPTContourPlotDataSource<CPTPlotDataSource>

@optional

/// @name Plot Symbols
/// @{

/** @brief @optional Gets a range of plot symbols for the given contour plot.
 *  @param plot The contour plot.
 *  @param indexRange The range of the data indexes of interest.
 *  @return An array of plot symbols.
 **/
-(nullable CPTPlotSymbolArray *)symbolsForContourPlot:(nonnull CPTContourPlot *)plot recordIndexRange:(NSRange)indexRange;

/** @brief @optional Gets a single plot symbol for the given contour plot.
 *  This method will not be called if
 *  @link CPTContourPlotDataSource::symbolsForContourPlot:recordIndexRange:  @endlink
 *  is also implemented in the datasource.
 *  @param plot The scatter plot.
 *  @param idx The data index of interest.
 *  @return The plot symbol to show for the point with the given index.
 **/
-(nullable CPTPlotSymbol *)symbolForContourPlot:(nonnull CPTContourPlot *)plot recordIndex:(NSUInteger)idx;

/// @}


/// @name Contour  Style
/// @{

/** @brief @optional Gets a range of contour line styles for the given range plot.
 *  @param plot The Contour plot.
 *  @param indices The arrary of the isoCurve indexes of interest.
 *  @return An array of line styles.
 **/
-(nullable CPTLineStyleArray *)lineStylesForContourPlot:(nonnull CPTContourPlot *)plot isoCurveIndices:(nonnull NSUInteger*)indices isoCurveIndicesSize:(NSUInteger)size;

/** @brief @optional Gets a contour style for the given range plot.
 *  This method will not be called if
 *  @link CPTContourPlotDataSource::lineStylesForContourPlot:recordIndexRange: -lineStylesForContourPlot:recordIndexRange: @endlink
 *  is also implemented in the datasource.
 *  @param plot The range plot.
 *  @param idx The data index of interest.
 *  @return The contour style for the isoCurve with the given index. If the data source returns @nil, the default line style is used.
 *  If the data source returns an NSNull object, no line is drawn.
 **/
-(nullable CPTLineStyle *)lineStyleForContourPlot:(nonnull CPTContourPlot *)plot isoCurveIndex:(NSUInteger)idx;

/// @}

/// @name Contour  Fill
/// @{

/** @brief @optional Gets a range of contour fills for the given range plot.
 *  @param plot The Contour plot.
 *  @param indices The arrayof the isoCurve indexes of interest.
 *  @param size The size of indices array.
 *  @return An array of fill styles.
 **/
-(nullable CPTFillArray *)fillsForContourPlot:(nonnull CPTContourPlot *)plot isoCurveIndices:(nonnull NSUInteger*)indices isoCurveIndicesSize:(NSUInteger)size;

/** @brief @optional Gets a contour fill for the given range plot.
 *  This method will not be called if
 *  @link CPTContourPlotDataSource::lfillForContourPlot:recordIndexRange: -fillForContourPlot:recordIndexRange: @endlink
 *  is also implemented in the datasource.
 *  @param plot The range plot.
 *  @param idx The data index of interest.
 *  @return The fill for the isoCurve with the given index. If the data source returns @nil, no fill is used.
 *  If the data source returns an NSNull object, no fill is drawn.
 **/
-(nullable CPTFill *)fillForContourPlot:(nonnull CPTContourPlot *)plot isoCurveIndex:(NSUInteger)idx;

/// @}

/// @name Isocurve Labeling 
/// @{

/** @brief @optional Gets a range of data labels for the given plot.
 *  @param plot The plot.
 *  @param indices The array of the isoCurve indexes of interest.
 *  @param size The no of indices in array
 *  @return An array of data labels.
 **/
-(nullable CPTLayerArray *)isoCurveLabelsForPlot:(nonnull CPTPlot *)plot isoCurveIndices:(nonnull NSUInteger*)indices isoCurveIndicesSize:(NSUInteger)size;

/** @brief @optional Gets a isocurve label for the given plot isocurve contour.
 *  This method will not be called if
 *  @link CPTContourPlotDataSource::isoCurveLabelsForPlot:recordIndexRange: -dataLabelsForPlot:recordIndexRange: @endlink
 *  is also implemented in the datasource.
 *  @param plot The plot.
 *  @param idx The data index of interest.
 *  @return The data label for the point with the given index.
 *  If you return @nil, the default data label will be used. If you return an instance of NSNull,
 *  no label will be shown for the index in question.
 **/
-(nullable CPTLayer *)isoCurveLabelForPlot:(nonnull CPTContourPlot *)plot isoCurveIndex:(NSUInteger)idx;

/// @}


@end

#pragma mark -

/**
 *  @brief Contour plot delegate.
 **/
@protocol CPTContourPlotDelegate<CPTPlotDelegate>

@optional

/// @name Data Point Selection
/// @{

/** @brief @optional Informs the delegate that a data point
 *  @if MacOnly was both pressed and released. @endif
 *  @if iOSOnly received both the touch down and up events. @endif
 *  @param plot The contour plot.
 *  @param idx The index of the
 *  @if MacOnly clicked data point. @endif
 *  @if iOSOnly touched data point. @endif
 **/
-(void)contourPlot:(nonnull CPTContourPlot *)plot plotSymbolWasSelectedAtRecordIndex:(NSUInteger)idx;

/** @brief @optional Informs the delegate that a data point
 *  @if MacOnly was both pressed and released. @endif
 *  @if iOSOnly received both the touch down and up events. @endif
 *  @param plot The contour plot.
 *  @param idx The index of the
 *  @if MacOnly clicked data point. @endif
 *  @if iOSOnly touched data point. @endif
 *  @param event The event that triggered the selection.
 **/
-(void)contourPlot:(nonnull CPTContourPlot *)plot plotSymbolWasSelectedAtRecordIndex:(NSUInteger)idx withEvent:(nonnull CPTNativeEvent *)event;

/** @brief @optional Informs the delegate that a data point
 *  @if MacOnly was pressed. @endif
 *  @if iOSOnly touch started. @endif
 *  @param plot The contour plot.
 *  @param idx The index of the
 *  @if MacOnly clicked data point. @endif
 *  @if iOSOnly touched data point. @endif
 **/
-(void)contourPlot:(nonnull CPTContourPlot *)plot plotSymbolTouchDownAtRecordIndex:(NSUInteger)idx;

/** @brief @optional Informs the delegate that a data point
 *  @if MacOnly was pressed. @endif
 *  @if iOSOnly touch started. @endif
 *  @param plot The contour plot.
 *  @param idx The index of the
 *  @if MacOnly clicked data point. @endif
 *  @if iOSOnly touched data point. @endif
 *  @param event The event that triggered the selection.
 **/
-(void)contourPlot:(nonnull CPTContourPlot *)plot plotSymbolTouchDownAtRecordIndex:(NSUInteger)idx withEvent:(nonnull CPTNativeEvent *)event;

/** @brief @optional Informs the delegate that a data point
 *  @if MacOnly was released. @endif
 *  @if iOSOnly touch ended. @endif
 *  @param plot The contour plot.
 *  @param idx The index of the
 *  @if MacOnly clicked data point. @endif
 *  @if iOSOnly touched data point. @endif
 **/
-(void)contourPlot:(nonnull CPTContourPlot *)plot plotSymbolTouchUpAtRecordIndex:(NSUInteger)idx;

/** @brief @optional Informs the delegate that a data point
 *  @if MacOnly was released. @endif
 *  @if iOSOnly touch ended. @endif
 *  @param plot The Contour plot.
 *  @param idx The index of the
 *  @if MacOnly clicked data point. @endif
 *  @if iOSOnly touched data point. @endif
 *  @param event The event that triggered the selection.
 **/
-(void)contourPlot:(nonnull CPTContourPlot *)plot plotSymbolTouchUpAtRecordIndex:(NSUInteger)idx withEvent:(nonnull CPTNativeEvent *)event;

/// @}

/// @name Point Selection
/// @{

/** @brief @optional Informs the delegate that a contour base point
 *  @if MacOnly was both pressed and released. @endif
 *  @if iOSOnly received both the touch down and up events. @endif
 *  @param plot The Contour plot.
 *  @param idx The index of the
 *  @if MacOnly clicked bar. @endif
 *  @if iOSOnly touched bar. @endif
 **/
-(void) contourPlot:(nonnull  CPTContourPlot *)plot contourWasSelectedAtRecordIndex:(NSUInteger)idx;

/** @brief @optional Informs the delegate that  a contour base point
 *  @if MacOnly was both pressed and released. @endif
 *  @if iOSOnly received both the touch down and up events. @endif
 *  @param plot The Contour plot.
 *  @param idx The index of the
 *  @if MacOnly clicked bar. @endif
 *  @if iOSOnly touched bar. @endif
 *  @param event The event that triggered the selection.
 **/
-(void) contourPlot:(nonnull  CPTContourPlot *)plot contourWasSelectedAtRecordIndex:(NSUInteger)idx withEvent:(nonnull CPTNativeEvent *)event;

/** @brief @optional Informs the delegate that a contour base point
 *  @if MacOnly was pressed. @endif
 *  @if iOSOnly touch started. @endif
 *  @param plot The Contour plot.
 *  @param idx The index of the
 *  @if MacOnly clicked bar. @endif
 *  @if iOSOnly touched bar. @endif
 **/
-(void) contourPlot:(nonnull  CPTContourPlot *)plot  contourTouchDownAtRecordIndex:(NSUInteger)idx;

/** @brief @optional Informs the delegate that a contour base point
 *  @if MacOnly was pressed. @endif
 *  @if iOSOnly touch started. @endif
 *  @param plot The Contour plot.
 *  @param idx The index of the
 *  @if MacOnly clicked bar. @endif
 *  @if iOSOnly touched bar. @endif
 *  @param event The event that triggered the selection.
 **/
-(void) contourPlot:(nonnull  CPTContourPlot *)plot  contourTouchDownAtRecordIndex:(NSUInteger)idx withEvent:(nonnull CPTNativeEvent *)event;

/** @brief @optional Informs the delegate that a contour base point
 *  @if MacOnly was released. @endif
 *  @if iOSOnly touch ended. @endif
 *  @param plot The Contour plot.
 *  @param idx The index of the
 *  @if MacOnly clicked bar. @endif
 *  @if iOSOnly touched bar. @endif
 **/
-(void) contourPlot:(nonnull  CPTContourPlot *)plot contourTouchUpAtRecordIndex:(NSUInteger)idx;

/** @brief @optional Informs the delegate that a contour base point
 *  @if MacOnly was released. @endif
 *  @if iOSOnly touch ended. @endif
 *  @param plot The Contour plot.
 *  @param idx The index of the
 *  @if MacOnly clicked bar. @endif
 *  @if iOSOnly touched bar. @endif
 *  @param event The event that triggered the selection.
 **/
-(void) contourPlot:(nonnull  CPTContourPlot *)plot contourTouchUpAtRecordIndex:(NSUInteger)idx withEvent:(nonnull CPTNativeEvent *)event;

/// @}

@end

#pragma mark -

@interface CPTContourPlot : CPTPlot

/// @name Contour Processing Activity Indicator
/// @{

/**
 *  @brief An Objective-C block called to generate activity indicator whilst processing contours.
 **/
typedef void (^CPTActivityIndicatorBlock)(void);
@property (nonatomic, readwrite, strong, nullable) CPTActivityIndicatorBlock activityIndicatorBlock;
@property (nonatomic, readwrite, assign) BOOL showActivityIndicator;
@property (nonatomic, readwrite, strong, nullable) NSString* activityMessage;
/// @}

/// @name Contour Data Source
/// @{
@property (nonatomic, readwrite, strong, nullable) CPTContourDataSourceBlock dataSourceBlock;
@property (nonatomic, readwrite, assign) BOOL functionPlot;
/// @}


/// @name Appearance
/// @{
@property (nonatomic, readwrite, copy, nullable) CPTPlotSymbol *plotSymbol;
@property (nonatomic, readwrite, copy, nullable) CPTLineStyle *isoCurveLineStyle;
@property (nonatomic, readwrite, copy, nullable) CPTFill *isoCurveFill;
@property (nonatomic, readwrite, assign) double minFunctionValue;
@property (nonatomic, readwrite, assign) double maxFunctionValue;
@property (nonatomic, readwrite, assign) NSUInteger noIsoCurves;
@property (nonatomic, readwrite, assign) CPTContourPlotInterpolation interpolation;
@property (nonatomic, readwrite, assign) CPTContourPlotCurvedInterpolationOption curvedInterpolationOption;
@property (nonatomic, readwrite, assign) CGFloat curvedInterpolationCustomAlpha;
@property (nonatomic, readwrite, assign) BOOL adjustIsoCurvesLabelAnchors;
@property (nonatomic, readwrite, assign) CGFloat isoCurvesLabelOffset;
@property (nonatomic, readwrite, assign) CGFloat isoCurvesLabelRotation;
@property (nonatomic, readwrite, assign) CGPoint isoCurvesLabelContentAnchorPoint;
@property (nonatomic, readwrite, copy, nullable) CPTTextStyle *isoCurvesLabelTextStyle;
@property (nonatomic, readwrite, strong, nullable) NSFormatter *isoCurvesLabelFormatter;
@property (nonatomic, readwrite, strong, nullable) CPTShadow *isoCurvesLabelShadow;
@property (nonatomic, readwrite, assign) BOOL showIsoCurvesLabels;
@property (nonatomic, readwrite, strong, nonnull) CPTMutableNumberArray *limits;       // left, right, bottom, top;
@property (nonatomic, readwrite, assign) BOOL easyOnTheEye;
@property (nonatomic, readwrite, assign) BOOL extrapolateToLimits;
@property (nonatomic, readwrite, assign) BOOL fillIsoCurves;
@property (nonatomic, readwrite, assign) BOOL joinContourLineStartToEnd;
/// @}

/// @name User Interaction
/// @{
@property (nonatomic, readwrite, assign) CGFloat plotSymbolMarginForHitDetection;
@property (nonatomic, readwrite, assign) CGFloat plotLineMarginForHitDetection;
@property (nonatomic, readwrite, assign) BOOL allowSimultaneousSymbolAndPlotSelection;
/// @}

/// @name Plot Symbols
/// @{
-(nullable CPTPlotSymbol *)plotSymbolForRecordIndex:(NSUInteger)idx;
-(void)reloadPlotSymbols;
-(void)reloadPlotSymbolsInIndexRange:(NSRange)indexRange;
/// @}

/// @name Contour IsoCurve Styles
/// @{
-(void)reloadContourLineStyles;
-(void)reloadContourLineStylesInIsoCurveIndexRange:(NSRange)indexRange;
/// @}

/// @name Contour IsoCurve Labels
/// @{
-(void)reloadContourLabels;
-(void)reloadContourLabelsInIsoCurveIndexRange:(NSRange)indexRange;
/// @}

/// @name Accessors
/// @{
-(nullable CPTNumberArray *)getIsoCurveValues;
-(nullable CPTNumberArray *)getIsoCurveIndices;
-(nullable CPTMutableFillArray *)getIsoCurveFills;
-(nullable CPTLineStyleArray *)getIsoCurveLineStyles;

-(NSUInteger)getNoDataPointsUsedForIsoCurves;
-(void)setFirstGridColumns:(NSUInteger)cols Rows:(NSUInteger)rows;
-(void)setSecondaryGridColumns:(NSUInteger)cols Rows:(NSUInteger)rows;
-(void)updateDataSourceBlock:(nonnull CPTContourDataSourceBlock)newDataSourceBlock;
/// @}

@end

