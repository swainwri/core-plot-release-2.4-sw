//
//  CPTContours.m
//  CorePlot
//
//  Created by Steve Wainwright on 25/11/2021.
//

#import "_CPTContours.h"

static long columnSize;
static long toleranceComparison;
bool compare_same_indices(const Indices *a, const Indices *b);
//int compare_closeby_indices(const void *a, const void *b);

// a binary predicate implemented as a function:
bool compare_same_indices(const Indices *a, const Indices *b) {
    return abs((int)a->jndex - (int)b->jndex) < toleranceComparison;
}

//int compare_closeby_indices(const void *_a, const void *_b) {
//    const Indices *a = (const Indices*)_a;
//    const Indices *b = (const Indices*)_b;
//    if (a->jndex == b->jndex && (((int)a->index - (int)a->jndex) / columnSize < ((int)b->index - (int)b->jndex) / columnSize || ((int)a->index - (int)a->jndex) % columnSize < ((int)b->index - (int)b->jndex) % columnSize) {
//        return 0;
//    }
//    else if (aO->startPoint.y > bO->startPoint.y) {
//        return -1;
//    }
//    else {
//        return 0;
//    }
////    return a->jndex == b->jndex && (((int)a->index - (int)a->jndex) / columnSize < ((int)b->index - (int)b->jndex) / columnSize || ((int)a->index - (int)a->jndex) % columnSize < ((int)b->index - (int)b->jndex) % columnSize);
//}

void initIndicesList(IndicesList *a, size_t initialSize);
void appendIndicesList(IndicesList *a, Indices element);
void insertIndicesListAtIndex(IndicesList *a, Indices element, size_t index);
void sortIndicesList(IndicesList *a, int (*compar)(const void*, const void*));
void uniqueIndicesList(IndicesList *a, bool (*compar)(const Indices*, const Indices*));
void clearIndicesList(IndicesList *a);
void freeIndicesList(IndicesList *a);

void initIndicesList(IndicesList *a, size_t initialSize) {
    a->array = (Indices*)calloc(initialSize, sizeof(Indices));
    a->used = 0;
    a->size = initialSize;
}

void appendIndicesList(IndicesList *a, Indices element) {
    // a->used is the number of used entries, because a->array[a->used++] updates a->used only *after* the array has been accessed.
    // Therefore a->used can go up to a->size
    if (a->used == a->size) {
        a->size *= 2;
        a->array = (Indices*)realloc(a->array, a->size * sizeof(Indices));
    }
    a->array[a->used++] = element;
}

void insertIndicesListAtIndex(IndicesList *a, Indices element, size_t index) {
    if (a->used == a->size) {
        a->size *= 2;
        a->array = (Indices*)realloc(a->array, a->size * sizeof(Indices));
    }
    
    size_t n = a->used;
    a->array[a->used++] = element;
    if ( index < a->used ) {
        // shift elements forward
        for( size_t i = n; i > index; i-- ) {
            a->array[i] =  a->array[i - 1];
        }
        a->array[index] = element;
    }
}

void sortIndicesList(IndicesList *a, int (*compar)(const void*, const void*)) {
    qsort(a->array, a->used, sizeof(IndicesList), compar);
}

void uniqueIndicesList(IndicesList *a, bool (*compar)(const Indices*, const Indices*)) {
    /*
    * Find duplicate elements in array
    */
    for(size_t i = 0; i < a->used; i++) {
        for(size_t j = i + 1; j < a->used; j++) {
            /* If any duplicate found */
            if(compar(&a->array[i], &a->array[j])) {
                /* Delete the current duplicate element */
                for(size_t k = j; k < a->used - 1; k++) {
                    a->array[k-1] = a->array[k];
                }
                /* Decrement size after removing duplicate element */
                a->used--;
                /* If shifting of elements occur then don't increment j */
                j--;
            }
        }
    }
}

void clearIndicesList(IndicesList *a) {
    a->used = 0;
}

void freeIndicesList(IndicesList *a) {
    free(a->array);
    a->array = NULL;
    a->used = a->size = 0;
}


@interface CPTContours()

-(BOOL) checkForCrossesOverOnStrip:(LineStrip*)pStrip Index:(NSUInteger)index Jndex:(NSUInteger)jndex StartIndex:(NSUInteger*)startIndex;

@end

@implementation CPTContours

static IndicesList intersectionIndicesList;
// array of line strips
static IsoCurvesList extraLineStripLists;


//////////////////////////////////////////////////////////////////////
// Construction/Destruction
//////////////////////////////////////////////////////////////////////
///


-(nonnull instancetype)initWithNoIsoCurve:(NSUInteger)newNoPlanes IsoCurveValues:(double*)newContourPlanes Limits:(double*)newLimits {
    self = [super initWithNoIsoCurve:newNoPlanes IsoCurveValues:newContourPlanes Limits:newLimits];
    
    return self;
}

-(void)dealloc {
    [self cleanMemory];
    
    if ( intersectionIndicesList.size > 0 ) {
        freeIndicesList(&intersectionIndicesList);
    }
    if( extraLineStripLists.size > 0 ) {
        LineStrip* pStrip;
        LineStripList *pStripList;
        // reseting lists
        for (NSUInteger i = 0; i < extraLineStripLists.size; i++) {
            pStripList = &extraLineStripLists.array[i];
            NSAssert(pStripList != NULL, @"LineStripList is NULL");
            for(NSUInteger j = 0; j < pStripList->used; j++) {
                pStrip = &pStripList->array[j];
                NSAssert(pStrip != NULL, @"LineStrip is NULL");
                freeLineStrip(pStrip);
            }
            freeLineStripList(pStripList);
        }
        freeIsoCurvesList(&extraLineStripLists);
    }
}

-(ContourPlanes*) getContourPlanes {
    return [super getContourPlanes];
}

-(IsoCurvesList*) getIsoCurvesLists {
    return [super getIsoCurvesLists];
}

-(IsoCurvesList*) getExtraIsoCurvesLists {
    if ( extraLineStripLists.size == 0) {
        initIsoCurvesList(&extraLineStripLists, [self getIsoCurvesLists]->used);
        for ( NSUInteger i = 0; i < [self getIsoCurvesLists]->used; i++) {
            LineStripList _extraLineStripList;
            initLineStripList(&_extraLineStripList, 8);
            appendIsoCurvesList(&extraLineStripLists, _extraLineStripList);
        }
    }
    return &extraLineStripLists;
}

-(LineStripList*) getExtraIsoCurvesListsAtIsoCurve:(NSUInteger)plane {
    if ( extraLineStripLists.size == 0) {
        initIsoCurvesList(&extraLineStripLists, [self getIsoCurvesLists]->used);
        for ( NSUInteger i = 0; i < [self getIsoCurvesLists]->used; i++) {
            LineStripList _extraLineStripList;
            initLineStripList(&_extraLineStripList, 8);
            appendIsoCurvesList(&extraLineStripLists, _extraLineStripList);
        }
    }
    return &extraLineStripLists.array[plane];
}

-(IndicesList*) getIntersectionIndicesList {
    if ( intersectionIndicesList.array == NULL ) {
        initIndicesList(&intersectionIndicesList, 8);
    }
    return &intersectionIndicesList;
}


-(BOOL) readPlanesFromDisk:(NSString*)filePath {
    BOOL OK = NO;
    
    [self initialiseMemory];
    
    NSMutableData *data = [[NSMutableData alloc] initWithContentsOfFile:filePath];
    if(data.length > 0) {
        NSUInteger index, noIsoCurves;
        LineStripList stripList;
        LineStrip strip;
        size_t stripLists_Size, strip_Size;;
        
        NSRange theRange = NSMakeRange(0, 0);
        NSUInteger counter = 0;
        theRange.location = counter;
        theRange.length = sizeof(size_t);
        counter+= theRange.length;
        [data getBytes:&noIsoCurves range:theRange];
        if ( noIsoCurves == [self getNoIsoCurves] ) {
            for(NSUInteger iPlane = 0; iPlane < [self getNoIsoCurves]; iPlane++) {
                theRange.location = counter;
                theRange.length = sizeof(size_t);
                counter+= theRange.length;
                
                [data getBytes:&stripLists_Size range:theRange];
                initLineStripList(&stripList, stripLists_Size);
                
//                NSLog(@"Number of strips : %ld\n", stripLists_Size);
                
                for(NSUInteger i = 0; i < stripLists_Size; i++) {
                    theRange.location = counter;
                    theRange.length = sizeof(size_t);
                    counter+= theRange.length;
                    [data getBytes:&strip_Size range:theRange];
                    initLineStrip(&strip, strip_Size);
                    
                    for(NSUInteger j = 0; j < strip_Size; j++) {
                        theRange.location = counter;
                        theRange.length = sizeof(NSUInteger);
                        counter+= theRange.length;
                        [data getBytes:&index range:theRange];
                        appendLineStrip(&strip, index);
                    }
                    appendLineStripList(&stripList, strip);
//                    NSLog(@"\t%ld\t%ld\t%ld\n", strip.used, strip.array[0], strip.array[strip.used-1]);
                }
//                NSLog(@"\n");
                if(&stripList.used > 0) {
                    [self setStripListAtPlane:iPlane StripList:&stripList];
                }
            }
            double deltaX, deltaY;
            theRange.location = counter;
            theRange.length = sizeof(size_t);
            counter+= theRange.length;
            [data getBytes:&deltaX range:theRange];
            [self setDX:deltaX];
            theRange.location = counter;
            theRange.length = sizeof(size_t);
            counter+= theRange.length;
            [data getBytes:&deltaY range:theRange];
            [self setDY:deltaY];
            theRange.location = counter;
            theRange.length = sizeof(size_t);
            counter+= theRange.length;
            NSUInteger noDiscontinuities;
            [data getBytes:&noDiscontinuities range:theRange];
            Discontinuities *pDiscontinuties = [self getDiscontinuities];
            if ( pDiscontinuties->size == 0 ) {
                initDiscontinuities(pDiscontinuties, noDiscontinuities);
            }
            else {
                clearDiscontinuities(pDiscontinuties);
            }
            for( NSUInteger i = 0; i < noDiscontinuities; i++ ) {
                theRange.location = counter;
                theRange.length = sizeof(NSUInteger);
                counter+= theRange.length;
                [data getBytes:&index range:theRange];
                appendDiscontinuities(pDiscontinuties, index);
            }
            OK = YES;
        }
    }
    return OK;
}

-(BOOL) writePlanesToDisk:(NSString*)filePath {
    
    NSMutableData *data = [[NSMutableData alloc] init];
    NSUInteger index, noIsoCurves = [self getNoIsoCurves];
    LineStrip* pStrip;

    [data appendBytes:&noIsoCurves length:(NSUInteger)sizeof(size_t)];
    for(NSUInteger iPlane = 0; iPlane < noIsoCurves; iPlane++) {
        LineStripList* pStripList = [self getStripListForIsoCurve:iPlane];
        [data appendBytes:&pStripList->used length:(NSUInteger)sizeof(size_t)];
        if ( pStripList->used > 0 ) {
            for (NSUInteger pos = 0; pos < pStripList->used; pos++) {
                pStrip = &pStripList->array[pos];
                NSAssert(pStrip, @"pStrip is null");
                [data appendBytes:&pStrip->used length:(NSUInteger)sizeof(size_t)];
                if ( pStrip->used > 0 ) {
                    for (NSUInteger pos2 = 0; pos2 < pStrip->used; pos2++) {
                        index = pStrip->array[pos2];
                        [data appendBytes:&index length:(NSUInteger)sizeof(NSUInteger)];
                    }
                }
            }
        }
    }
    double delta = [self getDX];
    [data appendBytes:&delta length:(NSUInteger)sizeof(double)];
    delta = [self getDY];
    [data appendBytes:&delta length:(NSUInteger)sizeof(double)];
    
    [data appendBytes:&[self getDiscontinuities]->used length:(NSUInteger)sizeof(size_t)];
    for( NSUInteger i = 0; i < [self getDiscontinuities]->used; i++ ) {
        [data appendBytes:&[self getDiscontinuities]->array[i] length:(NSUInteger)sizeof(NSUInteger)];
    }
    
    BOOL OK = [data writeToFile:filePath atomically:YES];
    return OK;
}

-(void) intersectionsWithAnotherList:(LineStrip*)pStrip0 Other:(LineStrip*)pStrip1 Tolerance:(NSUInteger)tolerance {
    
    if ( intersectionIndicesList.size > 0 ) {
        clearIndicesList(&intersectionIndicesList);
    }
    else {
        initIndicesList(&intersectionIndicesList, 8);
    }
    Indices indices;
    NSUInteger foundPos = 0;
    NSUInteger columnMutliplier =  [self getNoColumnsSecondaryGrid] + 1;
    NSUInteger x, y, layer, leg, iteration;
    toleranceComparison = (long)tolerance;
    columnSize = (long)[self getNoColumnsSecondaryGrid] + 1;
    // if the lists are the same check for overlap
    if ( pStrip0 == pStrip1) {  // if the lists are the same check for overlap
        // first check duplicates
        for(NSUInteger pos0 = 0; pos0 < pStrip0->used; pos0++) {
            for(NSUInteger pos1 = 0; pos1 < pStrip1->used; pos1++) {
                if( pStrip0->array[pos0] == pStrip1->array[pos1] ) {
                    if( pos0 != pos1 ) {
                        indices.index = pos0;
                        indices.jndex = pos0;
                        insertIndicesListAtIndex(&intersectionIndicesList, indices, 0);
                    }
                }
            }
        }
        uniqueIndicesList(&intersectionIndicesList, compare_same_indices);
        
//        unsigned int testIndex1, row, row1, col, col1;
//        for ( pos = pStrip0->begin(); pos != pStrip0->end(); pos++ ) {
//            testIndex = *pos;
//            row = testIndex / (columnMutliplier+1);
//            col = testIndex % (columnMutliplier+1);
//            for ( CLineStrip::reverse_iterator pos1 = pStrip1->rbegin(); pos1 != pStrip1->rend(); ++pos1 ) { //
//                testIndex1 = *pos1;
//                row1 = testIndex1 / (columnMutliplier+1);
//                col1 = testIndex1 % (columnMutliplier+1);
//                if ( row >= row1 - tolerance / 2 && row <= row1 + tolerance / 2  && col >= col1 - tolerance / 2 && col <= col1 + tolerance / 2 ) {
//                    index = testIndex;
//                    *jndex = testIndex;
//                    found = true;
//                    intersectionIndices->insert(intersectionIndices->begin(), index);
//                    break;
//                }
//            }
////            if ( found ) {
////                break;
////            }
//        }
    }
    else { // if lists not the same, search for intersections with a tolerance
        NSUInteger testIndex, startPos = 0;
        double weldDist = tolerance * sqrt(pow([self getDX], 2.0) + pow([self getDY], 2.0));
        for ( NSUInteger pos = 0; pos < pStrip0->used; pos++ ) {
            testIndex = pStrip0->array[pos];
            x = 0;
            y = 0;
            layer = 1;
            leg = 0;
            iteration = 0;
            startPos = 0;

            while ( iteration < tolerance * tolerance ) {
                if((foundPos = searchForLineStripIndexForElement(pStrip1, testIndex + x + y * columnMutliplier, startPos)) != NSNotFound && (NSUInteger)labs((NSInteger)testIndex - (NSInteger)pStrip1->array[foundPos]) < tolerance && sqrt(pow([self getXAt:testIndex] - [self getXAt:pStrip1->array[foundPos]], 2.0) + pow([self getYAt:testIndex] - [self getYAt:pStrip1->array[foundPos]], 2.0)) < weldDist ) {
                    indices.index = testIndex;
                    indices.jndex = pStrip1->array[foundPos];
                    insertIndicesListAtIndex(&intersectionIndicesList, indices, 0);
//                    std::cout << iteration << "  " << x << "  " << y << "  " << *foundPos << "\n";
                    break;
                }
                else if ( foundPos == NSNotFound ) {
                    startPos = 0;
                }
                iteration++;
                if ( leg == 0 ) {
                    x++;
                    if ( x == layer ) {
                        leg++;
                    }
                }
                else if ( leg == 1 ) {
                    y++;
                    if ( y == layer) {
                        leg++;
                    }
                }
                else if ( leg == 2 ) {
                    x--;
                    if ( -x == layer ) {
                        leg++;
                    }
                }
                else if ( leg == 3 ) {
                    y--;
                    if ( -y == layer ) {
                        leg = 0;
                        layer++;
                    }
                }
            }
        }
    }
    
    if ( intersectionIndicesList.used > 1) {
//        sortIndicesList(&intersectionIndicesList, compare_closeby_indices);
        uniqueIndicesList(&intersectionIndicesList, compare_same_indices);
    }
}

-(void) intersectionsWithAnotherListOrLimits:(LineStrip*)pStrip0 Other:(LineStrip*)pStrip1 Tolerance:(NSUInteger)tolerance {
    
    if ( intersectionIndicesList.size > 0 ) {
        clearIndicesList(&intersectionIndicesList);
    }
    else {
        initIndicesList(&intersectionIndicesList, 8);
    }
    Indices indices;
    NSUInteger columnMutliplier = [self getNoColumnsSecondaryGrid] + 1;
//    unsigned int testIndex;
    NSUInteger x, y, layer, leg, iteration;
    
    toleranceComparison = (long)tolerance;
    columnSize = (long)[self getNoColumnsSecondaryGrid] + 1;
    // if the lists are the same check for overlap
    if ( pStrip0 == pStrip1) {  // if the lists are the same check for overlap
        // first check duplicates
        // first check duplicates
        for(NSUInteger pos0 = 0; pos0 < pStrip0->used; pos0++) {
            for(NSUInteger pos1 = 0; pos1 < pStrip1->used; pos1++) {
                if( pStrip0->array[pos0] == pStrip1->array[pos1] ) {
                    if( pos0 != pos1 ) {
                        indices.index = pos0;
                        indices.jndex = pos0;
                        insertIndicesListAtIndex(&intersectionIndicesList, indices, 0);
                    }
                }
            }
        }
        uniqueIndicesList(&intersectionIndicesList, compare_same_indices);
        
//        unsigned int testIndex1, row, row1, col, col1;
//        for ( pos = pStrip0->begin(); pos != pStrip0->end(); pos++ ) {
//            testIndex = *pos;
//            row = testIndex / (columnMutliplier+1);
//            col = testIndex % (columnMutliplier+1);
//            for ( CLineStrip::reverse_iterator pos1 = pStrip1->rbegin(); pos1 != pStrip1->rend(); ++pos1 ) { //
//                testIndex1 = *pos1;
//                row1 = testIndex1 / (columnMutliplier+1);
//                col1 = testIndex1 % (columnMutliplier+1);
//                if ( row >= row1 - tolerance / 2 && row <= row1 + tolerance / 2  && col >= col1 - tolerance / 2 && col <= col1 + tolerance / 2 ) {
//                    index = testIndex;
//                    *jndex = testIndex;
//                    found = true;
//                    intersectionIndices->insert(intersectionIndices->begin(), index);
//                    break;
//                }
//            }
////            if ( found ) {
////                break;
////            }
//        }
    }
    else { // if lists not the same, search for intersections with a tolerance
        for ( NSUInteger pos = 0; pos < pStrip0->used; pos++ ) {
            NSUInteger testIndex = pStrip0->array[pos];
            x = 0;
            y = 0;
            layer = 1;
            leg = 0;
            iteration = 0;
            NSUInteger foundPos = 0;
            while ( iteration < tolerance * tolerance ) {
                if((foundPos = searchForLineStripIndexForElement(pStrip1, testIndex + x + y * columnMutliplier, foundPos)) != NSNotFound && (NSUInteger)labs((NSInteger)testIndex - (NSInteger)pStrip1->array[foundPos]) < tolerance) {
                    indices.index = testIndex;
                    indices.jndex = pStrip0->array[foundPos];
                    insertIndicesListAtIndex(&intersectionIndicesList, indices, 0);
//                    std::cout << iteration << "  " << x << "  " << y << "  " << *foundPos << "\n";
                    break;
                }
    
                iteration++;
                if ( leg == 0 ) {
                    x++;
                    if ( x == layer ) {
                        leg++;
                    }
                }
                else if ( leg == 1 ) {
                    y++;
                    if ( y == layer) {
                        leg++;
                    }
                }
                else if ( leg == 2 ) {
                    x--;
                    if ( -x == layer ) {
                        leg++;
                    }
                }
                else if ( leg == 3 ) {
                    y--;
                    if ( -y == layer ) {
                        leg = 0;
                        layer++;
                    }
                }
            }
        }
    }
    
    if ( pStrip0->array[0] != pStrip0->array[pStrip0->used-1]) {
        indices.index = pStrip0->array[0];
        indices.jndex = pStrip0->array[0];
        insertIndicesListAtIndex(&intersectionIndicesList, indices, 0);
        indices.index = pStrip0->array[pStrip0->used-1];
        indices.jndex = pStrip0->array[pStrip0->used-1];
        insertIndicesListAtIndex(&intersectionIndicesList, indices, 0);
    }
//    sortIndicesList(&intersectionIndicesList, compare_closeby_indices);
    uniqueIndicesList(&intersectionIndicesList, compare_same_indices);
}

-(BOOL) addIndicesInNewLineStripToLineStripList:(LineStripList*)pStripList Indices:(NSUInteger*)indices NoIndices:(NSUInteger)noIndices {
    
    NSAssert(pStripList, @"pStripList is nil");
    
    BOOL OK = NO;
    for(NSUInteger iPlane = 0; iPlane < [self getNoIsoCurves]; iPlane++) {
        if ( pStripList == [self getStripListForIsoCurve:iPlane] ) {
            OK = YES;
            break;
        }
    }
    if ( OK ) {
        LineStrip strip;
        initLineStrip(&strip, noIndices);
        for(NSUInteger i = 0; i < noIndices; i++) {
            appendLineStrip(&strip, indices[i]);
        }
        appendLineStripList(pStripList, strip);
        return YES;
    }
    else {
        return NO;
    }
}

-(BOOL) add2StripsToIntersectionPtToLineStripList:(LineStripList*)pStripList Strip0:(LineStrip*)pStrip0 Strip1:(LineStrip*)pStrip1 Index:(NSUInteger)index Jndex:(NSUInteger)jndex {
    NSAssert(pStripList, @"pStripList is nil");
    BOOL OK = NO;
    for(NSUInteger iPlane = 0; iPlane < [self getNoIsoCurves]; iPlane++) {
        if ( pStripList == [self getStripListForIsoCurve:iPlane] ) {
            OK = YES;
            break;
        }
    }
    if ( OK ) {
        LineStrip strip;
        initLineStrip(&strip, 8);
        
        for (NSUInteger pos0 = 0; pos0 < pStrip0->used; pos0++ ) {
            appendLineStrip(&strip, pStrip0->array[pos0]);
            if (  pStrip0->array[pos0] == jndex ) {
                break;
            }
        }
        NSUInteger foundPos = 0;
        if((foundPos = searchForLineStripIndexForElement(pStrip1, index, foundPos)) != NSNotFound) {
            if (index == jndex) {
                foundPos++;
            }
            for (NSUInteger pos1 = foundPos; pos1 < pStrip1->used; pos1++ ) {
                appendLineStrip(&strip, pStrip1->array[pos1]);
            }
        }
        appendLineStripList(pStripList, strip);
        return YES;
    }
    else {
        return NO;
    }
}

-(BOOL) createNPointShapeFromIntersectionPtToLineStripList:(LineStripList*)pStripList striplist1:(LineStripList*)pStrips0 striplist2:(LineStripList*)pStrips1 indices:(NSUInteger*)indexs jndices:(NSUInteger*)jndexs NPoints:(NSUInteger)N  isoCurve:(NSUInteger)plane {
    NSAssert(pStripList, @"pStripList is null)");
    NSAssert(N > 1, @"Number of points has to be at least 2 for a triangle!");
    BOOL OK = NO;
    if( pStripList == [self getExtraIsoCurvesListsAtIsoCurve:plane] ) { // first check extra LineStripList
        OK = YES;
    }
    else {
        for(NSUInteger iPlane = 0; iPlane < [self getNoIsoCurves]; iPlane++) {
            if ( pStripList == [self getStripListForIsoCurve:iPlane] ) {
                OK = YES;
                break;
            }
        }
    }

    if ( OK ) {
        LineStrip newStrip;
        initLineStrip(&newStrip, 8);
        NSUInteger posStart = 0, posEnd = 0, posEnd1 = 0, posEnd2 = 0;
        LineStrip *pStrip = NULL;
        NSUInteger counter0, counter1;
        BOOL useStrips, crossesover = NO;   // the contour crosses over itself
        
        for ( NSUInteger i = 0, j = 1; i < N; i++, j++ ) {
            useStrips = YES;
            if ( j == N ) {
                j = 0;
            }
            if ( pStrips0->array[i].used != 0 && pStrips1->array[i].used != 0 ) {
                // check which of intersecting strips contains both corner indexes
                if((posStart = searchForLineStripIndexForElement(&pStrips0->array[i], indexs[i], posStart)) != NSNotFound && ((posEnd1 = searchForLineStripIndexForElement(&pStrips0->array[i], indexs[j], posEnd1)) != NSNotFound || (posEnd2 = searchForLineStripIndexForElement(&pStrips0->array[i], jndexs[j], posEnd2)) != NSNotFound)) {
                    if(searchForLineStripIndexForElement(&newStrip, indexs[i], 0) != NSNotFound && (searchForLineStripIndexForElement(&newStrip, indexs[j], 0) != NSNotFound || searchForLineStripIndexForElement(&newStrip, jndexs[j], 0) != NSNotFound)) {
                        continue;
                    }
                    pStrip = &pStrips0->array[i];
                    if(posEnd1 < pStrips0->array[i].used) {
                        crossesover = [self checkForCrossesOverOnStrip:pStrip Index:indexs[i] Jndex:indexs[j] StartIndex:&posStart];
                        posEnd = posEnd1;
                    }
                    else {
                        crossesover = [self checkForCrossesOverOnStrip:pStrip Index:indexs[j] Jndex:indexs[j] StartIndex:&posStart];
                        posEnd = posEnd2;
                    }
                }
                else if((posStart = searchForLineStripIndexForElement(&pStrips0->array[i], jndexs[i], posStart)) != NSNotFound && ((posEnd1 = searchForLineStripIndexForElement(&pStrips0->array[i], jndexs[j], posEnd1)) != NSNotFound || (posEnd2 = searchForLineStripIndexForElement(&pStrips0->array[i], indexs[j], posEnd2)) != NSNotFound))  {
                    if(searchForLineStripIndexForElement(&newStrip, jndexs[i], 0) != NSNotFound && (searchForLineStripIndexForElement(&newStrip, jndexs[j], 0) != NSNotFound || searchForLineStripIndexForElement(&newStrip, indexs[j], 0) != NSNotFound)) {
                        continue;
                    }
                    pStrip = &pStrips0->array[i];
                    if(posEnd1 < pStrips0[i].used) {
                        crossesover = [self checkForCrossesOverOnStrip:pStrip Index:jndexs[i] Jndex:jndexs[j] StartIndex:&posStart];
                        posEnd = posEnd1;
                    }
                    else {
                        crossesover = [self checkForCrossesOverOnStrip:pStrip Index:jndexs[j] Jndex:indexs[j] StartIndex:&posStart];
                        posEnd = posEnd2;
                    }
                }
                else if((posStart = searchForLineStripIndexForElement(&pStrips1->array[i], indexs[i], posStart)) != NSNotFound && ((posEnd1 = searchForLineStripIndexForElement(&pStrips1->array[i], indexs[j], posEnd1)) != NSNotFound || (posEnd2 = searchForLineStripIndexForElement(&pStrips1->array[i], jndexs[j], posEnd2)) != NSNotFound)) {
                    if(searchForLineStripIndexForElement(&newStrip, indexs[i], 0) != NSNotFound && (searchForLineStripIndexForElement(&newStrip, indexs[j], 0) != NSNotFound || searchForLineStripIndexForElement(&newStrip, jndexs[j], 0) != NSNotFound)) {
                        continue;
                    }
                    pStrip = &pStrips1->array[i];
                    if(posEnd1 < pStrips0->array[i].used) {
                        crossesover = [self checkForCrossesOverOnStrip:pStrip Index:indexs[i] Jndex:indexs[j] StartIndex:&posStart];
                        posEnd = posEnd1;
                    }
                    else {
                        crossesover = [self checkForCrossesOverOnStrip:pStrip Index:indexs[j] Jndex:jndexs[j] StartIndex:&posStart];
                        posEnd = posEnd2;
                    }
                }
                else if((posStart = searchForLineStripIndexForElement(&pStrips1->array[i], jndexs[i], posStart)) != NSNotFound && ((posEnd1 = searchForLineStripIndexForElement(&pStrips1->array[i], jndexs[j], posEnd1)) != NSNotFound || (posEnd2 = searchForLineStripIndexForElement(&pStrips1->array[i], indexs[j], posEnd2)) != NSNotFound)) {
                    if(searchForLineStripIndexForElement(&newStrip, jndexs[i], 0) != NSNotFound && (searchForLineStripIndexForElement(&newStrip, jndexs[j], 0) != NSNotFound || searchForLineStripIndexForElement(&newStrip, indexs[j], 0) != NSNotFound)) {
                        continue;
                    }
                    pStrip = &pStrips1->array[i];
                    if(posEnd1 < pStrips0[i].used) {
                        crossesover = [self checkForCrossesOverOnStrip:pStrip Index:jndexs[i] Jndex:jndexs[j] StartIndex:&posStart];
                        posEnd = posEnd1;
                    }
                    else {
                        crossesover = [self checkForCrossesOverOnStrip:pStrip Index:jndexs[j] Jndex:indexs[j] StartIndex:&posStart];
                        posEnd = posEnd2;
                    }
                }
                else if(searchForLineStripIndexForElement(&newStrip, indexs[i], 0) != NSNotFound && searchForLineStripIndexForElement(&newStrip, indexs[j], 0) != NSNotFound) {
                    continue;
                }
                else if(searchForLineStripIndexForElement(&newStrip, jndexs[i], 0) != NSNotFound && searchForLineStripIndexForElement(&newStrip, jndexs[j], 0) != NSNotFound) {
                    continue;
                }
                else {
                    if ( !crossesover ) {
                        useStrips = NO;
                        if ( newStrip.used == 0 || newStrip.array[newStrip.used-1] != indexs[i] ) {
                            appendLineStrip(&newStrip, indexs[i]);
                        }
                    }
                }
                
                if ( useStrips ) {
                    counter0 = posStart;
                    counter1 = posEnd;
                    
                    // make sure we order the new strip properly, since counter0 & counter1 tells us how far into strip is start and end corners
                    if ( counter1 < counter0 ) {
                        if ( i > 0 && newStrip.used > 1 ) {
                            removeLineStripAtIndex(&newStrip, newStrip.used - 1);
                        }
                        for ( NSInteger pos = (NSInteger)posStart; pos >= (NSInteger)posEnd; pos-- ) {
                            appendLineStrip(&newStrip, pStrip->array[pos]);
                        }
                    }
                    else {
                        if ( i > 0 && newStrip.used > 1 ) {
                            removeLineStripAtIndex(&newStrip, newStrip.used - 1);
                        }
                        for ( NSUInteger pos = posStart; pos < posEnd; pos++ ) {
                            appendLineStrip(&newStrip, pStrip->array[pos]);
                        }
                    }
                }
            }
            else if ( pStrips0->array[i].used != 0 || pStrips1->array[i].used != 0 ) {
                if ( pStrips0->array[i].used > 0 ) {
                    pStrip = &pStrips0->array[i];
                }
                else {
                    pStrip = &pStrips1->array[i];
                }
                if( (posStart = searchForLineStripIndexForElement(pStrip, indexs[i], posStart)) != NSNotFound && (posEnd = searchForLineStripIndexForElement(pStrip, indexs[j], posEnd)) != NSNotFound) {
                    if(searchForLineStripIndexForElement(&newStrip, indexs[i], 0) != NSNotFound && searchForLineStripIndexForElement(&newStrip, indexs[j], 0) != NSNotFound) {
                        continue;
                    }
                }
                else if( (posStart = searchForLineStripIndexForElement(pStrip, jndexs[i], posStart)) != NSNotFound && (posEnd = searchForLineStripIndexForElement(pStrip, jndexs[j], posEnd)) != NSNotFound) {
                    if(searchForLineStripIndexForElement(&newStrip, jndexs[i], 0) != NSNotFound && searchForLineStripIndexForElement(&newStrip, jndexs[j], 0) != NSNotFound) {
                        continue;
                    }
                }
                else {
                    useStrips = NO;
                    if( newStrip.used == 0 || newStrip.array[newStrip.used-1] != indexs[i] ) {
                        appendLineStrip(&newStrip, indexs[i]);
                    }
                }
                
                if ( useStrips ) {
                    counter0 = posStart;
                    counter1 = posEnd;
                    
                    // make sure we order the new strip properly, since counter0 & counter1 tells us how far into strip is start and end corners
                    if ( counter1 < counter0 ) {
                        if ( i > 0 && newStrip.used > 1 ) {
                            removeLineStripAtIndex(&newStrip, newStrip.used - 1);
                        }
                        for ( NSInteger pos = (NSInteger)posStart; pos >= (NSInteger)posEnd; pos-- ) {
                            appendLineStrip(&newStrip, pStrip->array[pos]);
                        }
                    }
                    else {
                        if ( i > 0 && newStrip.used > 1 ) {
                            removeLineStripAtIndex(&newStrip, newStrip.used - 1);
                        }
                        for ( NSUInteger pos = posStart; pos < posEnd; pos++ ) {
                            appendLineStrip(&newStrip, pStrip->array[pos]);
                        }
                    }
                }
            }
            else {
                if ( newStrip.used == 0 || newStrip.array[newStrip.used-1] != indexs[i] ) {
                    appendLineStrip(&newStrip, indexs[i]);
                }
            }
            if ( crossesover ) {
                break;
            }
//            if( i == 0 ) {
//                firstIndex = pNewStrip->front();
//            }
        }
//        if ( !crossesover ) {
//            pNewStrip->insert(pNewStrip->end(), firstIndex);
//        }
        appendLineStripList(pStripList, newStrip);
    
        return OK;
    }
    else {
        return FALSE;
    }
}

-(BOOL) addLineStripToLineStripList:(LineStripList*)pStripList lineStrip:(LineStrip*)pStrip isoCurve:(NSUInteger)plane {
    NSAssert(pStripList, @"pStripList is null)");
    NSAssert(pStrip->used > 1, @"Number of points has to be at least 2 for a triangle!");
    BOOL OK = NO;
    if( pStripList == [self getExtraIsoCurvesListsAtIsoCurve:plane] ) { // first check extra LineStripList
        OK = YES;
    }
    else {
        for(NSUInteger iPlane = 0; iPlane < [self getNoIsoCurves]; iPlane++) {
            if ( pStripList == [self getStripListForIsoCurve:iPlane] ) {
                OK = YES;
                break;
            }
        }
    }

    if ( OK ) {
        appendLineStripList(pStripList, *pStrip);
    
        return OK;
    }
    else {
        return FALSE;
    }
}

-(BOOL)checkForDirectConnectBetween2IndicesInAStrip:(LineStrip*)pStrip Index:(NSUInteger)index Jndex:(NSUInteger)jndex IndicesList:(LineStrip*)pIndicesList {
    BOOL connectedDirectly = false;
    
    NSUInteger pos0 = searchForLineStripIndexForElement(pStrip, index, 0);
    NSUInteger pos1 = searchForLineStripIndexForElement(pStrip, jndex, 0);
    if(pos0 != NSNotFound && pos1 != NSNotFound) {
        connectedDirectly = true;
        NSUInteger posStart, posEnd;
        if ( pos0 < pos1 ) {
            posStart = pos0;
            posEnd = pos1;
        }
        else {
            posStart = pos1;
            posEnd = pos0;
        }
        posStart++;
        NSUInteger element;
        LineStrip portionStrip;
        initLineStrip(&portionStrip, (size_t)(posEnd - posStart));
        for(NSUInteger i = posStart; i < posEnd; i++) {
            appendLineStrip(&portionStrip, pStrip->array[i]);
        }
        for(NSUInteger j = 0; j < pIndicesList->used; j++) {
            element = pIndicesList->array[j];
            if(searchForLineStripIndexForElement(&portionStrip, element, 0) != NSNotFound) {
                connectedDirectly = false;
                break;
            }
        }
        freeLineStrip(&portionStrip);
    }
    
    return connectedDirectly;
}

-(BOOL)checkForDirectConnectWithoutOtherIndicesBetween2IndicesInAStrip:(nonnull LineStrip*)pStrip Index:(NSUInteger)index Jndex:(NSUInteger)jndex IndicesList:(nonnull LineStrip*)pIndicesList JndicesList:(nonnull LineStrip*)pJndicesList {
    BOOL connectedDirectly = NO;
    
//    NSUInteger pos0 = searchForLineStripIndexForElementWithTolerance(pStrip, index, 4, [self getNoColumnsSecondaryGrid]);
//    NSUInteger pos1 = searchForLineStripIndexForElementWithTolerance(pStrip, jndex, 4, [self getNoColumnsSecondaryGrid]);
    NSUInteger pos0 = searchForLineStripIndexForElement(pStrip, index, 0);
    NSUInteger pos1 = searchForLineStripIndexForElement(pStrip, jndex, 0);
    if( pos0 != NSNotFound && pos1 != NSNotFound && pos0 != pos1 ) {
        connectedDirectly = YES;
        NSUInteger posStart, posEnd;
        if ( pos0 < pos1 ) {
            posStart = pos0;
            posEnd = pos1;
        }
        else {
            posStart = pos1;
            posEnd = pos0;
        }
        posStart++;
        NSUInteger element;
        LineStrip portionStrip;
        initLineStrip(&portionStrip, (size_t)(posEnd - posStart));
        for(NSUInteger i = posStart; i < posEnd; i++) {
            appendLineStrip(&portionStrip, pStrip->array[i]);
        }
        NSUInteger pos = NSNotFound;
        for(NSUInteger j = 0; j < pIndicesList->used; j++) {
            element = pIndicesList->array[j];
//            if( (pos = searchForLineStripIndexForElementWithTolerance(&portionStrip, element, 4, [self getNoColumnsSecondaryGrid])) != NSNotFound ) {
            if( (pos = searchForLineStripIndexForElement(&portionStrip, element, 0)) != NSNotFound ) {
                connectedDirectly = NO;
                break;
            }
        }
        if ( pos == NSNotFound ) {
            for(NSUInteger j = 0; j < pJndicesList->used; j++) {
                element = pJndicesList->array[j];
                if( searchForLineStripIndexForElement(&portionStrip, element, 0) != NSNotFound ) {
                    connectedDirectly = NO;
                    break;
                }
            }
        }
        freeLineStrip(&portionStrip);
    }
    
    return connectedDirectly;
}

-(BOOL)checkStripHasNoBigGaps:(nonnull LineStrip*)pStrip {
    BOOL bigGaps = NO;
    NSUInteger index;
    double x, y;
    const double weldDist = 50.0 * (pow([self getDX], 2.0) + pow([self getDY], 2.0));
    for ( NSUInteger i = 0; i < pStrip->used - 1; i++ ) {
        index = pStrip->array[i];
        x = [self getXAt:index];
        y = [self getYAt:index];
        index = pStrip->array[i + 1];
        x -= [self getXAt:index];
        y -= [self getYAt:index];
        if ( x * x + y * y > weldDist ) {
            bigGaps = YES;
            break;
        }
    }
    return bigGaps;
}

-(BOOL)removeExcessBoundaryNodeFromExtraLineStrip:(LineStrip*)pStrip {
    BOOL anyRemoved = NO;
    NSUInteger *boundaryPositions = (NSUInteger*)calloc(1, sizeof(NSUInteger));
    [self searchExtraLineStripOfTwoBoundaryPoints:pStrip boundaryPositions:&boundaryPositions];
    for( size_t pos = 0; pos < pStrip->used; pos++ ) {
        if( pos < (size_t)boundaryPositions[0] || pos > (size_t)boundaryPositions[1] ) {
            removeLineStripAtIndex(pStrip, pos);
            anyRemoved = YES;
        }
    }
    free(boundaryPositions);
    return anyRemoved;
}

-(void)searchExtraLineStripOfTwoBoundaryPoints:(LineStrip*)pStrip boundaryPositions:(NSUInteger**)boundaryPositions {  // each LineStrip should touch boundary twice only
    if (*boundaryPositions == NULL ) {
        *boundaryPositions = (NSUInteger*)calloc(1, sizeof(NSUInteger));
    }
    NSUInteger countBoundaryPositions = 0, index;

    for (NSUInteger pos2 = 0; pos2 < (NSUInteger)pStrip->used; pos2++) {
        // retreiving index
        index = pStrip->array[pos2];
        if ( [self isNodeOnBoundary:index] ) { // if a border contour should only touch border twice
            // yet CPTContour class may have 2 or more boundary points next to each other, for CPTContourPlot can only have 2 border points
            *(*boundaryPositions + countBoundaryPositions) = pos2;
            countBoundaryPositions++;
            *boundaryPositions = (NSUInteger*)realloc(*boundaryPositions, (size_t)(countBoundaryPositions + 1) * sizeof(NSUInteger));
        }
    }
    if ( countBoundaryPositions > 2 ) {
        NSUInteger pos, pos2, n, i = 0, halfway = countBoundaryPositions / 2;
        while ( i < halfway ) {
            pos = *(*boundaryPositions + i);
            pos2 = *(*boundaryPositions + i + 1);
            if( pos2 - pos < 5 ) {
                n = countBoundaryPositions;
                if ( i < n ) {
                    for( NSUInteger j = i + 1; j < n; j++ ) {
                        *(*boundaryPositions + j - 1) = *(*boundaryPositions + j);
                    }
                    countBoundaryPositions--;
                }
            }
            i++;
        }
        i = countBoundaryPositions - 1;
        while ( i > 1 ) {
            pos = *(*boundaryPositions + i);
            pos2 = *(*boundaryPositions + i - 1);
            if( pos - pos2 < 5 ) {
                n = countBoundaryPositions;
                if ( i < n ) {
                    for( NSUInteger j = n-1; j > 1; j-- ) {
                        *(*boundaryPositions + j) = *(*boundaryPositions + j - 1);
                    }
                    countBoundaryPositions--;
                }
            }
            i--;
        }
    }
}


typedef struct {
    NSUInteger *array;
    size_t used;
    size_t size;
} Occurences;

void initOccurences(Occurences *a, size_t initialSize);
void appendOccurences(Occurences *a, NSUInteger element);
void clearOccurences(Occurences *a);
void freeOccurences(Occurences *a);

void initOccurences(Occurences *a, size_t initialSize) {
    a->array = (NSUInteger*)calloc(initialSize, sizeof(NSUInteger));
    a->used = 0;
    a->size = initialSize;
}

void appendOccurences(Occurences *a, NSUInteger element) {
    // a->used is the number of used entries, because a->array[a->used++] updates a->used only *after* the array has been accessed.
    // Therefore a->used can go up to a->size
    if (a->used == a->size) {
        a->size *= 2;
        a->array = (NSUInteger*)realloc(a->array, a->size * sizeof(NSUInteger));
    }
    a->array[a->used++] = element;
}

void clearOccurences(Occurences *a) {
    a->used = 0;
}

void freeOccurences(Occurences *a) {
    free(a->array);
    a->array = NULL;
    a->used = a->size = 0;
}


-(BOOL) checkForCrossesOverOnStrip:(LineStrip*)pStrip Index:(NSUInteger)index Jndex:(NSUInteger)jndex StartIndex:(NSUInteger*)startIndex {
    BOOL crossesover = NO;
    Occurences occurences;
    initOccurences(&occurences, 8);
    
    NSUInteger posTemp = 0;
    while ((posTemp = searchForLineStripIndexForElement(pStrip, index, posTemp)) != NSNotFound ) {
        appendOccurences(&occurences, posTemp);
        posTemp++;
        if (posTemp > pStrip->used - 1 ) {
            break;
        }
    }
    
    if ( occurences.used < 2 ) {
        clearOccurences(&occurences);
        posTemp = 0;
        while ((posTemp = (NSUInteger)searchForLineStripIndexForElement(pStrip, jndex, posTemp)) != NSNotFound ) {
            appendOccurences(&occurences, posTemp);
            posTemp++;
            if (posTemp > pStrip->used - 1 ) {
                break;
            }
        }
        if ( occurences.used > 1 ) {
            *startIndex = occurences.array[1];
            crossesover = YES;
        }
    }
    else {
        *startIndex = occurences.array[1];
        crossesover = YES;
    }
    freeOccurences(&occurences);
    return crossesover;
}

-(BOOL) removeLineStripFromLineStripList:(LineStripList*)pStripList Strip:(LineStrip*)pStrip {
    NSAssert(pStripList, @"pStripList is null");
    NSAssert(pStrip, @"pStrip is null");
    BOOL OK = false;

    for(NSUInteger iPlane = 0; iPlane < [self getNoIsoCurves]; iPlane++) {
        if ( pStripList == [self getStripListForIsoCurve:iPlane] ) {
            OK = true;
            break;
        }
    }
    if ( OK ) {
        NSUInteger foundPos = (NSUInteger)findLineStripListIndexForLineStrip(pStripList, pStrip);
        if (foundPos != NSNotFound) {
            freeLineStrip(pStrip);
            removeLineStripListAtIndex(pStripList, (size_t)foundPos);
        }
    }
    return OK;
}

@end
