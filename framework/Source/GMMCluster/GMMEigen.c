#include <math.h>
#include "GMMEigen.h"
#include "GMMMemoryUtility.h"

static int G_tqli(double *d, double *e, int n, double **z);
static void G_tred2( double **a, int n, double *d, double *e );

#define MAX_ITERS 30
#define SIGN(a,b) ((b)<0 ? -fabs(a) : fabs(a))


/* Computes eigenvalues (and eigen vectors if desired) for */
/*  symmetric matices.                                     */
//  double **M,     /* Input matrix */
//  double *lambda, /* Output eigenvalues */
//  int n           /*
void eigen(double **M, double *lambda, int n) {
    
    double **a = G_alloc_matrix((size_t)n, (size_t)n);
    double *e = G_alloc_vector((size_t)n);

    for( int i = 0; i < n; i++ ) {
        for( int j = 0; j < n; j++ ) {
            a[i][j] = M[i][j];
        }
    }
    G_tred2(a, n, lambda, e);
    G_tqli(lambda, e, n, a);
	
   /* Returns eigenvectors	*/
    
    for( int i = 0; i < n; i++) {
        for( int j = 0; j < n; j++) {
            M[i][j] = a[i][j];
        }
    }

    G_free_matrix(a);
    G_free_vector(e);
}


/* From Numerical Recipies in C */
static int G_tqli(double *d, double *e, int n, double **z) {
    int iter;
    double s,r,p,g,f,dd,c,b;

    for ( int i = 1; i < n; i++ ) {
        e[i-1] = e[i];
    }
    e[n-1] = 0.0;
    for ( int l = 0;l < n; l++) {
        iter = 0;
        int m;
        do {
            for ( m = l; m < n-1; m++ ) {
                dd = fabs(d[m]) + fabs(d[m+1]);
                if (fabs(e[m]) + dd == dd) {
                    break;
                }
            }
            if (m != l) {
                if (iter++ == MAX_ITERS) {
                    return 0; /* Too many iterations in TQLI */
                }
                g = (d[l+1] - d[l]) / (2.0 * e[l]);
                r = sqrt((g * g) + 1.0);
                g = d[m] - d[l] + e[l] / (g + SIGN(r, g));
                s = c = 1.0;
                p = 0.0;
                for ( int i = m-1; i>=l; i-- ) {
                    f = s * e[i];
                    b = c * e[i];
                    if (fabs(f) >= fabs(g)) {
                        c = g / f;
                        r = sqrt((c * c) + 1.0);
                        e[i+1] = f * r;
                        c *= (s = 1.0 / r);
                    }
                    else {
                        s=f/g;
                        r=sqrt((s * s) + 1.0);
                        e[i+1] = g * r;
                        s *= (c = 1.0 / r);
                    }
                    g = d[i+1] - p;
                    r = (d[i] - g) * s + 2.0 * c * b;
                    p = s * r;
                    d[i+1] = g + p;
                    g = c * r - b;
                    /* Next loop can be omitted if eigenvectors not wanted */
                    for ( int k = 0; k < n; k++) {
                        f = z[k][i+1];
                        z[k][i+1] = s * z[k][i] + c * f;
                        z[k][i] = c * z[k][i] - s * f;
                    }
                }
                d[l] = d[l]-p;
                e[l] = g;
                e[m] = 0.0;
            }
        } while (m != l);
    }
    return 1;
}



static void G_tred2( double **a, int n, double *d, double *e ) {
    double scale, hh, h, g, f;
    int l;
    for ( int i = n - 1; i >= 1; i-- ) {
        l = i - 1;
        h = scale = 0.0;
        if ( l > 0 ) {
            for ( int k = 0; k <= l; k++ ) {
                scale += fabs(a[i][k]);
            }
            if (scale == 0.0) {
                e[i]=a[i][l];
            }
            else {
                for ( int k = 0; k <= l; k++) {
                    a[i][k] /= scale;
                    h += a[i][k] * a[i][k];
                }
                f = a[i][l];
                g = f > 0 ? -sqrt(h) : sqrt(h);
                e[i] = scale * g;
                h -= f * g;
                a[i][l] = f - g;
                f = 0.0;
                for ( int j = 0; j <= l; j++ ) {
                /* Next statement can be omitted if eigenvectors not wanted */
                    a[j][i]=a[i][j] / h;
                    g = 0.0;
                    for ( int k = 0; k <= j; k++) {
                        g += a[j][k] * a[i][k];
                    }
                    for (int k = j + 1; k <= l;k++ ) {
                        g += a[k][j] * a[i][k];
                    }
                    e[j] = g / h;
                    f += e[j] * a[i][j];
                }
                hh = f / (h + h);
                for ( int j = 0; j <= l; j++ ) {
                    f = a[i][j];
                    e[j] = g = e[j] - hh * f;
                    for ( int k = 0; k <= j; k++) {
                        a[j][k] -= (f * e[k] + g * a[i][k]);
                    }
                }
            }
        }
        else {
            e[i] = a[i][l];
        }
        d[i]=h;
    }
    /* Next statement can be omitted if eigenvectors not wanted */
    d[0]=0.0;
    e[0]=0.0;
    /* Contents of this loop can be omitted if eigenvectors not
            wanted except for statement d[i]=a[i][i]; */
    for ( int i = 0; i < n; i++) {
        l = i - 1;
        if ( d[i] != 0 ) {
            for ( int j = 0; j <= l; j++) {
                g = 0.0;
                for ( int k = 0; k <= l; k++) {
                    g += a[i][k] * a[k][j];
                }
                for ( int k = 0; k <= l; k++) {
                    a[k][j] -= g * a[k][i];
                }
            }
        }
        d[i] = a[i][i];
        a[i][i] = 1.0;
        for ( int j = 0; j <= l; j++) {
            a[j][i]=a[i][j]=0.0;
        }
    }
}
