//
//  GMMClusterTest.m
//  CorePlot
//
//  Created by Steve Wainwright on 07/06/2022.
//

#import "GMMClusterTests.h"
#import "GMMCluster.h"

@implementation GMMClusterTests

@synthesize cluster;

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
    
    self.cluster = [GMMCluster new];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    self.cluster = nil;
}

- (void)testClusterUsingInputFile {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
    
    NSArray *dirPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    // Get the documents directory
    NSString *infoFile = [[dirPaths objectAtIndex:0] stringByAppendingPathComponent:@"GMMCluster/info_file1"];
    NSString *paramsFile = [[dirPaths objectAtIndex:0] stringByAppendingPathComponent:@"GMMCluster/params1"];
    
    
    [self.cluster initialiseClassesFromFile:infoFile];
    [self.cluster clusterToParametersFile:paramsFile];
}

- (void)testClusterUsingGMMPoints {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
    
    NSArray *dirPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    
    NSString *dataFile3 = [[dirPaths objectAtIndex:0] stringByAppendingPathComponent:@"GMMCluster/data3"];
    NSString *paramsFile3 = [[dirPaths objectAtIndex:0] stringByAppendingPathComponent:@"GMMCluster/params3"];
    
    NSFileManager *filemgr = [NSFileManager defaultManager];
    if ([filemgr fileExistsAtPath: dataFile3]) {
        @autoreleasepool {
            NSError *_error;
            NSString* content;
            if ( (content = [NSString stringWithContentsOfFile:dataFile3 encoding:NSUTF8StringEncoding error:&_error]) == nil ) {
                _error = nil;
                content = [NSString stringWithContentsOfFile:dataFile3 encoding:NSUTF16StringEncoding error:&_error];
            }
            if ( _error == nil ) {
                NSArray *fileLines;
                NSRange rangeOccurence = [content rangeOfString:@"\r\n"];
                if(rangeOccurence.location == NSNotFound) {
                    rangeOccurence = [content rangeOfString:@"\n"];
                    if(rangeOccurence.location == NSNotFound) {
                        rangeOccurence = [content rangeOfString:@"\r"];
                        if(rangeOccurence.location == NSNotFound) {
                            NSLog(@"Parser Exception: No lines");
                        }
                        else {
                            fileLines = [content componentsSeparatedByString:@"\r"];
                        }
                    }
                    else {
                        fileLines = [content componentsSeparatedByString:@"\n"];
                    }
                }
                else {
                    fileLines = [content componentsSeparatedByString:@"\r\n"];
                }
                if ( fileLines.count > 0 ) {
                    NSCharacterSet *commaSet = [NSCharacterSet characterSetWithCharactersInString:@","];
                    NSCharacterSet *tabSet = [NSCharacterSet characterSetWithCharactersInString:@"\t"];
                    NSCharacterSet *spaceSet = [NSCharacterSet characterSetWithCharactersInString:@" "];
                    NSCharacterSet *characterSet;
                    
                    rangeOccurence = [content rangeOfCharacterFromSet:commaSet];
                    if(rangeOccurence.location != NSNotFound && rangeOccurence.location > [(NSString*)fileLines[0] length])
                        characterSet = commaSet;
                    else
                    {
                        rangeOccurence = [content rangeOfCharacterFromSet:tabSet];
                        if(rangeOccurence.location != NSNotFound && rangeOccurence.location > [(NSString*)fileLines[0] length])
                            characterSet = tabSet;
                        else
                            characterSet = spaceSet;
                    }
                    
                    GMMPoints samplePoints[1];
                    initGMMPoints(&samplePoints[0], fileLines.count);
                    NSMutableArray *items;
                    GMMPoint gmmpoint;
                    for ( NSUInteger ii = 0; ii < fileLines.count; ii++ ) {
                        items = (NSMutableArray*)[fileLines[ii] componentsSeparatedByCharactersInSet:characterSet];
                        NSMutableIndexSet *indexes = (NSMutableIndexSet*)[items indexesOfObjectsWithOptions:NSEnumerationConcurrent passingTest:^(id obj, NSUInteger idx, BOOL *stop) {
                                NSLog(@"%ld %d", idx, (int)*stop);
                                   NSString *item = (NSString *)obj;
                                   if([item isEqualToString:@""])
                                       return NO;
                                   else
                                       return YES;
                               }];
                            if([indexes count] > 0 && [indexes count] != [items count]) {
                                NSMutableArray *itemsCopy = [[NSMutableArray alloc] initWithCapacity:[indexes count]];
                                NSUInteger idx = [indexes firstIndex];
                                while(idx != NSNotFound) {
                                    [itemsCopy addObject: items[idx]];
                                    idx = [indexes indexGreaterThanIndex:idx];
                                }
                                [items removeAllObjects];
                                [items addObjectsFromArray:itemsCopy];
                            }
                        }

                        
                        if( items.count == 2 ) {
                            gmmpoint.x = [items[0] doubleValue];
                            gmmpoint.y = [items[1] doubleValue];
                            appendGMMPoints(&samplePoints[0], gmmpoint);
                        }
                    }
                    [gmmCluster initialiseUsingGMMPointsWithNoClasses:1 vector_dimension:2 samples:samplePoints];
                    [gmmCluster clusterToParametersFile: paramsFile3];
                }
            }
        }
    }
    else {
        NSLog(@"Parser Exception: File does not exist!");
    }
}

//- (void)testPerformanceExample {
//    // This is an example of a performance test case.
//    [self measureBlock:^{
//        // Put the code you want to measure the time of here.
//    }];
//}

@end
