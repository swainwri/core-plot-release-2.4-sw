//
//  CPTContours.h
//  CorePlot
//
//  Created by Steve Wainwright on 25/11/2021.
//
// _CPTContours.m: implementation of the CPTContours class.
//
// _CPTContours.h: interface for the CContour class.
//
// CPTContours implements Contour plot algorithm described in
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
//  additional routines by S.Wainwright in order to facilitate generating extra contour lines for a function based plot.
//  The contour algorithm will generate border to border lines from one border point to another, yet with a function based plot
//  there will be specific regions which have a coincidental border with other regions, we will have to generate these contour lines
//  since they aren't detected by the CPTContours algorithm. We therefore need to find intersections of contours, and will have to use
//  a tolerance.


#import "_CPTListContour.h"

NS_ASSUME_NONNULL_BEGIN

typedef struct {
    NSUInteger index;
    NSUInteger jndex;
} Indices;

typedef struct {
    Indices * _Nullable array;
    size_t used;
    size_t size;
} IndicesList;

@interface CPTContours : CPTListContour

-(nonnull instancetype)initWithNoIsoCurve:(NSUInteger)newNoPlanes IsoCurveValues:(double * _Nonnull)newContourPlanes Limits:(double *  _Nonnull)newLimits;

/**
 *  return the contour planes(isocurve) values
 */
-(ContourPlanes* _Nullable) getContourPlanes;

/**
 *  returns the IsoCurves lists, the actual contour data for each plane(iso curve value)
 */
-(IsoCurvesList* _Nullable) getIsoCurvesLists;

/**
 *  returns the extra IsoCurves lists, the actual contour data for each plane(iso curve value).
 *   The contour algorithm needs enhancing for filling in borders as on occasion a filled region can
 *   share part of a contour line with another region, so have to account for this by breaking down
 *   these contours and creating extra ones.
 */
-(IsoCurvesList* _Nullable) getExtraIsoCurvesLists;

/**
 *  returns the Extra LineStripList for shared contour lines at iso curve index
 *  The contour algorithm needs enhancing for filling in borders as on occasion a filled region can
 *   share part of a contour line with another region, so have to account for this by breaking down
 *   these contours and creating extra ones.
 *
 */
-(LineStripList* _Nullable) getExtraIsoCurvesListsAtIsoCurve:(NSUInteger)plane;

/**
 *  returns Intersection Indices list
 */
-(IndicesList* _Nullable) getIntersectionIndicesList;

/**
 *  The reads all planes and contours from the disk
 */
-(BOOL) readPlanesFromDisk:(nonnull NSString*)filePath;

/**
 *  The writes all planes and contours to the disk
 */
-(BOOL) writePlanesToDisk:(nonnull NSString*)filePath;

/**
*   Find any indices if there is an intersection of 2 CLineStrips
 */
-(void) intersectionsWithAnotherList:(nonnull LineStrip*)pStrip0 Other:(nonnull LineStrip*)pStrip1 Tolerance:(NSUInteger)tolerance;
-(void) intersectionsWithAnotherListOrLimits:(nonnull LineStrip*)pStrip0 Other:(nonnull LineStrip*)pStrip1 Tolerance:(NSUInteger)tolerance;

/**
 * Add indices in new CLineStrip to CLineStripList
 *  return the CLineStrip address
 */
-(BOOL) addIndicesInNewLineStripToLineStripList:(LineStripList*)pStripList Indices:(NSUInteger*)indices NoIndices:(NSUInteger)noIndices;

/**
 * Add 2 strips together upto and from index in new CLineStrip to CLineStripList
 * if index & jndex don't coincide since meet tolerance of 2 strips interesting
 * use index for end of part 1 and jndex as start for part 2
 *  return the CLineStrip address
 */
-(BOOL) add2StripsToIntersectionPtToLineStripList:(nonnull LineStripList*)pStripList Strip0:(nonnull LineStrip*)pStrip0 Strip1:(nonnull LineStrip*)pStrip1 Index:(NSUInteger)index Jndex:(NSUInteger)jndex;

/**
 *  Create N point shape with contour intersections
 *  return the CLineStrip address
 */
-(BOOL) createNPointShapeFromIntersectionPtToLineStripList:(nonnull LineStripList*)pStripList striplist1:(nonnull LineStripList*)pStrips striplist2:(nonnull LineStripList*)pStrips1 indices:(nonnull NSUInteger*)indexs jndices:(nonnull NSUInteger*)jndexs NPoints:(NSUInteger)N isoCurve:(NSUInteger)plane;

/**
 * add CLineStrip to CLineStripList
 */
-(BOOL) addLineStripToLineStripList:(nonnull LineStripList*)pStripList lineStrip:(nonnull LineStrip*)pStrip isoCurve:(NSUInteger)plane;

/**
 * remove CLineStrip from CLineStripList
 */
-(BOOL) removeLineStripFromLineStripList:(nonnull LineStripList*)pStripList Strip:(nonnull LineStrip*)pStrip;

/**
 * check that a direct link exost between 2 indices in a CLineStrip that are not interrrupted bt any of the indices in list
 */
-(BOOL)checkForDirectConnectBetween2IndicesInAStrip:(nonnull LineStrip*)pStrip Index:(NSUInteger)index Jndex:(NSUInteger)jndex IndicesList:(nonnull LineStrip*)pIndicesList;
-(BOOL)checkForDirectConnectWithoutOtherIndicesBetween2IndicesInAStrip:(nonnull LineStrip*)pStrip Index:(NSUInteger)index Jndex:(NSUInteger)jndex IndicesList:(nonnull LineStrip*)pIndicesList JndicesList:(nonnull LineStrip*)pJndicesList;

/**
 * check for big gaps in the LineStrip as may need alternative method to fill in gaps
 */
-(BOOL)checkStripHasNoBigGaps:(nonnull LineStrip*)pStrip;

/**
 * remove excess boundary nodes from in the extra LineStrip, returns YES if any removed
 */
-(BOOL)removeExcessBoundaryNodeFromExtraLineStrip:(nonnull LineStrip*)pStrip;

/**
 * remove excess boundary nodes from in the extra LineStrip
 */
-(void)searchExtraLineStripOfTwoBoundaryPoints:(nonnull LineStrip*)pStrip boundaryPositions:(NSUInteger* _Nonnull * _Nonnull)boundaryPositions;

@end

NS_ASSUME_NONNULL_END
