//
//  _CPTHull.m
//  CorePlot
//
//  Created by Steve Wainwright on 13/05/2022.
//


#import "_CPTHull.h"

int compareCGPointsByDescXThenY(const void *a, const void *b);
void sortCGPointsByDescXThenY(CGPoint *a, size_t size);

int compareIntersectionsByDescXThenY(const void *a, const void *b);
void sortIntersectionsByDescXThenY(Intersections *a);

int compareHullPointsByIndex(const void *a, const void *b);

void initHullPoints(HullPoints *a, size_t initialSize);
void appendHullPoints(HullPoints *a, HullPoint element);
void insertHullPointsAtIndex(HullPoints *a, HullPoint element, size_t index);
void removeHullPoints(HullPoints *a, HullPoint element);
void removeHullPointsAtIndex(HullPoints *a, size_t index);
void reverseHullPoints(HullPoints *a, HullPoints *b);
NSUInteger searchForIndexHullPoints(HullPoints *a, HullPoint element);
void sortHullPointsByAscXThenY(HullPoints *a);
void sortHullPointsByDescXThenY(HullPoints *a);
void sortHullPointsByIndex(HullPoints *a);
NSUInteger searchForIndexHullPoints(HullPoints *a, HullPoint element);
BOOL containsHullPoints(HullPoints *a, HullPoint hullpoint);
NSUInteger filterHullPoints(HullPoints *a, HullPoints *b, HullPoints *c);
int removeDuplicatesHullPoints(HullPoints *a);
void clearHullPoints(HullPoints *a);
void freeHullPoints(HullPoints *a);

int compareHullPointsByAscXThenY(const void *a, const void *b);
int compareHullPointsByDescXThenY(const void *a, const void *b);

void initHullCells(HullCells *a, size_t initialSize);
void appendHullCells(HullCells *a, HullCell element);
NSUInteger searchForIndexHullCells(HullCells *a, NSInteger rowIndex, NSInteger colIndex);
void freeHullCells(HullCells *a);

@interface Grid : NSObject

@property (nonatomic) double cellSize;

- (instancetype)initWithPoints:(HullPoints*)points cellSize:(CGFloat)newCellSize;
-(void) rangePoints:(CGFloat*)bbox points:(HullPoints*)points;

@end

@implementation Grid

@synthesize cellSize;

static HullCells cells;

- (instancetype)initWithPoints:(HullPoints*)points cellSize:(CGFloat)newCellSize {
    if ( (self = [super init]) ) {
        self.cellSize = newCellSize;
        initHullCells(&cells, 4);
        NSUInteger index;
        for( NSUInteger i = 0; i < (NSUInteger)points->used; i++ ) {
            NSInteger cellXY[2];
            [self point2CellXY:&points->array[i] cellRef:cellXY];
            if ( (index = searchForIndexHullCells(&cells, cellXY[0], cellXY[1])) == NSNotFound ) {
                HullCell element;
                HullPoints pts;
                initHullPoints(&pts, 4);
                element.index = cellXY[0];
                element.jndex = cellXY[1];
                element.hullpoints = pts;
                appendHullCells(&cells, element);
                index = cells.used - 1;
            }
            appendHullPoints(&cells.array[index].hullpoints, points->array[i]);
        }
    }
    return self;
}

- (void)dealloc {
    for (NSUInteger i = 0; i < cells.used; i++ ) {
        freeHullPoints(&cells.array[i].hullpoints);
    }
    freeHullCells(&cells);
}

-(void)point2CellXY:(HullPoint*)point cellRef:(NSInteger*)cellRef {
    cellRef[0] = (NSInteger)(point->point.x / self.cellSize);
    cellRef[1] = (NSInteger)(point->point.y / self.cellSize);
}

-(void)extendBbox:(double*)bbox scaleFactor:(double)_scaleFactor eBox:(double*)ebox {
    ebox[0] = bbox[0] - (_scaleFactor * self.cellSize);
    ebox[1] = bbox[1] - (_scaleFactor * self.cellSize);
    ebox[2] = bbox[2] + (_scaleFactor * self.cellSize);
    ebox[3] = bbox[3] + (_scaleFactor * self.cellSize);
}

-(void)removePoint:(HullPoint*)point {
    NSInteger cellXY[2];
    [self point2CellXY:point cellRef:cellXY];
    NSUInteger index;
    if ( (index = searchForIndexHullCells(&cells, cellXY[0], cellXY[1])) != NSNotFound ) {
        HullPoints *cell = &cells.array[index].hullpoints;
        NSUInteger pointIdxInCell = 0;
        for(NSUInteger idx = 0; idx < cell->used; idx++ ) {
            if ( cell->array[idx].point.x == point->point.x && cell->array[idx].point.y == point->point.y ) {
                pointIdxInCell = idx;
                break;
            }
        }
        removeHullPointsAtIndex(cell, pointIdxInCell);
    }
}

-(void) rangePoints:(CGFloat*)bbox points:(HullPoints*)points {
    NSInteger tlCellXY[2], brCellXY[2];
    HullPoint topLeft, btmRight;
    topLeft.point = CGPointMake(bbox[0], bbox[1]);
    btmRight.point = CGPointMake(bbox[2], bbox[3]);
    [self point2CellXY:&topLeft cellRef:tlCellXY];
    [self point2CellXY:&btmRight cellRef:brCellXY];
        
    if ( points->size == 0 ) {
        initHullPoints(points, 4);
    }
    for ( NSInteger i = tlCellXY[0]; i < brCellXY[0] + 1; i++ ) {
        for ( NSInteger j = tlCellXY[1]; j < brCellXY[1] + 1; j++ ) {
            HullPoints *newPoints;
            if ( (newPoints = [self cellPoints:i yOrd:j]) != nil ) {
                for ( NSUInteger k = 0; k < newPoints->used; k++ ) {
                    appendHullPoints(points, newPoints->array[k]);
                }
            }
        }
    }
}

-(HullPoints*) cellPoints:(NSInteger)xAbs yOrd:(NSInteger)yOrd {
    NSUInteger index = NSNotFound;
    if ( (index = searchForIndexHullCells(&cells, xAbs, yOrd)) != NSNotFound ) {
        return &cells.array[index].hullpoints;
    }
    return nil;
}

@end

@interface Convex : NSObject

- (instancetype)initWithPoints:(HullPoints*)points;
-(HullPoints*)hullPoints;

@end

@implementation Convex

static HullPoints hullpoints;

-(nonnull instancetype)init {
    if ( (self = [super init]) ) {
        initHullPoints(&hullpoints, 8);
    }
    return self;
}

- (instancetype)initWithPoints:(HullPoints*)points {
    if ( (self = [super init]) ) {
        initHullPoints(&hullpoints, 8);
        HullPoints upper, lower;
        initHullPoints(&upper, 8);
        initHullPoints(&lower, 8);
        [self upperTangent:points upperPoints:&upper];
        [self lowerTangent:points lowerPoints:&lower];
        for( NSUInteger i = 0; i < (NSUInteger)lower.used; i++ ) {
            appendHullPoints(&hullpoints, lower.array[i]);
        }
        for( NSUInteger i = 0; i < (NSUInteger)upper.used; i++ ) {
            appendHullPoints(&hullpoints, upper.array[i]);
        }
        appendHullPoints(&hullpoints, hullpoints.array[0]);
        freeHullPoints(&upper);
        freeHullPoints(&lower);
    }
    return self;
}

- (void)dealloc {
    freeHullPoints(&hullpoints);
}

-(HullPoints*)hullPoints {
    return &hullpoints;
}

-(double)cross:(HullPoint)ooo aaa:(HullPoint)aaa bbb:(HullPoint)bbb {
    return (aaa.point.x - ooo.point.x) * (bbb.point.y - ooo.point.y) - (aaa.point.y - ooo.point.y) * (bbb.point.x - ooo.point.x);
}

-(void)upperTangent:(HullPoints*)points upperPoints:(HullPoints*)lower {
    HullPoint point;
    for( NSUInteger i = 0; i < points->used; i++ ) {
        point = points->array[i];
        while( lower->used >= 2 && [self cross:lower->array[lower->used - 2] aaa:lower->array[lower->used - 1] bbb:point] <= 0 ) {
            removeHullPointsAtIndex(lower, lower->used - 1);
        }
        appendHullPoints(lower, point);
    }
    removeHullPointsAtIndex(lower, lower->used - 1);
}

-(void)lowerTangent:(HullPoints*)points lowerPoints:(HullPoints*)upper {
    HullPoints reversed;
    initHullPoints(&reversed, points->used);
    reverseHullPoints(points, &reversed);
    HullPoint point;
    for( NSUInteger i = 0; i < reversed.used; i++ ) {
        point = reversed.array[i];
        while( upper->used >= 2 && [self cross:upper->array[upper->used - 2] aaa:upper->array[upper->used - 1] bbb:point] <= 0 ) {
            removeHullPointsAtIndex(upper, upper->used - 1);
        }
        appendHullPoints(upper, point);
    }
    removeHullPointsAtIndex(upper, upper->used - 1);
}

@end

int compareIntersectionsByDescXThenY(const void *a, const void *b) {
    const Intersection *aO = (const Intersection*)a;
    const Intersection *bO = (const Intersection*)b;
    
    if ( aO->point.x < bO->point.x ) {
        return 1;
    }
    else if ( aO->point.x > bO->point.x ) {
        return -1;
    }
    else {
        if ( aO->point.y < bO->point.y ) {
            return 1;
        }
        else if ( aO->point.y > bO->point.y ) {
            return -1;
        }
        else {
            return 0;
        }
    }
}

void sortIntersectionsByDescXThenY(Intersections *a) {
    qsort((void*)a->array, a->used, sizeof(Intersection), compareIntersectionsByDescXThenY);
}

int compareCGPointsByDescXThenY(const void *a, const void *b) {
    const CGPoint *aO = (const CGPoint*)a;
    const CGPoint *bO = (const CGPoint*)b;
    
    if ( aO->x < bO->x ) {
        return -1;
    }
    else if ( aO->x > bO->x ) {
        return 1;
    }
    else {
        if ( aO->y < bO->y ) {
            return -1;
        }
        else if ( aO->y > bO->y ) {
            return 1;
        }
        else {
            return 0;
        }
    }
}

void sortCGPointsByDescXThenY(CGPoint *a, size_t size) {
    qsort((void*)a, size, sizeof(CGPoint), compareCGPointsByDescXThenY);
}

int compareHullPointsByAscXThenY(const void *a, const void *b) {
    const HullPoint *aO = (const HullPoint*)a;
    const HullPoint *bO = (const HullPoint*)b;
    
    if ( aO->point.x < bO->point.x ) {
        return 1;
    }
    else if ( aO->point.x > bO->point.x ) {
        return -1;
    }
    else {
        if ( aO->point.y < bO->point.y ) {
            return 1;
        }
        else if ( aO->point.y > bO->point.y ) {
            return -1;
        }
        else {
            return 0;
        }
    }
}

int compareHullPointsByDescXThenY(const void *a, const void *b) {
    const HullPoint *aO = (const HullPoint*)a;
    const HullPoint *bO = (const HullPoint*)b;
    
    if ( aO->point.x < bO->point.x ) {
        return -1;
    }
    else if ( aO->point.x > bO->point.x ) {
        return 1;
    }
    else {
        if ( aO->point.y < bO->point.y ) {
            return -1;
        }
        else if ( aO->point.y > bO->point.y ) {
            return 1;
        }
        else {
            return 0;
        }
    }
}

int compareHullPointsByIndex(const void *a, const void *b) {
    const HullPoint *aO = (const HullPoint*)a;
    const HullPoint *bO = (const HullPoint*)b;
    
    if ( aO->index < bO->index ) {
        return -1;
    }
    else if ( aO->index > bO->index ) {
        return 1;
    }
    else {
        return 0;
    }
}


void initHullPoints(HullPoints *a, size_t initialSize) {
    a->array = (HullPoint*)calloc(initialSize, sizeof(HullPoint));
    a->used = 0;
    a->size = initialSize;
}

void appendHullPoints(HullPoints *a, HullPoint element) {
    // a->used is the number of used entries, because a->array[a->used++] updates a->used only *after* the array has been accessed.
    // Therefore a->used can go up to a->size
    if (a->used == a->size) {
        a->size *= 2;
        a->array = (HullPoint*)realloc(a->array, a->size * sizeof(HullPoint));
    }
    a->array[a->used++] = element;
}

void insertHullPointsAtIndex(HullPoints *a, HullPoint element, size_t index) {
    if (a->used == a->size) {
        a->size *= 2;
        a->array = (HullPoint*)realloc(a->array, a->size * sizeof(HullPoint));
    }
    
    if ( index < a->used ) {
        for( NSInteger i = (NSInteger)a->used - 1; i >= (NSInteger)index; i-- ) {
            a->array[i + 1] =  a->array[i];
        }
        a->array[index] = element;
        a->used++;
    }
    else {
        appendHullPoints(a, element);
    }
}

void removeHullPoints(HullPoints *a, HullPoint element) {
    size_t n = a->used;
    size_t index = 0;
    
    for( index = 0; index < n; index++ ) {
        if( CGPointEqualToPoint(element.point, a->array[index].point) && element.index == a->array[index].index ) {
            break;
        }
    }
    
    if ( index < n ) {
        for( size_t i = index + 1; i < n; i++ ) {
            a->array[i-1] = a->array[i];
        }
        a->used--;
    }
}

void removeHullPointsAtIndex(HullPoints *a, size_t index) {
    size_t n = a->used;
    if ( index < n ) {
        for( size_t i = index + 1; i < n; i++ ) {
            a->array[i-1] =  a->array[i];
        }
        a->used--;
    }
}

int removeDuplicatesHullPoints(HullPoints *a) {
    sortHullPointsByDescXThenY(a);
    
    int n = (int)a->used;
    int count = 0;
    if (n == 0 || n == 1) {
        return n;
    }
    HullPoints temp;
    initHullPoints(&temp, a->used);
    
    for (int i = 0; i < n; i++) {
        int j;
        for (j = 0; j < count; j++) {
            if ( CGPointEqualToPoint(a->array[i].point, temp.array[j].point)  ) {
                break;
            }
        }
        if (j == count) {
            appendHullPoints(&temp, a->array[i]);
            count++;
        }
    }
    clearHullPoints(a);
    for (int i = 0; i < (int)temp.used; i++) {
        appendHullPoints(a, temp.array[i]);
    }
    freeHullPoints(&temp);
    return (int)a->used;
}


void reverseHullPoints(HullPoints *a, HullPoints *b) {
    if ( b->size > 0 ) {
        for ( NSInteger i = (NSInteger)a->used - 1; i > -1; i-- ) {
            appendHullPoints(b, a->array[i]);
        }
    }
}

void sortHullPointsByAscXThenY(HullPoints *a) {
    qsort((void*)a->array, a->used, sizeof(HullPoint), compareHullPointsByAscXThenY);
}

void sortHullPointsByDescXThenY(HullPoints *a) {
    qsort((void*)a->array, a->used, sizeof(HullPoint), compareHullPointsByDescXThenY);
}

void sortHullPointsByIndex(HullPoints *a) {
    qsort((void*)a->array, a->used, sizeof(HullPoint), compareHullPointsByIndex);
}

NSUInteger searchForIndexHullPoints(HullPoints *a, HullPoint element) {
    NSUInteger index = NSNotFound;
    for( NSUInteger i = 0; i < (NSUInteger)a->used; i++ ) {
        if ( CGPointEqualToPoint(element.point, a->array[i].point) && element.index == a->array[i].index ) {
            index = i;
            break;
        }
    }
    return index;
}

BOOL containsHullPoints(HullPoints *a, HullPoint hullpoint) {
    BOOL contains = NO;
    for( NSUInteger i = 0 ; i < (NSUInteger)a->used; i++) {
        if(a->array[i].point.x == hullpoint.point.x && a->array[i].point.y == hullpoint.point.y) {
            contains = YES;
            break;
        }
    }
    return contains;
}

NSUInteger filterHullPoints(HullPoints *a, HullPoints *b, HullPoints *c) {
    if ( c->size > 0 ) {
        for ( size_t i = 0; i < a->used; i++ ) {
            if ( !containsHullPoints(b, a->array[i]) ) {
                appendHullPoints(c, a->array[i]);
            }
        }
    }
    return c->used;
}

void clearHullPoints(HullPoints *a) {
    a->used = 0;
}

void freeHullPoints(HullPoints *a) {
    free(a->array);
    a->array = NULL;
    a->used = a->size = 0;
}

void initHullCells(HullCells *a, size_t initialSize) {
    a->array = (HullCell*)calloc(initialSize, sizeof(HullCell));
    a->used = 0;
    a->size = initialSize;
}

void appendHullCells(HullCells *a, HullCell element) {
    if (a->used == a->size) {
        a->size *= 2;
        a->array = (HullCell*)realloc(a->array, a->size * sizeof(HullCell));
    }
    a->array[a->used++] = element;
}

NSUInteger searchForIndexHullCells(HullCells *a, NSInteger rowIndex, NSInteger colIndex) {
    NSUInteger index = NSNotFound;
    for( NSUInteger i = 0; i < (NSUInteger)a->used; i++ ) {
        if ( rowIndex == a->array[i].index && colIndex == a->array[i].jndex ) {
            index = i;
            break;
        }
    }
    return index;
}

void freeHullCells(HullCells *a) {
    free(a->array);
    a->array = NULL;
    a->used = a->size = 0;
}


@interface _CPTHull()

@property (nonatomic) CGFloat maxConcaveAngleCos;
@property (nonatomic) CGFloat maxSearchBboxSizePercent;

@end

@implementation _CPTHull

// Inaccessibles variables
static HullPoints hullpoints;   // Hullpoint array

@synthesize concavity;
@synthesize maxConcaveAngleCos;
@synthesize maxSearchBboxSizePercent;

-(nonnull instancetype)init {
    if ( (self = [super init]) ) {
        self.concavity = 20.0;
        maxConcaveAngleCos = cos(90 / (180 / M_PI)); // angle = 90 deg
        maxSearchBboxSizePercent = 0.6;
        initHullPoints(&hullpoints, 8);
    }
    return self;
}

- (instancetype)initWithConcavity:(CGFloat)newConcavity {
    if ( (self = [super init]) ) {
        self.concavity = newConcavity;
        maxConcaveAngleCos = cos(90 / (180 / M_PI)); // angle = 90 deg
        maxSearchBboxSizePercent = 0.6;
        initHullPoints(&hullpoints, 8);
    }
    return self;
}

- (void)dealloc {
    freeHullPoints(&hullpoints);
}

-(HullPoints*)hullpoints {
    return &hullpoints;
}

-(HullPoint*)hullpointsArray {
    return hullpoints.array;
}

-(NSUInteger)hullpointsCount {
    return hullpoints.used;
}

#pragma mark -
#pragma mark Sorting
-(void) sortHullpointsByIndex {
    sortHullPointsByIndex(&hullpoints);
}


#pragma mark -
#pragma mark Hull Convex Points methods

-(void)quickConvexHullOnViewPoints:(CGPoint*)viewPoints dataCount:(NSUInteger)dataCount  {
    sortCGPointsByDescXThenY(viewPoints, dataCount);
    
    HullPoint point;
    if ( dataCount < 2 ) {
        point.point = viewPoints[0];
        point.index = 0;
        appendHullPoints(&hullpoints, point);
        if( dataCount == 2 ) {
            point.point = viewPoints[1];
            point.index = 1;
            appendHullPoints(&hullpoints, point);
        }
        appendHullPoints(&hullpoints, hullpoints.array[0]);
        return;
    }
    HullPoints pts;
    initHullPoints(&pts, dataCount - 2);
  // Assume points has at least 2 points
  // Assume list is ordered on x
    
    for ( NSUInteger i = 1; i < (NSUInteger)dataCount - 1; i++ ) {
        point.point = viewPoints[i];
        point.index = i;
        appendHullPoints(&pts, point);
    }
    // p1 and p2 are outer most points and thus are part of the hull
    
    HullPoint p1, p2;
    // left most point
    p1.point = viewPoints[0];
    p1.index = 0;
    appendHullPoints(&hullpoints, p1);
    // right most point
    p2.point = viewPoints[dataCount - 1];
    p2.index = dataCount - 1;
    appendHullPoints(&hullpoints, p2);

    // points to the right of oriented line from p1 to p2
    HullPoints s1;
    initHullPoints(&s1, dataCount);

    // points to the right of oriented line from p2 to p1
    HullPoints s2;
    initHullPoints(&s2, dataCount);

    // p1 to p2 line
    CGPoint lineVec1 = CGPointMake(p2.point.x - p1.point.x, p2.point.y - p1.point.y);
    CGPoint pVec1;
    CGFloat sign1;
    for ( NSUInteger i = 0; i < (NSUInteger)pts.used; i++ ) {
        point = pts.array[i];
        pVec1 = CGPointMake(point.point.x - p1.point.x, point.point.y - p1.point.y);
        sign1 = lineVec1.x * pVec1.y - pVec1.x * lineVec1.y; // cross product to check on which side of the line point p is.
        if ( sign1 > 0 ) { // right of p1 p2 line (in a normal xy coordinate system this would be < 0 but due to the weird iPhone screen coordinates this is > 0
            appendHullPoints(&s1, point);
        }
        else { // right of p2 p1 line
            appendHullPoints(&s2, point);
        }
    }
    
    // find new hull points
    [self findHullOnPoints:&s1 convexHull:&hullpoints p1:p1 p2:p2];
    [self findHullOnPoints:&s2 convexHull:&hullpoints p1:p2 p2:p1];
    
    appendHullPoints(&hullpoints, hullpoints.array[0]);
}

-(void)quickConvexHullOnIntersections:(Intersections*)pIntersections {
    sortIntersectionsByDescXThenY(pIntersections);
    
    HullPoint point;
    if ( pIntersections->used < 2 ) {
        point.point = pIntersections->array[0].point;
        point.index = pIntersections->array[0].intersectionIndex;
        appendHullPoints(&hullpoints, point);
        if( pIntersections->used == 2 ) {
            point.point = pIntersections->array[1].point;
            point.index = pIntersections->array[1].intersectionIndex;
            appendHullPoints(&hullpoints, point);
        }
        return;
    }
    HullPoints pts;
    initHullPoints(&pts, pIntersections->used-2);
  // Assume points has at least 2 points
  // Assume list is ordered on x
    
    for ( NSUInteger i = 1; i < (NSUInteger)pIntersections->used-1; i++ ) {
        point.point = pIntersections->array[i].point;
        point.index = pIntersections->array[i].intersectionIndex;
        appendHullPoints(&pts, point);
    }
    // p1 and p2 are outer most points and thus are part of the hull
    
    HullPoint p1, p2;
    // left most point
    p1.point = pIntersections->array[0].point;
    p1.index = pIntersections->array[0].intersectionIndex;
    appendHullPoints(&hullpoints, p1);
    // right most point
    p2.point = pIntersections->array[(int)pIntersections->used-1].point;
    p2.index = pIntersections->array[(int)pIntersections->used-1].intersectionIndex;
    appendHullPoints(&hullpoints, p2);

    // points to the right of oriented line from p1 to p2
    HullPoints s1;
    initHullPoints(&s1, pIntersections->used);

    // points to the right of oriented line from p2 to p1
    HullPoints s2;
    initHullPoints(&s2, pIntersections->used);

    // p1 to p2 line
    CGPoint lineVec1 = CGPointMake(p2.point.x - p1.point.x, p2.point.y - p1.point.y);
    CGPoint pVec1;
    CGFloat sign1;
    for ( NSUInteger i = 0; i < (NSUInteger)pts.used; i++ ) {
        point = pts.array[i];
        pVec1 = CGPointMake(point.point.x - p1.point.x, point.point.y - p1.point.y);
        sign1 = lineVec1.x * pVec1.y - pVec1.x * lineVec1.y; // cross product to check on which side of the line point p is.
        if ( sign1 > 0 ) { // right of p1 p2 line (in a normal xy coordinate system this would be < 0 but due to the weird iPhone screen coordinates this is > 0
            appendHullPoints(&s1, point);
        }
        else { // right of p2 p1 line
            appendHullPoints(&s2, point);
        }
    }
    
    // find new hull points
    [self findHullOnPoints:&s1 convexHull:&hullpoints p1:p1 p2:p2];
    [self findHullOnPoints:&s2 convexHull:&hullpoints p1:p2 p2:p1];
}

-(void)quickConvexHullOnBorderStrips:(Strips*)pBorderStrips {
    HullPoint point;
    if ( pBorderStrips->used < 2 ) {
        point.point = pBorderStrips->array[0].startPoint;
        point.index = 0;
        appendHullPoints(&hullpoints, point);
        
        point.point = pBorderStrips->array[1].endPoint;
        point.index = 1;
        appendHullPoints(&hullpoints, point);
        return;
    }
    HullPoints pts;
    initHullPoints(&pts, (pBorderStrips->used - 1) * 2);
  // Assume points has at least 2 points
  // Assume list is ordered on x
    
    for ( NSUInteger i = 0; i < (NSUInteger)pBorderStrips->used; i++ ) {
        if ( i != 0 ) {
            point.point = pBorderStrips->array[i].startPoint;
            point.index = i;
            appendHullPoints(&pts, point);
        }
        if ( i != (NSUInteger)pBorderStrips->used - 1 ) {
            point.point = pBorderStrips->array[i].endPoint;
            point.index = i;
            appendHullPoints(&pts, point);
        }
    }
    // p1 and p2 are outer most points and thus are part of the hull
    
    HullPoint p1, p2;
    // left most point
    p1.point = pBorderStrips->array[0].startPoint;
    p1.index = 0;
    appendHullPoints(&hullpoints, p1);
    // right most point
    p2.point = pBorderStrips->array[(int)pBorderStrips->used - 1].endPoint;
    p2.index = (NSUInteger)pBorderStrips->used - 1;
    appendHullPoints(&hullpoints, p2);

    // points to the right of oriented line from p1 to p2
    HullPoints s1;
    initHullPoints(&s1, pBorderStrips->used * 2);

    // points to the right of oriented line from p2 to p1
    HullPoints s2;
    initHullPoints(&s2, pBorderStrips->used * 2);

    // p1 to p2 line
    CGPoint lineVec1 = CGPointMake(p2.point.x - p1.point.x, p2.point.y - p1.point.y);
    CGPoint pVec1;
    CGFloat sign1;
    for ( NSUInteger i = 0; i < (NSUInteger)pts.used; i++ ) {
        point = pts.array[i];
        pVec1 = CGPointMake(point.point.x - p1.point.x, point.point.y - p1.point.y);
        sign1 = lineVec1.x * pVec1.y - pVec1.x * lineVec1.y; // cross product to check on which side of the line point p is.
        if ( sign1 > 0 ) { // right of p1 p2 line (in a normal xy coordinate system this would be < 0 but due to the weird iPhone screen coordinates this is > 0
            appendHullPoints(&s1, point);
        }
        else { // right of p2 p1 line
            appendHullPoints(&s2, point);
        }
    }
    
    // find new hull points
    [self findHullOnPoints:&s1 convexHull:&hullpoints p1:p1 p2:p2];
    [self findHullOnPoints:&s2 convexHull:&hullpoints p1:p2 p2:p1];
}

-(void)quickConvexHullOnBorderIndices:(BorderIndices*)pBorderIndices {
    
    //pBorderIndices should already be sorted by position around perimeter starting with bottom left corner
    
    HullPoint point;
    if ( pBorderIndices->used < 2 ) {
        point.point = pBorderIndices->array[0].point;
        point.index = 0;
        appendHullPoints(&hullpoints, point);
        if( pBorderIndices->used == 2 ) {
            point.point = pBorderIndices->array[1].point;
            point.index = 1;
            appendHullPoints(&hullpoints, point);
        }
        return;
    }
    HullPoints pts;
    initHullPoints(&pts, pBorderIndices->used - 2);
  // Assume points has at least 2 points
  // Assume list is ordered on x
    
    for ( NSUInteger i = 1; i < (NSUInteger)pBorderIndices->used - 1; i++ ) {
        point.point = pBorderIndices->array[i].point;
        point.index = i;
        appendHullPoints(&pts, point);
    }
    // p1 and p2 are outer most points and thus are part of the hull
    
    HullPoint p1, p2;
    // left most point
    p1.point = pBorderIndices->array[0].point;
    p1.index = 0;
    appendHullPoints(&hullpoints, p1);
    // right most point
    p2.point = pBorderIndices->array[(int)pBorderIndices->used - 1].point;
    p2.index = (NSUInteger)pBorderIndices->used - 1;
    appendHullPoints(&hullpoints, p2);

    // points to the right of oriented line from p1 to p2
    HullPoints s1;
    initHullPoints(&s1, pBorderIndices->used);

    // points to the right of oriented line from p2 to p1
    HullPoints s2;
    initHullPoints(&s2, pBorderIndices->used);

    // p1 to p2 line
    CGPoint lineVec1 = CGPointMake(p2.point.x - p1.point.x, p2.point.y - p1.point.y);
    CGPoint pVec1;
    CGFloat sign1;
    for ( NSUInteger i = 0; i < (NSUInteger)pts.used; i++ ) {
        point = pts.array[i];
        pVec1 = CGPointMake(point.point.x - p1.point.x, point.point.y - p1.point.y);
        sign1 = lineVec1.x * pVec1.y - pVec1.x * lineVec1.y; // cross product to check on which side of the line point p is.
        if ( sign1 > 0 ) { // right of p1 p2 line (in a normal xy coordinate system this would be < 0 but due to the weird iPhone screen coordinates this is > 0
            appendHullPoints(&s1, point);
        }
        else { // right of p2 p1 line
            appendHullPoints(&s2, point);
        }
    }
    
    // find new hull points
    [self findHullOnPoints:&s1 convexHull:&hullpoints p1:p1 p2:p2];
    [self findHullOnPoints:&s2 convexHull:&hullpoints p1:p2 p2:p1];
}

-(void)quickConvexHullOnHullPoints:(HullPoints*)points {
    sortHullPointsByDescXThenY(points);
    HullPoint point;
    if ( points->used < 2 ) {
        appendHullPoints(&hullpoints, points->array[0]);
        if( points->used == 2 ) {
            appendHullPoints(&hullpoints, points->array[1]);
        }
        appendHullPoints(&hullpoints, hullpoints.array[0]);
        return;
    }
    
    // p1 and p2 are outer most points and thus are part of the hull
    
    HullPoint p1, p2;
    // left most point
    p1 = points->array[0];
    appendHullPoints(&hullpoints, p1);
    // right most point
    p2 = points->array[points->used - 1];
    appendHullPoints(&hullpoints, p2);

    // points to the right of oriented line from p1 to p2
    HullPoints s1;
    initHullPoints(&s1, points->used);

    // points to the right of oriented line from p2 to p1
    HullPoints s2;
    initHullPoints(&s2, points->used);

    // p1 to p2 line
    CGPoint lineVec1 = CGPointMake(p2.point.x - p1.point.x, p2.point.y - p1.point.y);
    CGPoint pVec1;
    CGFloat sign1;
    for ( NSUInteger i = 1; i < (NSUInteger)points->used - 1; i++ ) {
        point = points->array[i];
        pVec1 = CGPointMake(point.point.x - p1.point.x, point.point.y - p1.point.y);
        sign1 = lineVec1.x * pVec1.y - pVec1.x * lineVec1.y; // cross product to check on which side of the line point p is.
        if ( sign1 > 0 ) { // right of p1 p2 line (in a normal xy coordinate system this would be < 0 but due to the weird iPhone screen coordinates this is > 0
            appendHullPoints(&s1, point);
        }
        else { // right of p2 p1 line
            appendHullPoints(&s2, point);
        }
    }
    
    // find new hull points
    [self findHullOnPoints:&s1 convexHull:&hullpoints p1:p1 p2:p2];
    [self findHullOnPoints:&s2 convexHull:&hullpoints p1:p2 p2:p1];
    appendHullPoints(&hullpoints, hullpoints.array[0]);
}

-(void)findHullOnPoints:(HullPoints*)points convexHull:(HullPoints*)pConvexHull p1:(HullPoint)p1 p2:(HullPoint)p2 {
    // if set of points is empty there are no points to the right of this line so this line is part of the hull.
    if ( points->used == 0 ) {
        return;
    }

    CGFloat dist, maxDist = -1.0;
    HullPoint maxPoint = points->array[0];
    CGPoint point;
    CGPoint line[2];
    for ( NSUInteger i = 0; i < (NSUInteger)points->used; i++ ) { // for every point check the distance from our line
        point = points->array[i].point;
        line[0] = p1.point;
        line[1] = p2.point;
        dist = [self distanceFromPoint:point toline:line];
        if ( dist > maxDist ) { // if distance is larger than current maxDist remember new point p
            maxDist = dist;
            maxPoint.point = point;
            maxPoint.index = points->array[i].index;
        }
    }
  
    // insert point with max distance from line in the convexHull after p1
    NSUInteger index;
    if ( (index = searchForIndexHullPoints(pConvexHull, p1)) != NSNotFound ) {
        insertHullPointsAtIndex(pConvexHull, maxPoint, (size_t)index + 1);
    }

    // remove maxPoint from points array as we are going to split this array in points left and right of the line
    if ( (index = searchForIndexHullPoints(points, maxPoint)) != NSNotFound ) {
        removeHullPointsAtIndex(points, (size_t)index);
    }

    // points to the right of oriented line from p1 to maxPoint
    HullPoints s1;
    initHullPoints(&s1, (size_t)points->used);

    // points to the right of oriented line from maxPoint to p2
    HullPoints s2;
    initHullPoints(&s2, (size_t)points->used);

    // p1 to maxPoint line
    CGPoint lineVec1 = CGPointMake(maxPoint.point.x - p1.point.x, maxPoint.point.y - p1.point.y);
    // maxPoint to p2 line
    CGPoint lineVec2 = CGPointMake(p2.point.x - maxPoint.point.x, p2.point.y - maxPoint.point.y);

    HullPoint p;
    CGPoint pVec1, pVec2;
    CGFloat sign1, sign2;
    for( NSUInteger i = 0; i < (NSUInteger)points->used; i++ ) {
        p = points->array[i];
        pVec1 = CGPointMake(p.point.x - p1.point.x, p.point.y - p1.point.y); // vector from p1 to p
        sign1 = lineVec1.x * pVec1.y - pVec1.x * lineVec1.y; // sign to check is p is to the right or left of lineVec1
        pVec2 = CGPointMake(p.point.x - maxPoint.point.x, p.point.y - maxPoint.point.y); // vector from p2 to p
        sign2 = lineVec2.x * pVec2.y - pVec2.x * lineVec2.y; // sign to check is p is to the right or left of lineVec2

        if ( sign1 > 0 ) { // right of p1 maxPoint line
            appendHullPoints(&s1, p);
        }
        else if ( sign2 > 0 ) { // right of maxPoint p2 line
            appendHullPoints(&s2, p);
        }
    }

    // find new hull points
    [self findHullOnPoints:&s1 convexHull:pConvexHull p1:p1 p2:maxPoint];
    [self findHullOnPoints:&s2 convexHull:pConvexHull p1:maxPoint p2:p2];
}

-(CGFloat)distanceFromPoint:(CGPoint)point toline:(CGPoint*)line {
  // If line.0 and line.1 are the same point, they don't define a line (and, besides,
  // would cause division by zero in the distance formula). Return the distance between
  // line.0 and point p instead.
  if ( CGPointEqualToPoint(line[0], line[1])) {
      return sqrt(pow(point.x - line[0].x, 2.0) + pow(point.y - line[0].y, 2.0));
  }
  // from Deza, Michel Marie; Deza, Elena (2013), Encyclopedia of Distances (2nd ed.), Springer, p. 86, ISBN 9783642309588
  return fabs((line[1].y - line[0].y) * point.x - (line[1].x - line[0].x) * point.y + line[1].x * line[0].y - line[1].y * line[0].x) / sqrt(pow(line[1].y - line[0].y, 2.0) + pow(line[1].x - line[0].x, 2.0));
}

#pragma mark -
#pragma mark Hull Concave Points methods

-(void)concaveHullOnViewPoints:(CGPoint*)viewPoints dataCount:(NSUInteger)dataCount {
    HullPoint point;
    HullPoints points;
    initHullPoints(&points, dataCount);
    for ( NSUInteger i = 0; i < (NSUInteger)dataCount; i++ ) {
        point.point = viewPoints[i];
        point.index = i;
        appendHullPoints(&points, point);
    }
    removeDuplicatesHullPoints(&points);
    
    Convex *convexEngine = [[Convex alloc] initWithPoints:&points];
    HullPoints convex;
    initHullPoints(&convex, [convexEngine hullPoints]->used);
    for ( NSUInteger i = 0; i < (NSUInteger)[convexEngine hullPoints]->used; i++ ) {
        appendHullPoints(&convex, [convexEngine hullPoints]->array[i]);
    }
    convexEngine = nil;

    HullPoint occupiedArea;
    [self occupiedAreaFunc:&points hullPoint:&occupiedArea];
    if( !(occupiedArea.point.x == 0 || occupiedArea.point.y == 0) ) {

        CGFloat maxSearchArea[2] = { occupiedArea.point.x * self.maxSearchBboxSizePercent, occupiedArea.point.y * self.maxSearchBboxSizePercent };

        NSMutableDictionary *skipList = [[NSMutableDictionary alloc] init];
        HullPoints innerPoints;
        initHullPoints(&innerPoints, points.used);

        filterHullPoints(&points, &convex, &innerPoints);
        sortHullPointsByAscXThenY(&innerPoints);
        
        CGFloat cellSize = ceil(occupiedArea.point.x * occupiedArea.point.y / (CGFloat)points.used);
//        freeHullPoints(&points);
        
        Grid *grid = [[Grid alloc] initWithPoints:&innerPoints cellSize:cellSize];
        [self concaveFunc:&convex maxSqEdgeLen:pow(self.concavity, 2) maxSearchArea:maxSearchArea grid:grid edgeSkipList:skipList];
        freeHullPoints(&innerPoints);
    }
    freeHullPoints(&points);
    if ( hullpoints.used == 0 ) {
        initHullPoints(&hullpoints, convex.used);
    }
    for ( NSUInteger i = 0; i < convex.used; i++ ) {
        appendHullPoints(&hullpoints, convex.array[i]);
    }
    freeHullPoints(&convex);
}

-(CGFloat)squareLength:(HullPoint*)aaa second:(HullPoint*)bbb {
    return pow(bbb->point.x - aaa->point.x, 2) + pow(bbb->point.y - aaa->point.y, 2);
}

-(CGFloat)cosFunc:(HullPoint*)ooo aaa:(HullPoint*)aaa bbb:(HullPoint*)bbb {
    CGFloat aShifted[2] = { aaa->point.x - ooo->point.x, aaa->point.y - ooo->point.y };
    CGFloat bShifted[2] = { bbb->point.x - ooo->point.x, bbb->point.y - ooo->point.y };
    CGFloat sqALen = [self squareLength:ooo second:aaa];
    CGFloat sqBLen = [self squareLength:ooo second:bbb];
    CGFloat dot = aShifted[0] * bShifted[0] + aShifted[1] * bShifted[1];
    return dot / sqrt(sqALen * sqBLen);
}

-(BOOL)intersectFunc:(HullPoint*)segment points:(HullPoints*)points {
    for ( NSUInteger idx = 0; idx < points->used - 1; idx++ ) {
        HullPoint seg[2] = { points->array[idx], points->array[idx + 1] };
        if ( (segment[0].point.x == seg[0].point.x && segment[0].point.y == seg[0].point.y) ||
            (segment[0].point.x == seg[1].point.x && segment[0].point.y == seg[1].point.y) ) {
            continue;
        }
        HullPoint segment1 = segment[0], segment2 = segment[1], segment3 = seg[0], segment4 = seg[1];
        if ( [self ccw:&segment1 seg2:&segment3 seg3:&segment4] != [self ccw:&segment2 seg2:&segment3 seg3:&segment4] &&
            [self ccw:&segment1 seg2:&segment2 seg3:&segment3] != [self ccw:&segment1 seg2:&segment2 seg3:&segment4] ) {
            return YES;
        }
    }
    return NO;
}

-(BOOL) ccw:(HullPoint*)seg1 seg2:(HullPoint*)seg2 seg3:(HullPoint*)seg3 {
    CGFloat ccw = ((seg3->point.y - seg1->point.y) * (seg2->point.x - seg1->point.x)) - ((seg2->point.y - seg1->point.y) * (seg3->point.x - seg1->point.x));
    return ccw > 0 ? YES : ccw < 0 ? NO : YES;
}

-(void) occupiedAreaFunc:(HullPoints*)points hullPoint:(HullPoint*)hullPoint {
    CGFloat minX = CGFLOAT_MAX, minY = CGFLOAT_MAX, maxX = -CGFLOAT_MAX, maxY = -CGFLOAT_MAX;

    for( NSUInteger idx = 0; idx < points->used/*reversed.used*/; idx++ ) {
        if ( points->array[idx].point.x < minX ) {
            minX = points->array[idx].point.x;
        }
        if ( points->array[idx].point.y < minY ) {
            minY = points->array[idx].point.y;
        }
        if ( points->array[idx].point.x > maxX ) {
            maxX = points->array[idx].point.x;
        }
        if ( points->array[idx].point.y > maxY ) {
            maxY = points->array[idx].point.y;
        }
    }
    hullPoint->point.x = maxX - minX;
    hullPoint->point.y = maxY - minY;
}

-(void) bBoxAroundFunc:(HullPoint*)edge box:(CGFloat*)box {
    box[0] = MIN(edge[0].point.x, edge[1].point.x);
    box[1] = MIN(edge[0].point.y, edge[1].point.y);
    box[2] = MAX(edge[0].point.x, edge[1].point.x);
    box[3] = MAX(edge[0].point.y, edge[1].point.y);
}

-(void) midPointFunc:(HullPoint*)edge innerPoints:(HullPoints*)innerPoints convex:(HullPoints*)convex hullPoint:(HullPoint*)hullpoint {
    HullPoint point = *hullpoint;
    HullPoint seg1[2], seg2[2];
    CGFloat angle1Cos = self.maxConcaveAngleCos;
    CGFloat angle2Cos = self.maxConcaveAngleCos;
    CGFloat a1Cos = 0.0;
    CGFloat a2Cos = 0.0;
    for( NSUInteger i = 0; i < innerPoints->used; i++ ) {
        HullPoint innerPoint = innerPoints->array[i];
        a1Cos = [self cosFunc:&edge[0] aaa:&edge[1] bbb:&innerPoint];
        a2Cos = [self cosFunc:&edge[1] aaa:&edge[0] bbb:&innerPoint];
        seg1[0] = edge[0];
        seg1[1] = innerPoint;
        seg2[0] = edge[1];
        seg2[1] = innerPoint;
        if ( a1Cos > angle1Cos && a2Cos > angle2Cos &&
            ![self intersectFunc:seg1 points:convex] && ![self intersectFunc:seg2 points:convex] ) {
            angle1Cos = a1Cos;
            angle2Cos = a2Cos;
            point = innerPoint;
        }
    }
    hullpoint->point = point.point;
}


-(void) concaveFunc:(HullPoints*)convex maxSqEdgeLen:(CGFloat)maxSqEdgeLen maxSearchArea:(CGFloat*)maxSearchArea grid:(Grid*)grid edgeSkipList:(NSMutableDictionary*)edgeSkipList {

    HullPoint edge[2];
    NSString *keyInSkipList = @"";
    CGFloat scaleFactor;
    HullPoint midPoint;
    CGFloat bBoxAround[4];
    CGFloat bBoxWidth = 0;
    CGFloat bBoxHeight = 0;
    BOOL midPointInserted = NO;

    HullPoints hpoints;
    initHullPoints(&hpoints, 8);
    for( NSUInteger idx = 0; idx < convex->used - 1; idx++ ) {
        edge[0] = convex->array[idx];
        edge[1] = convex->array[idx + 1];
        keyInSkipList = [NSString stringWithFormat:@"%0.3f %0.3f, %0.3f %0.3f", edge[0].point.x, edge[0].point.y, edge[1].point.x, edge[1].point.y];
        scaleFactor = 0.0;
        [self bBoxAroundFunc:edge box:bBoxAround];
        if ( [self squareLength:&edge[0] second:&edge[1]] < maxSqEdgeLen || [[edgeSkipList objectForKey:keyInSkipList] boolValue] ) {
            continue;
        }
        
        do {
            [grid extendBbox:bBoxAround scaleFactor:scaleFactor eBox:bBoxAround];
            bBoxWidth = bBoxAround[2] - bBoxAround[0];
            bBoxHeight = bBoxAround[3] - bBoxAround[1];
            [grid rangePoints:bBoxAround points:&hpoints];
            midPoint.point = CGPointMake(-0.0, -0.0);
            [self midPointFunc:edge innerPoints:&hpoints convex:convex hullPoint:&midPoint];
            clearHullPoints(&hpoints);
            scaleFactor+= 1.0;
        } while( midPoint.point.x == -0.0 && (maxSearchArea[0] > bBoxWidth || maxSearchArea[1] > bBoxHeight) );
        
        if ( bBoxWidth >= maxSearchArea[0] && bBoxHeight >= maxSearchArea[1] ) {
            [edgeSkipList setObject:[NSNumber numberWithBool:YES] forKey:keyInSkipList];
        }
        if ( midPoint.point.x != -0.0 ) {
            insertHullPointsAtIndex(convex, midPoint, idx + 1);
            [grid removePoint:&midPoint];
            midPointInserted = YES;
        }
    }
    freeHullPoints(&hpoints);

    if ( midPointInserted ) {
        [self concaveFunc:convex maxSqEdgeLen:maxSqEdgeLen maxSearchArea:maxSearchArea grid:grid edgeSkipList:edgeSkipList];
    }
}

@end
