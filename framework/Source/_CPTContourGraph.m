//
//  _CPTContourGraph.m
//  CorePlot
//
//  Created by Steve Wainwright on 13/05/2022.
//

#import "_CPTContourGraph.h"

typedef struct {
    NSUInteger *array;
    size_t used;
    size_t size;
} Queue;

void initQueue(Queue *a, size_t initialSize);
void appendQueue(Queue *a, NSUInteger element);
void removeQueueAtIndex(Queue *a, size_t index);
void printQueue(Queue* a);
bool isEmptyQueue(Queue* a);
void clearQueue(Queue *a);
void freeQueue(Queue *a);

void initQueue(Queue *a, size_t initialSize) {
    a->array = (NSUInteger*)calloc(initialSize, sizeof(NSUInteger));
    a->used = 0;
    a->size = initialSize;
}

// Adding elements into queue
void appendQueue(Queue *a, NSUInteger element) {
    // a->used is the number of used entries, because a->array[a->used++] updates a->used only *after* the array has been accessed.
    // Therefore a->used can go up to a->size
    if (a->used == a->size) {
        a->size *= 2;
        a->array = (NSUInteger*)realloc(a->array, a->size * sizeof(NSUInteger));
    }
    a->array[a->used++] = element;
}

// Removing elements from queue
void removeQueueAtIndex(Queue *a, size_t index) {
    size_t n = a->used;
        
    if ( index < n ) {
        for( size_t i = index+1; i < n; i++ ) {
            a->array[i-1] =  a->array[i];
        }
        a->used--;
    }
}

// Print the queue
void printQueue(Queue* a) {
    if (isEmptyQueue(a)) {
       printf("Queue is empty");
    }
    else {
        //printf("\nQueue contains \n");
        for (NSUInteger i = 0; i < a->used; i++) {
            printf("%ld ", a->array[i]);
        }
    }
}

// Check if the queue is empty
bool isEmptyQueue(Queue* a) {
    return a->used == 0;
}

void clearQueue(Queue *a) {
    a->used = 0;
}

void freeQueue(Queue *a) {
    free(a->array);
    a->array = NULL;
    a->used = a->size = 0;
}

typedef struct {
    NSUInteger *array;
    size_t used;
    size_t size;
} Adjacency;

void initAdjacency(Adjacency *a, size_t initialSize);
NSUInteger searchAdjacencyElementForSourceTarget(Adjacency *a, NSUInteger element);
void appendAdjacency(Adjacency *a, NSUInteger element);
void removeAdjacencyAtIndex(Adjacency *a, size_t index);
void freeAdjacency(Adjacency *a);

void initAdjacency(Adjacency *a, size_t initialSize) {
    a->array = (NSUInteger*)calloc(initialSize, sizeof(NSUInteger));
    a->used = 0;
    a->size = initialSize;
}

void appendAdjacency(Adjacency *a, NSUInteger element) {
    // a->used is the number of used entries, because a->array[a->used++] updates a->used only *after* the array has been accessed.
    // Therefore a->used can go up to a->size
    if (a->used == a->size) {
        a->size *= 2;
        a->array = (NSUInteger*)realloc(a->array, a->size * sizeof(NSUInteger));
    }
    a->array[a->used++] = element;
}

NSUInteger searchAdjacencyElementForSourceTarget(Adjacency *a, NSUInteger element) {
    NSUInteger index = NSNotFound;
    for( NSUInteger i = 0; i < (NSUInteger)a->used; i++ ) {
        if ( element == a->array[i] ) {
            index = i;
            break;
        }
    }
    return index;
}

// Removing elements from queue
void removeAdjacencyAtIndex(Adjacency *a, size_t index) {
    size_t n = a->used;
        
    if ( index < n ) {
        for( size_t i = index+1; i < n; i++ ) {
            a->array[i-1] =  a->array[i];
        }
        a->used--;
    }
}

void freeAdjacency(Adjacency *a) {
    free(a->array);
    a->array = NULL;
    a->used = a->size = 0;
}


@implementation _CPTContourGraph

// Inaccessibles variables
static Adjacency *adjacency;   // adjacency array

@synthesize noNodes;   //number of nodes in graph

- (instancetype)initWithNoNodes:(NSUInteger)newNoNodes {
    if (self) {
        self.noNodes = newNoNodes;
        adjacency = (Adjacency*)calloc((size_t)newNoNodes, sizeof(Adjacency));
        for ( NSUInteger i = 0; i < self.noNodes; i++ ) {
            initAdjacency(&adjacency[i], 2);
        }
    }
    return self;
}

- (void)dealloc {
    for ( NSUInteger i = 0; i < self.noNodes; i++ ) {
        freeAdjacency(&adjacency[i]);
    }
    free(adjacency);
}

// check for intersecting vertex
-(NSUInteger) isIntersecting:(BOOL*)s_visited and:(BOOL*)t_visited {
    NSUInteger intersectNode = NSNotFound;
    for( NSUInteger i = 0; i < self.noNodes; i++ ) {
        // if a vertex is visited by both front
        // and back BFS search return that node
        // else return -1
        if( s_visited[i] && t_visited[i] ) {
            intersectNode = i;
            break;
        }
    }
    return intersectNode;
}

// Add edge
-(void) addEdgeFrom:(NSUInteger)src to:(NSUInteger)dest {
    // Add edge from src to dest
    appendAdjacency(&adjacency[src], dest);
    // Add edge from dest to src
    appendAdjacency(&adjacency[dest], src);
}

-(void) formPathFrom:(NSUInteger*)s_parent to:(NSUInteger*)t_parent source:(NSUInteger)source target:(NSUInteger)target intersectNode:(NSUInteger)intersectNode path:(LineStrip*)path {
    // Print the path from source to target
    
    appendLineStrip(path, intersectNode);
    NSUInteger i = intersectNode;
    while ( i != source ) {
        appendLineStrip(path, s_parent[i]);
        i = s_parent[i];
        if ( i == NSNotFound ) {
            break;
        }
    }
    reverseLineStrip(path);
    i = intersectNode;
    while( i != target ) {
        appendLineStrip(path, t_parent[i]);
        i = t_parent[i];
        if ( i == NSNotFound ) {
            break;
        }
    }
    printf("*****Path*****\n");
    for ( i = 0; i < path->used; i++ ) {
        printf(" %ld", path->array[i]);
    }
    printf("\n");
}

// Method for Breadth First Search BFS algorithm
-(void) BFS:(Queue*)queue visited:(BOOL*)visited parent:(NSUInteger*)parent {
    
    NSUInteger current = queue->array[0];
    removeQueueAtIndex(queue, 0);
    NSUInteger node;
    for( NSUInteger i = 0 ; i < adjacency[current].used; i++ ) {
        node = adjacency[current].array[i];
        if( !visited[node] ) {
            parent[node] = current;
            visited[node] = YES;
            appendQueue(queue, node);
        }
    }
}

-(NSUInteger) biDirSearchFromSource:(NSUInteger)source toTarget:(NSUInteger)target paths:(LineStripList*)paths {
    
    // first make a copy of the whole adjacency matrix
    // then remove the nodes that are connected if exists between source and target
    NSUInteger posFoundSource = NSNotFound, posFoundTarget = NSNotFound;
    if ( (posFoundSource = searchAdjacencyElementForSourceTarget(&adjacency[source], target)) != NSNotFound && (posFoundTarget = searchAdjacencyElementForSourceTarget(&adjacency[target], source)) != NSNotFound ) {
        removeAdjacencyAtIndex(&adjacency[source], posFoundSource);
        removeAdjacencyAtIndex(&adjacency[target], posFoundTarget);
    }
    
    // boolean array for BFS started from
    // source and target(front and backward BFS)
    // for keeping track on visited nodes
    BOOL *source_visited = (BOOL*)calloc((size_t)self.noNodes, sizeof(BOOL));
    BOOL *target_visited = (BOOL*)calloc((size_t)self.noNodes, sizeof(BOOL));

    // Keep track on parents of nodes
    // for front and backward search
    NSUInteger *source_parent = (NSUInteger*)calloc((size_t)self.noNodes, sizeof(NSUInteger));
    NSUInteger *target_parent = (NSUInteger*)calloc((size_t)self.noNodes, sizeof(NSUInteger));
    // queue for front and backward search
    Queue source_queue, target_queue;
    initQueue(&source_queue, 8);
    initQueue(&target_queue, 8);

    NSUInteger intersectNode = NSNotFound;

    // necessary initialization
    for(NSUInteger i = 0; i < self.noNodes; i++) {
        source_visited[i] = NO;
        target_visited[i] = NO;
    }
    appendQueue(&source_queue, source);
    source_visited[source] = YES;

    // parent of source is set to NSNotFound
    source_parent[source] = NSNotFound;

    appendQueue(&target_queue, target);
    target_visited[target] = YES;

    // parent of target is set to NSNotFound
    target_parent[target] = NSNotFound;
    
    while ( !isEmptyQueue(&source_queue) && !isEmptyQueue(&target_queue) ) {
        // Do BFS from source and target vertices
        [self BFS:&source_queue visited:source_visited parent:source_parent];
        [self BFS:&target_queue visited:target_visited parent:target_parent];
        
        // check for intersecting vertex
        intersectNode = [self isIntersecting:source_visited and:target_visited];

        // If intersecting vertex is found
        // that means there exist a path
        if( intersectNode != NSNotFound ) {
            NSLog(@"Path exist between %ld and %ld, Intersection at: %ld\n", source, target, intersectNode);
            // print the path and exit the program
            LineStrip path;
            initLineStrip(&path, 8);
            [self formPathFrom:source_parent to:target_parent source:source target:target intersectNode:intersectNode path:&path];
            if ( path.used > 2 ) {  // check it's at least a triangle
                if ( paths->used == 0 ) {
                    appendLineStripList(paths, path);
                }
                else {
                    NSInteger *canAdd = (NSInteger*)calloc(paths->used, sizeof(NSInteger));
                    for ( NSInteger i = (NSInteger)paths->used - 1; i > -1; i-- ) {
                        canAdd[i] = checkLineStripToAnotherForSameDifferentOrder(&(paths->array[i]), &path);
                    }
                    NSInteger ableToAdd = YES;
                    for ( NSInteger i = (NSInteger)paths->used - 1; i > -1; i-- ) {
                        ableToAdd &= canAdd[i];
                    }
                    if ( (BOOL)ableToAdd ) {
                        appendLineStripList(paths, path);
                    }
                    free(canAdd);
                }
            }
            break;
        }
    }
    free(source_visited);
    free(target_visited);
    free(source_parent);
    free(target_parent);
    freeQueue(&source_queue);
    freeQueue(&target_queue);
    
    // if the source and target Edge were taken out of the adjacency matrix replace it
    if ( posFoundSource !=  NSNotFound && posFoundTarget !=  NSNotFound ) {
        [self addEdgeFrom:source to:target];
    }
    
    return intersectNode;
}

@end
