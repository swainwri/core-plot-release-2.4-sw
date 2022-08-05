//
//  _CPTContourGraph.h
//  CorePlot
//
//  Created by Steve Wainwright on 13/05/2022.
//

#import <Foundation/Foundation.h>
#import "_CPTContours.h"

NS_ASSUME_NONNULL_BEGIN

@interface _CPTContourGraph : NSObject
/// @name Graph variables
/// @{
@property (nonatomic, readwrite) NSUInteger noNodes;
/// @}

- (instancetype)initWithNoNodes:(NSUInteger)newNoNodes;
-(void) addEdgeFrom:(NSUInteger)src to:(NSUInteger)dest;
-(void) formPathFrom:(NSUInteger*)s_parent to:(NSUInteger*)t_parent source:(NSUInteger)source target:(NSUInteger)target intersectNode:(NSUInteger)intersectNode path:(LineStrip*)path;
-(NSUInteger) biDirSearchFromSource:(NSUInteger)source toTarget:(NSUInteger)target paths:(LineStripList*)paths;
@end


NS_ASSUME_NONNULL_END
