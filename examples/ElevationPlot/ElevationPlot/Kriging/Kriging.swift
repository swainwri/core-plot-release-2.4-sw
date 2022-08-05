//
//  Kriging.swift
//  EZPlotter
//
//  Created by Steve Wainwright on 27/03/2021.
//  Copyright © 2021 Whichtoolface.com. All rights reserved.
//
//  Kriging Interpolator
//  written in c by Chao-yi Lang
//  July, 1995
//  lang@cs.cornell.edu

import Foundation
import Accelerate


/**
 *  @brief Enumeration of Kriging Models.
 **/
enum SWKrigingMode: Int16 {
    case spherical = 0 ///< Spherical mode
    case exponential = 1 ///< Exponential mode
    case gauss = 2 ///< Gauss mode
    
    var description: String {
        get {
            switch self {
                case .spherical:
                    return "Spherical"
                case .exponential:
                    return "Exponential"
                case .gauss:
                    return "Gaussian"
            }
        }
    }
    
    static var count: Int {
        return Int(SWKrigingMode.gauss.rawValue + 1)
    }
}

enum KrigingError: Error {
    case none
    case notenoughpoints
    case nomodel
    case unabletoinvertmatrix
    
    var description: String {
        get {
            switch self {
                case .none:
                    return "No Errors"
                case .notenoughpoints:
                    return "Not enough raw data points"
                case .nomodel:
                    return "No Kriging Model assigned"
                case .unabletoinvertmatrix:
                    return "Unable to Invert a matrix"
            }
        }
    }
}

public class Kriging  {
    
    private var t: [Double] = []
    private var x: [Double] = []
    private var y: [Double] = []
    private var nugget: Double = 0.0
    private var range: Double = 0.0
    private var sill: Double = 0.0
    private var A: Double  = 1.0 / 3.0
    private var n: Int = 0
    private var variogramFunction: (( Double, Double, Double, Double, Double) -> Double)?
    private var K: [Double]?
    private var M: [Double]?
    
    var error: KrigingError?
    
    // Variogram models
    private func variogram_gaussian(h: Double, nugget: Double, range: Double, sill: Double, A: Double) -> Double {
        return nugget + ((sill - nugget) / range) * ( 1.0 - exp(-1.0 / A * pow(h / range, 2)) )
    }
    
    private func variogram_exponential(h: Double, nugget: Double, range: Double, sill: Double, A: Double) -> Double {
        return nugget + ((sill - nugget) / range) * ( 1.0 - exp(-1.0 / A * h / range) )
    };
    
    private func variogram_spherical(h: Double, nugget: Double, range: Double, sill: Double, A: Double) -> Double {
        if h > range {
            return nugget + (sill - nugget) / range
        }
        else {
            return nugget + ((sill - nugget) / range) * ( 1.5 * h / range - 0.5 * pow(h / range, 3) )
        }
    }
    
    init() {
        self.error = KrigingError.none
        self.nugget = 0.0
        self.range = 0.0
        self.sill = 0.0
        self.A  = 1.0 / 3.0
        self.n = 0
    }
    
    func train(t: [Double], x: [Double], y: [Double], model: SWKrigingMode, sigma2: Double, alpha: Double) {
        self.t = t
        self.x = x
        self.y = y
        
        // Lag distance/semivariance
        var n = t.count;
        var distance: [[Double]] = Array(repeating: Array(repeating: 0, count: 2), count: (n * n - n) / 2)
        var k: Int = 0
        for i in 0..<n {
            for j in 0..<i {
                distance[k][0] = sqrt(pow(x[i] - x[j], 2.0) + pow(y[i] - y[j], 2.0))
                distance[k][1] = fabs(t[i] - t[j])
                k += 1
            }
        }
        distance.sort(by: { $0[0] < $1[0] })
        self.range = distance[(n * n - n) / 2 - 1][0]
        
        // Bin lag distance
        var noLags: Int = 0
        let lags: Int = ((n * n - n) / 2) > 30 ? 30 : (n * n - n) / 2
        let tolerance: Double = self.range / Double(lags)
        var lag: [Double] = Array(repeating: 0.0, count: lags)
        var semi: [Double] = Array(repeating: 0.0, count: lags)
        if lags < 30 {
            for l in 0..<lags {
                lag[l] = distance[l][0]
                semi[l] = distance[l][1]
            }
            noLags = lags
        }
        else {
            var j: Int = 0
            var k: Int = 0
            var l: Int = 0
            for i in 0..<lags where j < (n * n - n) / 2 {
                k = 0
                while distance[j][0] <= Double(i + 1) * tolerance {
                    lag[l] += distance[j][0]
                    semi[l] += distance[j][1]
                    j += 1
                    k += 1
                    if j >= (n * n - n) / 2 {
                        break
                    }
                }
                if k > 0 {
                    lag[l] /= Double(k)
                    semi[l] /= Double(k)
                    l += 1
                }
            }
            noLags = l
            if l < 2 {
                error = .notenoughpoints // Error: Not enough points
            }
        }
        if self.error == KrigingError.none {
            // Feature transformation
            n = noLags
            self.range = lag[n-1] - lag[0]
            var X: [Double] = Array(repeating: 1.0, count: 2 * n)
            var Y: [Double] = Array(repeating: 0.0, count: n)
        
            for i in 0..<n {
                switch model {
                    case .gauss:
                        X[i * 2 + 1] = 1.0 - exp(-1.0 / A * pow(lag[i] / range, 2))
                    case .exponential:
                        X[i * 2 + 1] = 1.0 - exp(-1.0 / A * lag[i] / range);
                    case .spherical:
                        X[i * 2 + 1] = 1.5 * lag[i] / range - 0.5 * pow(lag[i] / range, 3)
                }
                Y[i] = semi[i]
            }
            
            // Least squares
            var Xt = Array(repeating: 0.0, count: 2 * n)
            vDSP_mtransD(X, vDSP_Stride(1), &Xt, vDSP_Stride(1), vDSP_Length(2), vDSP_Length(n))
                            
            var Z: [Double] = Array(repeating: 0.0, count: 4)
            vDSP_mmulD(Xt, vDSP_Stride(1), X, vDSP_Stride(1), &Z, vDSP_Stride(1), vDSP_Length(2), vDSP_Length(2), vDSP_Length(n))
            
            let alphaDiagonal: [Double] = [1 / alpha, 0.0, 0.0, 1 / alpha]
            Z = vDSP.add(Z, alphaDiagonal)
//                var cloneZ = Z
//
//                if(kriging_matrix_chol(Z, 2))
//                    kriging_matrix_chol2inv(Z, 2);
//                else {
//                    kriging_matrix_solve(cloneZ, 2);
//                    Z = cloneZ;
//                }
            var invertError: Int = 0
            let invZ = self.invert(matrix: Z, Error: &invertError)
            if invertError != 0 {
                self.error = .unabletoinvertmatrix
            }
            else {
                var tmpW: [Double] = Array(repeating: 0, count: 2 * n)
                
                vDSP_mmulD(invZ, vDSP_Stride(1), Xt, vDSP_Stride(1), &tmpW, vDSP_Stride(1), vDSP_Length(2), vDSP_Length(n), vDSP_Length(2))
                var W: [Double] = Array(repeating: 0, count: 2)
                vDSP_mmulD(tmpW, vDSP_Stride(1), Y, vDSP_Stride(1), &W, vDSP_Stride(1), vDSP_Length(2), vDSP_Length(1), vDSP_Length(n))
            
                // Variogram parameters
                self.nugget = W[0]
                self.sill = W[1] * range + nugget
                self.n = x.count
            
                n = x.count
                // Gram matrix with prior
                switch(model) {
                    case .gauss:
                        self.variogramFunction = self.variogram_gaussian;
                    case .exponential:
                        self.variogramFunction = self.variogram_exponential;
                    case .spherical:
                        self.variogramFunction = self.variogram_spherical;
                }
                if let _variogramFunction = self.variogramFunction {
                    var K: [Double] = Array(repeating: 0.0, count: n * n)
                    for i in 0..<n {
                        for j in i..<n {
                            K[i * n + j] = _variogramFunction(sqrt(pow(x[i]-x[j], 2) + pow(y[i]-y[j], 2)), nugget, range, sill, A)
                            K[j * n + i] = K[i * n + j]
                        }
                        K[i * n + i] = _variogramFunction(0, nugget, range, sill, A)
                    }
                    var sigma2Diagonal: [Double] = Array(repeating: 0.0, count: n * n)
                    for i in 0..<n {
                        sigma2Diagonal[i * n + i] = sigma2;
                    }
                    
                    // Inverse penalized Gram matrix projected to target vector
                    K = vDSP.add(K, sigma2Diagonal)
                    let C = invert(matrix: K, Error: &invertError)
  //                  if invertError == 0 {
        //                var cloneC = C.slice(0);
        //                if(kriging_matrix_chol(C, n))
        //                    kriging_matrix_chol2inv(C, n);
        //                else {
        //                    kriging_matrix_solve(cloneC, n);
        //                    C = cloneC;
        //                }
                    
                        // Copy unprojected inverted matrix as K
                        var M = Array(repeating: 0.0, count: n * n)
                        vDSP_mmulD(C, vDSP_Stride(1), t, vDSP_Stride(1), &M, vDSP_Stride(1), vDSP_Length(n), vDSP_Length(1), vDSP_Length(n))
                        self.K = C;
                        self.M = M;
//                    }
//                    else {
//                        self.error = .unabletoinvertmatrix
//                    }
                }
                else {
                    self.error = .nomodel
                }
            }
        }
    }
    
    // Model prediction
    func predict(x: Double, y: Double) -> Double {
        if self.error == KrigingError.none,
           let _M = self.M,
           let _variogramFunction = self.variogramFunction {
            var k: [Double] = Array(repeating: 0.0, count: self.n)
            for i in 0..<self.n {
                k[i] = _variogramFunction(sqrt(pow(x - self.x[i], 2.0) + pow(y - self.y[i], 2.0)), self.nugget, self.range, self.sill, self.A)
            }
            
            var result: [Double] = [0]
//            vDSP_mmulD(k, vDSP_Stride(1), _M, vDSP_Stride(1), &result, vDSP_Stride(1), vDSP_Length(1), vDSP_Length(self.n), vDSP_Length(1))
            naive_multiply(matrixA: k, matrixB: _M, matrixC: &result, n: 1, m: self.n, p: 1)
            return result[0]
        }
        else {
            return -0.0
        }
    }
    
    func variance(x: Double, y: Double) -> Double {
        if self.error == KrigingError.none,
           let _K = self.K,
           let _variogramFunction = self.variogramFunction {
            var k: [Double] = Array(repeating: 0.0, count: self.n)
            for i in 0..<self.n {
                k[i] = _variogramFunction(sqrt(pow(x - self.x[i], 2.0) + pow(y - self.y[i], 2.0)), self.nugget, self.range, self.sill, self.A)
            }
            
            var result1: [Double] = Array(repeating: 0.0, count: self.n)
            vDSP_mmulD(&k, vDSP_Stride(1), _K, vDSP_Stride(1), &result1, vDSP_Stride(1), vDSP_Length(1), vDSP_Length(self.n), vDSP_Length(self.n))
            var result2: [Double] = Array(repeating: 0.0, count: self.n)
            vDSP_mmulD(&result1, vDSP_Stride(1), k, vDSP_Stride(1), &result2, vDSP_Stride(1), vDSP_Length(1), vDSP_Length(self.n), vDSP_Length(1))
            return result2[0] + _variogramFunction(0.0, self.nugget, self.range, self.sill, self.A)
        }
        else {
            return -0.0
        }
    }
    
    private func invert(matrix: [Double], Error: inout Int) -> [Double] {
        var inMatrix = matrix
        var N = __CLPK_integer(sqrt(Double(matrix.count)))
        var pivots = [__CLPK_integer](repeating: 0, count: Int(N))
        var workspace = [Double](repeating: 0.0, count: Int(N))
        var error1 : __CLPK_integer = 0
        var error2 : __CLPK_integer = 0

        withUnsafeMutablePointer(to: &N) {
//            INFO is INTEGER
//                      = 0:  successful exit
//                      < 0:  if INFO = -i, the i-th argument had an illegal value
//                      > 0:  if INFO = i, U(i,i) is exactly zero. The factorization
//                            has been completed, but the factor U is exactly
//                            singular, and division by zero will occur if it is used
//                            to solve a system of equations.
            dgetrf_($0, $0, &inMatrix, $0, &pivots, &error1)
//            INFO is INTEGER
//                      = 0:  successful exit
//                      < 0:  if INFO = -i, the i-th argument had an illegal value
//                      > 0:  if INFO = i, U(i,i) is exactly zero; the matrix is
//                            singular and its inverse could not be computed.
            dgetri_($0, &inMatrix, $0, &pivots, &workspace, $0, &error2)
        }
        Error = Int(error1)
        return inMatrix
    }
    
    // Naive matrix multiplication
    private func naive_multiply(matrixA: [Double], matrixB: [Double], matrixC: inout [Double], n: Int, m: Int, p: Int) {
        for i in 0..<n {
            for j in 0..<p {
                matrixC[i * p + j] = 0
                for k in 0..<m {
                    matrixC[i * p + j] += matrixA[i * m + k] * matrixB[k * p + j]
                }
            }
        }
    }
}


///// A structure that contains a point in a two-dimensional coordinate system, a predcited value and its variance.
//struct KrigingPoint {
//    var x: Double
//    var y: Double
//    var value: Double
//    var variance: Double
//}
//public class Kriging1  {
//
//    var predictedPoints: [[KrigingPoint]]?
//
//    private var D: [Double]?
//    private var weight: [Double]?
//    private var V: [Double]
//    private var inversionError: Int = -1
//    private var Mode: SWKrigingMode = .exponential
//    private var C0: Double = 0.0
//    private var C1: Double = 1.0
//    private var A: Double = 0.0
//    private var Dim: Int = 0
//    private var Pos: [Double] = []
//    private var Values: [Double] = []
//
//    var error: Int {
//        get {
//            return inversionError
//        }
//    }
//    /**
//     *  @brief Setting up of kriging variogram for later predictions
//     *  range
//     **/
//    /** @brief Setting up of kriging variogram for later predictions
//     *  @param mode The Kriging mode: spherical, exponential, gaussian
//     *  @param item The dimensions of the known positions and values
//     *  @param pos The known values in [v0,v1,....vn] order
//     *  @param pos The known positions in [x0,y0,x1,y1....xn,yn] order
//     *  @param c0 The nugget
//     *  @param c1 The Sill (c0 + c1)
//     *  @param a The distance which cause the variogram reach plateau is called range.
//     **/
//    init(KrigingMode mode: SWKrigingMode, knownDimensions item: Int, values Z_s: [Double], knownPositions pos: [Double], c0: Double, c1: Double, a: Double) {
//        self.Mode = mode
//        self.Dim = item + 1
//        self.C0 = c0
//        self.C1 = c1
//        self.A = a
//        self.Pos = pos
//        self.Values = Z_s
//
//        // allocate V array
//        V = Array(repeating: 0.0, count: Dim * Dim)
//
//        D = Array(repeating: 0.0, count: Dim)
//        weight = Array(repeating: 0.0, count: Dim)
//
//        // allocate Cd array
//        var Cd: [Double] = Array(repeating: 0, count: Dim * Dim)
//
//        // calculate the distance between sample datas put into Cd array*/
//        for i in 0..<Dim-1 {
//            for j in i..<Dim-1 {
//                let test_t = ( Pos[i * 2] - Pos[j * 2] ) * ( Pos[i * 2] - Pos[j * 2]) + ( Pos[i * 2 + 1] - Pos[j * 2 + 1] ) * ( Pos[i * 2 + 1] - Pos[j * 2 + 1] )
//                Cd[i * Dim + j] = sqrt(test_t)
//            }
//        }
//        for i in 0..<Dim-1 {
//            V[i * Dim + Dim - 1] = 1
//            V[(Dim - 1) * Dim + i] = 1
//        }
//        V[(Dim - 1) * Dim + Dim - 1] = 0
//
//        // calculate the variogram of sample datas and put into  V array
//        for i in 0..<Dim-1 {
//            for j in i..<Dim-1 {
//                switch mode {
//                    case .spherical:
//                        if Cd[i * Dim + j] < a {
//                            V[j * Dim + i] = c0 + c1 * (1.5 * Cd[i * Dim + j] / a - 0.5 * (Cd[i * Dim + j] / a) * (Cd[i * Dim + j] / a) * (Cd[i * Dim + j] / a))
//                            V[i * Dim + j] = V[j * Dim + i]
//                        }
//                        else {
//                            V[j * Dim + i] = c0 + c1
//                            V[i * Dim + j] = V[j * Dim + i]
//                        }
//                    case .exponential:
//                        V[j * Dim + i] = c0 + c1 * ( 1 - exp(-3.0 * Cd[i * Dim + j] / a) )
//                        V[i * Dim + j] = V[j * Dim + i]
//                    case .gauss:
//                        V[j * Dim + i] = c0 + c1 * ( 1 - exp(-3.0 * Cd[i * Dim + j] * Cd[i * Dim + j] / a / a))
//                        V[i * Dim + j] = V[j * Dim + i]
//                }
//            }
//        }
//
//        //  release Cd array
//        Cd.removeAll()
//
//        // call inverse matrix function to inverse matrix C
//        V = invert(matrix: V, Error: &inversionError)
//    }
//
//    func singlepoint(x: Double, y: Double) -> (prediction: Double, variance: Double) {
//        if inversionError == 0 {
//            return kriging_result(x_unkn: x, y_unkn: y)
//        }
//        else {
//            return (-0.0, -0.0)
//        }
//    }
//
//    func range(range: [Double], predictionDimensions resolution: [Int]) {
//        if inversionError == 0 {
//            let startX: Double = Double(range[0])
//            let startY: Double = Double(range[1])
//            let endX: Double = Double(range[2])
//            let endY: Double = Double(range[3])
//            let resol_x = resolution[0]
//            let resol_y = resolution[1]
//            predictedPoints = Array(repeating: Array(repeating: KrigingPoint(x: 0, y: 0, value: 0, variance: 0), count: resol_y), count: resol_x)
//
//            //    /* for loop for each point of the estimated block */
//            let increment_x = (endX - startX) / Double(resol_x)
//            let increment_y = (endY - startY) / Double(resol_y)
//            var x = startX
//            var y = startY
//            var i: Int = 0
//            while x <= endX {
//                var j: Int = 0
//                while y <= endY {
//                    let result = kriging_result(x_unkn: x, y_unkn: y)
//                    predictedPoints?[i][j].x = x
//                    predictedPoints?[i][j].y = y
//                    predictedPoints?[i][j].value = result.prediction
//                    predictedPoints?[i][j].variance = result.variance
//                    y += increment_y
//                    j += 1
//                }
//                x += increment_x
//                i += 1
//            }
//        }
//    }
//
//    private func kriging_result(x_unkn: Double, y_unkn: Double) -> (prediction: Double, variance: Double) {
//
//        // calculate the distance between estimated point and sample datas
//        // and calculate the variogram of estimated point and sample datas and
//        // put into D array
//        for i in 0..<Dim-1 {
//            let h = sqrt( ( Pos[i * 2] - x_unkn ) * ( Pos[i * 2] - x_unkn ) + ( Pos[i * 2 + 1] - y_unkn ) * ( Pos[i * 2 + 1] - y_unkn ) )
//            switch Mode {
//                case .spherical:
//                    if h < A {
//                        D?[i] = C0 + C1 * (1.5 * h / A - 0.5 * (h / A) * (h / A) * (h / A))
//                    }
//                    else {
//                        D?[i] = C0 + C1
//                    }
//                case .exponential:
//                    D?[i] = C0 + C1 * (1 - exp(-3.0 * h / A))
//                case .gauss:
//                    D?[i] = C0 + C1 * (1 - exp(-3.0 * h * h / A / A))
//            }
//        }
//        D?[Dim-1] = 1;
//
//        //  calculate the weights
//        for i in 0..<Dim {
//            weight?[i] = 0
//            for j in 0..<Dim {
//                weight?[i] += V[i * Dim + j] * D![j]
//            }
//        }
//
//        // calculate and return the estimated value */
//        var prediction: Double = 0
//        for i in 0..<Dim-1 {
//            prediction += weight![i] * Values[i]
//        }
//
//        // prediction : kriging result
//        // variance : error variance result
//        prediction = prediction >= 0 ? prediction : 0
//
//        var variance: Double = 0
//        for i in 0..<Dim-1 {
//            variance += weight![i] * D![i]
//        }
//        variance += weight![Dim-1];
//        variance = sqrt(variance)
//        return (prediction, variance)
//    }
//
//    private func invert(matrix : [Double], Error: inout Int) -> [Double] {
//        var inMatrix = matrix
//        var N = __CLPK_integer(sqrt(Double(matrix.count)))
//        var pivots = [__CLPK_integer](repeating: 0, count: Int(N))
//        var workspace = [Double](repeating: 0.0, count: Int(N))
//        var error : __CLPK_integer = 0
//
//        withUnsafeMutablePointer(to: &N) {
//            dgetrf_($0, $0, &inMatrix, $0, &pivots, &error)
//            dgetri_($0, &inMatrix, $0, &pivots, &workspace, $0, &error)
//        }
//        Error = Int(error)
//        return inMatrix
//    }
//
//    // get the maximum and minimum value of input range as default range
//    private func get_range(pos: [Double], item: Int) -> [Int] {
//        var min_row = pos[0]
//        var min_col = pos[1]
//        var max_row = pos[0]
//        var max_col = pos[1]
//
//        for i in stride(from: 2, to: item, by: 2) {
//            min_row = max(min_row, pos[i])
//            min_col = max(min_col, pos[i+1])
//            max_row = min(max_row, pos[i])
//            max_col = min(max_col, pos[i+1])
//        }
//        return [Int(min_row), Int(min_col), Int(max_row+1), Int(max_col+1)]
//    }
//
//
//}
