//
//  CPTListContour.h
//  CorePlot
//
//  Created by Steve Wainwright on 22/11/2021.
//
// _CPTListContour.m: implementation of the CPTListContour class.
//
// _CPTListContour.h: interface for the CPTListContour class.
//
// CPTListContour implements Contour plot algorithm described in
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
#import "_CPTContour.h"

NS_ASSUME_NONNULL_BEGIN

typedef struct {
    NSUInteger * _Nullable array;
    size_t used;
    size_t size;
} LineStrip;

typedef struct {
    LineStrip * _Nullable array;
    size_t used;
    size_t size;
} LineStripList;

typedef struct {
    LineStripList * _Nullable array;
    size_t used;
    size_t size;
} IsoCurvesList;

void initLineStrip(LineStrip *a, size_t initialSize);
void appendLineStrip(LineStrip *a, NSUInteger element);
void insertLineStripAtIndex(LineStrip *a, NSUInteger element, size_t index);
void removeLineStripAtIndex(LineStrip *a, size_t index);
void assignLineStripInRange(LineStrip *a, LineStrip *b, size_t start, size_t end);
NSUInteger searchForLineStripIndexForElement(LineStrip *a, NSUInteger element, NSUInteger startPos);
NSUInteger searchForLineStripIndexForElementWithTolerance(LineStrip *a, NSUInteger element, NSUInteger tolerance, NSUInteger columnMutliplier);
void reverseLineStrip(LineStrip *a);
NSInteger checkLineStripToAnotherForSameDifferentOrder(LineStrip *a, LineStrip *b);
void clearLineStrip(LineStrip *a);
void freeLineStrip(LineStrip *a);

void initLineStripList(LineStripList *a, size_t initialSize);
void appendLineStripList(LineStripList *a, LineStrip element);
void insertLineStripListAtIndex(LineStripList *a, LineStrip element, size_t index);
void removeLineStripListAtIndex(LineStripList *a, size_t index);
NSUInteger findLineStripListIndexForLineStrip(LineStripList *a, LineStrip *b);
void sortLineStripList(LineStripList *a);
void clearLineStripList(LineStripList *a);
void freeLineStripList(LineStripList *a);
int compareLineStripListByPosition(const void *a, const void *b);

void initIsoCurvesList(IsoCurvesList *a, size_t initialSize);
void appendIsoCurvesList(IsoCurvesList *a, LineStripList element);
void clearIsoCurvesList(IsoCurvesList *a);
void freeIsoCurvesList(IsoCurvesList *a);


@interface CPTListContour : CPTContour

@property (nonatomic, readwrite, assign) BOOL overrideWeldDistance;

-(nonnull instancetype)initWithNoIsoCurve:(NSUInteger)newNoIsoCurves IsoCurveValues:(double*)newContourPlanes Limits:(double*)newLimits;;

-(IsoCurvesList* _Nullable) getIsoCurvesLists;
-(ContourPlanes* _Nullable) getContourPlanes;
-(LineStripList* _Nullable) getStripListForIsoCurve:(NSUInteger)iPlane;

-(void) setStripListAtPlane:(NSUInteger)iPlane StripList:(LineStripList*)pLineStripList;

-(void) exportLineForIsoCurve:(NSUInteger)iPlane FromX1:(NSUInteger)x1 FromY1:(NSUInteger)y1 ToX2:(NSUInteger)x2 ToY2:(NSUInteger)y2;

// Basic algorithm to concatanate line strip. Not optimized at all !
-(void)generateAndCompactStrips;
/// debugging
-(void) dumpPlane:(NSUInteger)iPlane;

// Area given by this function can be positive or negative depending on the winding direction of the contour.
-(double) area:(LineStrip*)line;

-(double) edgeWeight:(LineStrip*)line R:(double)R;
-(BOOL) printEdgeWeightContour:(NSString*)fname;
// returns true if node is touching boundary
-(BOOL) isNodeOnBoundary:(NSUInteger)index;

@end

NS_ASSUME_NONNULL_END
