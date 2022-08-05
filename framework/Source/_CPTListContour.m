//
//  CPTListContour.m
//  CorePlot
//
//  Created by Steve Wainwright on 22/11/2021.
//

#import "_CPTListContour.h"

void swapLineStripElements(NSUInteger* a, NSUInteger* b);

// Function to swap two memory contents
void swapLineStripElements(NSUInteger* a, NSUInteger* b){
    NSUInteger temp = *a;
    *a = *b;
    *b = temp;
}

void initLineStrip(LineStrip *a, size_t initialSize) {
    a->array = (NSUInteger*)calloc(initialSize, sizeof(NSUInteger));
    a->used = 0;
    a->size = initialSize;
}

void appendLineStrip(LineStrip *a, NSUInteger element) {
    // a->used is the number of used entries, because a->array[a->used++] updates a->used only *after* the array has been accessed.
    // Therefore a->used can go up to a->size
    if (a->used == a->size) {
        a->size *= 2;
        a->array = (NSUInteger*)realloc(a->array, a->size * sizeof(NSUInteger));
    }
    a->array[a->used++] = element;
}

void insertLineStripAtIndex(LineStrip *a, NSUInteger element, size_t index) {
    if (a->used == a->size) {
        a->size *= 2;
        a->array = (NSUInteger*)realloc(a->array, a->size * sizeof(NSUInteger));
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

void removeLineStripAtIndex(LineStrip *a, size_t index) {
    size_t n = a->used;
    
    if ( index < n ) {
        for( size_t i = index+1; i < n; i++ ) {
            a->array[i-1] =  a->array[i];
        }
        a->used--;
    }
}

void assignLineStripInRange(LineStrip *a, LineStrip *b, size_t start, size_t end) {
    if(end > b->used - 1) {
        end = b->used - 1;
    }
    if(start < b->used - 1 && end <= b->used - 1 && start < end) {
        for( size_t i = start; i < end; i++ ) {
            appendLineStrip(a, b->array[i]);
        }
    }
}

NSUInteger searchForLineStripIndexForElement(LineStrip *a, NSUInteger element, NSUInteger startPos) {
    NSUInteger foundPos = NSNotFound;
    for(size_t i = (size_t)startPos; i < a->used; i++) {
        if(element == a->array[i]) {
            foundPos = (NSUInteger)i;
            break;
        }
    }
    return foundPos;
}

NSUInteger searchForLineStripIndexForElementWithTolerance(LineStrip *a, NSUInteger element, NSUInteger tolerance, NSUInteger columnMutliplier) {
    NSUInteger foundPos = NSNotFound;
    NSUInteger startPos = 0;
    // try it without a tolerance first
    if ( (foundPos = searchForLineStripIndexForElement(a, element, startPos)) == NSNotFound ) {
        NSUInteger x = 0, y = 0, layer = 1, leg = 0, iteration = 0;
        while ( iteration < tolerance * tolerance ) {
            if((foundPos = searchForLineStripIndexForElement(a, element + x + y * columnMutliplier, startPos)) != NSNotFound && (NSUInteger)labs((NSInteger)element - (NSInteger)a->array[foundPos]) < tolerance) {
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

    return foundPos;
}

// Function to reverse the array through pointers
void reverseLineStrip(LineStrip *a) {
    // pointer1 pointing at the beginning of the array
    NSUInteger *pointer1 = a->array;
    // pointer2 pointing at end of the array
    NSUInteger *pointer2 = a->array + a->used - 1;
    while (pointer1 < pointer2) {
        swapLineStripElements(pointer1, pointer2);
        pointer1++;
        pointer2--;
    }
}

NSInteger checkLineStripToAnotherForSameDifferentOrder(LineStrip *a, LineStrip *b) {
    NSInteger same = -1;
    size_t count = 0;
    if( a->used == b->used ) {
        while ( TRUE ) {
            same = (memcmp(a->array, b->array, a->used * sizeof(NSUInteger)) == 0) ? 0 : 1;
            if ( same == 0 ) {
                break;
            }
            size_t n = b->used;
            NSUInteger temp = b->array[0];
            for( size_t j = 1; j < n; j++ ) {
                b->array[j-1] =  b->array[j];
            }
            b->array[n-1] = temp;
            count++;
            if ( count == n  ) {
                break;
            }
        }
    }
    return same;
}

void clearLineStrip(LineStrip *a) {
    a->used = 0;
}

void freeLineStrip(LineStrip *a) {
    free(a->array);
    a->array = NULL;
    a->used = a->size = 0;
}

void initLineStripList(LineStripList *a, size_t initialSize) {
    a->array = (LineStrip*)calloc(initialSize, sizeof(LineStrip));
    a->used = 0;
    a->size = initialSize;
}

void appendLineStripList(LineStripList *a, LineStrip element) {
    // a->used is the number of used entries, because a->array[a->used++] updates a->used only *after* the array has been accessed.
    // Therefore a->used can go up to a->size
    if (a->used == a->size) {
        a->size *= 2;
        a->array = (LineStrip*)realloc(a->array, a->size * sizeof(LineStrip));
    }
    a->array[a->used++] = element;
}

void insertLineStripListAtIndex(LineStripList *a, LineStrip element, size_t index) {
    if (a->used == a->size) {
        a->size *= 2;
        a->array = (LineStrip*)realloc(a->array, a->size * sizeof(LineStrip));
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

void removeLineStripListAtIndex(LineStripList *a, size_t index) {
    size_t n = a->used;
    
    if ( index < n ) {
        for( size_t i = index+1; i < n; i++ ) {
            a->array[i-1] =  a->array[i];
        }
        a->used--;
    }
}

NSUInteger findLineStripListIndexForLineStrip(LineStripList *a, LineStrip *b) {
    NSUInteger foundPos = NSNotFound;
    for(NSUInteger i = 0; i < (NSUInteger)a->used; i++) {
        if(b == &a->array[i]) {
            foundPos = i;
            break;
        }
    }
    return foundPos;
}

void sortLineStripList(LineStripList *a) {
    qsort(a->array, a->used, sizeof(LineStripList), compareLineStripListByPosition);
}

void clearLineStripList(LineStripList *a) {
    a->used = 0;
}

void freeLineStripList(LineStripList *a) {
    free(a->array);
    a->array = NULL;
    a->used = a->size = 0;
}

int compareLineStripListByPosition(const void *a, const void *b) {
    const LineStrip *aO = (const LineStrip*)a;
    const LineStrip *bO = (const LineStrip*)b;
    
    if (aO->array[0] > bO->array[0]) {
        return 1;
    }
    else if (aO->array[0] < bO->array[0]) {
        return -1;
    }
    else {
        return 0;
    }
}

void initIsoCurvesList(IsoCurvesList *a, size_t initialSize) {
    a->array = (LineStripList*)calloc(initialSize, sizeof(LineStripList));
    a->used = 0;
    a->size = initialSize;
}

void appendIsoCurvesList(IsoCurvesList *a, LineStripList element) {
    // a->used is the number of used entries, because a->array[a->used++] updates a->used only *after* the array has been accessed.
    // Therefore a->used can go up to a->size
    if (a->used == a->size) {
        a->size *= 2;
        a->array = (LineStripList*)realloc(a->array, a->size * sizeof(LineStripList));
    }
    a->array[a->used++] = element;
}


void clearIsoCurvesList(IsoCurvesList *a) {
    a->used = 0;
}

void freeIsoCurvesList(IsoCurvesList *a) {
    free(a->array);
    a->array = NULL;
    a->used = a->size = 0;
}

@interface CPTListContour()


@end

@implementation CPTListContour

// array of line strips
static IsoCurvesList stripLists;

@synthesize overrideWeldDistance; // for flexiblity may want to override the Weld Distance for compacting contours

//////////////////////////////////////////////////////////////////////
// Construction/Destruction
//////////////////////////////////////////////////////////////////////

-(nonnull instancetype)initWithNoIsoCurve:(NSUInteger)newNoIsoCurves IsoCurveValues:(double*)newContourPlanes Limits:(double*)newLimits {
    
    NSAssert(newLimits[0] < newLimits[1], @"X: lower limit must be less than upper limit ");
    NSAssert(newLimits[2] < newLimits[3], @"Y: lower limit must be less than upper limit ");
    
    self = [super initWithNoIsoCurve:newNoIsoCurves IsoCurveValues:newContourPlanes Limits:newLimits];
    self.overrideWeldDistance = NO;
        
    return self;
}

-(void)dealloc {
    [self cleanMemory];
}

-(ContourPlanes* _Nullable) getContourPlanes {
    return [super getContourPlanes];
}

-(IsoCurvesList*) getIsoCurvesLists {
    return &stripLists;
}

-(void)generateAndCompactStrips {
    // generate line strips
    if( [self generate] ) {
        // compact strips
        [self compactStrips];
    }
}

-(void) initialiseMemory {
    if ( stripLists.size > 0 ) {
        [self cleanMemory];
    }
    [super initialiseMemory];
    initIsoCurvesList(&stripLists, (size_t)[self getNoIsoCurves]);
    for(NSUInteger i = 0; i < [self getNoIsoCurves]; i++) {
        LineStripList list;
        initLineStripList(&list, 4);
        appendIsoCurvesList(&stripLists, list);
    }
}

-(void) cleanMemory {
    
    [super cleanMemory];
    
    LineStrip* pStrip;
    LineStripList *pStripList;
    
    if ( stripLists.size > 0 ) {
        // reseting lists
        NSAssert(stripLists.size == (size_t)[self getNoIsoCurves], @"stripLists not same size as asked for");
        for (NSUInteger i = 0; i < [self getNoIsoCurves]; i++) {
            pStripList = &stripLists.array[i];
            NSAssert(pStripList != NULL, @"LineStripList is NULL");
            for(NSUInteger j = 0; j < pStripList->used; j++) {
                pStrip = &pStripList->array[j];
                NSAssert(pStrip != NULL, @"LineStrip is NULL");
                freeLineStrip(pStrip);
            }
            freeLineStripList(pStripList);
        }
        freeIsoCurvesList(&stripLists);
    }
}


-(LineStripList*) getStripListForIsoCurve:(NSUInteger)iPlane {
    return &stripLists.array[iPlane];
}

-(void) setStripListAtPlane:(NSUInteger)iPlane StripList:(LineStripList*)pLineStripList {
    NSAssert(iPlane < [self getNoIsoCurves] && iPlane != NSNotFound, @"iPlane not in range");
    
    LineStrip* pStrip;
    LineStripList* actualStripList = [self getStripListForIsoCurve:iPlane];
    for(NSUInteger pos = 0; pos < (NSUInteger)pLineStripList->used; pos++) {
        pStrip = &pLineStripList->array[pos];
        if(pStrip->used > 0) {
            appendLineStripList(actualStripList, *pStrip);
        }
    }
}

-(void) exportLineForIsoCurve:(NSUInteger)iPlane FromX1:(NSUInteger)x1 FromY1:(NSUInteger)y1 ToX2:(NSUInteger)x2 ToY2:(NSUInteger)y2 {
    NSAssert(iPlane != NSNotFound && iPlane < [self getNoIsoCurves], @"Plane index is not valid 0 to no. Planes");
    
    if ( x1 > [self getNoColumnsSecondaryGrid] + 1 || x2 > [self getNoColumnsSecondaryGrid] + 1 || y1 > [self getNoRowsSecondaryGrid] + 1 || y2 > [self getNoRowsSecondaryGrid] + 1 ) {
        self.overrideWeldDistance = YES;
        return;
    }
    
    // check that the two points are not at the beginning or end of the some line strip
    NSUInteger i1 = y1 * ([self getNoColumnsSecondaryGrid] + 1) + x1;
    NSUInteger i2 = y2 * ([self getNoColumnsSecondaryGrid] + 1) + x2;
    
   
    LineStrip* pStrip;
    LineStripList* pStripList = &stripLists.array[iPlane];
    
    BOOL added = NO;
    for (NSUInteger pos = 0; pos < pStripList->used && !added; pos++) {
        pStrip = &pStripList->array[pos];
        NSAssert(pStrip->array != NULL, @"LineStrip is NULL");
        if (i1 == pStrip->array[0]) {
            insertLineStripAtIndex(pStrip, i2, 0);
            return;
        }
        if (i1 == pStrip->array[pStrip->used-1]) {
            appendLineStrip(pStrip, i2);
            return;
        }
        if (i2 == pStrip->array[0]) {
            insertLineStripAtIndex(pStrip, i1, 0);
            return;
        }
        if (i2 == pStrip->array[pStrip->used-1]) {
            appendLineStrip(pStrip, i1);
            return;
        }
    }
    // segment was not part of any line strip, creating new one
    LineStrip strip;
    initLineStrip(&strip, 2);
    appendLineStrip(&strip, i1);
    appendLineStrip(&strip, i2);
    insertLineStripListAtIndex(pStripList, strip, 0);
}

-(BOOL) forceMerge:(LineStrip*) pStrip1 With:(LineStrip*) pStrip2 {
    
    if (pStrip2->used == 0)
        return false;
    
    double x[4], y[4], weldDist;
    NSUInteger index = pStrip1->array[0];
    x[0] = [self getXAt:index];
    y[0] = [self getYAt:index];
    index = pStrip1->array[pStrip1->used - 1];
    x[1] = [self getXAt:index];
    y[1] = [self getYAt:index];
    index = pStrip2->array[0];
    x[2] = [self getXAt:index];
    y[2] = [self getYAt:index];
    index = pStrip2->array[pStrip2->used - 1];
    x[3] = [self getXAt:index];
    y[3] = [self getYAt:index];
    
    weldDist = 10.0 * (pow([self getDX], 2.0) + pow([self getDY], 2.0));
    
    if ((x[1] - x[2]) * (x[1] - x[2]) + (y[1] - y[2]) * (y[1] - y[2]) < weldDist) {
        for(NSInteger i = 0; i < (NSInteger)pStrip2->used; i++) {
            index = pStrip2->array[i];
            NSAssert(index >= 0, @"index has to be >= 0");
            appendLineStrip(pStrip1, index);
        }
        //freeLinestrip(pStrip2);
        return true;
    }
    
    if ((x[3] - x[0]) * (x[3] - x[0]) + (y[3] - y[0]) * (y[3] - y[0]) < weldDist) {
        for(NSInteger i = (NSInteger)pStrip2->used-1; i > -1; i--) {
            index = pStrip2->array[i];
            NSAssert(index >= 0, @"index has to be >= 0");
            insertLineStripAtIndex(pStrip1, index, 0);
        }
        //freeLinestrip(pStrip2);
        return true;
    }
    
    if ((x[1] - x[3]) * (x[1] - x[3]) + (y[1] - y[3]) * (y[1] - y[3]) < weldDist) {
        for(NSInteger i = (NSInteger)pStrip2->used-1; i > -1; i--) {
            index = pStrip2->array[i];
            NSAssert(index >= 0, @"index has to be >= 0");
            appendLineStrip(pStrip1, index);
        }
        //freeLinestrip(pStrip2);
        return true;
    }

    if ((x[0] - x[2]) * (x[0] - x[2]) + (y[0] - y[2]) * (y[0] - y[2]) < weldDist) {
        for(NSInteger i = 0; i < (NSInteger)pStrip2->used; i++) {
            index = pStrip2->array[i];
            NSAssert(index >= 0, @"index has to be >= 0");
            insertLineStripAtIndex(pStrip1, index, 0);
        }
        //freeLinestrip(pStrip2);
        return true;
    }

    return false;
}

-(BOOL) mergeStrips:(LineStrip*) pStrip1 With:(LineStrip*) pStrip2 {
    if (pStrip2->used == 0)
        return false;
    
    NSUInteger index;
    // debugging stuff
    if (pStrip2->array[0] == pStrip1->array[0]) {
        // not using first element
        // adding the rest to strip1
        for(NSUInteger pos = 1; pos < (NSUInteger)pStrip2->used; pos++) {
            index = pStrip2->array[pos];
            NSAssert(index >= 0 && index != NSNotFound, @"index not valid");
            insertLineStripAtIndex(pStrip1, index, 0);
        }
        clearLineStrip(pStrip2);
        return true;
    }
    
    if (pStrip2->array[0] == pStrip1->array[pStrip1->used-1]) {
        // adding the rest to strip1
        for(NSUInteger pos = 1; pos < (NSUInteger)pStrip2->used; pos++) {
            index = pStrip2->array[pos];
            NSAssert(index >= 0 && index != NSNotFound, @"index not valid");
            appendLineStrip(pStrip1, index);
        }
        clearLineStrip(pStrip2);
        return true;
    }
    
    if (pStrip2->array[pStrip2->used-1] == pStrip1->array[0]) {
        for(NSInteger pos = (NSInteger)pStrip2->used - 2; pos > -1; pos--) {
            index = pStrip2->array[(NSUInteger)pos];
            NSAssert(index >= 0, @"index not valid");
            insertLineStripAtIndex(pStrip1, index, 0);
        }
        clearLineStrip(pStrip2);
        return true;
    }
    
    if (pStrip2->array[pStrip2->used-1] == pStrip1->array[pStrip1->used-1]) {
        for(NSInteger pos = (NSInteger)pStrip2->used - 2; pos > -1; pos--) {
            index = pStrip2->array[(NSUInteger)pos];
            NSAssert(index >= 0, @"index not valid");
            appendLineStrip(pStrip1, index);
        }
        clearLineStrip(pStrip2);
        return true;
    }
    
    return false;
}

// Basic algorithm to concatanate line strip. Not optimized at all !
-(void) compactStrips {
    LineStrip* pStrip = NULL;
    LineStrip* pStripBase = NULL;
    LineStripList* pStripList = NULL;
    
    BOOL again;
    LineStripList newList;
    initLineStripList(&newList, 4);
    const double weldDist = 10.0 * (pow([self getDX], 2.0) + pow([self getDY], 2.0));
//    NSLog(@"wellDist: %f\n", weldDist);
//    NSLog(@"deltaX: %f\n", [self getDX]);
//    NSLog(@"deltaY: %f\n", [self getDY]);
    NSAssert(stripLists.used == [self getNoIsoCurves], @"No of Planes(isocurves) not the same a striplist used");
    for (NSUInteger i = 0; i < [self getNoIsoCurves]; i++) {
        pStripList = &stripLists.array[i];
//        sortLineStripList(pStripList);
        again = YES;
        while(again) {
            // REPEAT COMPACT PROCESS UNTIL LAST PROCESS MAKES NO CHANGE
            again = NO;
            // building compacted list
            NSAssert(newList.used == 0, @"newList is empty");
            for (NSUInteger pos = 0; pos < (NSUInteger)pStripList->used; pos++) {
                pStrip = &pStripList->array[pos];
                for (NSUInteger pos2 = 0; pos2 < (NSUInteger)newList.used; pos2++) {
                    pStripBase = &newList.array[pos2];
                    if([self mergeStrips:pStripBase With:pStrip]) {
                        again = YES;
                    }
                    if(pStrip->used == 0) {
                        break;
                    }
                }
                if(pStrip->used == 0) {
                    removeLineStripListAtIndex(pStripList, pos);
                    pos--;
                }
                else {
                    insertLineStripListAtIndex(&newList, *pStrip, 0);
                }
            }
            
            // deleting old list
            clearLineStripList(pStripList);
            
            // Copying all
            for(NSUInteger pos2 = 0; pos2 < (NSUInteger)newList.used; pos2++) {
                pStrip = &newList.array[pos2];
                NSUInteger pos1 = 0, pos3;
                while(pos1 < (NSUInteger)pStrip->used) {
                    pos3 = pos1;
                    pos3++;
                    if( pos3 > (NSUInteger)pStrip->used-1 ) {
                        break;
                    }
                    if(pStrip->array[pos1] == pStrip->array[pos3]) {
                        removeLineStripAtIndex(pStrip, pos3);
                    }
                    else {
                        pos1++;
                    }
                }
                if(pStrip->used != 1) {
                    insertLineStripListAtIndex(pStripList, *pStrip, 0);
                }
                else {
//                    freeLineStrip(pStrip);
                    removeLineStripListAtIndex(pStripList, pos2);
                }
            }
            // emptying temp list
            clearLineStripList(&newList);
        } // OF WHILE(AGAIN) (LAST COMPACT PROCESS MADE NO CHANGES)
        
        if (pStripList->used == 0) {
            continue;
        }
        ///////////////////////////////////////////////////////////////////////
        // compact more
        NSUInteger index, count = 0;
        NSUInteger Nstrip = (NSUInteger)pStripList->used;
        BOOL *closed = (BOOL*)calloc(pStripList->used, sizeof(BOOL));
        double x,y;

        // First let's find the open and closed lists in m_vStripLists
        for(NSUInteger j = 0; j < pStripList->used; j++) {
            pStrip = &pStripList->array[j];
            // is it open ?
            if (pStrip->array[0] != pStrip->array[pStrip->used-1]) {
                index = pStrip->array[0];
                x = [self getXAt:index];
                y = [self getYAt:index];
                index = pStrip->array[pStrip->used-1];
                x -= [self getXAt:index];
                y -= [self getYAt:index];
                
                if ( x * x + y * y < weldDist) { // is it "almost closed" ?
                    closed[j] = YES;
                }
                else {
                    closed[j] = NO;
                    count++; // updating not closed counter...
                }
            }
            else {
                closed[j] = YES;
            }
        }
        
        // is there any open strip ?
        if (count > 1) {
            // Merge the open strips into NewList
            NSUInteger pos = 0;
            for(NSUInteger j = 0; j < Nstrip; j++) {
                if (!closed[j]) {
                    pStrip = &pStripList->array[pos];
                    insertLineStripListAtIndex(&newList, *pStrip, 0);
//                    freeLineStrip(pStrip);
                    removeLineStripListAtIndex(pStripList, pos);
                }
                else {
                    pos++;
                }
            }
            
            // are there open strips to process ?
            while(newList.used > 1) {
                pStripBase = &newList.array[0];
                // merge the rest to pStripBase
                again = YES;
                while (again) {
                    again = NO;
                    for(pos = 1; pos < newList.used; pos++) {
                        pStrip = &newList.array[pos];
                        if ([self forceMerge:pStripBase With:pStrip]) {
                            again = YES;
//                            freeLineStrip(pStrip);
                            removeLineStripListAtIndex(&newList, pos);
                        }
                        else {
                            pos++;
                        }
                    }
                } // while(again)
                
                index = pStripBase->array[0];
                x = [self getXAt:index];
                y = [self getYAt:index];
                index = pStripBase->array[pStripBase->used - 1];
                x -= [self getXAt:index];
                y -= [self getYAt:index];
                
                // if pStripBase is closed or not
                if (x * x + y * y < weldDist && !self.overrideWeldDistance) {
//                    NSLog(@"# Plane %ld: open strip ends close enough based on weldDist  %ld && %ld, continue.\n", i, pStripBase->array[0], pStripBase->array[pStripBase->used-1]);
                    insertLineStripListAtIndex(pStripList, *pStripBase, 0);
//                    freeLineStrip(pStripBase);
                    removeLineStripListAtIndex(&newList, 0);
                }
                else {
                    if ([self onBoundaryWithStrip:pStripBase]) {
//                        NSLog(@"# Plane %ld: open strip ends on boundary %ld && %ld, continue.\n", i, pStripBase->array[0], pStripBase->array[pStripBase->used-1]);
                        insertLineStripListAtIndex(pStripList, *pStripBase, 0);
//                        freeLineStrip(pStripBase);
                        removeLineStripListAtIndex(&newList, 0);
                    }
                    else {
                        if ( self.overrideWeldDistance ) {
                            insertLineStripListAtIndex(pStripList, *pStripBase, 0);
    //                        freeLineStrip(pStripBase);
                            removeLineStripListAtIndex(&newList, 0);
                        }
                        else {
//                        NSLog(@"# Plane %ld: unpaired open strip  %ld && %ld  at 1!\n", i, pStripBase->array[0], pStripBase->array[pStripBase->used-1]);
//                        [self dumpPlane:i];
//                        delete pStripBase;
//                        if ( newList.size() > 0 ) {
//                            newList.front() = newList.back();
//                            newList.pop_back();
//                        }
//            //            exit(0);
                            break;
                        }
                    }
                }
            } // while(newList.size()>1);


            if (newList.used == 1) {
                pStripBase = &newList.array[0];
                if ([self onBoundaryWithStrip:pStripBase]) {
//                    NSLog(@"# Plane %ld: open strip ends on boundary %ld && %ld, continue.\n", i, pStripBase->array[0], pStripBase->array[pStripBase->used-1]);
                    insertLineStripListAtIndex(pStripList, *pStripBase, 0);
//                    freeLineStrip(pStripBase);
                    removeLineStripListAtIndex(&newList, 0);
                }
                else {
//                    NSLog(@"# Plane %ld: unpaired open strip %ld && %ld at 2!\n", i, pStripBase->array[0], pStripBase->array[pStripBase->used-1]);
//                    [self dumpPlane:i];
//                    delete pStripBase;
//                    if ( newList.size() > 0 ) {
//                        newList.front() = newList.back();
//                        newList.pop_back();
//                    }
//exit(0);
                }
            }
            clearLineStripList(&newList);
        }
        else if (count == 1) {
            NSUInteger pos = 0;
            for(NSUInteger j = 0;j < Nstrip; j++) {
                if (!closed[j] ) {
                    pStripBase = &pStripList->array[pos];
                    break;
                }
                pos++;
            }
            if ([self onBoundaryWithStrip:pStripBase]) {
//                NSLog(@"# Plane %ld: open strip ends on boundary %ld && %ld, continue.\n", i, pStripBase->array[0], pStripBase->array[pStripBase->used-1]);
            }
            else {
//                NSLog(@"# Plane %ld: unpaired open strip %ld && %ld at 3!\n", i, pStripBase->array[0], pStripBase->array[pStripBase->used-1]);
//                [self dumpPlane:i];
//                delete pStripBase;
//                if ( newList.size() > 0 ) {
//                    newList.front() = newList.back();
//                    newList.pop_back();
//                }
               // exit(0);
            }
        }

        free(closed);
        //////////////////////////////////////////////////////////////////////////////////////////////////
        clearLineStripList(&newList);
    }
    freeLineStripList(&newList);
}

-(BOOL) onBoundaryWithStrip:(LineStrip*) pStrip {
    BOOL e1 = NO, e2 = NO;
    if (pStrip != NULL) {
        NSUInteger index = pStrip->array[0];
        double x = [self getXAt:index], y = [self getYAt:index];
        double *limits = [self getLimits];
        if (x == limits[0] || x == limits[1] || y == limits[2] || y == limits[3]) {
            e1 = YES;
        }
        else {
            e1 = NO;
        }
        index = pStrip->array[pStrip->used - 1];
        x = [self getXAt:index];
        y = [self getYAt:index];
        if (x == limits[0] || x == limits[1] || y == limits[2] || y == limits[3]) {
            e2 = YES;
        }
        else {
            e2 = NO;
        }
    }
    return (e1 && e2);
}

-(void) setLinesForPlane:(NSUInteger)iPlane LineStripList:(LineStripList*)lineStripList {
    NSAssert(iPlane != NSNotFound && iPlane < [self getNoIsoCurves], @"Plane not between valid ranges");
    
    LineStripList* pStripList;
    LineStrip* pStrip;
    if(lineStripList->used != 0) {
        for(NSInteger i = 0; i < (NSInteger)lineStripList->used; i++) {
            pStrip = &lineStripList->array[i];
            if(pStrip->used != 0) {
                pStripList = &stripLists.array[iPlane];
                insertLineStripListAtIndex(pStripList, *pStrip, 0);
            }
        }
    }
}

/// debugging
-(void) dumpPlane:(NSUInteger)iPlane {
    NSAssert(iPlane >= 0 && iPlane < [self getNoIsoCurves], @"iPlane index not between range");

    LineStripList* pStripList = &stripLists.array[iPlane];
    NSLog(@"Level: %f\n", [self getIsoCurveAt:iPlane]);
    NSLog(@"Number of strips : %ld\n", pStripList->used);
    NSLog(@"i\tnp\tstart\tend\txstart\tystart\txend\tyend\n");

    
    LineStrip* pStrip;
    for (NSInteger i = 0; i < (NSInteger)pStripList->used; i++) {
        pStrip = &pStripList->array[i];
        NSAssert(pStrip != NULL, @"pStrip not set");
        NSLog(@"%ld\t%ld\t%ld\t%ld\t%g\t%g\t%g\t%g\n", i, pStrip->used, pStrip->array[0], pStrip->array[pStrip->used-1], [self getXAt:pStrip->array[0]], [self getYAt:pStrip->array[0]], [self getXAt:pStrip->array[pStrip->used-1]], [self getYAt:pStrip->array[pStrip->used-1]] );
    }
    NSLog(@"\n");
}

// Area given by this function can be positive or negative depending on the winding direction of the contour.
-(double) area:(LineStrip*)line {
    // if Line is not closed, return 0;
    
    double Ar = 0, x, y, x0, y0, x1, y1;
    
    NSUInteger index = line->array[0];
    x0 = x =  [self getXAt:index];
    y0 = y =  [self getYAt:index];
    
    for(NSInteger i = 1; i < (NSInteger)line->used; i++) {
        index =  line->array[i];
        x1 = [self getXAt:index];
        y1 = [self getYAt:index];
        // Ar += (x1-x)*(y1+y);
        Ar += (y1 - y) * (x1 + x) - (x1 - x) * (y1 + y);
        x = x1;
        y = y1;
    }
    
    //Ar += (x0-x)*(y0+y);
    Ar += (y0 - y) * (x0 + x) - (x0 - x) * (y0 + y);
    // if not closed curve, return 0;
    if ((x0 - x) * (x0 - x) + (y0 - y) * (y0 - y) > 20.0 * pow([self getDX], 2.0) + pow([self getDY], 2.0) ) {
        Ar = 0.0;
//        NSLog(@"# open curve!\n");
    }
    //else   Ar /= -2;
    else {
        Ar /= 4.0;
    }
    // result is \int ydex/2 alone the implicit direction.
    return Ar;
}

-(double) edgeWeight:(LineStrip*)line R:(double)R {
    NSUInteger count = 0,index;
    double x,y;
    for(NSUInteger i = 0; i < (NSUInteger)line->used ; i++) {
        index = line->array[i];
        x = [self getXAt:index];
        y = [self getYAt:index];
        if (fabs(x) > R || fabs(y) > R) {
            count ++;
        }
    }
    return (double)count / line->used;
}

-(BOOL) printEdgeWeightContour:(NSString*)fname {
    NSArray *dirPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([dirPaths count] > 0) ? [dirPaths objectAtIndex:0] : nil;
    NSURL *filenameUrl = [NSURL URLWithString:[NSString stringWithFormat:@"%@/Export/%@.contour", basePath, fname]];
    
    NSUInteger index;
    LineStrip* pStrip;
    LineStripList* pStripList;
    NSMutableString *textfilestring = [[NSMutableString alloc] init];
    for(NSUInteger i = 0; i < [self getNoIsoCurves]; i++) {
        pStripList = &stripLists.array[i];
        for(NSUInteger j = 0; j < (NSUInteger)pStripList->used; j++) {
            pStrip = &pStripList->array[j];
            for(NSUInteger k = 0; k < (NSUInteger)pStrip->used; k++) {
                index = pStrip->array[k];
                [textfilestring appendFormat:@"%f\t%f\n", [self getXAt:index], [self getYAt:index]];
            }
            [textfilestring appendString:@"\n"];
        }
    }
    
    NSError *error;
    BOOL OK = [textfilestring writeToURL:filenameUrl atomically:YES encoding:NSUTF16StringEncoding error:&error];
    
    return OK;
}

// returns true if node is touching boundary
-(BOOL) isNodeOnBoundary:(NSUInteger)index {
    BOOL e1 = NO;
    double x = [self getXAt:index];
    double y = [self getYAt:index];
    double *limits = [self getLimits];
    if(x == limits[0] || x == limits[1] || y == limits[2] || y == limits[3]) {
        e1 = YES;
    }
    return e1;
}

@end
