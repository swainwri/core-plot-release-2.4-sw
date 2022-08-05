//
//  clust_invert.h
//  CorePlot
//
//  Created by Steve Wainwright on 04/06/2022.
//

#ifndef clust_invert_h
#define clust_invert_h

/***********************************************************/
/* inverts a matrix of arbitrary size input as a 2D array. */
/***********************************************************/
//double **a,      /* input/output matrix */
//int    n,        /* dimension */
//double *det_man, /* determinant mantisa */
//int    *det_exp, /* determinant exponent */
///* scratch space */
//int    *indx,    /* indx = G_alloc_ivector(n);  */
//double **y,      /* y = G_alloc_matrix(n,n); */
//double *col      /* col = G_alloc_vector(n); */
int clust_invert(double **a, int n, double *det_man, int *det_exp, int *indx, double **y, double *col);

#endif /* clust_invert_h */
