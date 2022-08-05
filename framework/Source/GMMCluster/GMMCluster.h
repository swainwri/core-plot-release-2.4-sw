//
//  GMMCluster.h
//  CorePlot
//
//*       Prof. Charles A. Bouman
//*       Purdue University
//*       School of Electrical and Computer Engineering
//*       1285 Electrical Engineering Building
//*       West Lafayette, IN 47907-1285
//*       USA
//*       +1 765 494 0340
//*       +1 765 494 3358 (fax)
//*       email:  bouman@ecn.purdue.edu
//*       http://www.ece.purdue.edu/~bouman
//*
//* Copyright (c) 1995 The Board of Trustees of Purdue University.
//*
//  Ported from c to objective c by Steve Wainwright on 05/06/2022.
//

#import <Foundation/Foundation.h>
#import "GMMClusterDefinitions.h"

NS_ASSUME_NONNULL_BEGIN


typedef struct {
    GMMPoint * _Nonnull array;
    size_t used;
    size_t size;
} GMMPoints;

void initGMMPoints(GMMPoints * _Nonnull a, size_t initialSize);
void appendGMMPoints(GMMPoints * _Nonnull a, GMMPoint element);
void clearGMMPoints(GMMPoints *a);
void freeGMMPoints(GMMPoints * _Nonnull a);
void eigenValuesAndEigenVectorsOfCoVariance(SubSig * _Nonnull subSig, double * _Nonnull eigenValues, double * _Nonnull * _Nonnull eigenVectors, NSInteger dimension);


@interface GMMCluster : NSObject

@property (nonatomic, readwrite, assign) NSInteger init_num_of_subclasses;// #_subclasses - initial number of clusters for each class
@property (nonatomic, readwrite, assign) NSInteger nclasses; // <# of classes>
@property (nonatomic, readwrite, assign) NSInteger vector_dimension; // <data vector length>
@property (nonatomic, readwrite, assign) GMMClusterModel option1; //option1 - (optional) controls clustering model\n");
                                                            //      full - (default) use full convariance matrices\n");
                                                            //      diag - use diagonal convariance matrices\n\n");
@property (nonatomic, readwrite, assign) NSInteger option2; //    option2 - (optional) controls number of clusters\n");
                                                            //      0 - (default) estimate number of clusters\n");
                                                            //      n - use n clusters in mixture model with n<#_subclasses");

-(nonnull instancetype)initUsingNSArrayWithInitialSubclasses:(NSInteger)_init_num_of_subclasses noClasses:(NSInteger)_nclasses  vector_dimension:(NSInteger)_vector_dimension samples:(NSMutableArray<NSMutableArray<NSMutableArray<NSNumber*>*>*>*)objcSamples option1:(GMMClusterModel)_option1 option2:(NSInteger)_option2;

-(nonnull instancetype)initUsingGMMPointsWithInitialSubclasses:(NSInteger)_init_num_of_subclasses noClasses:(NSInteger)_nclasses vector_dimension:(NSInteger)_vector_dimension samples:(nonnull GMMPoints*)samplePoints option1:(GMMClusterModel)_option1 option2:(NSInteger)_option2;

-(void)initialiseUsingNSArrayWithNoClasses:(NSInteger)_nclasses vector_dimension:(NSInteger)_vector_dimension samples:(NSMutableArray<NSMutableArray<NSMutableArray<NSNumber*>*>*>*)objcSamples;

-(void)initialiseUsingGMMPointsWithNoClasses:(NSInteger)_nclasses vector_dimension:(NSInteger)_vector_dimension samples:(nonnull GMMPoints*)samplePoints;
-(void)initialiseClassesFromFile:(NSString*)infoFileName;

-(void)cluster;
-(void)clusterToParametersFile:(NSString*)paramsFilename;
-(void)classify;

-(void)classifyUsingNSArray:(NSMutableArray<NSMutableArray<NSNumber*>*>*)objcSamples;
-(void)classifyUsingGMMPoints:(nonnull GMMPoints*)samplePoints;
-(void)classifyWithDataFile:(NSString*)dataFileName;

-(void)splitClasses;
-(void)splitClassesWithParametersOutputFile:(NSString*)paramsFilename;

-(SigSet*)getSignatureSet;
-(SigSet*)getOutSignatureSet;

@end

NS_ASSUME_NONNULL_END
//1
//2
//data 500
