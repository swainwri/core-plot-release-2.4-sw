//
//  GMMClusterClassify.m
//  CorePlot
//
//  Created by Steve Wainwright on 05/06/2022.
//

#import "NSNumberExtensions.h"
#import "GMMCluster.h"
#import "GMMClusterDefinitions.h"
#import "GMMClusterUtility.h"
#import "GMMMemoryUtility.h"
#import "GMMCluster_IO.h"
#import "GMMSubCluster.h"
#import "GMMClassifyUtility.h"
#import "GMMEigen.h"

void initGMMPoints(GMMPoints *a, size_t initialSize) {
    a->array = (GMMPoint*)calloc(initialSize, sizeof(GMMPoint));
    a->used = 0;
    a->size = initialSize;
}

void appendGMMPoints(GMMPoints *a, GMMPoint element) {
    // a->used is the number of used entries, because a->array[a->used++] updates a->used only *after* the array has been accessed.
    // Therefore a->used can go up to a->size
    if (a->used == a->size) {
        a->size *= 2;
        a->array = (GMMPoint*)realloc(a->array, a->size * sizeof(GMMPoint));
    }
    a->array[a->used++] = element;
}

void clearGMMPoints(GMMPoints *a) {
    a->used = 0;
}

void freeGMMPoints(GMMPoints *a) {
    free(a->array);
    a->used = 0;
    a->size = 0;
}

void eigenValuesAndEigenVectorsOfCoVariance(SubSig* subSig, double* eigenValues, double** eigenVectors, NSInteger dimension) {
    for ( NSInteger i = 0; i < dimension; i++ ) {
        for ( NSInteger j = 0; j < dimension; j++ ) {
            eigenVectors[i][j] = subSig->R[i][j];
        }
    }
    eigen(eigenVectors, eigenValues, (int)dimension);
}


@interface GMMCluster()

@property (nonatomic, readwrite, assign) BOOL useFilesForInput;
@property (nonatomic, readwrite, assign) BOOL usedExternalSamples;
@property (nonatomic, readwrite, assign) BOOL usedExternalTrainedSamples;

@end

@implementation GMMCluster

static SigSet S, Sout;
static GMMPoints *samples;  // dimension nclasses by _vector_dimension
static GMMPoints trainedSamples;
extern int clusterMessageVerboseLevel;

@synthesize init_num_of_subclasses;
@synthesize nclasses;
@synthesize vector_dimension;
@synthesize option1;
@synthesize option2;
@synthesize useFilesForInput;
@synthesize usedExternalSamples;
@synthesize usedExternalTrainedSamples;

- (instancetype)init {
    if ( (self = [super init]) ) {
        self.init_num_of_subclasses = 20;
        self.nclasses = 1;
        self.vector_dimension = 2;
        
        self.option1 = GMMClusterModelFull;
        self.option2 = 0;
        useFilesForInput = NO;
        usedExternalSamples = NO;
        usedExternalTrainedSamples = NO;
    }
    return self;
}

-(instancetype)initUsingNSArrayWithInitialSubclasses:(NSInteger)_init_num_of_subclasses noClasses:(NSInteger)_nclasses  vector_dimension:(NSInteger)_vector_dimension samples:(NSMutableArray<NSMutableArray<NSMutableArray<NSNumber*>*>*>*)objcSamples option1:(GMMClusterModel)_option1 option2:(NSInteger)_option2 {
    if ( (self = [super init]) ) {
        self.init_num_of_subclasses = _init_num_of_subclasses;
        self.nclasses = _nclasses;
        self.vector_dimension = _vector_dimension;
        
        samples = (GMMPoints*)calloc((size_t)self.nclasses, sizeof(GMMPoints));
        NSUInteger i = 0;
        GMMPoint element;
#if defined(__STRICT_ANSI__)
        element.v[0] = -0.0;
        element.v[1] = -0.0;
        element.v[2] = -0.0;
#else
        element.x = -0.0;
        element.y = -0.0;
        element.z = -0.0;
#endif
        for( NSMutableArray *classes in objcSamples) {
            initGMMPoints(&samples[i], (size_t)classes.count);
            for( NSMutableArray *data in classes) {
                for ( NSUInteger j = 0; j < (NSUInteger)self.vector_dimension; j++ ) {
                    element.v[j] = [(NSNumber*)[data objectAtIndex:j] cgFloatValue];
                }
                appendGMMPoints(&samples[i], element);
            }
            i++;
        }
        self.option1 = _option1;
        self.option2 = _option2;
        useFilesForInput = NO;
        usedExternalSamples = NO;
        usedExternalTrainedSamples = NO;
    }
    return self;
}

-(instancetype)initUsingGMMPointsWithInitialSubclasses:(NSInteger)_init_num_of_subclasses noClasses:(NSInteger)_nclasses vector_dimension:(NSInteger)_vector_dimension samples:(GMMPoints*)samplePoints option1:(GMMClusterModel)_option1 option2:(NSInteger)_option2 {
    if ( (self = [super init]) ) {
        self.init_num_of_subclasses = _init_num_of_subclasses;
        self.nclasses = _nclasses;
        self.vector_dimension = _vector_dimension;
        samples = samplePoints;
        useFilesForInput = NO;
        usedExternalSamples = YES;
        usedExternalTrainedSamples = NO;
    }
    return self;
}

-(void)dealloc {
    // if you want to keep class data
//    for( NSInteger k = 0; k < self.nclasses; k++ ) {
//        I_DeallocClassData(&(S.classSig[k]));
//    }
    if ( !usedExternalSamples ) {
        for( NSInteger i = 0; i < S.nclasses; i++ ) {
            if ( samples[i].size > 0 ) {
                freeGMMPoints(&samples[i]);
            }
        }
    }
    if ( !usedExternalTrainedSamples ) {
        freeGMMPoints(&trainedSamples);
    }

    /* De-allocate cluster signature memory */
    I_DeallocSigSet(&S);
    I_DeallocSigSet(&Sout);
}

-(void)initialiseUsingNSArrayWithNoClasses:(NSInteger)_nclasses vector_dimension:(NSInteger)_vector_dimension samples:(NSMutableArray<NSMutableArray<NSMutableArray<NSNumber*>*>*>*)objcSamples {
    
    self.nclasses = _nclasses;
    self.vector_dimension = _vector_dimension;
        
    samples = (GMMPoints*)calloc((size_t)self.nclasses, sizeof(GMMPoints));
    NSUInteger i = 0;
    GMMPoint element;
#if defined(__STRICT_ANSI__)
        element.v[0] = -0.0;
        element.v[1] = -0.0;
        element.v[2] = -0.0;
#else
        element.x = -0.0;
        element.y = -0.0;
        element.z = -0.0;
#endif
    for( NSMutableArray *classes in objcSamples) {
        initGMMPoints(&samples[i], (size_t)classes.count);
        for( NSMutableArray *data in classes) {
            for ( NSUInteger j = 0; j < (NSUInteger)self.vector_dimension; j++ ) {
                element.v[j] = [(NSNumber*)[data objectAtIndex:j] cgFloatValue];
            }
            appendGMMPoints(&samples[i], element);
        }
        i++;
    }
    self.useFilesForInput = NO;
    self.usedExternalSamples = NO;
}

-(void)initialiseUsingGMMPointsWithNoClasses:(NSInteger)_nclasses vector_dimension:(NSInteger)_vector_dimension samples:(GMMPoints*)samplePoints {
    
    self.nclasses = _nclasses;
    self.vector_dimension = _vector_dimension;
        
    samples = samplePoints;
    
    self.useFilesForInput = NO;
    self.usedExternalSamples = YES;
}

-(void)initialiseClassesFromFile:(NSString*)infoFileName {
    
    FILE *fp, *info_fp;
    const char *_infoFileName = [infoFileName cStringUsingEncoding:NSUTF8StringEncoding];
    if( (info_fp = fopen(_infoFileName,"r")) == NULL) {
        NSLog(@"Can't open information file\n");
        return;
    }
    
    NSInteger _nclasses, _vector_dimension;
    /* read number of classes from info file */
    fscanf(info_fp,"%ld\n",&_nclasses);

    /* read vector dimension from info file */
    fscanf(info_fp,"%ld\n",&_vector_dimension);

    self.nclasses = _nclasses;
    self.vector_dimension = _vector_dimension;
    
    /* Initialize SigSet data structure */
    I_InitSigSet(&S);
    I_SigSetNBands(&S, (int)self.vector_dimension);
    I_SetSigTitle(&S, "test signature set");

    ClassSig *Sig;
    /* Allocate memory for cluster signatures */
    for( NSInteger k = 0; k < self.nclasses; k++ ) {
        Sig = I_NewClassSig(&S);
        I_SetClassTitle (Sig, "test class signature");
        for( NSInteger i = 0; i < self.init_num_of_subclasses; i++ ) {
            I_NewSubSig (&S, Sig);
        }
    }
    
    NSMutableString *paramsFileNamePath = [NSMutableString new];
    [paramsFileNamePath appendString:[infoFileName stringByDeletingLastPathComponent]];
    
    char fname[512];
    size_t num_of_samples;
    /* Read data for each class */
    for( NSInteger k = 0; k < self.nclasses; k++) {
        /* read class k data file name */
        fscanf(info_fp,"%s",fname);
        
        NSString *objcFName = [NSString stringWithUTF8String:fname];
        NSString *paramsFileName = [paramsFileNamePath stringByAppendingPathComponent:objcFName];
        
        /* read number of samples for class k */
        fscanf(info_fp,"%ld\n",&num_of_samples);

        Sig = &(S.classSig[k]);

        I_AllocClassData (&S, Sig, num_of_samples);

        /* Read Data */
        if( (fp = fopen([paramsFileName cStringUsingEncoding:NSUTF8StringEncoding], "r")) == NULL) {
            NSLog(@"Can't open data file\n");
            return;
        }

        for( size_t i = 0; i < Sig->classData.npixels; i++) {
            for(  NSInteger j = 0; j < self.vector_dimension; j++ ) {
                fscanf(fp, "%lf", &(Sig->classData.x[i][j]) );
            }
            fscanf(fp,"\n");
        }
        fclose(fp);

        /* Set unity weights and compute SummedWeights */
        Sig->classData.SummedWeights = 0.0;
        for( size_t i = 0; i < Sig->classData.npixels; i++) {
            Sig->classData.w[i] = 1.0;
            Sig->classData.SummedWeights += Sig->classData.w[i];
        }
    }
    fclose(info_fp);
    
    self.useFilesForInput = YES;
    self.usedExternalSamples = NO;
}

-(void)cluster {
    /* set level of diagnostic printing */
    clusterMessageVerboseLevel = 2;
    ClassSig *Sig;
    if ( !self.useFilesForInput ) {
        /* Initialize SigSet data structure */
        I_InitSigSet(&S);
        I_SigSetNBands(&S, (int)self.vector_dimension);
        I_SetSigTitle(&S, "test signature set");

        /* Allocate memory for cluster signatures */
        for( int k = 0; k < self.nclasses; k++ ) {
            Sig = I_NewClassSig(&S);
            I_SetClassTitle (Sig, "test class signature");
            for( int i = 0; i < self.init_num_of_subclasses; i++ ) {
                I_NewSubSig (&S, Sig);
            }
        }

        /* Read data for each class */
        for( int k = 0; k < self.nclasses; k++ ) {
            Sig = &(S.classSig[k]);
            I_AllocClassData(&S, Sig, samples[k].used);
            for( size_t i = 0; i < Sig->classData.npixels; i++ ) {
                for( NSInteger j = 0; j < self.vector_dimension; j++ ) {
                    Sig->classData.x[i][j] = samples[k].array[i].v[j];
                }
            }
            
            /* Set unity weights and compute SummedWeights */
            Sig->classData.SummedWeights = 0.0;
            for( size_t i = 0; i < Sig->classData.npixels; i++ ) {
                Sig->classData.w[i] = 1.0;
                Sig->classData.SummedWeights += Sig->classData.w[i];
            }
        }
    }
    
    /* Compute the average variance over all classes */
    double Rmin = 0;
    for( NSInteger k = 0; k < self.nclasses; k++ ) {
        Sig = &(S.classSig[k]);
        Rmin += [self averageVariance:Sig noBands: (int)self.vector_dimension];
    }
    Rmin = Rmin / (COVAR_DYNAMIC_RANGE * self.nclasses);

    int max_num = (int)self.nclasses * 2;
    
    /* Perform clustering for each class */
    for( NSInteger k = 0; k < self.nclasses; k++ ) {
        Sig = &(S.classSig[k]);
        if( 1 <= clusterMessageVerboseLevel ) {
            NSLog(@"Start clustering class %ld\n\n", k);
        }
        /* assume covariance matrices to be diagonal */
        /* no assumption for covariance matrices */
        subcluster(&S, (int)k, (int)self.option2, self.option1, Rmin, &max_num);
        
        if( 2 <= clusterMessageVerboseLevel ) {
            NSLog(@"Maximum number of subclasses = %d\n", max_num);
        }
        I_DeallocClassData(Sig); // comments out if you wants to keep class data, see dealloc also
    }
}

-(void)clusterToParametersFile:(NSString*)paramsFilename {
    [self cluster];
    const char *_paramsFileName = [paramsFilename cStringUsingEncoding:NSUTF8StringEncoding];
        /* Write out result to output parameter file */
    FILE *fp;
    if(( fp = fopen(_paramsFileName, "w")) == NULL) {
        NSLog(@"can't open parameter output file\n");
        return;
    }
    I_WriteSigSet(fp, &S);
    fclose(fp);
}

-(double)averageVariance:(ClassSig *)Sig noBands:(int)nbands {
    /* Compute the mean of variance for each band */
    double *mean = G_alloc_vector((size_t)nbands);
    double **R = G_alloc_matrix((size_t)nbands, (size_t)nbands);

    for( int b1 = 0; b1 < nbands; b1++ ) {
        mean[b1] = 0.0;
        for( int i = 0; i < (int)Sig->classData.npixels; i++ ) {
            mean[b1] += (Sig->classData.x[i][b1])*(Sig->classData.w[i]);
        }
        mean[b1] /= Sig->classData.SummedWeights;
    }

    for( int b1 = 0; b1 < nbands; b1++ ) {
        R[b1][b1] = 0.0;
        for( int i = 0; i < (int)Sig->classData.npixels; i++) {
            R[b1][b1] += (Sig->classData.x[i][b1]) * (Sig->classData.x[i][b1]) * (Sig->classData.w[i]);
        }
        R[b1][b1] /= Sig->classData.SummedWeights;
        R[b1][b1] -= mean[b1] * mean[b1];
    }

    /* Compute average of diagonal entries */
    double Rmin = 0.0;
    for( int b1 = 0; b1 < nbands; b1++ ) {
        Rmin += R[b1][b1];
    }
    Rmin = Rmin / (nbands);

    G_free_vector(mean);
    G_free_matrix(R);

    return Rmin;
}

-(void)classifyUsingNSArray:(NSMutableArray<NSMutableArray<NSNumber*>*>*)objcSamples {
    if ( trainedSamples.size == 0 ) {
        initGMMPoints(&trainedSamples, objcSamples.count);
    }
    else {
        clearGMMPoints(&trainedSamples);
    }
    GMMPoint element;
#if defined(__STRICT_ANSI__)
        element.v[0] = -0.0;
        element.v[1] = -0.0;
        element.v[2] = -0.0;
#else
        element.x = -0.0;
        element.y = -0.0;
        element.z = -0.0;
#endif
    for( NSMutableArray *data in objcSamples) {
        for ( NSUInteger i = 0; i < (NSUInteger)self.vector_dimension; i++ ) {
            element.v[i] = [(NSNumber*)[data objectAtIndex:i] cgFloatValue];
        }
        appendGMMPoints(&trainedSamples, element);
    }
    self.usedExternalTrainedSamples = NO;
}

-(void)classifyUsingGMMPoints:(nonnull GMMPoints*)samplePoints {
    trainedSamples = *samplePoints;
    self.usedExternalTrainedSamples = YES;
}

-(void)classifyWithDataFile:(NSString*)dataFileName {
    
    FILE *fp;
    const char *_dataFileName = [dataFileName cStringUsingEncoding:NSUTF8StringEncoding];
    /* Determine number of lines in file */
    if( (fp = fopen(_dataFileName, "r")) == NULL ) {
        NSLog(@"\nError: Can't open data file %@", dataFileName);
        return;
    }
    double tmp;
    int NRead = 1;
    int NDataVectors = -1;
    while( NRead > 0 ) {
      for( int j = 0; j < S.nbands; j++ ) {
        NRead = fscanf(fp, "%lf", &tmp );
      }
      fscanf(fp, "\n");
      NDataVectors++;
    }
    fclose(fp);

    initGMMPoints(&trainedSamples, (size_t)NDataVectors);
    /* Read lines from file */
    if( (fp = fopen(_dataFileName,"r")) == NULL ) {
      fprintf(stderr, "\nError: Can't open data file %s", _dataFileName);
      exit(-1);
    }
    
    for( int i = 0; i < NDataVectors; i++) {
        for( int j = 0; j < S.nbands; j++ ) {
            fscanf(fp, "%lf", &(trainedSamples.array[i].v[j]));
        }
        fscanf(fp,"\n");
    }
    fclose(fp);
    self.usedExternalTrainedSamples = NO;
}

-(void)classify {
    
    /* Initialize constants for Log likelihood calculations */
    ClassLogLikelihood_init(&S);

    /* Compute Log likelihood for each class*/
    double *ll = G_alloc_vector((size_t)S.nclasses);
    double maxval;
    int maxindex;
    
    for( size_t i = 0; i < samples[0].used; i++ ) {
        ClassLogLikelihood(samples[0].array[i], ll, &S);
        maxval = ll[0];
        maxindex = 0;
        for( int j = 0; j < S.nclasses; j++ ) {
            if( ll[j] > maxval ) {
                maxval = ll[j];
                maxindex = j;
            }
        }
        for( int j = 0; j < S.nclasses; j++ ) {
           printf("Loglike = %g ", ll[j]);
            
        }
        printf("ML Class = %d\n",maxindex);
    }

    G_free_vector(ll);
}

-(void)splitClasses {
    /* Initialize SigSet data structure */
    I_InitSigSet (&Sout);
    I_SigSetNBands (&Sout, S.nbands);
    I_SetSigTitle (&Sout, "signature set for unsupervised clustering");
    
    ClassSig *Sig;
    
    /* Copy each subcluster (subsignature) from input to cluster (class signature) of output */
    for( int k = 0; k < S.nclasses; k++ ) {
        for( int l = 0; l < (S.classSig[k].nsubclasses); l++ ) {
            Sig = I_NewClassSig(&Sout);
            I_SetClassTitle (Sig, "Single Model Class");
            I_NewSubSig (&Sout, Sig);
            Sig->subSig[0].pi = 1.0;
            for( int i = 0; i < S.nbands; i++ ) {
                Sig->subSig[0].means[i] = S.classSig[k].subSig[l].means[i];
            }
            for( int i = 0; i < S.nbands; i++ ) {
                for( int j = 0; j < S.nbands; j++ ) {
                    Sig->subSig[0].R[i][j] = S.classSig[k].subSig[l].R[i][j];
                }
            }
        }
    }
}

-(void)splitClassesWithParametersOutputFile:(NSString*)paramsFilename {
    [self splitClasses];
    const char *_paramsFileName = [paramsFilename cStringUsingEncoding:NSUTF8StringEncoding];
        /* Write out result to output parameter file */
    FILE *fp;
    if(( fp = fopen(_paramsFileName, "w")) == NULL) {
        NSLog(@"can't open parameter output file\n");
        return;
    }
    I_WriteSigSet(fp, &Sout);
    fclose(fp);
}

-(SigSet*)getSignatureSet {
    return &S;
}

-(SigSet*)getOutSignatureSet {
    return &Sout;
}

@end
