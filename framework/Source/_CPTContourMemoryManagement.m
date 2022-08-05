//
//  _CPTContourMemoryManagement.m
//  CorePlot
//
//  Created by Steve Wainwright on 13/05/2022.
//

#import "_CPTContourMemoryManagement.h"

// Function to swap two memory contents
void swapPoints(CGPoint* a, CGPoint* b) {
    CGPoint temp = *a;
    *a = *b;
    *b = temp;
}

// A utility function to return square of distance between
// p1 and p2
CGFloat dist(CGPoint p1, CGPoint p2) {
    return (p1.x - p2.x) * (p1.x - p2.x) + (p1.y - p2.y) * (p1.y - p2.y);
}

static CGPoint comparisonPoint;

int comparePoints(const void *a, const void *b) {
    const CGPoint *aO = (const CGPoint*)a;
    const CGPoint *bO = (const CGPoint*)b;
//    CGFloat dist1 = (aO.x * aO.x) + (aO.y * aO.y);
//    CGFloat dist2 = (bO.x * bO.x) + (bO.y * bO.y);
    CGFloat dist1 = dist(*aO, comparisonPoint);
    CGFloat dist2 = dist(*bO, comparisonPoint);
    return (int)(floor(dist1 - dist2));
}

void closestKPoints(CGPoint* _Nonnull points, NSUInteger n, CGPoint point/*, NSUInteger k*/) {
    comparisonPoint = point;
    qsort(points, n, sizeof(CGPoint), comparePoints);
}

#pragma mark -
#pragma mark CGPoints

void insertCGPointsAtIndex(CGPoint *a, CGPoint element, size_t index, size_t *a_used, size_t *a_size) {
    if ( *a_used >= *a_size ) {
        *a_size = *a_size * 2;
        a = (CGPoint*)realloc(a, *a_size * sizeof(CGPoint));
    }
    
    if ( index < *a_used ) {
        for( NSInteger i = (NSInteger)*a_used - 1; i >= (NSInteger)index; i-- ) {
            a[i + 1] =  a[i];
        }
        a[index] = element;
        *a_used = *a_used + 1;
    }
    else {
        a[*a_used] = element;
        *a_used = *a_used + 1;
    }
}

size_t removeCGPointsFromCGPoints(CGPoint *a, size_t a_size, CGPoint *b, size_t b_size) {
    if ( b_size > a_size ) {
        return 0;
    }
    size_t k = 0;
    for ( size_t i = 0; i < b_size; i++ ) {
        for( size_t j = k; j < a_size; j++ ) {
            if ( CGPointEqualToPoint(a[j], b[i]) ) {
                a_size = removeCGPointAtIndex(a, a_size, j);
                k = j;
            }
        }
    }
    return a_size;
}

size_t removeCGPointAtIndex(CGPoint *a, size_t a_size, size_t index) {
    if ( index < a_size ) {
        for( size_t i = index + 1; i < a_size; i++ ) {
            a[i-1] =  a[i];
        }
        a_size--;
    }
    return a_size;
}

BOOL containsCGPoint(CGPoint *a, size_t a_size, CGPoint point) {
    BOOL hasPoint = NO;
    for( size_t i = 0; i < a_size; i++ ) {
        if ( fabs(a[i].x - point.x) < 0.00001 && fabs(a[i].y - point.y) < 0.00001 ) {
            hasPoint = YES;
            break;
        }
    }
    return hasPoint;
}

#pragma mark -
#pragma mark CGPathBoundaryPoints


int compareCGPathBoundaryPointsByPosition(const void *a, const void *b);
int compareCGPathBoundaryPointsByBottomEdge(const void *a, const void *b);
int compareCGPathBoundaryPointsByRightEdge(const void *a, const void *b);
int compareCGPathBoundaryPointsByTopEdge(const void *a, const void *b);
int compareCGPathBoundaryPointsByLeftEdge(const void *a, const void *b);

BOOL callbackPlotEdge(const CGPathBoundaryPoint item, CPTContourBorderDimensionDirection direction, CGFloat edge) {
    BOOL test;
    switch(direction) {
        case CPTContourBorderDimensionDirectionXForward:
        case CPTContourBorderDimensionDirectionXBackward:
            test = item.point.y == edge;
            break;
        case CPTContourBorderDimensionDirectionYForward:
        case CPTContourBorderDimensionDirectionYBackward:
            test = item.point.x == edge;
            break;
        default:
            test = NO;
            break;
    }
    return test;
}

BOOL callbackPlotCorner(const CGPathBoundaryPoint item, CGPoint corner) {
    return CGPointEqualToPoint(corner, item.point);
}

int compareCGPathBoundaryPointsByPosition(const void *a, const void *b) {
    const CGPathBoundaryPoint *aO = (const CGPathBoundaryPoint*)a;
    const CGPathBoundaryPoint *bO = (const CGPathBoundaryPoint*)b;
    
    if (aO->position > bO->position) {
        return 1;
    }
    else if (aO->position < bO->position) {
        return -1;
    }
    else {
        return 0;
    }
}

int compareCGPathBoundaryPointsByBottomEdge(const void *a, const void *b) {
    const CGPathBoundaryPoint *aO = (const CGPathBoundaryPoint*)a;
    const CGPathBoundaryPoint *bO = (const CGPathBoundaryPoint*)b;
    
    if (aO->point.x > bO->point.x) {
        return 1;
    }
    else if (aO->point.x < bO->point.x) {
        return -1;
    }
    else {
        if ( aO->direction != CPTContourBorderDimensionDirectionXForward ) {
            return 1;
        }
        return aO->position > bO->position;
    }
}

int compareCGPathBoundaryPointsByRightEdge(const void *a, const void *b) {
    const CGPathBoundaryPoint *aO = (const CGPathBoundaryPoint*)a;
    const CGPathBoundaryPoint *bO = (const CGPathBoundaryPoint*)b;
    
    if (aO->point.y > bO->point.y) {
        return 1;
    }
    else if (aO->point.y < bO->point.y) {
        return -1;
    }
    else {
        if ( aO->direction != CPTContourBorderDimensionDirectionYForward ) {
            return 1;
        }
        return aO->position > bO->position;;
    }
}

int compareCGPathBoundaryPointsByTopEdge(const void *a, const void *b) {
    const CGPathBoundaryPoint *aO = (const CGPathBoundaryPoint*)a;
    const CGPathBoundaryPoint *bO = (const CGPathBoundaryPoint*)b;
    
    if (aO->point.x < bO->point.x) {
        return 1;
    }
    else if (aO->point.x > bO->point.x) {
        return -1;
    }
    else {
        if ( aO->direction != CPTContourBorderDimensionDirectionXBackward ) {
            return 1;
        }
        return aO->position > bO->position;;
    }
}

int compareCGPathBoundaryPointsByLeftEdge(const void *a, const void *b) {
    const CGPathBoundaryPoint *aO = (const CGPathBoundaryPoint*)a;
    const CGPathBoundaryPoint *bO = (const CGPathBoundaryPoint*)b;
    
    if (aO->point.y < bO->point.y) {
        return 1;
    }
    else if (aO->point.y > bO->point.y) {
        return -1;
    }
    else {
        if ( aO->direction != CPTContourBorderDimensionDirectionYBackward ) {
            return 1;
        }
        return aO->position > bO->position;;
    }
}

void initCGPathBoundaryPoints(CGPathBoundaryPoints *a, size_t initialSize) {
    a->array = (CGPathBoundaryPoint*)calloc(initialSize, sizeof(CGPathBoundaryPoint));
    a->used = 0;
    a->size = initialSize;
}

void appendCGPathBoundaryPoints(CGPathBoundaryPoints *a, CGPathBoundaryPoint element) {
    // a->used is the number of used entries, because a->array[a->used++] updates a->used only *after* the array has been accessed.
    // Therefore a->used can go up to a->size
    if (a->used == a->size) {
        a->size *= 2;
        a->array = (CGPathBoundaryPoint*)realloc(a->array, a->size * sizeof(CGPathBoundaryPoint));
    }
    a->array[a->used++] = element;
}

void insertCGPathBoundaryPointsAtIndex(CGPathBoundaryPoints *a, CGPathBoundaryPoint element, size_t index) {
    if (a->used == a->size) {
        a->size *= 2;
        a->array = (CGPathBoundaryPoint*)realloc(a->array, a->size * sizeof(CGPathBoundaryPoint));
    }
    
    if ( index < a->used ) {
        for( NSInteger i = (NSInteger)a->used - 1; i >= (NSInteger)index; i-- ) {
            a->array[i + 1] =  a->array[i];
        }
        a->array[index] = element;
        a->used++;
    }
    else {
        appendCGPathBoundaryPoints(a, element);
    }
}

void removeCGPathBoundaryPointsAtIndex(CGPathBoundaryPoints *a, size_t index) {
    size_t n = a->used;
    if ( index < n ) {
        for( size_t i = index+1; i < n; i++ ) {
            a->array[i-1] =  a->array[i];
        }
        a->used--;
    }
}

NSUInteger filterCGPathBoundaryPoints(CGPathBoundaryPoints *a, BOOL (*predicate)(const CGPathBoundaryPoint item, CPTContourBorderDimensionDirection direction, CGFloat edge), CGPathBoundaryPoints *b, CPTContourBorderDimensionDirection direction, CGFloat edge) {
    if ( b->size > 0 ) {
        for ( size_t i = 0; i < a->used; i++ ) {
            if ( predicate(a->array[i], direction, edge) ) {
                appendCGPathBoundaryPoints(b, a->array[i]);
            }
        }
    }
    return b->used;
}

NSUInteger filterCGPathBoundaryPointsForACorner(CGPathBoundaryPoints *a, BOOL (*predicate)(const CGPathBoundaryPoint item, CGPoint corner), CGPathBoundaryPoints *b, CGPoint corner) {
    if ( b->size > 0 ) {
        for ( size_t i = 0; i < a->used; i++ ) {
            if ( predicate(a->array[i], corner) ) {
                appendCGPathBoundaryPoints(b, a->array[i]);
            }
        }
    }
    return b->used;
}

BOOL checkCGPathBoundaryPointsAreUniqueForEdge(CGPathBoundaryPoints *a, CPTContourBorderDimensionDirection direction) {
    BOOL isUnique = YES;
    for ( size_t i = 0; i < a->used; i++ ) {
        for ( size_t j = 0; j < a->used; j++) {
            if ( i != j && ((a->array[i].point.x == a->array[j].point.x && (direction == CPTContourBorderDimensionDirectionYBackward || direction == CPTContourBorderDimensionDirectionYForward) ) || (a->array[i].point.y == a->array[j].point.y && (direction == CPTContourBorderDimensionDirectionXForward || direction == CPTContourBorderDimensionDirectionXBackward))) ) {
                isUnique = NO;
                break;
            }
        }
        if ( !isUnique ) {
            break;
        }
    }
    return isUnique;
}

void sortCGPathBoundaryPointsByPosition(CGPathBoundaryPoints *a) {
    qsort(a->array, a->used, sizeof(CGPathBoundaryPoint), compareCGPathBoundaryPointsByPosition);
}

void sortCGPathBoundaryPointsByBottomEdge(CGPathBoundaryPoints *a) {
    qsort(a->array, a->used, sizeof(CGPathBoundaryPoint), compareCGPathBoundaryPointsByBottomEdge);
}

void sortCGPathBoundaryPointsByRightEdge(CGPathBoundaryPoints *a) {
    qsort(a->array, a->used, sizeof(CGPathBoundaryPoint), compareCGPathBoundaryPointsByRightEdge);
}

void sortCGPathBoundaryPointsByTopEdge(CGPathBoundaryPoints *a) {
    qsort(a->array, a->used, sizeof(CGPathBoundaryPoint), compareCGPathBoundaryPointsByTopEdge);
}

void sortCGPathBoundaryPointsByLeftEdge(CGPathBoundaryPoints *a) {
    qsort(a->array, a->used, sizeof(CGPathBoundaryPoint), compareCGPathBoundaryPointsByLeftEdge);
}

int removeDuplicatesCGPathBoundaryPoints(CGPathBoundaryPoints *a) {
    int n = (int)a->used;
    int count = 0;
    if (n == 0 || n == 1) {
        return n;
    }
    CGPathBoundaryPoints temp;
    initCGPathBoundaryPoints(&temp, a->used);

    for (int i = 0; i < n; i++) {
        int j;
        for (j = 0; j < count; j++) {
            if ( CGPointEqualToPoint(a->array[i].point, temp.array[j].point)  ) {
                break;
            }
        }
        if (j == count) {
            appendCGPathBoundaryPoints(&temp, a->array[i]);
            count++;
        }
    }
    clearCGPathBoundaryPoints(a);
    for (int i = 0; i < (int)temp.used; i++) {
        appendCGPathBoundaryPoints(a, temp.array[i]);
    }
    freeCGPathBoundaryPoints(&temp);
    return (int)a->used;
}

void clearCGPathBoundaryPoints(CGPathBoundaryPoints *a) {
    a->used = 0;
}

void freeCGPathBoundaryPoints(CGPathBoundaryPoints *a) {
    free(a->array);
    a->array = NULL;
    a->used = a->size = 0;
}

#pragma mark -
#pragma mark ContourPoints

void initContourPoints(ContourPoints *a, size_t initialSize) {
    a->array = (CGPoint*)calloc(initialSize, sizeof(CGPoint));
    a->used = 0;
    a->size = initialSize;
}

void appendContourPoints(ContourPoints *a, CGPoint element) {
    // a->used is the number of used entries, because a->array[a->used++] updates a->used only *after* the array has been accessed.
    // Therefore a->used can go up to a->size
    if (a->used == a->size) {
        a->size *= 2;
        a->array = (CGPoint*)realloc(a->array, a->size * sizeof(CGPoint));
    }
    a->array[a->used++] = element;
}

// Function to reverse the array through pointers
void reverseContourPoints(ContourPoints *a) {
    // pointer1 pointing at the beginning of the array
    CGPoint *pointer1 = a->array;
    // pointer2 pointing at end of the array
    CGPoint*pointer2 = a->array + a->used - 1;
    while (pointer1 < pointer2) {
        swapPoints(pointer1, pointer2);
        pointer1++;
        pointer2--;
    }
}

void clearContourPoints(ContourPoints *a) {
    a->used = 0;
}

void freeContourPoints(ContourPoints *a) {
    free(a->array);
//    a->array = NULL;
    a->used = a->size = 0;
}

#pragma mark -
#pragma mark BorderIndex

BorderIndex initBorderIndex() {
    BorderIndex element;
    element.index = NSNotFound;
    element.extra = NSNotFound;
    element.borderdirection = CPTContourBorderDimensionDirectionNone;
    element.angle = 0;
    element.end = NO;
    element.used = NO;
    element.dummy = 0;
    return element;
}

#pragma mark -
#pragma mark BorderIndices

void initBorderIndices(BorderIndices *a, size_t initialSize) {
    a->array = (BorderIndex*)calloc(initialSize, sizeof(BorderIndex));
    a->used = 0;
    a->size = initialSize;
}

void appendBorderIndices(BorderIndices *a, BorderIndex element) {
    // a->used is the number of used entries, because a->array[a->used++] updates a->used only *after* the array has been accessed.
    // Therefore a->used can go up to a->size
    if (a->used == a->size) {
        a->size *= 2;
        a->array = (BorderIndex*)realloc(a->array, a->size * sizeof(BorderIndex));
    }
    a->array[a->used++] = element;
}

void insertBorderIndicesAtIndex(BorderIndices *a, BorderIndex element, size_t index) {
    if (a->used == a->size) {
        a->size *= 2;
        a->array = (BorderIndex*)realloc(a->array, a->size * sizeof(BorderIndex));
    }
    
    if ( index < a->used ) {
        for( NSInteger i = (NSInteger)a->used - 1; i >= (NSInteger)index; i-- ) {
            a->array[i + 1] =  a->array[i];
        }
        a->array[index] = element;
        a->used++;
    }
    else {
        appendBorderIndices(a, element);
    }
}

void removeBorderIndicesAtIndex(BorderIndices *a, size_t index) {
    size_t n = a->used;
    if ( index < n ) {
        for( size_t i = index+1; i < n; i++ ) {
            a->array[i-1] =  a->array[i];
        }
        a->used--;
    }
}

NSUInteger removeNextToDuplicatesBorderIndices(BorderIndices *a) {
    NSUInteger n = (NSUInteger)a->used;
    if (n == 0 || n == 1) {
        return n;
    }
    NSUInteger nextPosition, k;
    for ( NSUInteger i = 0, j = 1; i < a->used; i++, j++ ) {
        if ( j == n ) {
            j = 0;
        }
        if ( CGPointEqualToPoint(a->array[i].point, a->array[j].point) ) {
            NSUInteger *positionsForBorderStripIndex = (NSUInteger*)calloc(1, sizeof(NSUInteger));
            /*NSUInteger countPositionsForBorderStripIndex = */searchBorderIndicesForBorderStripIndex(a, a->array[i].index, &positionsForBorderStripIndex);
//            NSLog(@"countPositionsForBorderStripIndex: %ld", countPositionsForBorderStripIndex);
            nextPosition = searchBorderIndicesForNextBorderStripIndex(a, a->array[i].index);
            free(positionsForBorderStripIndex);
            if ( nextPosition > i ) {
                k = nextPosition + 1;
                if ( k == n ) {
                    k = 0;
                }
                if ( CGPointEqualToPoint(a->array[nextPosition].point, a->array[k].point) ) {
                    removeBorderIndicesAtIndex(a, k);
                    removeBorderIndicesAtIndex(a, j);
                }
            }
        }
    }
    
    return (NSUInteger)a->used;
}

void authenticateNextToDuplicatesBorderIndices(BorderIndices *a) {
    NSInteger nextPosition = NSNotFound, k = NSNotFound;
    for ( NSInteger i = 0, j = 1; i < (NSInteger)a->used; i++, j++ ) {
        if ( j == (NSInteger)a->used ) {
            j = 0;
        }
        a->array[i].extra = NSNotFound;
        if ( CGPointEqualToPoint(a->array[i].point, a->array[j].point) ) {
            NSUInteger *positionsForBorderStripIndex = (NSUInteger*)calloc(1, sizeof(NSUInteger));
            /*NSUInteger countPositionsForBorderStripIndex = */searchBorderIndicesForBorderStripIndex(a, a->array[i].index, &positionsForBorderStripIndex);
//            NSLog(@"countPositionsForBorderStripIndex: %ld", countPositionsForBorderStripIndex);
//            nextPosition = searchBorderIndicesForNextBorderStripIndex(a, a->array[i].index);
            nextPosition = (NSInteger)positionsForBorderStripIndex[1];
            free(positionsForBorderStripIndex);
            if ( nextPosition > i ) {
                k = nextPosition + 1;
                if ( k == (NSInteger)a->used ) {
                    k = 0;
                }
                if ( CGPointEqualToPoint(a->array[nextPosition].point, a->array[k].point) ) {
                    a->array[i].extra = (NSUInteger)nextPosition;
                    a->array[nextPosition].extra = (NSUInteger)i;
                    a->array[j].extra = (NSUInteger)k;
                    a->array[k].extra = (NSUInteger)j;
                }
                else {
                    k = nextPosition - 1;
                    if ( k == -1 ) {
                        k = (NSInteger)a->used - 1;
                    }
                    if ( CGPointEqualToPoint(a->array[nextPosition].point, a->array[k].point) ) {
                        a->array[i].extra = (NSUInteger)nextPosition;
                        a->array[nextPosition].extra = (NSUInteger)i;
                        a->array[j].extra = (NSUInteger)k;
                        a->array[k].extra = (NSUInteger)j;
                    }
                }
            }
        }
    }
}

void copyBorderIndices(BorderIndices *a, BorderIndices *b) {
    if ( a->size > 0 ) {
        for( NSUInteger i = 0; i < (NSUInteger)b->used; i++ ) {
            appendBorderIndices(a, b->array[i]);
        }
    }
}

void sortBorderIndicesWithExtraContours(BorderIndices *a) {
    BorderIndex element;
    for( NSUInteger i = 0, j = 1, k = (NSUInteger)a->used - 1; i < (NSUInteger)a->used; i++, j++, k++ ) {
        if ( j == a->used ) {
            j = 0;
        }
        if ( k == a->used ) {
            k = 0;
        }
        if ( CGPointEqualToPoint(a->array[i].point, a->array[j].point) ) {
            if ( !a->array[i].end && a->array[j].end ) {
                element = a->array[j];
                removeBorderIndicesAtIndex(a, (size_t)j);
                insertBorderIndicesAtIndex(a, element, (size_t)i);
                i++;
                j++;
                k++;
                if ( j == a->used ) {
                    j = 0;
                }
                if ( k == a->used ) {
                    k = 0;
                }
            }
        }
    }
}

void sortBorderIndicesByBorderDirection(BorderIndices *a, CPTContourBorderDimensionDirection borderDirection) {
    switch ( borderDirection ) {
        case CPTContourBorderDimensionDirectionXForward:
            qsort(a->array, a->used, sizeof(BorderIndex), compareBorderIndicesXForward);
            break;
        case CPTContourBorderDimensionDirectionYForward:
            qsort(a->array, a->used, sizeof(BorderIndex), compareBorderIndicesYForward);
            break;
        case CPTContourBorderDimensionDirectionXBackward:
            qsort(a->array, a->used, sizeof(BorderIndex), compareBorderIndicesXBackward);
            break;
        default:
            qsort(a->array, a->used, sizeof(BorderIndex), compareBorderIndicesYBackward);
            break;
    }
}

void sortBorderIndicesByAngle(BorderIndices * _Nonnull a) {
    qsort(a->array, a->used, sizeof(BorderIndex), compareBorderIndicesAngle);
}

NSUInteger searchBorderIndicesForBorderStripIndex(BorderIndices *a, NSUInteger index, NSUInteger **positions) {
//        NSAssert(positions != NULL, @"positions has no be allocated heap memory")
    if( *positions == NULL ) {
        *positions = (NSUInteger*)calloc(1, sizeof(NSUInteger));
    }
    NSUInteger j = 0;
    for ( size_t i = 0; i < a->used; i++ ) {
        if ( a->array[i].index == index ) {
            *(*positions + j) = (NSUInteger)i;
            j++;
            *positions = (NSUInteger*)realloc(*positions, ((size_t)j + 1) * sizeof(NSUInteger));
        }
    }
    return j;
}

NSUInteger searchBorderIndicesForNextBorderStripIndex(BorderIndices *a, NSUInteger index) {
    NSUInteger positions[2] = { NSNotFound, NSNotFound }, j = 0;
    for ( size_t i = 0; i < a->used; i++ ) {
        if ( a->array[i].index == index ) {
            if ( j < 2 ) {
                positions[j] = i;
            }
            j++;
        }
    }
//    if ( positions[1] >= (NSUInteger)a->used ) {
////        return a->array[0].index;
//        return NSNotFound;
//    }
//    else {
//        return a->array[positions[1] + 1].index;
//    }
    return positions[1];
}

NSUInteger searchBorderIndicesForPreviousBorderStripIndex(BorderIndices *a, NSUInteger index) {
    NSUInteger positions[2] = { NSNotFound, NSNotFound }, j = 0;
    for ( size_t i = 0; i < a->used; i++ ) {
        if ( a->array[i].index == index ) {
            if ( j < 2 ) {
                positions[j] = i;
            }
            j++;
        }
    }
//    if ( positions[0] >= (NSUInteger)a->used ) {
////        return a->array[0].index;
//        return NSNotFound;
//    }
//    else {
//        return a->array[positions[1] + 1].index;
//    }
    return positions[0];
}

NSUInteger searchBorderIndicesForCGPoint(BorderIndices *a, CGPoint point) {
    NSUInteger index = NSNotFound;
    for ( size_t i = 0; i < a->used; i++ ) {
        if ( CGPointEqualToPoint(point, a->array[i].point) ) {
            index = (NSUInteger)i;
            break;
        }
    }
    return index;
}

void reverseBorderIndices(BorderIndices *a, BorderIndices *b) {
    if ( b->size > 0 ) {
        for ( NSInteger i = (NSInteger)a->used - 1; i > -1; i-- ) {
            appendBorderIndices(b, a->array[i]);
        }
    }
}

void clearBorderIndices(BorderIndices *a) {
    a->used = 0;
}

void freeBorderIndices(BorderIndices *a) {
    free(a->array);
    a->array = NULL;
    a->used = a->size = 0;
}

int compareBorderIndicesXForward(const void *a, const void *b) {
    const BorderIndex *aO = (const BorderIndex*)a;
    const BorderIndex *bO = (const BorderIndex*)b;
    
    if (aO->point.x > bO->point.x) {
        return 1;
    }
    else if (aO->point.x < bO->point.x) {
        return -1;
    }
    else {
        if ( aO->borderdirection != CPTContourBorderDimensionDirectionXForward ) {
            return 1;
        }
        if ( (!aO->end && aO->index > bO->index) || (aO->end && aO->index < bO->index) ) {
            return 1;
        }
        else if ( (!aO->end && aO->index < bO->index) || (aO->end && aO->index > bO->index) ) {
            return -1;
        }
        else {
            return 0;
        }
    }
}

int compareBorderIndicesYForward(const void *a, const void *b) {
    const BorderIndex *aO = (const BorderIndex*)a;
    const BorderIndex *bO = (const BorderIndex*)b;
    
    if (aO->point.y > bO->point.y) {
        return 1;
    }
    else if (aO->point.y < bO->point.y) {
        return -1;
    }
    else {
        if ( aO->borderdirection != CPTContourBorderDimensionDirectionYForward ) {
            return 1;
        }
        if ( (!aO->end && aO->index > bO->index) || (aO->end && aO->index < bO->index) ) {
            return 1;
        }
        else if ( (!aO->end && aO->index < bO->index) || (aO->end && aO->index > bO->index) ) {
            return -1;
        }
        else {
            return 0;
        }
    }
}

int compareBorderIndicesXBackward(const void *a, const void *b) {
    const BorderIndex *aO = (const BorderIndex*)a;
    const BorderIndex *bO = (const BorderIndex*)b;
    
    if (aO->point.x < bO->point.x) {
        return 1;
    }
    else if (aO->point.x > bO->point.x) {
        return -1;
    }
    else {
        if ( aO->borderdirection != CPTContourBorderDimensionDirectionXBackward ) {
            return 1;
        }
        if ( (!aO->end && aO->index > bO->index) || (aO->end && aO->index < bO->index) ) {
            return 1;
        }
        else if ( (!aO->end && aO->index < bO->index) || (aO->end && aO->index > bO->index) ) {
            return -1;
        }
        else {
            return 0;
        }
    }
}

int compareBorderIndicesYBackward(const void *a, const void *b) {
    const BorderIndex *aO = (const BorderIndex*)a;
    const BorderIndex *bO = (const BorderIndex*)b;
    
    if (aO->point.y < bO->point.y) {
        return 1;
    }
    else if (aO->point.y > bO->point.y) {
        return -1;
    }
    else {
        if ( aO->borderdirection != CPTContourBorderDimensionDirectionYBackward ) {
            return 1;
        }
        if ( (!aO->end && aO->index > bO->index) || (aO->end && aO->index < bO->index) ) {
            return 1;
        }
        else if ( (!aO->end && aO->index < bO->index) || (aO->end && aO->index > bO->index) ) {
            return -1;
        }
        else {
            return 0;
        }
    }
}


int compareBorderIndicesAngle(const void *a, const void *b) {
    const BorderIndex *aO = (const BorderIndex*)a;
    const BorderIndex *bO = (const BorderIndex*)b;
    
    if (aO->angle < bO->angle) {
        return 1;
    }
    else if (aO->angle > bO->angle) {
        return -1;
    }
    else {
        if ( (!aO->end && aO->index > bO->index) || (aO->end && aO->index < bO->index) ) {
            return 1;
        }
        else if ( (!aO->end && aO->index < bO->index) || (aO->end && aO->index > bO->index) ) {
            return -1;
        }
        else {
            return 0;
        }
    }
}

#pragma mark -
#pragma mark Strip

Strip initStrip() {
    Strip element;
    element.startPoint = CGPointMake(-0.0, -0.0);
    element.endPoint = CGPointMake(-0.0, -0.0);
    element.index = NSNotFound;
    element.plane = NSNotFound;
    element.pStripList = NULL;
    element.startBorderdirection = CPTContourBorderDimensionDirectionNone;
    element.endBorderdirection = CPTContourBorderDimensionDirectionNone;
    element.reverse = 0;
    element.extra = 0;
    element.usedInExtra = 0;
    element.dummy = 0;
    return element;
}

#pragma mark -
#pragma mark Strips

void initStrips(Strips *a, size_t initialSize) {
    a->array = (Strip*)calloc(initialSize, sizeof(Strip));
    a->used = 0;
    a->size = initialSize;
}

void appendStrips(Strips *a, Strip element) {
    // a->used is the number of used entries, because a->array[a->used++] updates a->used only *after* the array has been accessed.
    // Therefore a->used can go up to a->size
    if (a->used == a->size) {
        a->size *= 2;
        a->array = (Strip*)realloc(a->array, a->size * sizeof(Strip));
    }
    a->array[a->used++] = element;
}

NSUInteger searchForStripForPlanes(Strips *a, NSUInteger plane1, NSUInteger plane2, NSUInteger exceptPosition) {
    NSUInteger foundPos = NSNotFound;
    for(size_t i = exceptPosition+1; i < a->used; i++) {
        if(plane1 == a->array[i].plane || (plane2 != NSNotFound && plane2 == a->array[i].plane)) {
            foundPos = (NSUInteger)i;
            break;
        }
    }
    return foundPos;
}

NSUInteger searchForStripIndicesForPlane(Strips *a, NSUInteger plane, NSUInteger** indices) {
    NSUInteger *pointerIndices = *indices;
    NSUInteger count = 0;
    for(size_t i = 0; i < a->used; i++) {
        if(plane == a->array[i].plane) {
            pointerIndices[count] = (NSUInteger)i;
            count++;
            pointerIndices = (NSUInteger*)realloc(pointerIndices, (size_t)(count + 1) * sizeof(NSUInteger));
        }
    }
    *indices = pointerIndices;
    return count;
}

NSUInteger searchForStripIndicesForPlanes(Strips *a, NSUInteger plane1, NSUInteger plane2, NSUInteger** indices) {
    NSUInteger *pointerIndices = *indices;
    NSUInteger count = 0;
    for(size_t i = 0; i < a->used; i++) {
        if(plane1 == a->array[i].plane || (plane2 != NSNotFound && plane2 == a->array[i].plane)) {
            pointerIndices[count] = (NSUInteger)i;
            count++;
            pointerIndices = (NSUInteger*)realloc(pointerIndices, (size_t)(count + 1) * sizeof(NSUInteger));
        }
    }
    *indices = pointerIndices;
    return count;
}

NSUInteger searchForPlanesWithinStrips(Strips *a, NSUInteger** planes) {
    NSUInteger count = 0;
    NSUInteger *pointerPlanes = *planes;
    Strips b;
    initStrips(&b, a->used);
    for(size_t i = 0; i < a->used; i++) {
        appendStrips(&b, a->array[i]);
    }
//    removeDuplicatesStrips(&b);
    sortStripsByPlane(&b);
    
    for(size_t i = 0; i < b.used; i++) {
        for(size_t j = i + 1; j < b.used; j++) {
            if ( b.array[i].plane == b.array[j].plane) {
                // delete the current position of the duplicate element
                for(size_t k = j; k < b.used - 1; k++) {
                    b.array[k] = b.array[k + 1];
                }
                // decrease the size of array after removing duplicate element
                b.used--;
               // if the position of the elements is changes, don't increase the index j
                j--;
            }
        }
    }
    pointerPlanes = (NSUInteger*)realloc(pointerPlanes, b.used * sizeof(NSUInteger));
    for(size_t i = 0; i < b.used; i++) {
        pointerPlanes[i] = b.array[i].plane;
    }
    count = b.used;
    *planes = pointerPlanes;
    freeStrips(&b);
    return count;
}

NSUInteger numberBorderIsoCurvesForStripForPlane(Strips *a, NSUInteger plane) {
    NSUInteger count = 0;
    for(size_t i = 0; i < a->used; i++) {
        if(plane == a->array[i].plane) {
            count++;
        }
    }
    return count;
}

/*
//void searchForStripForLowestAndHighestPlane(Strips *a, NSUInteger *lowestPlane,  NSUInteger *highestPlane) {
//    NSUInteger _lowestPlane = ULONG_MAX;
//    NSUInteger _highestPlane = 0;
//    for(size_t i = 0; i < a->used; i++) {
//        if ( a->array[i].plane < _lowestPlane ) {
//            _lowestPlane = a->array[i].plane;
//        }
//        if (  a->array[i].plane > _highestPlane ) {
//            _highestPlane = a->array[i].plane;
//        }
//    }
//    *lowestPlane = _lowestPlane;
//    *highestPlane = _highestPlane;
//}
  */

void sortStripsByBorderDirection(Strips *a, CPTContourBorderDimensionDirection startBorderdirection) {
    switch ( startBorderdirection ) {
        case CPTContourBorderDimensionDirectionXForward:
            qsort(a->array, a->used, sizeof(Strip), compareBorderStripsXForward);
            break;
        case CPTContourBorderDimensionDirectionYForward:
            qsort(a->array, a->used, sizeof(Strip), compareBorderStripsYForward);
            break;
        case CPTContourBorderDimensionDirectionXBackward:
            qsort(a->array, a->used, sizeof(Strip), compareBorderStripsXBackward);
            break;
        default:
            qsort(a->array, a->used, sizeof(Strip), compareBorderStripsYBackward);
            break;
    }
}

void sortStripsByPlane(Strips *a) {
    qsort(a->array, a->used, sizeof(Strip), compareBorderStripsPlanes);
}

void sortStripsIntoStartEndPointPositions(Strips *a, BorderIndices* indices) {
    
    BorderIndices borders[4];
    for(size_t i = 0; i < 4; i++) {
        initBorderIndices(&borders[i], 4);
    }
    
    for(size_t i = 0; i < a->used; i++) {
        BorderIndex element0 = initBorderIndex(), element1 = initBorderIndex();
        element0.index = i;
        element0.point = a->array[i].startPoint;
        element0.borderdirection = a->array[i].startBorderdirection;
        element0.end = NO;
        switch ( a->array[i].startBorderdirection ) {
            case CPTContourBorderDimensionDirectionXForward:
                appendBorderIndices(&borders[0], element0);
                break;
            case CPTContourBorderDimensionDirectionYForward:
                appendBorderIndices(&borders[1], element0);
                break;
            case CPTContourBorderDimensionDirectionXBackward:
                appendBorderIndices(&borders[2], element0);
                break;
            default:
                appendBorderIndices(&borders[3], element0);
                break;
        }
        element1.index = i;
        element1.point = a->array[i].endPoint;
        element1.borderdirection = a->array[i].endBorderdirection;
        element1.end = YES;
        switch ( a->array[i].endBorderdirection ) {
            case CPTContourBorderDimensionDirectionXForward:
                appendBorderIndices(&borders[0], element1);
                break;
            case CPTContourBorderDimensionDirectionYForward:
                appendBorderIndices(&borders[1], element1);
                break;
            case CPTContourBorderDimensionDirectionXBackward:
                appendBorderIndices(&borders[2], element1);
                break;
            default:
                appendBorderIndices(&borders[3], element1);
                break;
        }
        
    }
    for ( CPTContourBorderDimensionDirection i = 0; i < 4; i++ ) {
        sortBorderIndicesByBorderDirection(&borders[(NSUInteger)i], i);
        for ( NSUInteger j = 0; j < borders[(NSUInteger)i].used; j++ ) {
            appendBorderIndices(indices, borders[(NSUInteger)i].array[j]);
        }
    }
}

BOOL concatenateStrips(Strips *a, Strips b[], int n) {
    if ( a->size != 0 ) {
        for (int i = 0; i < n; i++) {
            for(int j = 0 ; j < (int)b[i].used; j++) {
                appendStrips(a, b[i].array[j]);
            }
        }
        return TRUE;
    }
    else {
        return FALSE;
    }
}

void removeStripsAtIndex(Strips *a, size_t index) {
    size_t n = a->used;
    if ( index < n ) {
        for( size_t i = index+1; i < n; i++ ) {
            a->array[i-1] =  a->array[i];
        }
        a->used--;
    }
}

int removeDuplicatesStrips(Strips *a) {
    int n = (int)a->used;
    int count = 0;
    if (n == 0 || n == 1) {
        return n;
    }
    Strips temp;
    initStrips(&temp, a->used);

    LineStripList *pStripList, *pTempStripList;
    LineStrip *pStrip, *pTempStrip;
    NSUInteger startIndex, endIndex, tempStartIndex, tempEndIndex;
    
    for (int i = 0; i < n; i++) {
        int j;
        for (j = 0; j < count; j++) {
            if ( a->array[i].plane == temp.array[j].plane ) {
                if( (pStripList = a->array[i].pStripList) != NULL && a->array[i].index < pStripList->used && (pTempStripList = temp.array[j].pStripList) != NULL && a->array[j].index < pTempStripList->used ) {
                    pStrip = &pStripList->array[a->array[i].index];
                    startIndex = pStrip->array[0];
                    endIndex = pStrip->array[pStrip->used - 1];
                    pTempStrip = &pTempStripList->array[a->array[j].index];
                    tempStartIndex = pTempStrip->array[0];
                    tempEndIndex = pTempStrip->array[pTempStrip->used - 1];
                
                    if( (startIndex == tempStartIndex && endIndex == tempEndIndex) || (startIndex == tempEndIndex && endIndex == tempStartIndex) ) {
                        break;
                    }
                }
                if( a->array[i].index == temp.array[j].index ) {
                    break;
                }
            }
        }
        if (j == count) {
            appendStrips(&temp, a->array[i]);
            count++;
        }
    }
    clearStrips(a);
    for (int i = 0; i < (int)temp.used; i++) {
        appendStrips(a, temp.array[i]);
    }
    freeStrips(&temp);
    return (int)a->used;
}

int removeDuplicatesStripsWithStartEndPointsPlaneSame(Strips *a) {
    int n = (int)a->used;
    int count = 0;
    if (n == 0 || n == 1) {
        return n;
    }
    Strips temp;
    initStrips(&temp, a->used);

    for (int i = 0; i < n; i++) {
        int j;
        for (j = 0; j < count; j++) {
            if ( a->array[i].plane == temp.array[j].plane ) {
                if( CGPointEqualToPoint(a->array[i].startPoint, temp.array[j].startPoint) && CGPointEqualToPoint(a->array[i].endPoint, temp.array[j].endPoint) && a->array[i].startBorderdirection == temp.array[j].startBorderdirection && a->array[i].endBorderdirection == temp.array[j].endBorderdirection ) {
                    break;
                }
            }
        }
        if (j == count) {
            appendStrips(&temp, a->array[i]);
            count++;
        }
    }
    clearStrips(a);
    for (int i = 0; i < (int)temp.used; i++) {
        appendStrips(a, temp.array[i]);
    }
    freeStrips(&temp);
    return (int)a->used;
}

void clearStrips(Strips *a) {
    a->used = 0;
}

void freeStrips(Strips *a) {
    free(a->array);
    a->array = NULL;
    a->used = a->size = 0;
}

int compareBorderStripsPlanes(const void *a, const void *b) {
    const Strip *aO = (const Strip*)a;
    const Strip *bO = (const Strip*)b;
    
    if (aO->plane > bO->plane) {
        return 1;
    }
    else if (aO->plane < bO->plane) {
        return -1;
    }
    else {
        return 0;
    }
}

int compareBorderStripsXForward(const void *a, const void *b) {
    const Strip *aO = (const Strip*)a;
    const Strip *bO = (const Strip*)b;
    
    if (aO->startPoint.x > bO->startPoint.x) {
        return 1;
    }
    else if (aO->startPoint.x < bO->startPoint.x) {
        return -1;
    }
    else {
        if ( aO->endBorderdirection != CPTContourBorderDimensionDirectionXForward ) {
            return 1;
        }
        return 0;
    }
}

int compareBorderStripsYForward(const void *a, const void *b) {
    const Strip *aO = (const Strip*)a;
    const Strip *bO = (const Strip*)b;
    
    if (aO->startPoint.y > bO->startPoint.y) {
        return 1;
    }
    else if (aO->startPoint.y < bO->startPoint.y) {
        return -1;
    }
    else {
        if ( aO->endBorderdirection != CPTContourBorderDimensionDirectionYForward ) {
            return 1;
        }
        return 0;
    }
}

int compareBorderStripsXBackward(const void *a, const void *b) {
    const Strip *aO = (const Strip*)a;
    const Strip *bO = (const Strip*)b;
    
    if (aO->startPoint.x < bO->startPoint.x) {
        return 1;
    }
    else if (aO->startPoint.x > bO->startPoint.x) {
        return -1;
    }
    else {
        if ( aO->endBorderdirection != CPTContourBorderDimensionDirectionXBackward ) {
            return 1;
        }
        return 0;
    }
}

int compareBorderStripsYBackward(const void *a, const void *b) {
    const Strip *aO = (const Strip*)a;
    const Strip *bO = (const Strip*)b;
    
    if (aO->startPoint.y < bO->startPoint.y) {
        return 1;
    }
    else if (aO->startPoint.y > bO->startPoint.y) {
        return -1;
    }
    else {
        if ( aO->endBorderdirection != CPTContourBorderDimensionDirectionYBackward ) {
            return 1;
        }
        return 0;
    }
}

#pragma mark -
#pragma mark Intersections

void initIntersections(Intersections *a, size_t initialSize) {
    a->array = (Intersection*)calloc(initialSize, sizeof(Intersection));
    a->used = 0;
    a->size = initialSize;
}

void appendIntersections(Intersections *a, Intersection element) {
    // a->used is the number of used entries, because a->array[a->used++] updates a->used only *after* the array has been accessed.
    // Therefore a->used can go up to a->size
    if (a->used == a->size) {
        a->size *= 2;
        a->array = (Intersection*)realloc(a->array, a->size * sizeof(Intersection));
    }
    a->array[a->used++] = element;
}

void copyIntersections(Intersections *a, Intersections *b) {
    clearIntersections(b);
    
    for ( size_t i = 0; i < a->used; i++ ) {
        appendIntersections(b, a->array[i]);
    }
}

void sortIntersectionsByPointXCoordinate(Intersections *a) {
    sortIntersectionsByPointIncreasingXCoordinate(a);
}

void sortIntersectionsByPointIncreasingXCoordinate(Intersections *a) {
    qsort(a->array, a->used, sizeof(Intersection), compareIntersectionsByPointIncreasingXCoordinate);
}

void sortIntersectionsByPointDecreasingXCoordinate(Intersections *a) {
    qsort(a->array, a->used, sizeof(Intersection), compareIntersectionsByPointDecreasingXCoordinate);
}

void sortIntersectionsByPointIncreasingYCoordinate(Intersections *a) {
    qsort(a->array, a->used, sizeof(Intersection), compareIntersectionsByPointIncreasingYCoordinate);
}

void sortIntersectionsByPointDecreasingYCoordinate(Intersections *a) {
    qsort(a->array, a->used, sizeof(Intersection), compareIntersectionsByPointDecreasingYCoordinate);
}

void sortIntersectionsByOrderAntiClockwiseFromBottomLeftCorner(Intersections *a, CGPoint* corners, CGFloat tolerance) {
    int n = (int)a->used;
    
    if ( n == 0 || n == 1 ) {
        return;
    }
    Intersections temp1, temp2;
    initIntersections(&temp1, (unsigned int)n);
    initIntersections(&temp2, (unsigned int)n);
    
    for (int i = 0; i < n; i++) {
        if ( fabs(a->array[i].point.y - corners[0].y) < tolerance ) {
            appendIntersections(&temp1, a->array[i]);
        }
    }
    sortIntersectionsByPointIncreasingXCoordinate(&temp1);
    for (int i = 0; i < (int)temp1.used; i++) {
        appendIntersections(&temp2, temp1.array[i]);
    }
    clearIntersections(&temp1);
    for (int i = 0; i < n; i++) {
        if ( fabs(a->array[i].point.x - corners[1].x) < tolerance ) {
            appendIntersections(&temp1, a->array[i]);
        }
    }
    sortIntersectionsByPointIncreasingYCoordinate(&temp1);
    for (int i = 0; i < (int)temp1.used; i++) {
        appendIntersections(&temp2, temp1.array[i]);
    }
    clearIntersections(&temp1);
    for (int i = 0; i < n; i++) {
        if ( fabs(a->array[i].point.y - corners[2].y) < tolerance ) {
            appendIntersections(&temp1, a->array[i]);
        }
    }
    sortIntersectionsByPointDecreasingXCoordinate(&temp1);
    for (int i = 0; i < (int)temp1.used; i++) {
        appendIntersections(&temp2, temp1.array[i]);
    }
    clearIntersections(&temp1);
    for (int i = 0; i < n; i++) {
        if ( fabs(a->array[i].point.x - corners[3].x) < tolerance ) {
            appendIntersections(&temp1, a->array[i]);
        }
    }
    sortIntersectionsByPointDecreasingYCoordinate(&temp1);
    for (int i = 0; i < (int)temp1.used; i++) {
        appendIntersections(&temp2, temp1.array[i]);
    }
    freeIntersections(&temp1);
    removeDuplicatesIntersections(&temp2, 0.01);
    clearIntersections(a);
    for (int i = 0; i < (int)temp2.used; i++) {
        appendIntersections(a, temp2.array[i]);
    }
    
    freeIntersections(&temp2);
}

NSUInteger containsIntersection(Intersections *a, Intersection intersection) {
    Intersection *item = (Intersection*)bsearch(&intersection, a->array, a->used, sizeof(Intersection), compareIntersection);
    if( item != NULL ) {
        return item->intersectionIndex;
    }
    else {
        return NSNotFound;
    }
}

NSUInteger searchForIndexIntersection(Intersections *a, NSUInteger intersectionIndex) {
    NSUInteger index = NSNotFound;
    for (NSUInteger i = 0; i < (NSUInteger)a->used; i++ ) {
        if ( intersectionIndex == a->array[i].intersectionIndex ) {
            index = i;
            break;
        }
    }
    return index;
}

NSUInteger searchForContoursIndexIntersection(Intersections *a, NSUInteger contourIndex) {
    NSUInteger index = NSNotFound;
    for (NSUInteger i = 0; i < (NSUInteger)a->used; i++ ) {
        if ( contourIndex == a->array[i].index || contourIndex == a->array[i].jndex ) {
            index = i;
            break;
        }
    }
    return index;
}

NSUInteger searchForPointIntersection(Intersections *a, CGPoint point, CGFloat tolerance) {
    NSUInteger index = NSNotFound;
    for (NSUInteger i = 0; i < (NSUInteger)a->used; i++ ) {
        if ( fabs(point.x - a->array[i].point.x) < tolerance && fabs(point.y - a->array[i].point.y) < tolerance ) {
            index = i;
            break;
        }
    }
    return index;
}

NSUInteger searchForIndexFromPointIntersection(Intersection *a, NSUInteger no, CGPoint point, CGFloat tolerance) {
    NSUInteger index = NSNotFound;
    for (NSUInteger i = 0; i < no; i++ ) {
        if ( fabs(point.x - a[i].point.x) < tolerance && fabs(point.y - a[i].point.y) < tolerance ) {
            index = i;
            break;
        }
    }
    return index;
}

void removeIntersectionsAtIndex(Intersections * _Nonnull a, size_t index) {
    size_t n = a->used;
    if ( index < n ) {
        for( size_t i = index + 1; i < n; i++ ) {
            a->array[i-1] =  a->array[i];
        }
        a->used--;
    }
}

NSUInteger removeDuplicatesIntersections(Intersections *a, CGFloat tolerance) {
    NSUInteger n = (NSUInteger)a->used;
    NSUInteger count = 0;
    if (n == 0 || n == 1) {
        return n;
    }
    Intersections temp;
    initIntersections(&temp, (unsigned int)n);

    for (NSUInteger i = 0; i < n; i++) {
        NSUInteger j;
        for (j = 0; j < count; j++) {
            if ( fabs(a->array[i].point.x - temp.array[j].point.x) <= tolerance && fabs(a->array[i].point.y - temp.array[j].point.y) <= tolerance ) {
//                a->array[i].point.x = (a->array[i].point.x + temp.array[j].point.x) / 2.0;
//                a->array[i].point.y = (a->array[i].point.y + temp.array[j].point.y) / 2.0;
                break;
            }
        }
        if (j == count) {
            appendIntersections(&temp, a->array[i]);
            count++;
        }
    }

    clearIntersections(a);
    for (NSUInteger i = 0; i < (NSUInteger)temp.used; i++) {
        appendIntersections(a, temp.array[i]);
    }
    freeIntersections(&temp);
    return (NSUInteger)a->used;
}

NSUInteger removeSimilarIntersections(Intersections *a, Intersections *b) {
    NSUInteger n = (NSUInteger)a->used;
    
    if (n == 0 || n == 1) {
        return n;
    }
    Intersections temp;
    initIntersections(&temp, (unsigned int)n);
    
    for (NSUInteger i = 0; i < n; i++) {
        Intersection *item = (Intersection*)bsearch(&(a->array[i]), b->array, b->used, sizeof(Intersection), compareIntersection);
        if ( item == NULL) {
            appendIntersections(&temp, a->array[i]);
        }
    }
     
    clearIntersections(a);
    for (NSUInteger i = 0; i < (NSUInteger)temp.used; i++) {
        appendIntersections(a, temp.array[i]);
    }
    freeIntersections(&temp);
    return (NSUInteger)a->used;
}

void closestKIntersections(Intersections* _Nonnull a, Intersection intersect/*, NSUInteger k*/) {
    comparisonPoint = intersect.point;
    qsort(a->array, a->used, sizeof(Intersection), compareKIntersection);
}

void clearIntersections(Intersections *a) {
    a->used = 0;
}

void freeIntersections(Intersections *a) {
    free(a->array);
    a->array = NULL;
    a->used = a->size = 0;
}

int compareIntersectionsByPointIncreasingXCoordinate(const void *a, const void *b) {
    const Intersection *aO = (const Intersection*)a;
    const Intersection *bO = (const Intersection*)b;
    
    if ( fabs(aO->point.x - bO->point.x) < 0.01 ) {
        return (int)(aO->point.y - bO->point.y);
    }
    else {
        return (int)(aO->point.x - bO->point.x);
    }
}

int compareIntersectionsByPointDecreasingXCoordinate(const void *a, const void *b) {
    const Intersection *aO = (const Intersection*)a;
    const Intersection *bO = (const Intersection*)b;
    
    if ( fabs(bO->point.x - aO->point.x) < 0.01 ) {
        return (int)(bO->point.y - aO->point.y);
    }
    else {
        return (int)(bO->point.x - aO->point.x);
    }
}

int compareIntersectionsByPointIncreasingYCoordinate(const void *a, const void *b) {
    const Intersection *aO = (const Intersection*)a;
    const Intersection *bO = (const Intersection*)b;
    
    if ( fabs(aO->point.y - bO->point.y) < 0.01 ) {
        return (int)(aO->point.x - bO->point.x);
    }
    else {
        return (int)(aO->point.y - bO->point.y);
    }
}

int compareIntersectionsByPointDecreasingYCoordinate(const void *a, const void *b) {
    const Intersection *aO = (const Intersection*)a;
    const Intersection *bO = (const Intersection*)b;
    
    if ( fabs(bO->point.y - aO->point.y) < 0.01 ) {
        return (int)(bO->point.x - aO->point.x);
    }
    else {
        return (int)(bO->point.y - aO->point.y);
    }
}

int compareIntersection(const void * a, const void * b) {
    const Intersection *aO = (const Intersection*)a;
    const Intersection *bO = (const Intersection*)b;

    if ( fabs(aO->point.x - bO->point.x) < 5.01 ) {
        if ( fabs(aO->point.y - bO->point.y ) < 5.01 ) {
            return 0;
        }
        else {
            return (int)(aO->point.y - bO->point.y);
        }
    }
    else {
        return (int)(aO->point.x - bO->point.x);
    }
}

int compareKIntersection(const void * a, const void * b) {
    const Intersection *aO = (const Intersection*)a;
    const Intersection *bO = (const Intersection*)b;
    
    CGFloat dist1 = dist(aO->point, comparisonPoint);
    CGFloat dist2 = dist(bO->point, comparisonPoint);
    return (int)(floor(dist1 - dist2));
}


#pragma mark -
#pragma mark Index_DistanceAngles

int compareNearestPointDistances(const void *a, const void *b);
int compareNearestPointDistancesAngles(const void *a, const void *b);
int compareNearestPointAngles(const void *a, const void *b);

int compareNearestPointDistances(const void *a, const void *b) {
    const Index_DistanceAngle *aO = (const Index_DistanceAngle*)a;
    const Index_DistanceAngle *bO = (const Index_DistanceAngle*)b;
    
    return (int)((aO->distance - bO->distance) * 100.0);
}

int compareNearestPointDistancesAngles(const void *a, const void *b) {
    const Index_DistanceAngle *aO = (const Index_DistanceAngle*)a;
    const Index_DistanceAngle *bO = (const Index_DistanceAngle*)b;
    
    if ( fabs(aO->distance - bO->distance) < 0.5 ) {  // give a tolerance on distance so that angle is determinant
        return (int)((aO->angle - bO->angle) * 100.0);
    }
    else {
        return (int)((aO->distance - bO->distance) * 100.0);
    }
}

int compareNearestPointAngles(const void *a, const void *b) {
    const Index_DistanceAngle *aO = (const Index_DistanceAngle*)a;
    const Index_DistanceAngle *bO = (const Index_DistanceAngle*)b;
    
    if ( aO->angle == bO->angle ) {
        return (int)((aO->distance - bO->distance) * 100.0);
    }
    else {
        return (int)((aO->angle - bO->angle) * 100.0);
    }
}

#pragma mark -
#pragma mark Centroids

void initCentroids(Centroids *a, size_t initialSize) {
    a->array = (Centroid*)calloc(initialSize, sizeof(Centroid));
    a->used = 0;
    a->size = initialSize;
}

void appendCentroids(Centroids *a, Centroid element) {
    // a->used is the number of used entries, because a->array[a->used++] updates a->used only *after* the array has been accessed.
    // Therefore a->used can go up to a->size
    if (a->used == a->size) {
        a->size *= 2;
        a->array = (Centroid*)realloc(a->array, a->size * sizeof(Centroid));
    }
    a->array[a->used++] = element;
}
       
void removeCentroidsElement(Centroids *a, Centroid element) {
    int n = (int)a->used;
    int index = 0;
    
    for( index = 0; index < n; index++ ) {
        if( CGPointEqualToPoint(element.centre, a->array[index].centre) && element.noVertices == a->array[index].noVertices ) {
            break;
        }
    }
    
    if ( index < n ) {
        for( int i = index+1; i < n; i++ ) {
            a->array[i-1] =  a->array[i];
        }
        a->used--;
    }
}

void clearCentroids(Centroids *a) {
    a->used = 0;
}

void freeCentroids(Centroids *a) {
    free(a->array);
    a->array = NULL;
    a->used = a->size = 0;
}


int compareCentroids(const void *a, const void *b) {
    const Centroid *aO = (const Centroid*)a;
    const Centroid *bO = (const Centroid*)b;
    
    /*if ( fabs(aO->centre.x - bO->centre.x) < 0.01 && fabs(aO->centre.y - bO->centre.y) < 0.01 ) {
        if ( CGRectEqualToRect(aO->boundingBox, bO->boundingBox) ) {
            return 0;
        }
        else if ( CGRectContainsRect(aO->boundingBox, bO->boundingBox)) {
            return 1;
        }
        else {
            return -1;
        }
    }
    else*/ if ( fabs(aO->centre.x - bO->centre.x) < 5.0 ) {
        if ( fabs(aO->centre.y - bO->centre.y ) < 5.0 ) {
            return 0;
        }
        else {
            return (int)(aO->centre.y - bO->centre.y);
        }
    }
    else {
        return (int)(aO->centre.x - bO->centre.x);
    }
}

int compareCentroidsByXCoordinate(const void * a, const void * b) {
    const Centroid *aO = (const Centroid*)a;
    const Centroid *bO = (const Centroid*)b;

    if ( fabs(aO->centre.x - bO->centre.x) < 0.01 ) {
        if ( fabs(aO->centre.y - bO->centre.y ) < 0.01 ) {
            return 0;
        }
        else {
            return (int)(aO->centre.y - bO->centre.y);
        }
    }
    else {
        return (int)(aO->centre.x - bO->centre.x);
    }
}

#pragma mark -
#pragma mark Lines

int compareLine(const void * a, const void * b);

void initLines(Lines *a, size_t initialSize) {
    a->array = (Line*)calloc(initialSize, sizeof(Line));
    a->used = 0;
    a->size = initialSize;
}

void appendLines(Lines *a, Line element) {
    // a->used is the number of used entries, because a->array[a->used++] updates a->used only *after* the array has been accessed.
    // Therefore a->used can go up to a->size
    if (a->used == a->size) {
        a->size *= 2;
        a->array = (Line*)realloc(a->array, a->size * sizeof(Line));
    }
    a->array[a->used++] = element;
}

int containsLines(Lines *a, Line line) {
    Line *item = (Line*)bsearch(&line, a->array, a->used, sizeof(Line), compareLine);
    if( item != NULL ) {
        return item->index0;
    }
    else {
        return -1;
    }
}
       
void clearLines(Lines *a) {
    a->used = 0;
}

void freeLines(Lines *a) {
    free(a->array);
    a->array = NULL;
    a->used = a->size = 0;
}

int compareLine(const void * a, const void * b) {
    const Line *aO = (const Line*)a;
    const Line *bO = (const Line*)b;
    
    if (aO->gradient == bO->gradient) {
        return (int)((aO->constant - bO->constant) * 100.0);
    }
    else {
        return (int)((aO->gradient - bO->gradient) * 100.0);
    }
}

#pragma mark -
#pragma mark CGPoints

int compareCGPoint(const void * a, const void * b) {
    const CGPoint *aO = (const CGPoint*)a;
    const CGPoint *bO = (const CGPoint*)b;

    if ( fabs(aO->x - bO->x) < 0.001 ) {
        return (int)(aO->y - bO->y);
    }
    else {
        return (int)(aO->x - bO->x);
    }
}

int compareCGPointsForSimpleClosedPath(const void * a, const void * b) {
    const CGPoint *aO = (const CGPoint*)a;
    const CGPoint *bO = (const CGPoint*)b;
  
    // Find orientation
    int o = orientation(pointSimpleClosedPath, *aO, *bO);
    if (o == 0) {
        return (dist(pointSimpleClosedPath, *bO) >= dist(pointSimpleClosedPath, *aO)) ? -1 : 1;
    }
    return (o == 2) ? -1 : 1;
}

  
// To find orientation of ordered triplet (p, q, r).
// The function returns following values
// 0 --> p, q and r are colinear
// 1 --> Clockwise
// 2 --> Counterclockwise
int orientation(CGPoint p, CGPoint q, CGPoint r) {
    CGFloat val = (q.y - p.y) * (r.x - q.x) - (q.x - p.x) * (r.y - q.y);
    if (fabs(val) < 0.01) return 0;  // colinear
    return (val > 0)? 1: 2; // clockwise or counterclock wise
}

BOOL CGPointEqualToPointWithTolerance(CGPoint point1, CGPoint point2, CGFloat tolerance) {
  return fabs(point1.x - point2.x) < tolerance && fabs(point1.y - point2.y) < tolerance;
}

#pragma mark -
#pragma mark double array

int findSmallestAbsoluteValueIndex(double *arr, int n) {
   /* We are assigning the first array element to
    * the temp variable and then we are comparing
    * all the array elements with the temp inside
    * loop and if the element is smaller than temp
    * then the temp value is replaced by that. This
    * way we always have the smallest value in temp.
    * Finally we are returning temp.
    */
    double temp = DBL_MAX;
    int index = 0;
    for( int i = 0; i < n; i++ ) {
        if(temp > fabs(arr[i])) {
            temp = fabs(arr[i]);
            index = i;
        }
    }
    return index;
}
