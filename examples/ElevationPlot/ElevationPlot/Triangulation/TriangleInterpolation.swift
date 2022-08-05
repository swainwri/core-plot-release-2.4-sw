//
//  TriangleInterpolation.swift
//  EZPlotter
//
//  Created by Steve Wainwright on 01/03/2021.
//  Copyright © 2021 Whichtoolface.com. All rights reserved.
//

import Foundation

class TriangleInterpolation: NSObject {
    
    class func triangle_area(p1x: Double, p1y: Double, p2x: Double, p2y: Double, p3x: Double, p3y: Double) -> Double {
        //****************************************************************************80
        //
        //  Purpose:
        //
        //    TRIANGLE_AREA computes the area of a triangle in 2D.
        //
        //  Discussion:
        //
        //    If the triangle's vertices are given in counter clockwise order,
        //    the area will be positive.  If the triangle's vertices are given
        //    in clockwise order, the area will be negative!
        //
        //    An earlier version of this routine always returned the absolute
        //    value of the computed area.  I am convinced now that that is
        //    a less useful result!  For instance, by returning the signed
        //    area of a triangle, it is possible to easily compute the area
        //    of a nonconvex polygon as the sum of the (possibly negative)
        //    areas of triangles formed by node 1 and successive pairs of vertices.
        //
        //  Licensing:
        //
        //    This code is distributed under the GNU LGPL license.
        //
        //  Modified:
        //
        //    17 October 2005
        //
        //  Author:
        //
        //    John Burkardt
        //
        //  Parameters:
        //
        //    Input, double P1X, P1Y, P2X, P2Y, P3X, P3Y, the coordinates
        //    of the vertices P1, P2, and P3.
        //
        //    Output, double TRIANGLE_AREA, the area of the triangle.
        //
        return 0.5 * ( p1x * ( p2y - p3y ) + p2x * ( p3y - p1y ) + p3x * ( p1y - p2y ) )
    }
    
    // then zero sign value denotes that point lies exactly on the edge.
    //(More exactly - on the line containing edge. Signs for two other edges show whether point is between vertices)
    class func sign(p1x: Double, p1y: Double, p2x: Double, p2y: Double, p3x: Double, p3y: Double) -> Double {
        return (p1x - p3x) * (p2y - p3y) - (p2x - p3x) * (p1y - p3y)
    }

    class func triangle_interpolate_linear( m: Int, n: Int, p1: [Double], p2: [Double], p3: [Double], p: [Double], v1: [Double], v2: [Double], v3: [Double]) -> [Double] {

    //****************************************************************************80
    //
    //  Purpose:
    //
    //    TRIANGLE_INTERPOLATE_LINEAR interpolates data given on a triangle's vertices.
    //
    //  Licensing:
    //
    //    This code is distributed under the GNU LGPL license.
    //
    //  Modified:
    //
    //    19 January 2015
    //
    //  Author:
    //
    //    John Burkardt
    //
    //  Parameters:
    //
    //    Input, int M, the dimension of the quantity.
    //
    //    Input, int N, the number of points.
    //
    //    Input, double P1[2], P2[2], P3[2], the vertices of the triangle,
    //    in counterclockwise order.
    //
    //    Input, double P[2*N], the point at which the interpolant is desired.
    //
    //    Input, double V1[M], V2[M], V3[M], the value of some quantity at the vertices.
    //
    //    Output, double TRIANGLE_INTERPOLATE_LINEAR[M,N], the interpolated value
    //    of the quantity at P.
    //
        let abc = triangle_area( p1x:p1[0], p1y:p1[1], p2x:p2[0], p2y:p2[1], p3x:p3[0], p3y:p3[1] )
        var apc:Double
        var abp:Double
        var pbc:Double
        
        var v:[Double] = Array(repeating: 0.0, count: m * n)

        for j in 0..<n {
            pbc = triangle_area ( p1x:p[0+j*2], p1y:p[1+j*2], p2x:p2[0], p2y:p2[1], p3x:p3[0], p3y:p3[1] )
            apc = triangle_area ( p1x:p1[0], p1y:p1[1], p2x:p[0+j*2], p2y:p[1+j*2], p3x:p3[0], p3y:p3[1] )
            abp = triangle_area ( p1x:p1[0], p1y:p1[1], p2x:p2[0], p2y:p2[1], p3x:p[0+j*2], p3y:p[1+j*2] )
            for i in 0..<m {
                v[i+j*m] = ( pbc * v1[i] + apc * v2[i] + abp * v3[i] ) / abc
            }
        }

        return v;
    }

//    double LinearInterpolate( double y1,double y2, double mu) {
//       return(y1*(1-mu)+y2*mu);
//    }
//    
//    double CosineInterpolate( double y1,double y2, double mu) {
//       double mu2;
//
//       mu2 = (1-cos(mu*PI))/2;
//       return(y1*(1-mu2)+y2*mu2);
//    }
//    
//    double CubicInterpolate( double y0,double y1, double y2,double y3, double mu) {
//       double a0,a1,a2,a3,mu2;
//
//       mu2 = mu*mu;
//       a0 = y3 - y2 - y0 + y1;
//       a1 = y0 - y1 - a0;
//       a2 = y2 - y0;
//       a3 = y1;
//
//       return(a0*mu*mu2+a1*mu2+a2*mu+a3);
//    }
//    
//    /*
//       Tension: 1 is high, 0 normal, -1 is low
//       Bias: 0 is even,
//             positive is towards first segment,
//             negative towards the other
//    */
//    double HermiteInterpolate( double y0,double y1, double y2,double y3, double mu, double tension, double bias) {
//       double m0,m1,mu2,mu3;
//       double a0,a1,a2,a3;
//
//        mu2 = mu * mu;
//        mu3 = mu2 * mu;
//       m0  = (y1-y0)*(1+bias)*(1-tension)/2;
//       m0 += (y2-y1)*(1-bias)*(1-tension)/2;
//       m1  = (y2-y1)*(1+bias)*(1-tension)/2;
//       m1 += (y3-y2)*(1-bias)*(1-tension)/2;
//       a0 =  2*mu3 - 3*mu2 + 1;
//       a1 =    mu3 - 2*mu2 + mu;
//       a2 =    mu3 -   mu2;
//       a3 = -2*mu3 + 3*mu2;
//
//       return(a0*y1+a1*m0+a2*m1+a3*y2);
//    }

    class func isInsideTriangle(px: Double, py: Double, p1x: Double, p1y: Double, p2x: Double, p2y: Double, p3x: Double, p3y: Double) -> Bool {
        
        let Area = triangle_area(p1x: p1x, p1y: p1y, p2x: p2x, p2y: p2y, p3x: p3x, p3y: p3y)
        let s = (p1y * p3x - p1x * p3y + (p3y - p1y) * px + (p1x - p3x) * py) / (2 * Area)
        let t = (p1x * p2y - p1y * p2x + (p1y - p2y) * px + (p2x - p1x) * py) / (2 * Area)
       // where Area is the (signed) area of the triangle:

        if s > 0 && t > 0 && 1 - s - t > 0 {
            return true
        }
        else {
            return false
        }
    }
    
    class func triangle_extrapolate_linear_singleton( p1: [Double], p2: [Double], p: [Double], v1: Double, v2: Double) -> Double {
    
        let sx: Double = p[0] - p1[0]
        let sy: Double = p[1] - p1[1]
            
        let ax: Double = p2[0] - p1[0]
        let ay: Double = p2[1] - p1[1]
        let az: Double = v2 - v1
            
        let t = (sx * ax + sy * ay) / (ax * ax + ay * ay)
        var z: Double
        if t <= 0 {
            z = v1
//            nx = 0
//            ny = 0
//            nz = 1
        }
        else if t >= 1 {
            z = v2
//            nx = 0
//            ny = 0
//            nz = 1
        }
        else {
            z = t * az + v1;
//            nx = -az * ax;
//            ny = -az * ay;
//            nz = ax * ax + ay * ay;
        }
        return z;
    }
}
