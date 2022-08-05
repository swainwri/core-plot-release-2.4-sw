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


#include "GMMMemoryUtility.h"


char *G_malloc(size_t n) {
    char *b = NULL;
    if ( n > 0 ) {
        b = malloc(n * sizeof(char));
    }
    return b;;
}


char *G_calloc(size_t n, size_t m) {
    char *b = NULL;
    if ( n > 0 || m > 0 ) {
        b = calloc(n, m * sizeof(char));
    }
    return(b);
}


char *G_realloc(char *b, size_t n) {
    if ( n > 0 ) {
        if ( b == NULL ) {
            b = malloc(n  * sizeof(char));
        }
        else {
            b = realloc(b,  n * sizeof(char));
        }
    }
    return(b);
}

void G_dealloc(char *b) {
    free( b );
}

ClassSig *G_malloc_ClassSig(size_t n) {
    ClassSig *b = NULL;
    if ( n > 0 ) {
        b = malloc(n * sizeof(ClassSig));
    }
    return b;
}

ClassSig *G_calloc_ClassSig(size_t n) {
    ClassSig *b = NULL;
    if ( n > 0 ) {
        b = calloc(n, sizeof(ClassSig));
    }
    return b;
}

ClassSig *G_realloc_ClassSig(ClassSig *b, size_t n) {
    if ( n > 0 ) {
        if ( b == NULL ) {
            b = malloc(n * sizeof(ClassSig));
        }
        else {
            b = realloc(b, n * sizeof(ClassSig));
        }
    }
    return(b);
}

void G_dealloc_ClassSig(ClassSig *b) {
    free(b);
}

SubSig *G_malloc_SubSig(size_t n) {
    SubSig *b = NULL;
    if ( n > 0 ) {
        b = malloc(n * sizeof(SubSig));
    }
    return b;
}

SubSig *G_calloc_SubSig(size_t n) {
    SubSig *b = NULL;
    if ( n > 0 ) {
        b = calloc(n, sizeof(SubSig));
    }
    return b;
}

SubSig *G_realloc_SubSig(SubSig *b, size_t n) {
    if ( n > 0 ) {
        if ( b == NULL ) {
            b = malloc(n * sizeof(SubSig));
        }
        else {
            b = realloc(b, n * sizeof(SubSig));
        }
    }
    return(b);
}

void G_dealloc_SubSig(SubSig *b) {
    free(b);
}

double *G_alloc_vector(size_t n) {
    return (double *)calloc(n, sizeof(double));
}


double **G_alloc_matrix(size_t rows, size_t cols) {
    double **m = (double **)calloc(rows, sizeof(double *));
    m[0] = (double *)calloc(rows * cols, sizeof(double));
    for ( size_t i = 1; i < rows; i++ ) {
        m[i] = m[i-1] + cols;
    }
    return m;
}


void G_free_vector(double *v) {
    if( v != NULL) {
        free(v);
    }
}


void G_free_matrix(double **m) {
    if( m != NULL ) {
      free((char *)(m[0]));
      free((char *)m);
    }
}


int *G_alloc_ivector(size_t n) {
    return (int *)calloc(n, sizeof(int));
}

int **G_alloc_imatrix(size_t rows, size_t cols) {
    
    int **m = (int **)calloc(rows, sizeof(int *));
    m[0] = (int *)calloc(rows * cols, sizeof(int));
    for ( size_t i = 1; i < rows; i++ ) {
        m[i] = m[i-1] + cols;
    }
    return m;
}


void G_free_ivector(int *v) {
    if( v != NULL ) {
      free (v);
    }
}


void G_free_imatrix(int **m) {
    if( m != NULL ) {
      free ((m[0]));
      free (m);
    }
}
