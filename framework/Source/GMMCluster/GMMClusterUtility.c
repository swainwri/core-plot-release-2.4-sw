/*
* All questions regarding the software should be addressed to
* 
*       Prof. Charles A. Bouman
*       Purdue University
*       School of Electrical and Computer Engineering
*       1285 Electrical Engineering Building
*       West Lafayette, IN 47907-1285
*       USA
*       +1 765 494 0340
*       +1 765 494 3358 (fax)
*       email:  bouman@ecn.purdue.edu
*       http://www.ece.purdue.edu/~bouman
* 
* Copyright (c) 1995 The Board of Trustees of Purdue University.
*
* Permission to use, copy, modify, and distribute this software and its
* documentation for any purpose, without fee, and without written agreement is
* hereby granted, provided that the above copyright notice and the following
* two paragraphs appear in all copies of this software.
*
* IN NO EVENT SHALL PURDUE UNIVERSITY BE LIABLE TO ANY PARTY FOR DIRECT,
* INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE
* USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF PURDUE UNIVERSITY HAS
* BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*
* PURDUE UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES, INCLUDING, BUT NOT
* LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
* PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS ON AN "AS IS" BASIS,
* AND PURDUE UNIVERSITY HAS NO OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT,
* UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
*/

#include "GMMClusterDefinitions.h"
#include "GMMMemoryUtility.h"
#include "GMMClusterUtility.h"


short I_SigSetNClasses(SigSet *S) {
    short count = 0;
    for ( short i = 0; i < S->nclasses; i++ ) {
        if ( S->classSig[i].used ) {
            count++;
        }
    }
    return count;
}


ClassData *I_AllocClassData(SigSet *S, ClassSig *C, size_t npixels) {
    ClassData *Data;

    Data = &(C->classData);
    Data->npixels = npixels;
    Data->x = G_alloc_matrix(npixels, (size_t)S->nbands);
    Data->p = G_alloc_matrix(npixels, (size_t)C->nsubclasses);
    Data->w = G_alloc_vector(npixels * sizeof(double));
    return Data;
}


void I_InitSigSet(SigSet *S) {
    S->nbands = 0;
    S->nclasses = 0;
    S->classSig = NULL;
    S->title = NULL;
}

void I_SigSetNBands(SigSet *S, int nbands) {
    S->nbands = nbands;
}

ClassSig *I_NewClassSig(SigSet *S) {
    ClassSig *Sp;
    if (S->nclasses == 0) {
        S->classSig = G_malloc_ClassSig(1);
    }
    else {
        S->classSig = G_realloc_ClassSig(S->classSig, (size_t)S->nclasses + 1);
    }
    Sp = &S->classSig[S->nclasses++];
    Sp->classnum = 0;
    Sp->nsubclasses = 0;
    Sp->used = 1;
    Sp->type = SIGNATURE_TYPE_MIXED;
    Sp->title = NULL;
    Sp->classData.npixels = 0;
    Sp->classData.SummedWeights = 0.0;
    Sp->classData.x = NULL;
    Sp->classData.p = NULL;
    Sp->classData.w = NULL;

    return Sp;
}


SubSig *I_NewSubSig(SigSet *S, ClassSig *C) {
    SubSig *Sp;

    if ( C->nsubclasses == 0 ) {
        C->subSig = G_malloc_SubSig(1);
    }
    else {
        C->subSig = G_realloc_SubSig(C->subSig, (size_t)C->nsubclasses + 1);
    }
    Sp = &C->subSig[C->nsubclasses++];
    Sp->used = 1;
    Sp->R = (double **)calloc((size_t)S->nbands, sizeof(double *));
    Sp->R[0] = (double *)calloc((size_t)S->nbands * (size_t)S->nbands, sizeof(double));
    for ( int i = 1; i < S->nbands; i++ ) {
        Sp->R[i] = Sp->R[i-1] + S->nbands;
    }
    Sp->Rinv = (double **)calloc((size_t)S->nbands, sizeof(double *));
    Sp->Rinv[0] = (double *)calloc((size_t)S->nbands * (size_t)S->nbands, sizeof(double));
    for ( int i = 1; i < S->nbands; i++ ) {
        Sp->Rinv[i] = Sp->Rinv[i-1] + S->nbands;
    }
    Sp->means = (double *)calloc((size_t)S->nbands, sizeof(double));
    Sp->N = 0;
    Sp->pi = 0;
    Sp->cnst = 0;
    return Sp;
}


void I_SetSigTitle(SigSet *S, char *title) {
    if (title == NULL) {
        title = "";
    }
    if (S->title) {
        free(S->title);
    }
    S->title = G_malloc(strlen(title) + 1);
    strncpy(S->title, title, strlen(title) + 1);
}


char *I_GetSigTitle(SigSet *S) {
    if (S->title) {
        return S->title;
    }
    else {
        return "";
    }
}


void I_SetClassTitle(ClassSig *C, char *title) {
    if (title == NULL) {
        title = "";
    }
    if (C->title) {
        free(C->title);
    }
    C->title = G_malloc (strlen (title)+1);
    strncpy(C->title, title, strlen(title) + 1);
}

char *I_GetClassTitle(ClassSig *C) {
    if (C->title) {
        return C->title;
    }
    else {
        return "";
    }
}


/* Deallocators */

void I_DeallocClassData(ClassSig *C) {
    ClassData *Data;

    Data = &(C->classData);
    G_free_matrix(Data->x);
    Data->x = NULL;
    G_free_matrix(Data->p);
    Data->p = NULL;
    G_free_vector(Data->w);
    Data->w = NULL;
    Data->npixels = 0;
    Data->SummedWeights = 0.0;
}

    
void I_DeallocSubSig(ClassSig *C) {
    SubSig *Sp;

    Sp = &C->subSig[--C->nsubclasses];

    G_dealloc( (char *) Sp->R[0] );
    G_dealloc( (char *) Sp->R );
    G_dealloc( (char *) Sp->Rinv[0] );
    G_dealloc( (char *) Sp->Rinv );
    G_dealloc( (char *) Sp->means );

    C->subSig = G_realloc_SubSig(C->subSig,  (size_t)C->nsubclasses);
}


void I_DeallocClassSig(SigSet *S) {
    ClassSig *Sp;
    
    Sp = &(S->classSig[--S->nclasses]);
    
    I_DeallocClassData(Sp);
    
    while( Sp->nsubclasses > 0 ) {
        I_DeallocSubSig(Sp);
    }
    S->classSig = G_realloc_ClassSig(S->classSig, (size_t)S->nclasses);
}     
    

void I_DeallocSigSet(SigSet *S) {
    while(S->nclasses > 0) {
        I_DeallocClassSig( S );
    }
    G_dealloc(S->title);
}



