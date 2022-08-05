//
//  _CPTContourMemoryManagement.h
//  CorePlot
//
//  Created by Steve Wainwright on 13/05/2022.
//

#import "_CPTContourEnumerations.h"
#import "_CPTContours.h"

CGFloat dist(CGPoint p1, CGPoint p2);
void swapPoints(CGPoint* _Nonnull a, CGPoint* _Nonnull b);
int comparePoints(const void * _Nonnull a, const void * _Nonnull b);
void closestKPoints(CGPoint* _Nonnull points, NSUInteger n, CGPoint point);

void insertCGPointsAtIndex(CGPoint * _Nonnull a, CGPoint element, size_t index, size_t * _Nonnull a_used, size_t * _Nonnull a_size) ;
size_t removeCGPointsFromCGPoints(CGPoint * _Nonnull a, size_t a_size, CGPoint * _Nonnull b, size_t b_size);
size_t removeCGPointAtIndex(CGPoint * _Nonnull a, size_t a_size, size_t index);
BOOL containsCGPoint(CGPoint * _Nonnull a, size_t a_size, CGPoint point);

/** @brief A structure used internally by CPTContourPlot to plot boundary points.
 **/

typedef struct {
    CGPoint point;
    NSUInteger position;
    CPTContourBorderDimensionDirection direction;
    int used;
} CGPathBoundaryPoint;

typedef struct {
    CGPathBoundaryPoint * _Nullable array;
    size_t used;
    size_t size;
} CGPathBoundaryPoints;

void initCGPathBoundaryPoints(CGPathBoundaryPoints * _Nonnull a, size_t initialSize);
void appendCGPathBoundaryPoints(CGPathBoundaryPoints * _Nonnull a, CGPathBoundaryPoint element);
void insertCGPathBoundaryPointsAtIndex(CGPathBoundaryPoints * _Nonnull a, CGPathBoundaryPoint element, size_t index);
void removeCGPathBoundaryPointsAtIndex(CGPathBoundaryPoints * _Nonnull a, size_t index);
NSUInteger filterCGPathBoundaryPoints(CGPathBoundaryPoints * _Nonnull a, BOOL (* _Nonnull predicate)(const CGPathBoundaryPoint item, CPTContourBorderDimensionDirection direction, CGFloat edge), CGPathBoundaryPoints * _Nonnull b, CPTContourBorderDimensionDirection direction, CGFloat edge);
NSUInteger filterCGPathBoundaryPointsForACorner(CGPathBoundaryPoints * _Nonnull a, BOOL (* _Nonnull predicate)(const CGPathBoundaryPoint item, CGPoint corner), CGPathBoundaryPoints * _Nonnull b, CGPoint corner);
BOOL checkCGPathBoundaryPointsAreUniqueForEdge(CGPathBoundaryPoints * _Nonnull a, CPTContourBorderDimensionDirection direction);
void sortCGPathBoundaryPointsByPosition(CGPathBoundaryPoints * _Nonnull a);
void sortCGPathBoundaryPointsByBottomEdge(CGPathBoundaryPoints * _Nonnull a);
void sortCGPathBoundaryPointsByRightEdge(CGPathBoundaryPoints * _Nonnull a);
void sortCGPathBoundaryPointsByTopEdge(CGPathBoundaryPoints * _Nonnull a);
void sortCGPathBoundaryPointsByLeftEdge(CGPathBoundaryPoints * _Nonnull a);
int removeDuplicatesCGPathBoundaryPoints(CGPathBoundaryPoints * _Nonnull a);
void clearCGPathBoundaryPoints(CGPathBoundaryPoints * _Nonnull a);
void freeCGPathBoundaryPoints(CGPathBoundaryPoints * _Nonnull a);
/* PREDICATES**********/
/* predicate: callback */
BOOL callbackPlotEdge(const CGPathBoundaryPoint item, CPTContourBorderDimensionDirection direction, CGFloat edge);
BOOL callbackPlotCorner(const CGPathBoundaryPoint item, CGPoint corner);

/** @brief A structure used internally by CPTContourPlot to plot isoCurves.
 **/

typedef struct {
    CGPoint * _Nonnull array;
    size_t used;
    size_t size;
} ContourPoints;

void initContourPoints(ContourPoints * _Nonnull a, size_t initialSize);
void appendContourPoints(ContourPoints * _Nonnull a, CGPoint element);
void reverseContourPoints(ContourPoints * _Nonnull a);
void clearContourPoints(ContourPoints * _Nonnull a);
void freeContourPoints(ContourPoints * _Nonnull a);


/** @brief A structure used internally by CPTContourPlot to sorting border strips ordering.
 **/

typedef struct {
    CGPoint point;
    CGFloat angle;
    NSUInteger index;
    NSUInteger extra;
    CPTContourBorderDimensionDirection borderdirection;
    BOOL end;
    BOOL used;
    short dummy;
} BorderIndex;

BorderIndex initBorderIndex(void);

typedef struct {
    BorderIndex * _Nullable array;
    size_t used;
    size_t size;
} BorderIndices;

void initBorderIndices(BorderIndices * _Nonnull a, size_t initialSize);
void appendBorderIndices(BorderIndices * _Nonnull a, BorderIndex element);
void insertBorderIndicesAtIndex(BorderIndices * _Nonnull a, BorderIndex element, size_t index);
void removeBorderIndicesAtIndex(BorderIndices * _Nonnull a, size_t index);
NSUInteger removeNextToDuplicatesBorderIndices(BorderIndices * _Nonnull a);
void authenticateNextToDuplicatesBorderIndices(BorderIndices * _Nonnull a);
void copyBorderIndices(BorderIndices * _Nonnull a, BorderIndices * _Nonnull b);
void sortBorderIndicesWithExtraContours(BorderIndices * _Nonnull a);
void sortBorderIndicesByBorderDirection(BorderIndices * _Nonnull a, CPTContourBorderDimensionDirection borderDirection);
void sortBorderIndicesByAngle(BorderIndices * _Nonnull a);
NSUInteger searchBorderIndicesForBorderStripIndex(BorderIndices * _Nonnull a, NSUInteger index, NSUInteger * _Nonnull * _Nonnull positions);
NSUInteger searchBorderIndicesForNextBorderStripIndex(BorderIndices * _Nonnull a, NSUInteger index);
NSUInteger searchBorderIndicesForPreviousBorderStripIndex(BorderIndices * _Nonnull a, NSUInteger index);
NSUInteger searchBorderIndicesForCGPoint(BorderIndices * _Nonnull a, CGPoint point);
void reverseBorderIndices(BorderIndices * _Nonnull a, BorderIndices * _Nonnull b);
void clearBorderIndices(BorderIndices * _Nonnull a);
void freeBorderIndices(BorderIndices * _Nonnull a);
int compareBorderIndicesXForward(const void * _Nonnull a, const void * _Nonnull b);
int compareBorderIndicesYForward(const void * _Nonnull a, const void * _Nonnull b);
int compareBorderIndicesXBackward(const void * _Nonnull a, const void * _Nonnull b);
int compareBorderIndicesYBackward(const void * _Nonnull a, const void * _Nonnull b);
int compareBorderIndicesAngle(const void * _Nonnull a, const void * _Nonnull b);

/** @brief A structure used internally by CPTContourPlot to search for isoCurves intersecting the border.
 **/

typedef struct {
    CGPoint startPoint;
    CGPoint endPoint;
    NSUInteger index;
    NSUInteger plane;
    LineStripList * _Nullable pStripList;
    CPTContourBorderDimensionDirection startBorderdirection;
    CPTContourBorderDimensionDirection endBorderdirection;
    int reverse;
    int extra;
    int usedInExtra;
    int dummy;
} Strip;

Strip initStrip(void);

typedef struct {
    Strip * _Nullable array;
    size_t used;
    size_t size;
} Strips;

void initStrips(Strips * _Nonnull a, size_t initialSize);
void appendStrips(Strips * _Nonnull a, Strip element);
NSUInteger searchForStripForPlanes(Strips * _Nonnull a, NSUInteger plane1, NSUInteger plane2, NSUInteger exceptPosition);
NSUInteger searchForStripIndicesForPlane(Strips * _Nonnull a, NSUInteger plane, NSUInteger* _Nonnull *_Nonnull indices);
NSUInteger searchForStripIndicesForPlanes(Strips * _Nonnull a, NSUInteger plane1, NSUInteger plane2, NSUInteger* _Nonnull * _Nonnull indices);
NSUInteger numberBorderIsoCurvesForStripForPlane(Strips * _Nonnull a, NSUInteger plane);
//void searchForStripForLowestAndHighestPlane(Strips * _Nonnull a, NSUInteger *lowestPlane,  NSUInteger *highestPlane);
NSUInteger searchForPlanesWithinStrips(Strips * _Nonnull a, NSUInteger * _Nonnull * _Nonnull planes);
void sortStripsByBorderDirection(Strips * _Nonnull a, CPTContourBorderDimensionDirection startBorderdirection);
void sortStripsByPlane(Strips * _Nonnull a);
void sortStripsIntoStartEndPointPositions(Strips * _Nonnull a, BorderIndices * _Nonnull indices);
BOOL concatenateStrips(Strips * _Nonnull a, Strips b[_Nonnull], int n);
void removeStripsAtIndex(Strips * _Nonnull a, size_t index);
int removeDuplicatesStrips(Strips * _Nonnull a);
int removeDuplicatesStripsWithStartEndPointsPlaneSame(Strips * _Nonnull a);
void clearStrips(Strips * _Nonnull a);
void freeStrips(Strips * _Nonnull a);
int compareBorderStripsPlanes(const void * _Nonnull a, const void * _Nonnull b);
int compareBorderStripsXForward(const void * _Nonnull a, const void * _Nonnull b);
int compareBorderStripsYForward(const void * _Nonnull a, const void * _Nonnull b);
int compareBorderStripsXBackward(const void * _Nonnull a, const void * _Nonnull b);
int compareBorderStripsYBackward(const void * _Nonnull a, const void * _Nonnull b);


/** @brief A structure used internally by CPTContourPlot to search for intersections within the contours .
 **/

typedef struct {
    LineStrip * _Null_unspecified pStrip0;
    LineStrip * _Null_unspecified pStrip1;
    NSUInteger index;
    NSUInteger jndex;
    NSUInteger intersectionIndex;
    bool useStrips;
    bool isCorner;
    short usedCount;
    int dummy;
    CGPoint point;
} Intersection;

typedef struct {
    Intersection * _Nullable array;
    size_t used;
    size_t size;
} Intersections;

void initIntersections(Intersections * _Nonnull a, size_t initialSize);
void appendIntersections(Intersections * _Nonnull a, Intersection element);
void copyIntersections(Intersections * _Nonnull a, Intersections * _Nonnull b);
void sortIntersectionsByPointXCoordinate(Intersections * _Nonnull a);
void sortIntersectionsByPointIncreasingXCoordinate(Intersections * _Nonnull a);
void sortIntersectionsByPointDecreasingXCoordinate(Intersections * _Nonnull a);
void sortIntersectionsByPointIncreasingYCoordinate(Intersections * _Nonnull a);
void sortIntersectionsByPointDecreasingYCoordinate(Intersections * _Nonnull a);
void sortIntersectionsByOrderAntiClockwiseFromBottomLeftCorner(Intersections * _Nonnull a, CGPoint * _Nonnull  corners, CGFloat tolerance);
NSUInteger containsIntersection(Intersections * _Nonnull a, Intersection intersection);
NSUInteger searchForIndexIntersection(Intersections * _Nonnull a, NSUInteger IndexIntersection);
NSUInteger searchForContoursIndexIntersection(Intersections * _Nonnull a, NSUInteger contourIndex);
NSUInteger searchForPointIntersection(Intersections * _Nonnull a, CGPoint point, CGFloat tolerance);
NSUInteger searchForIndexFromPointIntersection(Intersection * _Nonnull a, NSUInteger no, CGPoint point, CGFloat tolerance);
void removeIntersectionsAtIndex(Intersections * _Nonnull a, size_t index);
NSUInteger removeDuplicatesIntersections(Intersections * _Nonnull a, CGFloat tolerance);
NSUInteger removeSimilarIntersections(Intersections * _Nonnull a, Intersections * _Nonnull b);
void closestKIntersections(Intersections* _Nonnull a, Intersection intersect);
void clearIntersections(Intersections * _Nonnull a);
void freeIntersections(Intersections * _Nonnull a);
int compareIntersectionsByPointIncreasingXCoordinate(const void * _Nonnull a, const void * _Nonnull b);
int compareIntersectionsByPointDecreasingXCoordinate(const void * _Nonnull a, const void * _Nonnull b);
int compareIntersectionsByPointIncreasingYCoordinate(const void * _Nonnull a, const void * _Nonnull b);
int compareIntersectionsByPointDecreasingYCoordinate(const void * _Nonnull a, const void * _Nonnull b);
int compareIntersection(const void * _Nonnull a, const void * _Nonnull b);
int compareKIntersection(const void * _Nonnull a, const void * _Nonnull b);

typedef struct {
    NSUInteger index;
    CGFloat distance;
    CGFloat angle;
} Index_DistanceAngle;

typedef struct {
    NSUInteger noVertices;
    CGPoint centre;
    CGRect boundingBox;
} Centroid;

typedef struct {
    Centroid * _Nullable array;
    size_t used;
    size_t size;
} Centroids;

void initCentroids(Centroids * _Nonnull a, size_t initialSize);
void appendCentroids(Centroids * _Nonnull a, Centroid element);
void removeCentroidsElement(Centroids * _Nonnull a, Centroid element);
void clearCentroids(Centroids * _Nonnull a);
void freeCentroids(Centroids * _Nonnull a);
int compareCentroids(const void * _Nonnull a, const void * _Nonnull b);
int compareCentroidsByXCoordinate(const void * _Nonnull a, const void * _Nonnull b);


typedef struct {
    int index0;
    int index1;
    CGFloat gradient;
    CGFloat constant;
} Line;

typedef struct {
    Line * _Nullable array;
    size_t used;
    size_t size;
} Lines;

void initLines(Lines * _Nonnull a, size_t initialSize);
void appendLines(Lines * _Nonnull a, Line element);
int containsLines(Lines * _Nonnull a, Line line);
void clearLines(Lines * _Nonnull a);
void freeLines(Lines * _Nonnull a);


// A global point needed for  sorting points with reference
// to the first point. Used in compare function of qsort()
static CGPoint pointSimpleClosedPath;
int compareCGPoint(const void * _Nonnull a, const void * _Nonnull b);
int compareCGPointsForSimpleClosedPath(const void * _Nonnull a, const void * _Nonnull b);
int orientation(CGPoint p, CGPoint q, CGPoint r);
BOOL CGPointEqualToPointWithTolerance(CGPoint point1, CGPoint point2, CGFloat tolerance);

int findSmallestAbsoluteValueIndex(double * _Nonnull arr, int n);


void pointsCGPathApplierFunc(void * _Nonnull info, const CGPathElement * _Nonnull element);
void multipleMoveTosCGPathApplierFunc(void * _Nonnull info, const CGPathElement * _Nonnull element);
void pathApplierSumCoordinatesOfAllPoints(void * _Nonnull info, const CGPathElement * _Nonnull element);

