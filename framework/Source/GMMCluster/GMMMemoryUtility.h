
#ifndef ALLOC_UTIL_H
#define ALLOC_UTIL_H

#include <stddef.h>
#include <stdlib.h>
#include "GMMClusterDefinitions.h"

char *G_malloc(size_t n);
char *G_calloc(size_t n, size_t m);
char *G_realloc(char *b, size_t n);
void G_dealloc(char *b);

ClassSig *G_malloc_ClassSig(size_t n);
ClassSig *G_calloc_ClassSig(size_t n);
ClassSig *G_realloc_ClassSig(ClassSig *b, size_t n);
void G_dealloc_ClassSig(ClassSig *b);

SubSig *G_malloc_SubSig(size_t n);
SubSig *G_calloc_SubSig(size_t n);
SubSig *G_realloc_SubSig(SubSig *b, size_t n);
void G_dealloc_SubSig(SubSig *b);

double *G_alloc_vector(size_t n);
double **G_alloc_matrix(size_t rows, size_t cols);
void G_free_vector(double *v);
void G_free_matrix(double **m);

int *G_alloc_ivector(size_t n);
int **G_alloc_imatrix(size_t rows, size_t cols);
void G_free_ivector(int *v);
void G_free_imatrix(int **m);

#endif /* ALLOC_UTIL_H */

