//
//  CPTContour.h
//  CorePlot
//
//  Created by Steve Wainwright on 22/11/2021.
//
// _CPTContour.m: implementation of the CPTContour class.
//
// _CPTContour.h: interface for the CPTContour class.
//
// CPTContour implements Contour plot algorithm described in
//        IMPLEMENTATION OF
//        AN IMPROVED CONTOUR
//        PLOTTING ALGORITHM
//        BY
//
//        MICHAEL JOSEPH ARAMINI
//
//        B.S., Stevens Institute of Technology, 1980
// See http://www.ultranet.com/~aramini/thesis.html
//
// Ported to C++ by Jonathan de Halleux.
// Ported to ObjC by Steve Wainwright 2021.
//
// Using CPTContour :
//
// CPTContour is not directly usable. The user has to
//    1. derive the function ExportLine that is
//        supposed to draw/store the segment of the contour
//    2. Set the function draw contour of. (using  SetFieldFn
//        The function must be declared as follows
//        double (*myF)(double x , double y);
//
//    History:
//        31-07-2002:
//            - A lot of contribution from Chenggang Zhou (better strip compressions, merging, area, weight),
//

#import <Foundation/Foundation.h>

#import "CPTFieldFunctionDataSource.h"

NS_ASSUME_NONNULL_BEGIN

typedef struct {
    double * _Nullable array;
    size_t used;
    size_t size;
} ContourPlanes;

void initContourPlanes(ContourPlanes *a, size_t initialSize);
void appendContourPlanes(ContourPlanes *a, double element);
void clearContourPlanes(ContourPlanes *a);
void freeContourPlanes(ContourPlanes *a);

typedef struct {
    NSUInteger * _Nullable array;
    size_t used;
    size_t size;
} Discontinuities;

void initDiscontinuities(Discontinuities *a, size_t initialSize);
void appendDiscontinuities(Discontinuities *a, NSUInteger element);
BOOL containsDiscontinuities(Discontinuities *a,  NSUInteger element);
void clearDiscontinuities(Discontinuities *a);
void freeDiscontinuities(Discontinuities *a);


@interface CPTContour : NSObject

// let user now that there are discontinuities in the region analysed
@property (nonatomic, readwrite) BOOL containsFunctionNans;
@property (nonatomic, readwrite) BOOL containsFunctionInfinities;
@property (nonatomic, readwrite) BOOL containsFunctionNegativeInfinities;

-(nonnull instancetype)initWithNoIsoCurve:(NSUInteger)newNoIsoCurves IsoCurveValues:(double*)newContourPlanes Limits:(double*)newLimits;
    
// Initialize memory. Called in Generate
-(void) initialiseMemory;
// Clean work arrays
-(void) cleanMemory;

// generate the contours
-(BOOL) generate;

// Set the dimension of the primary grid
-(void) setFirstGridDimensionColumns:(NSUInteger)iCol Rows:(NSUInteger)iRow;
// Set the dimension of the base grid
-(void) setSecondaryGridDimensionColumns:(NSUInteger)iCol Rows:(NSUInteger)iRow;
// Sets the region [left, right, bottom,top] to generate contour
-(void) setLimits:(double*)limits;
// Sets the isocurve values
-(void) setIsoCurves:(ContourPlanes*)contourPlanes;
// Also Sets the isocurve values
-(void) setIsoCurveValues:(double*)newContourPlanes noIsoCurves:(size_t)newNoIsoCurves;
// Sets the pointer to the F(x,y) function
//-(void) setFieldFunction:(CPTContourDataSourceFunction)function;
// Sets the block to the F(x,y) function
-(void) setFieldBlock:(CPTContourDataSourceBlock)block;
// sets the number of isocurves to look at
-(void) setNoIsoCurves:(NSUInteger)noPlanes;

// Gets the value for F(x,y) function
-(double) getFieldValueForX:(double)x Y:(double)y;

// Retrieve dimension of size region and isocurve
-(NSUInteger) getNoIsoCurves;
-(ContourPlanes* _Nullable) getContourPlanes;
-(Discontinuities* _Nullable) getDiscontinuities;
//-(Discontinuities* _Nullable * _Nullable) getDiscontinuityClusters;
-(double* _Nullable)getIsoCurves;
-(double)getIsoCurveAt:(NSUInteger)i;

-(NSUInteger) getNoColumnsFirstGrid;
-(NSUInteger) getNoRowsFirstGrid;
-(NSUInteger) getNoColumnsSecondaryGrid;
-(NSUInteger) getNoRowsSecondaryGrid;
-(double* _Nonnull) getLimits;
-(double) getDX;
-(double) getDY;
-(void) setDX:(double)newDeltaX;
-(void) setDY:(double)newDeltaY;

-(double) getXAt:(NSUInteger)i; // For an indexed point i on the sec. grid, returns x(i)
-(double) getYAt:(NSUInteger)i; // For an indexed point i on the fir. grid, returns y(i)
-(NSUInteger)getIndexAtX:(double)x Y:(double)y;
-(void) exportLineForIsoCurve:(NSUInteger)iPlane FromX1:(NSUInteger)x1 FromY1:(NSUInteger)y1 ToX2:(NSUInteger)x2 ToY2:(NSUInteger)y2; // plots a line from (x1,y1) to (x2,y2)

@end

NS_ASSUME_NONNULL_END
