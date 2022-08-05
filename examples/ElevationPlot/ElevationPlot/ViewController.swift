//
//  ViewController.swift
//  ElevationPlot
//
//  Created by Steve Wainwright on 27/01/2022.
//

//see https://mathematica.stackexchange.com/questions/11765/data-interpolation-and-listcontourplot

import UIKit
import CorePlot
import KDTree

struct DataStructure: Equatable {
    var x: Double
    var y: Double
    var z: Double
}

struct ConvexHullPoint: Equatable {
    var point: CGPoint
    var index: Int
    
    static func == (lhs: ConvexHullPoint, rhs: ConvexHullPoint) -> Bool {
        return __CGPointEqualToPoint(lhs.point, rhs.point)
    }
}

struct ContourManagerRecord {
    var fillContours: Bool = false
    var extrapolateToARectangleOfLimits: Bool = false
    var krigingSurfaceInterpolation: Bool = true
    var krigingSurfaceModel : SWKrigingMode = .exponential
    var trig: Bool = false
    var functionLimits:[Double]?
    var plottitle: String = ""
    var functionExpression : ((Double, Double) -> Double)?
    var data: [DataStructure]?
}


class ViewController: UIViewController, CPTPlotDataSource, CPTAxisDelegate, CPTPlotSpaceDelegate,  CPTContourPlotDataSource, CPTContourPlotDelegate, CPTLegendDelegate, CPTAnimationDelegate, UIGestureRecognizerDelegate, ContourManagerViewControllerDelegate, UIPopoverPresentationControllerDelegate {
    
    @IBOutlet var hostingView: CPTGraphHostingView?
    
    @IBOutlet var toggleFillButton: UIButton?
    @IBOutlet var toggleExtrapolateToLimitsRectangleButton: UIButton?
    @IBOutlet var toggleSurfaceInterpolationMethodButton: UIButton?
    @IBOutlet var tappedContourManagerButton: UIButton?
    
    private var spinner: SpinnerView?
    private var message: String?
//    private var spinner: SpinnerViewController = SpinnerViewController()
    private var contourManagerViewController: ContourManagerViewController?
    
    private var graph: CPTXYGraph = CPTXYGraph()
    
    private var plotdata: [DataStructure] = []
    private var discontinuousData: [DataStructure] = []
    private var dataBlockSources: [CPTFieldFunctionDataSource]?
    
    private var hull = Hull()
    
    private var minX = 0.0
    private var maxX = 0.0
    private var minY = 0.0
    private var maxY = 0.0
    private var minFunctionValue = 0.0
    private var maxFunctionValue = 0.0
    
    private var colourCodeAnnotation: CPTAnnotation?
    
    private var contourManagerCounter: Int = 2
    private var currentContour: ContourManagerRecord?
    private var contourManagerRecords: [ContourManagerRecord] = []
        
    private var longPressGestureForLegend: UILongPressGestureRecognizer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        contourManagerRecords.append(ContourManagerRecord(fillContours: true, extrapolateToARectangleOfLimits: true, krigingSurfaceInterpolation: false, krigingSurfaceModel: .exponential, trig: true, functionLimits: [-.pi, .pi, -.pi, .pi], plottitle: "0.5(sin(x+π/4) + cos(y+π/4)", functionExpression: { (x: Double, y: Double) -> Double in return 0.5 * (cos(x + .pi / 4.0) + sin(y + .pi / 4.0)) }, data: nil))
        contourManagerRecords.append(ContourManagerRecord(fillContours: true, extrapolateToARectangleOfLimits: true, krigingSurfaceInterpolation: false, krigingSurfaceModel: .exponential, trig: false, functionLimits: [-3, 3, -3, 3], plottitle: "log(2xy + x + y + 1)", functionExpression: { (x: Double, y: Double) -> Double in return log(2 * x * y + x + y + 1) }, data: nil))
        contourManagerRecords.append(ContourManagerRecord(fillContours: true, extrapolateToARectangleOfLimits: true, krigingSurfaceInterpolation: false, krigingSurfaceModel: .exponential, trig: false, functionLimits: [-3, 3, -3, 3], plottitle: "sin(√(x² + y²)) + 1 / √((x - 5)² + y²)", functionExpression: { (x: Double, y: Double) -> Double in return sin(sqrt(x * x + y * y)) + 1 / sqrt(pow(x - 5, 2.0) + y * y) }, data: nil))
        contourManagerRecords.append(ContourManagerRecord(fillContours: true, extrapolateToARectangleOfLimits: true, krigingSurfaceInterpolation: false, krigingSurfaceModel: .exponential, trig: false, functionLimits:  [-3, 3, -3, 3], plottitle: "xy/( x² + y²)", functionExpression: { (x: Double, y: Double) -> Double in return x * y / ( x * x + y * y) }, data: nil))
        contourManagerRecords.append(ContourManagerRecord(fillContours: true, extrapolateToARectangleOfLimits: true, krigingSurfaceInterpolation: false, krigingSurfaceModel: .exponential, trig: false, functionLimits:  [-3, 3, -3, 3], plottitle: "(x³ - x²y + 9xy²) / (5x²y + 7y³)", functionExpression: { (x: Double, y: Double) -> Double in return (x * x * x - x * x * y + 9 * x * y * y) / (5 * x * x * y + 7 * y * y * y) }, data: nil))
        contourManagerRecords.append(ContourManagerRecord(fillContours: true, extrapolateToARectangleOfLimits: false, krigingSurfaceInterpolation: true, krigingSurfaceModel: .exponential, trig: false, functionLimits: [500, 500], plottitle: "Barametric Contours", functionExpression: nil, data:[
                            DataStructure(x: 875.0, y: 3375.0, z: 632.0),
                            DataStructure(x: 500.0, y: 4000.0, z: 634.0),
                            DataStructure(x: 2250.0, y: 1250.0, z: 654.2),
                            DataStructure(x: 3000.0, y: 875.0, z: 646.4),
                            DataStructure(x: 2560.0, y: 1187.0, z: 641.5),
                            DataStructure(x: 1000.0, y: 750.0, z: 650.0),
                            DataStructure(x: 2060.0, y: 1560.0, z: 634.0),
                            DataStructure(x: 3000.0, y: 1750.0, z: 643.3),
                            DataStructure(x: 2750.0, y: 2560.0, z: 639.4),
                            DataStructure(x: 1125.0, y: 2500.0, z: 630.1),
                            DataStructure(x: 875.0, y: 3125.0, z: 638.0),
                            DataStructure(x: 1000.0, y: 3375.0, z: 632.3),
                            DataStructure(x: 1060.0, y: 3500.0, z: 630.8),
                            DataStructure(x: 1250.0, y: 3625.0, z: 635.8),
                            DataStructure(x: 750.0, y: 3375.0, z: 625.6),
                            DataStructure(x: 560.0, y: 4125.0, z: 632.0),
                            DataStructure(x: 185.0, y: 3625.0, z: 624.2)]))
        contourManagerRecords.append(ContourManagerRecord(fillContours: true, extrapolateToARectangleOfLimits: false, krigingSurfaceInterpolation: false, krigingSurfaceModel: .exponential, trig: false, functionLimits:  [10000, 10000], plottitle: "Elevation Contours", functionExpression: nil, data:[
                                DataStructure(x: 1772721, y: 582282, z: -3547),
                                DataStructure(x: 1781139, y: 585845, z: -3663),
                                DataStructure(x: 1761209, y: 581803, z: -3469),
                                DataStructure(x: 1761897, y: 586146, z: -3511),
                                DataStructure(x: 1757824, y: 586542, z: -3474),
                                DataStructure(x: 1759248, y: 593855, z: -3513),
                                DataStructure(x: 1751962, y: 595979, z: -3488),
                                DataStructure(x: 1748562, y: 600461, z: -3495),
                                DataStructure(x: 1749475, y: 601824, z: -3545),
                                DataStructure(x: 1748429, y: 612332, z: -3656),
                                DataStructure(x: 1747542, y: 610708, z: -3631),
                                DataStructure(x: 1752576, y: 610150, z: -3650),
                                DataStructure(x: 1749236, y: 605604, z: -3612),
                                DataStructure(x: 1777262, y: 614320, z: -3984),
                                DataStructure(x: 1783097, y: 614590, z: -3928),
                                DataStructure(x: 1788724, y: 614569, z: -3922),
                                DataStructure(x: 1788779, y: 602482, z: -3928),
                                DataStructure(x: 1783525, y: 602816, z: -3827),
                                DataStructure(x: 1782876, y: 595479, z: -3805),
                                DataStructure(x: 1790263, y: 601620, z: -3956),
                                DataStructure(x: 1786390, y: 587821, z: -3748),
                                DataStructure(x: 1772472, y: 591331, z: -3549),
                                DataStructure(x: 1774055, y: 585498, z: -3580),
                                DataStructure(x: 1771047, y: 582144, z: -3528),
                                DataStructure(x: 1769765, y: 592200, z: -3586),
                                DataStructure(x: 1784676, y: 602478, z: -3866),
                                DataStructure(x: 1769118, y: 593814, z: -3606),
                                DataStructure(x: 1774711, y: 589327, z: -3632),
                                DataStructure(x: 1762207, y: 601476, z: -3666),
                                DataStructure(x: 1767705, y: 611207, z: -3781),
                                DataStructure(x: 1760792, y: 601961, z: -3653),
                                DataStructure(x: 1768391, y: 602228, z: -3758),
                                DataStructure(x: 1760453, y: 592626, z: -3441),
                                DataStructure(x: 1786913, y: 605529, z: -3748),
                                DataStructure(x: 1746521, y: 614853, z: -3654)]))
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        currentContour = contourManagerRecords[contourManagerCounter]
//        showSpinner("Generating the contour plot, please wait...")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if let _hostingView = self.hostingView {
            
            let newGraph = CPTXYGraph(frame: _hostingView.bounds);
            newGraph.plotAreaFrame?.masksToBorder = false
            self.graph = newGraph
            _hostingView.hostedGraph = self.graph

            self.graph.titleDisplacement = CGPoint(x:0, y:-40)
            
            // Instructions
            let textStyle = CPTMutableTextStyle()
            textStyle.color    = CPTColor.darkGray()
            textStyle.fontName = "Helvetica"
            textStyle.fontSize = 12.0
            
            if let contourPlot = setupPlot(newGraph) {
                contourPlot.showActivityIndicator = true
                contourPlot.activityMessage = "Generating the contour plot, please wait..."
            
                self.graph.add(contourPlot)
                self.graph.legend?.add(contourPlot)
            }
            longPressGestureForLegend = UILongPressGestureRecognizer(target: self, action: #selector(self.toggleContourLegend(_ :)))
            longPressGestureForLegend?.minimumPressDuration = 2.0
            longPressGestureForLegend?.delegate = self
            
            // Add legend
            let legendTextStyle = CPTMutableTextStyle()
            legendTextStyle.color =  CPTColor.black()
            legendTextStyle.fontSize = UIDevice.current.userInterfaceIdiom == .phone ? 9.0 : 14.0
            legendTextStyle.fontName = "Helvetica"
            
            let legendLineStyle = CPTMutableLineStyle()
            // for banding effect dont want to see the plot just the band
            legendLineStyle.lineWidth = 1.5
            legendLineStyle.lineColor = CPTColor.blue()
            
            newGraph.legend                    = CPTLegend(graph: newGraph)
            newGraph.legend?.textStyle          = legendTextStyle
            newGraph.legend?.fill               = CPTFill(color: CPTColor.clear())
            newGraph.legend?.borderLineStyle    = legendLineStyle
            newGraph.legend?.cornerRadius       = 5.0
            newGraph.legend?.swatchCornerRadius = 3.0
            newGraph.legendAnchor              = .top
            newGraph.legendDisplacement        = CGPoint(x: 0.0, y: -120.0);
            newGraph.legend?.delegate = self
            
            // Add legend
            let titleTextStyle = CPTMutableTextStyle()
            titleTextStyle.color =  CPTColor.black()
            titleTextStyle.fontSize = UIDevice.current.userInterfaceIdiom == .phone ? 12.0 : 16.0
            titleTextStyle.fontName = "Helvetica-Bold"
            newGraph.titleTextStyle = titleTextStyle
            newGraph.title = "Contour Example"
            newGraph.titleDisplacement = CGPoint(x: 0, y: -40)
            
            // Note
            if let _plotArea = self.graph.plotAreaFrame?.plotArea {
                let textStyle = CPTMutableTextStyle()
                textStyle.color =  CPTColor.gray()
                textStyle.fontSize = UIDevice.current.userInterfaceIdiom == .phone ? 10.0 : 14.0
                textStyle.fontName = "Helvetica"
                let explanationLayer = CPTTextLayer(text: "Tap on legend to increase no isocurves.\nLong press toggles showing legend for contours.\nF button for changing contours.\nD button for swap beteen Delaunay & Kriging interpolation for raw data.\n⤡ Button for toggling extrapolating to corners for raw data.\n⧈ Button for toggle between filling contours", style: textStyle)
                let explantionAnnotation = CPTLayerAnnotation(anchorLayer: _plotArea)
                explantionAnnotation.rectAnchor         = .bottomLeft
                explantionAnnotation.contentLayer       = explanationLayer
                explantionAnnotation.contentAnchorPoint = CGPoint(x: 0.0, y: 0.0)
                _plotArea.addAnnotation(explantionAnnotation)
            }
        }
        
        createNavigationButtons(view, target: self, actions: [#selector(scrollUpButton(_:)), #selector(scrollDownButton(_:)), #selector(scrollLeftButton(_:)), #selector(scrollRightButton(_:))])
        setupConfigurationButtons()
        
        if let _longPressGestureForLegend = longPressGestureForLegend {
            self.hostingView?.addGestureRecognizer(_longPressGestureForLegend)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if let _longPressGestureForLegend = longPressGestureForLegend {
            self.hostingView?.removeGestureRecognizer(_longPressGestureForLegend)
        }
        longPressGestureForLegend = nil
    }
    
    private func setupPlot(_ graph: CPTXYGraph) -> CPTContourPlot? {
        if let _currentContour = currentContour {
            createData()
            searchForLimits()
            var deltaX = (maxX - minX) / 20.0
            var deltaY = (maxY - minY) / 20.0
            if !_currentContour.extrapolateToARectangleOfLimits && _currentContour.functionExpression == nil {
                if _currentContour.krigingSurfaceInterpolation { // in order to prevent any borders make extra 25% on all 4 sides
                    deltaX = (maxX - minX) / 4.0
                    deltaY = (maxY - minY) / 4.0
                }
                else {
                    deltaX = (maxX - minX) / 10.0
                    deltaY = (maxY - minY) / 10.0
                }
            }
            minX -= deltaX
            maxX += deltaX
            minY -= deltaY
            maxY += deltaY
//            self.plotdata.sort { (a: DataStructure, b: DataStructure) -> Bool in
//                return a.x < b.x
//            }
//            hull = Hull(concavity: .infinity)
//            let _ = hull.hull(self.discontinuousData.map({ [$0.x, $0.y] }), nil)
//            print(hull.hull)
//
//            let _/*continuousData*/ = self.plotdata.filter( {
//                var have = true
//                for i in 0..<discontinuousData.count {
//                    if ( $0.x == discontinuousData[i].x && $0.y == discontinuousData[i].y ) {
//                        have = false
//                        break
//                    }
//                }
//                return have
//            })
            
            
//            self.discontinuousData.sort { (a: DataStructure, b: DataStructure) -> Bool in
//                return a.x < b.x
//            }
//            hull.concavity = 1.0
//            let _ = hull.hull(self.discontinuousData.map({ [$0.x, $0.y] }), nil)
//            let _ = hull.hull(continuousData.map({ [$0.x, $0.y] }), nil)
//            for pt in hull.hull {
//                if let _pt = pt as? [Double] {
//                    print(_pt[0], ",", _pt[1])
//                }
//            }
            
          //  print(hull.hull)
            
//            let _ = hull.hull(data.map({ [$0.x, $0.y]  }), nil)
//            print("hull")
//            for pt in hull.hull {
//                if let _pt = pt as? [Double] {
//                    print("\(_pt[0]), \(_pt[1])")
//                }
//            }
            
//            let objcHull = _CPTHull(concavity: 5.0)
//            var cgPoints = /*self.discontinuousData*/data.map({ CGPoint(x: $0.x, y: $0.y) })
//
//            let p = withUnsafeMutablePointer(to: &cgPoints[0]) { (p) -> UnsafeMutablePointer<CGPoint> in
//                return p
//            }
//            objcHull.quickConvexHull(onViewPoints: p, dataCount:  UInt(/*self.discontinuousData*/data.count))
//            print("convex")
//            for point in UnsafeBufferPointer(start: objcHull.hullpointsArray(), count: Int(objcHull.hullpointsCount())) {
//                print("\(point.point.x), \(point.point.y)")
//            }
            
//            objcHull.concaveHull(onViewPoints: p, dataCount: UInt(self.discontinuousData.count))
//            for point in UnsafeBufferPointer(start: objcHull.hullpointsArray(), count: Int(objcHull.hullpointsCount())) {
//                print(point)
//            }
//            objcHull.concavity = 2.0
//            objcHull.concaveHull(onViewPoints: p, dataCount: UInt(/*self.discontinuousData*/data.count))
//            print("objc")
//            for point in UnsafeBufferPointer(start: objcHull.hullpointsArray(), count: Int(objcHull.hullpointsCount())) {
////                print(point)
//                print("\(point.point.x), \(point.point.y)")
//            }
            
//            let boundaryPoints = quickHullOnPlotData(plotdata: self.plotdata)
//            if !boundaryPoints.isEmpty {
//                print(boundaryPoints)
//            }
//        }
            let ratio = graph.bounds.size.width / graph.bounds.size.height
             // Setup plot space
            if let plotSpace = graph.defaultPlotSpace as? CPTXYPlotSpace {
                graph.remove(plotSpace)
                if let plot = graph.allPlots().first as? CPTContourPlot {
                    if let legend = graph.legend {
                        legend.remove(plot)
                    }
                    graph.remove(plot)
                }
            }
            
            let newPlotSpace = CPTXYPlotSpace()
            if ratio > 1 {
                newPlotSpace.yRange = CPTPlotRange(location: NSNumber(value: minY - deltaY), length:  NSNumber(value: maxY - minY + 2.0 * deltaY))
                let xRange = CPTMutablePlotRange(location: NSNumber(value: minX - deltaX), length: NSNumber(value: maxX - minX + 2.0 * deltaX))
                xRange.expand(byFactor: NSNumber(value: ratio))
                newPlotSpace.xRange = xRange
            }
            else {
                newPlotSpace.xRange = CPTPlotRange(location:  NSNumber(value: minX - deltaX), length: NSNumber(value: maxX - minX + 2.0 * deltaX))
                let yRange = CPTMutablePlotRange(location: NSNumber(value: minY - deltaY), length:  NSNumber(value: maxY - minY + 2.0 * deltaY))
                yRange.expand(byFactor: NSNumber(value: 1 / ratio))
                newPlotSpace.yRange = yRange
            }
            
            graph.add(newPlotSpace)
            if let plotSpace = graph.defaultPlotSpace as? CPTXYPlotSpace {
                plotSpace.allowsUserInteraction = true
                plotSpace.delegate              = self
                
                if let xRange = plotSpace.xRange.mutableCopy() as? CPTMutablePlotRange,
                   let yRange = plotSpace.yRange.mutableCopy() as? CPTMutablePlotRange {

                    // Expand the ranges to put some space around the plot
                    
                    xRange.expand(byFactor: NSNumber(value: 1.025))
                    xRange.location = plotSpace.xRange.location
                    yRange.expand(byFactor:NSNumber(value: 1.025))
                    
                    xRange.expand(byFactor:NSNumber(value:2.0))
                    yRange.expand(byFactor:NSNumber(value:2.0))
                    plotSpace.globalXRange = xRange
                    plotSpace.globalYRange = yRange
                    
                    var labelFormatter: NumberFormatter?
                    if ( _currentContour.trig ) {
                        labelFormatter = PiNumberFormatter()
                        labelFormatter?.multiplier = NSNumber(value: 16)
                    }
                    else {
                        labelFormatter = NumberFormatter()
                        labelFormatter?.maximumFractionDigits = 2
                    }
                    
                    // Axes
                    if let axisSet = graph.axisSet as? CPTXYAxisSet {
                        let textStyles = CPTMutableTextStyle()
                        textStyles.color    = CPTColor.blue()
                        textStyles.fontName = "Helvetica"
                        textStyles.fontSize = 12.0
                        let gridLineStyleMajor = CPTMutableLineStyle()
                        gridLineStyleMajor.lineWidth = 1.0
                        gridLineStyleMajor.lineColor = CPTColor.darkGray()
                        let gridLineStyleMinor = CPTMutableLineStyle()
                        gridLineStyleMinor.lineWidth = 0.5
                        gridLineStyleMinor.lineColor = CPTColor.gray()
                        var x2: CPTXYAxis?
                        var y2: CPTXYAxis?
                        if let x = axisSet.xAxis {
                            x.plotSpace = newPlotSpace
                            x.labelingPolicy = .fixedInterval
                            if _currentContour.functionExpression != nil,
                               let functionLimits = _currentContour.functionLimits,
                               functionLimits.count == 4 {
                                x.majorIntervalLength   = NSNumber(value: (functionLimits[1] - functionLimits[0]) / 8.0 )
                            }
                            else {
                                x.majorIntervalLength   = NSNumber(value: _currentContour.functionLimits?[0] ?? 500.0)
                            }
                            
                            x.axisConstraints = CPTConstraints.constraint(withLowerOffset: 0.0)
                            x.titleDirection = CPTSign.positive
                            x.labelAlignment = CPTAlignment.center
                            x.titleOffset = 30.0
                            x.tickLabelDirection = CPTSign.positive
                            x.labelTextStyle = textStyles
                            x.labelFormatter = labelFormatter
                        
                   //         x.orthogonalPosition    = NSNumber(value: minX)
                            x.visibleAxisRange = xRange
                            x.minorTicksPerInterval = 4;
                            x.majorGridLineStyle = gridLineStyleMajor
                            x.minorGridLineStyle = gridLineStyleMinor
                            x.labelRotation = .pi / 4
                            
                            
                            x2 = CPTXYAxis()
                            if let _x2 = x2 {
                                _x2.coordinate = CPTCoordinate.X
                                _x2.plotSpace = newPlotSpace
                                _x2.title = x.title
                                _x2.titleTextStyle = x.titleTextStyle
                                _x2.titleDirection = CPTSign.negative
                                _x2.axisConstraints = CPTConstraints.constraint(withUpperOffset: 0.0)
                                _x2.majorIntervalLength = x.majorIntervalLength
                                _x2.labelingPolicy = CPTAxisLabelingPolicy.fixedInterval
                                _x2.separateLayers = false
                                _x2.minorTicksPerInterval = 9
                                _x2.tickDirection = CPTSign.none
                                _x2.tickLabelDirection = CPTSign.negative
                                _x2.labelTextStyle = x.labelTextStyle
                                _x2.labelAlignment = CPTAlignment.center
                                _x2.axisLineStyle = x.axisLineStyle
                                _x2.majorTickLength = x.majorTickLength
                                _x2.majorTickLineStyle = x.axisLineStyle
                                _x2.minorTickLength = x.minorTickLength
                                _x2.labelFormatter = labelFormatter
                                _x2.labelRotation = .pi / 4
                                _x2.delegate = self
                            }
                        }
                        if let y = axisSet.yAxis {
                            y.plotSpace = newPlotSpace
                            y.labelingPolicy = .fixedInterval
                            if _currentContour.functionExpression != nil,
                               let functionLimits = _currentContour.functionLimits,
                               functionLimits.count == 4 {
                                y.majorIntervalLength   = NSNumber(value: (functionLimits[3] - functionLimits[2]) / 8.0 )
                            }
                            else {
                                y.majorIntervalLength   = NSNumber(value: _currentContour.functionLimits?[1] ?? 500.0)
                            }
                            y.minorTicksPerInterval = UInt(4)
                            y.visibleAxisRange = yRange
                            
                            y.axisConstraints = CPTConstraints.constraint(withLowerOffset: 0.0)
                            y.labelAlignment = CPTAlignment.center
                            y.titleDirection = CPTSign.positive
                            y.tickLabelDirection = CPTSign.positive
                            y.titleOffset = 30.0
                            y.titleDirection = CPTSign.positive
                            y.labelTextStyle = textStyles
                            
                            //y.orthogonalPosition    = NSNumber(value: minY)
                            y.majorGridLineStyle = gridLineStyleMajor
                            y.minorGridLineStyle = gridLineStyleMinor
                            y.labelFormatter = labelFormatter
                            y.labelRotation = .pi / 4
                            
                            y2 = CPTXYAxis()
                            if let _y2 = y2 {
                                _y2.coordinate = CPTCoordinate.Y
                                _y2.plotSpace = newPlotSpace
                                _y2.title = y.title
                                _y2.titleTextStyle = y.titleTextStyle
                                _y2.titleDirection = CPTSign.negative
                                _y2.axisConstraints = CPTConstraints.constraint(withUpperOffset: 0.0)
                                _y2.majorIntervalLength = y.majorIntervalLength
                                _y2.labelingPolicy = CPTAxisLabelingPolicy.fixedInterval
                                _y2.separateLayers = false
                                _y2.minorTicksPerInterval = 9
                                _y2.tickDirection = CPTSign.none
                                _y2.tickLabelDirection = CPTSign.negative
                                _y2.labelTextStyle = y.labelTextStyle
                                _y2.labelAlignment = CPTAlignment.center
                                _y2.axisLineStyle = y.axisLineStyle
                                _y2.majorTickLength = y.majorTickLength
                                _y2.majorTickLineStyle = y.axisLineStyle
                                _y2.minorTickLength = y.minorTickLength
                                _y2.labelFormatter = labelFormatter
                                _y2.labelRotation = .pi / 4
                                _y2.delegate = self
                            }
                        }
                        if let x = axisSet.xAxis,
                           let y = axisSet.yAxis,
                           let _x2 = x2,
                           let _y2 = y2 {
                            graph.axisSet?.axes =  [x, y, _x2, _y2]
                        }
                    }
                    
                    plotSpace.scale(toFit: graph.allPlots())
                }
            }
        
            // Contour properties
            let contourPlot = CPTContourPlot()
            contourPlot.setSecondaryGridColumns(1024, rows: 1024)
            if _currentContour.functionExpression != nil {
                contourPlot.identifier = "function" as NSCoding & NSCopying & NSObjectProtocol
            }
            else {
                contourPlot.identifier = "data" as NSCoding & NSCopying & NSObjectProtocol
            }
            contourPlot.title = _currentContour.plottitle
        
            contourPlot.interpolation = .linear//.curved
    //            contourPlot.curvedInterpolationOption = .hermiteCubic
            
            let lineStyle = CPTMutableLineStyle()
            // for banding effect dont want to see the plot just the band
            lineStyle.lineWidth = 3.0
            lineStyle.lineColor = CPTColor.blue()
            
            // isoCurve label appearance
            let labelTextstyle = CPTMutableTextStyle()
            labelTextstyle.fontName = "Helvetica"
            labelTextstyle.fontSize = 10.0
            labelTextstyle.textAlignment = .center
            labelTextstyle.color = CPTColor.black()
            contourPlot.isoCurvesLabelTextStyle = labelTextstyle
            let labelFormatter = NumberFormatter()
    //        labelFormatter.minimumSignificantDigits = 0
    //        labelFormatter.maximumSignificantDigits = 2
    //        labelFormatter.usesSignificantDigits = true
                labelFormatter.maximumFractionDigits = 2
            contourPlot.isoCurvesLabelFormatter = labelFormatter;
            
            contourPlot.isoCurveLineStyle = lineStyle
            contourPlot.alignsPointsToPixels = true
            
            contourPlot.noIsoCurves = 6
            contourPlot.functionPlot = _currentContour.functionExpression != nil
            contourPlot.minFunctionValue = minFunctionValue;
            contourPlot.maxFunctionValue = maxFunctionValue;
            contourPlot.limits = [NSNumber(value: minX), NSNumber(value: maxX), NSNumber(value: minY), NSNumber(value: maxY)]
            contourPlot.extrapolateToLimits = _currentContour.extrapolateToARectangleOfLimits
            contourPlot.fillIsoCurves = _currentContour.fillContours
            
            var resolution: CGFloat = 1.0
            if let plotArea = self.graph.plotAreaFrame?.plotArea {
                if(ratio < 1.0) {
                    resolution = plotArea.bounds.size.height * 0.02
                }
                else {
                    resolution = plotArea.bounds.size.width * 0.02
                }
            }
            
            if _currentContour.functionExpression != nil,
               let functionLimits = _currentContour.functionLimits {
                contourPlot.limits = [NSNumber(value: functionLimits[0]), NSNumber(value: functionLimits[1]), NSNumber(value: functionLimits[2]), NSNumber(value: functionLimits[3])]
                contourPlot.easyOnTheEye = true
                do {
                    if let plotDataSource = try generateFunctionDataForContours(dataSourceContourPlot: contourPlot) {
                        plotDataSource.resolutionX = resolution
                        plotDataSource.resolutionY = resolution
                        self.dataBlockSources?.append(plotDataSource)
                        contourPlot.dataSourceBlock = plotDataSource.dataSourceBlock
                        if functionLimits[0] == -Double.greatestFiniteMagnitude || functionLimits[1] == Double.greatestFiniteMagnitude || functionLimits[2] == -Double.greatestFiniteMagnitude || functionLimits[3] == Double.greatestFiniteMagnitude {
                            contourPlot.dataSource = plotDataSource
                        }
                        else {
                            contourPlot.dataSource = self
                            contourPlot.dataSourceBlock = plotDataSource.dataSourceBlock
                            contourPlot.minFunctionValue = minFunctionValue
                            contourPlot.maxFunctionValue = maxFunctionValue
                        }
                        contourPlot.functionPlot = true
                        contourPlot.plotSymbol = nil
    //                    let plotSymbol = CPTPlotSymbol()
    //                    plotSymbol.symbolType = .ellipse
    //                    plotSymbol.fill = CPTFill(color: .black())
    //        //            plotSymbol.lineStyle = lineStyle
    //                    plotSymbol.size = CGSize(width: 3, height: 3)
    //                    contourPlot.plotSymbol = plotSymbol
                    }
                }
                catch let error as NSError {
                    print("Error: \(error.localizedDescription)")
                    print("Error: \(String(describing: error.localizedFailureReason))")
                }
            }
            else {
                if let plotDataSource = setupContoursDataSource(plot: contourPlot, minX: minX, maxX: maxX, minY: minY, maxY: maxY) {
                    plotDataSource.resolutionX = resolution
                    plotDataSource.resolutionY = resolution
                    self.dataBlockSources?.append(plotDataSource)
                    contourPlot.dataSourceBlock = plotDataSource.dataSourceBlock
                }
                contourPlot.functionPlot =  false
                if ( /*self.krigingSurfaceInterpolation &&*/ !_currentContour.extrapolateToARectangleOfLimits ) {
                    contourPlot.joinContourLineStartToEnd = false
                }
                let plotSymbol = CPTPlotSymbol()
                plotSymbol.symbolType = .diamond
                plotSymbol.fill = CPTFill(color: .white())
    //            plotSymbol.lineStyle = lineStyle
                plotSymbol.size = CGSize(width: 10, height: 10)
                contourPlot.plotSymbol = plotSymbol
            }
            
            contourPlot.dataSource = self
            contourPlot.appearanceDataSource = self
            contourPlot.delegate     = self
            contourPlot.showLabels = true
            contourPlot.showIsoCurvesLabels = true
            
            self.message = "Generating the contour plot, please wait..."
            
            contourPlot.activityIndicatorBlock = {
                if self.spinner == nil {
                    self.spinner = SpinnerView()
                    if let _spinner = self.spinner {
                        _spinner.translatesAutoresizingMaskIntoConstraints = false
                        self.view.addSubview(_spinner)
                        _spinner.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
                        _spinner.centerYAnchor.constraint(equalTo: self.view.centerYAnchor).isActive = true
                        _spinner.widthAnchor.constraint(equalToConstant: _spinner.bounds.size.width).isActive = true
                        _spinner.heightAnchor.constraint(equalToConstant: _spinner.bounds.size.height).isActive = true
                    }
                }
                if let _spinner = self.spinner {
                    if let _message = self.message {
                        _spinner.message = _message
                    }
                    _spinner.isHidden = false
                }
                //     DispatchQueue.main.async {
    //            self.addChild(self.spinner)
    //            self.spinner.view.frame = self.view.frame
    //            self.view.addSubview(self.spinner.view)
    //            self.view.sendSubviewToBack(self.hostingView!)
    //            self.spinner.didMove(toParent: self)
             //   //     }
            } as CPTActivityIndicatorBlock
            
            return contourPlot
        }
        else {
            return nil
            
        }
    }
    
    private func createData() {
        // clean up old data
        if self.plotdata.count > 0 {
            self.plotdata.removeAll()
        }
        if let _currentContour = currentContour {
            if let _ = _currentContour.functionExpression {
                do {
                    try generateInitialFunctionData()
                    if !discontinuousData.isEmpty {
                        let outerDiscontinuousPoints = quickHullOnPlotData(plotdata: discontinuousData)
                        print(outerDiscontinuousPoints)
                    }
                }
                catch let error as NSError {
                    print("Error: \(error.localizedDescription)")
                    print("Error: \(String(describing: error.localizedFailureReason))")
                }
            }
            else if let _data = _currentContour.data {
                for i in 0..<_data.count {
                    self.plotdata.append(_data[i])
                }
            }
        }
    }
    
    private func searchForLimits() {
        if let _currentContour = currentContour,
           _currentContour.functionExpression != nil,
           let _functionLimits = _currentContour.functionLimits {
            minX = _functionLimits[0]
            maxX = _functionLimits[1]
            minY = _functionLimits[2]
            maxY = _functionLimits[3]
        }
        else {
            if let _minX = self.plotdata.map({ $0.x }).min() {
                minX = _minX
            }
            if let _maxX = self.plotdata.map({ $0.x }).max() {
                maxX = _maxX
            }
            if let _minY = self.plotdata.map({ $0.y }).min() {
                minY = _minY
            }
            if let _maxY = self.plotdata.map({ $0.y }).max() {
                maxY = _maxY
            }
        }
        if let _minFunctionValue = self.plotdata.map({ $0.z }).min() {
            minFunctionValue = _minFunctionValue
        }
        if let _maxFunctionValue = self.plotdata.map({ $0.z }).max() {
            maxFunctionValue = _maxFunctionValue
        }
    }
    
    private func setupContoursDataSource(plot: CPTContourPlot, minX: CGFloat, maxX: CGFloat, minY: CGFloat, maxY: CGFloat) -> CPTFieldFunctionDataSource? {
        var plotFieldFunctionDataSource: CPTFieldFunctionDataSource?
        if var _currentContour = currentContour {
            // use delaunay triangles to extrapolate to rectangle limits
            var vertices: [Point] = []
            var index = 0
            for data in self.plotdata {
                var point = Point(x: data.x, y: data.y)
                point.value = data.z
                point.index = index
                vertices.append(point)
                index += 1
            }
            
            let tree: KDTree<Point> = KDTree(values: vertices)
            if _currentContour.extrapolateToARectangleOfLimits {
                let edgePoints = [Point(x: minX, y: minY), Point(x: minX, y: (minY + maxY) / 3.0), Point(x: minX, y: (minY + maxY) * 2.0 / 3.0), Point(x: minX, y: maxY), Point(x: (minX + maxX) / 3.0, y: maxY), Point(x: (minX + maxX) * 2.0 / 3.0, y: maxY), Point(x: maxX, y: minY), Point(x: maxX, y: (minY + maxY) / 3.0), Point(x: maxX, y: (minY + maxY) * 2.0 / 3.0), Point(x: maxX, y: maxY), Point(x: (minX + maxX) / 3.0, y: minY), Point(x: (minX + maxX) * 2.0 / 3.0, y: minY)]

                for var point in edgePoints {
                    if !vertices.contains(point) {
                        let nearestPoints: [Point] = tree.nearestK(2, to: point)
                        point.value = TriangleInterpolation.triangle_extrapolate_linear_singleton( p1: [nearestPoints[0].x, nearestPoints[0].y], p2: [nearestPoints[1].x, nearestPoints[1].y], p: [point.x, point.y], v1: nearestPoints[0].value, v2: nearestPoints[1].value)
                        point.index = index
                        vertices.append(point)
                        index += 1
                    }
                }
            }
            
            if _currentContour.krigingSurfaceInterpolation {
                var knownXPositions: [Double] = self.plotdata.map({ $0.x })
                var knownYPositions: [Double] = self.plotdata.map({ $0.y })
                var knownValues: [Double] = self.plotdata.map({ $0.z })
                // include edges
                knownXPositions += vertices[self.plotdata.count..<vertices.count].map({ $0.x })
                knownYPositions += vertices[self.plotdata.count..<vertices.count].map({ $0.y })
                knownValues += vertices[self.plotdata.count..<vertices.count].map({ $0.value })
                let kriging: Kriging = Kriging()
                kriging.train(t: knownValues, x: knownXPositions, y: knownYPositions, model: _currentContour.krigingSurfaceModel, sigma2: 1.0, alpha: 10.0)
                if kriging.error == KrigingError.none {
                    plotFieldFunctionDataSource = generateInterpolatedDataForContoursUsingKriging(plot, kriging: kriging)
                }
                else {
                    _currentContour.krigingSurfaceInterpolation = false
                }
            }
            if !_currentContour.krigingSurfaceInterpolation {
                let triangles = Delaunay().triangulate(vertices) // Delauney uses clockwise ordered nodes
                plotFieldFunctionDataSource = generateInterpolatedDataForContoursUsingDelaunay(plot, triangles: triangles)
            }
        }
        return plotFieldFunctionDataSource
    }

    private func generateInterpolatedDataForContoursUsingDelaunay(_ dataSourceContourPlot: CPTContourPlot, triangles:[Triangle]) -> CPTFieldFunctionDataSource? {
        let plotDataSource = CPTFieldFunctionDataSource(for: dataSourceContourPlot, withBlock: { xValue, yValue in
            var functionValue: Double = 0 // Double.nan // such that if x,y outside triangle returns nonsnese
            let point = Point(x: xValue, y: yValue)
            for triangle in triangles {
                if triangle.contain(point) {
                    let v = TriangleInterpolation.triangle_interpolate_linear( m: 1, n: 1, p1: [triangle.point1.x, triangle.point1.y], p2: [triangle.point2.x, triangle.point2.y], p3: [triangle.point3.x, triangle.point3.y], p: [xValue, yValue], v1: [triangle.point1.value], v2: [triangle.point2.value], v3: [triangle.point3.value])
                    functionValue = v[0]
                    break;
                }
            }
            return functionValue
        } as CPTContourDataSourceBlock)
        
        return plotDataSource
    }
    
    private func generateInterpolatedDataForContoursUsingKriging(_ dataSourceContourPlot: CPTContourPlot, kriging: Kriging) -> CPTFieldFunctionDataSource? {
        let plotDataSource = CPTFieldFunctionDataSource(for: dataSourceContourPlot, withBlock: { xValue, yValue in
            return kriging.predict(x: xValue, y: yValue)
        } as CPTContourDataSourceBlock)
        
        return plotDataSource
    }
    
    private func generateFunctionDataForContours(dataSourceContourPlot: CPTContourPlot) throws -> CPTFieldFunctionDataSource? {
        let plotDataSource: CPTFieldFunctionDataSource = CPTFieldFunctionDataSource(for: dataSourceContourPlot, withBlock: { xValue, yValue in
            var functionValue: Double = Double.greatestFiniteMagnitude
            do {
                functionValue = try self.calculateFunctionValueAtXY(xValue, y: yValue)
            }
            catch let exception as NSError {
                print("An exception occurred: \(exception.localizedDescription)")
                print("Here are some details: \(String(describing: exception.localizedFailureReason))")
            }
            return functionValue
            
        } as CPTContourDataSourceBlock)
        
        return plotDataSource
    }
    
    private func generateInitialFunctionData() throws -> Void {
        if let _currentContour = self.currentContour,
           let functionLimits = _currentContour.functionLimits,
           functionLimits.count == 4 && functionLimits[0] < functionLimits[1] && functionLimits[2] < functionLimits[3] {
            var _y: Double = functionLimits[2]
            let increment: Double = (functionLimits[1] - functionLimits[0]) / 32.0
            while _y < functionLimits[3] + increment - 0.000001 {
                var _x: Double = functionLimits[0]
                while _x < functionLimits[1] + increment - 0.000001 {
                    do {
                        let _z = try calculateFunctionValueAtXY(_x, y: _y)
                        let data = DataStructure(x: _x, y: _y, z: _z)
                        if _z.isNaN {
                            self.discontinuousData.append(data)
                        }
                        self.plotdata.append(data)
                        _x += increment
                    }
                    catch let error as NSError {
                        print("An exception occurred: \(error.domain)")
                        print("Here are some details: \(String(describing: error.code)), \(error.localizedDescription)")
                        throw error
                    }
                }
                _y += increment
            }
        }
    }
    
    private func calculateFunctionValueAtXY(_ x: Double, y: Double) throws -> Double {
        if let _currentContour = self.currentContour,
           let functionExpression = _currentContour.functionExpression {
            var functionValue: Double = functionExpression(x, y)
            if functionValue.isInfinite {
                functionValue = Double.greatestFiniteMagnitude
            }
            else if (-functionValue).isInfinite {
                functionValue = -Double.greatestFiniteMagnitude
            }
    //        else if functionValue.isNaN {
    //            functionValue = -0.0
    //            let errString = "Result is not a number(nan)"
    //            let error = NSError(domain: Bundle.main.bundleIdentifier! + ".MathParserError", code: 222, userInfo: [NSLocalizedDescriptionKey: errString, NSLocalizedFailureReasonErrorKey: "It is possible there is a solution in your function that has turned complex, unfortunatley the DDMathParser used in this app cannot handle complex numbers. Please recheck your limits nb. stopped at x = \(x), y = \(y)."])
    //            throw error
    //        }
            return functionValue
        }
        else {
            return -0
        }
    }
    
    
    // MARK: -
    // MARK: Plot Data Source Methods
    
    func numberOfRecords(for plot: CPTPlot) -> UInt {
        return UInt(self.plotdata.count)
    }

    func number(for plot: CPTPlot, field fieldEnum: UInt, record idx: UInt) -> Any? {
        switch Int(fieldEnum) {
            case CPTContourPlotField.X.rawValue:
                return self.plotdata[Int(idx)].x
            case CPTContourPlotField.Y.rawValue:
                return self.plotdata[Int(idx)].y
            default:
                return self.plotdata[Int(idx)].z
        }
    }
    
    func dataLabel(for plot: CPTPlot, record idx: UInt) -> CPTLayer? {
        var newLayer: CPTTextLayer? = nil
        
        if let contourPlot = plot as? CPTContourPlot,
           !contourPlot.functionPlot {
            let dataPoint: DataStructure = self.plotdata[Int(idx)]
            let annotationString: String  = String(format: "%0.1f", dataPoint.z)
            newLayer = CPTTextLayer(text: annotationString)
        }
        return newLayer
    }

    // MARK: -
    // MARK: Plot Delegate Methods
    
    func didFinishDrawing(_ plot: CPTPlot) {
//        DispatchQueue.main.async {
//            self.spinner.willMove(toParent: nil)
//            self.spinner.view.removeFromSuperview()
//            self.spinner.removeFromParent()
//        }
            if let _spinner = self.spinner {
                _spinner.isHidden = true
            }
//        if let _activityIndicatorAnnotation = self.activityIndicatorAnnotation,
//           self.graph.annotations.contains(_activityIndicatorAnnotation) {
//            self.graph.removeAnnotation(_activityIndicatorAnnotation)
//        }
//        if let _activityTextAnnotation = self.activityTextAnnotation,
//           self.graph.annotations.contains(_activityTextAnnotation) {
//            self.graph.removeAnnotation(_activityTextAnnotation)
//        }
//        }
    }
    
    // MARK: -
    // MARK:  Plot Space Delegate Methods
    
    func plotSpace(_ space: CPTPlotSpace, shouldHandlePointingDeviceUp event: UIEvent, at point: CGPoint) -> Bool {
        return false
    }
    
    // MARK: -
    // MARK: CPTContourPlot Appearance Source Methods
    
    func lineStyle(for plot: CPTContourPlot, isoCurve idx: UInt) -> CPTLineStyle? {
        let linestyle = CPTMutableLineStyle(style: plot.isoCurveLineStyle)
        if let noIsoCurveValues = plot.getIsoCurveValues()?.count {
            var red:CGFloat = 0
            var green:CGFloat = 0
            var blue:CGFloat = 0
            let alpha:CGFloat = 1.0
            
            let value = CGFloat(idx) / CGFloat(noIsoCurveValues)
            blue = min(max(1.5 - 4.0 * abs(value - 0.25), 0.0), 1.0)
            green = min(max(1.5 - 4.0 * abs(value - 0.5), 0.0), 1.0)
            red  = min(max(1.5 - 4.0 * abs(value - 0.75), 0.0), 1.0)
            let colour = CPTColor(componentRed: red, green: green, blue: blue, alpha: alpha)
            linestyle.lineColor = colour
            return linestyle
        }
        else {
            return linestyle
        }
    }
    
    func fill(for plot: CPTContourPlot, isoCurve idx: UInt) -> CPTFill? {
        if let _currentContour = self.currentContour,
           _currentContour.fillContours,
            let noIsoCurveValues = plot.getIsoCurveFills()?.count {
            var red:CGFloat = 0
            var green:CGFloat = 0
            var blue:CGFloat = 0
            let alpha:CGFloat = 0.8
            let value: CGFloat = CGFloat(idx) / CGFloat(noIsoCurveValues + 1)
            blue = min(max(1.5 - 4.0 * abs(value - 0.25), 0.0), 1.0)
            green = min(max(1.5 - 4.0 * abs(value - 0.5), 0.0), 1.0)
            red  = min(max(1.5 - 4.0 * abs(value - 0.75), 0.0), 1.0)
            let colour = CPTColor(componentRed: red, green: green, blue: blue, alpha: alpha)
            let fill = CPTFill(color: colour)
            return fill
        }
        else {
            return nil
        }
    }

    func isoCurveLabel(for plot: CPTContourPlot, isoCurve idx: UInt) -> CPTLayer? {
        var newLayer: CPTTextLayer?
        if let isoCurveValues  = plot.getIsoCurveValues(),
            idx < isoCurveValues.count,
            let formatter = plot.isoCurvesLabelFormatter {
            let labelString = formatter.string(for: isoCurveValues[Int(idx)])
            if let isoCurvesLabelTextStyle = plot.isoCurvesLabelTextStyle {
                if let _ = isoCurvesLabelTextStyle.color {
                    newLayer = CPTTextLayer(text: labelString, style: plot.isoCurvesLabelTextStyle)
                }
                else {
                    let mutLabelTextStyle = CPTMutableTextStyle(style: plot.isoCurvesLabelTextStyle)
                    var red:CGFloat = 0
                    var green:CGFloat = 0
                    var blue:CGFloat = 0
                    let alpha:CGFloat = 0.8
                    let value:CGFloat = CGFloat(idx+1) / CGFloat(isoCurveValues.count+1)
                    blue = min(max(1.5 - 4.0 * abs(value - 0.25), 0.0), 1.0)
                    green = min(max(1.5 - 4.0 * abs(value - 0.5), 0.0), 1.0)
                    red  = min(max(1.5 - 4.0 * abs(value - 0.75), 0.0), 1.0)
                        let color = CPTColor(componentRed: red, green: green, blue: blue, alpha: alpha)
                    mutLabelTextStyle.color = color
                    newLayer = CPTTextLayer(text: labelString, style: mutLabelTextStyle)
                }
            }
            else {
                let lightGrayText = CPTMutableTextStyle()
                lightGrayText.color = CPTColor.lightGray()
                lightGrayText.fontName = "Helvetica"
                lightGrayText.fontSize = self.graph.titleTextStyle?.font?.pointSize ?? 10.0
                newLayer = CPTTextLayer(text: labelString, style: lightGrayText)
            }
        }
        return newLayer
    }
    
    // MARK: -
    // MARK: CPTLegendDelegate method
    
    func legend(_ legend: CPTLegend, legendEntryFor plot: CPTPlot, wasSelectedAt idx: UInt, with event: UIEvent) {
        if let contourPlot = plot as? CPTContourPlot {
            
            showSpinner("Generating the contour plot, please wait...")
            
            var isLegendShowing = false
            if let _ = colourCodeAnnotation {
                isLegendShowing = true
                removeColourCodeAnnotation()
            }
            contourPlot.noIsoCurves += 1
            if( contourPlot.noIsoCurves > 21 ) {
                contourPlot.noIsoCurves = 4
            }

            if isLegendShowing {
                showColourCodeAnnotation(contourPlot)
            }
        }
    }

    
    func legend(_ legend: CPTLegend, lineStyleForEntryAt idx: UInt, for plot: CPTPlot?) -> CPTLineStyle? {
        if let contourPlot = plot as? CPTContourPlot {
            if let entries = legend.getEntries() as? [CPTLegendEntry],
               let index = entries.firstIndex(where: { $0.indexCustomised == idx }),
               let _ = entries[index].plotCustomised,
               let _isoCurveLineStyles = contourPlot.getIsoCurveLineStyles(),
               let _isoCurveIndices = contourPlot.getIsoCurveIndices(),
               _isoCurveIndices.count > 0 && idx < _isoCurveIndices.count {
                return _isoCurveLineStyles[Int(truncating: _isoCurveIndices[Int(idx)])]
            }
            else {
                return nil;
            }
        }
        else {
            return nil;
        }
    }
    
    func legend(_ legend: CPTLegend, fillForSwatchAt idx: UInt, for plot: CPTPlot?) -> CPTFill? {
        if let _currentContour = self.currentContour,
           _currentContour.fillContours,
           let entries = legend.getEntries() as? [CPTLegendEntry],
           let index = entries.firstIndex(where: { $0.indexCustomised == idx }),
           let contourPlot = plot as? CPTContourPlot,
           entries[index].plotCustomised == contourPlot,
           let _isoCurveFills = contourPlot.getIsoCurveFills(),
           _isoCurveFills.count > 0 && idx < _isoCurveFills.count,
           let _fill = _isoCurveFills[Int(idx)] as? CPTFill {
            return _fill
        }
        else  {
            return nil;
        }
    }
    

    // MARK: -
    // MARK: Manage Colour Code Annotations
    
    private func showColourCodeAnnotation(_ plot: CPTContourPlot) {
        colourCodeAnnotation = CPTAnnotation()
        if let _isoCurveValues = plot.getIsoCurveValues(),
           let _isoCurveIndices = plot.getIsoCurveIndices() {
            let borderLineStyle = CPTMutableLineStyle()
            borderLineStyle.lineColor = CPTColor.black()
            borderLineStyle.lineWidth = 0.5
            let textStyle = CPTMutableTextStyle()
            textStyle.fontName = "Helvetica"
            textStyle.fontSize = UIDevice.current.userInterfaceIdiom == .phone ? 8.0 : 12.0
            let colorCodeLegend = CPTLegend()
            colorCodeLegend.fill = CPTFill(color: CPTColor(genericGray: 0.95).withAlphaComponent(0.6))
            colorCodeLegend.borderLineStyle = borderLineStyle
            if let _currentContour = self.currentContour,
               _currentContour.fillContours {
                let noContourFillColours = _isoCurveIndices.count + 1
                colorCodeLegend.numberOfRows = UInt(noContourFillColours) / (UIDevice.current.userInterfaceIdiom == .phone ? 3 : 4)
                if UInt(noContourFillColours) % (UIDevice.current.userInterfaceIdiom == .phone ? 3 : 4) > 0 {
                    colorCodeLegend.numberOfRows = colorCodeLegend.numberOfRows + 1
                }
                colorCodeLegend.numberOfColumns = UInt(noContourFillColours) > (UIDevice.current.userInterfaceIdiom == .phone ? 3 : 4) ? (UIDevice.current.userInterfaceIdiom == .phone ? 3 : 4) : UInt(noContourFillColours)
                colorCodeLegend.swatchSize = CGSize(width: 25.0, height: 16.0)

                var firstValue = _isoCurveValues[Int(truncating: _isoCurveIndices[0])].doubleValue
                var legendEntries:[CPTLegendEntry] = []
                let legendEntry0 = CPTLegendEntry()
                legendEntry0.indexCustomised = UInt(truncating: _isoCurveIndices[0])
                legendEntry0.plotCustomised = plot
                legendEntry0.textStyle = textStyle
                if( firstValue == 1000.0 * _isoCurveValues[Int(truncating: _isoCurveIndices[1])].doubleValue ) {
                    legendEntry0.titleCustomised = "Discontinuous"
                }
                else {
                    legendEntry0.titleCustomised = String(format:"<%0.2f", _isoCurveValues[Int(truncating: _isoCurveIndices[0])].doubleValue)
                }
                legendEntries.append(legendEntry0)
                for i in 1..<noContourFillColours - 1 {
                    let legendEntry = CPTLegendEntry()
                    legendEntry.indexCustomised = UInt(truncating: _isoCurveIndices[i])
                    legendEntry.plotCustomised = plot
                    legendEntry.textStyle = textStyle
                    legendEntry.titleCustomised = String(format:"%0.2f - %0.2f", firstValue, _isoCurveValues[Int(truncating: _isoCurveIndices[i])].doubleValue)
                    firstValue = _isoCurveValues[Int(truncating: _isoCurveIndices[i])].doubleValue
                    legendEntries.append(legendEntry)
                }
                let legendEntry1 = CPTLegendEntry()
                legendEntry1.indexCustomised = UInt(_isoCurveValues.count)
                legendEntry1.plotCustomised = plot
                legendEntry1.textStyle = textStyle
                if( _isoCurveValues[Int(truncating: _isoCurveIndices[_isoCurveIndices.count - 1])].doubleValue == 1000.0 * _isoCurveValues[Int(truncating: _isoCurveIndices[_isoCurveIndices.count - 2])].doubleValue ) {
                    legendEntry1.titleCustomised = "Discontinuous"
                }
                else {
                    legendEntry1.titleCustomised = String(format:">%0.2f", _isoCurveValues[Int(truncating: _isoCurveIndices[_isoCurveIndices.count - 1])].doubleValue)
                }
                legendEntries.append(legendEntry1)
                colorCodeLegend.setNewLegendEntries(NSMutableArray(array: legendEntries))
            }
            else {
                if let _isoCurveLineStyles = plot.getIsoCurveLineStyles() {
                    colorCodeLegend.numberOfRows = UInt(_isoCurveIndices.count) / (UIDevice.current.userInterfaceIdiom == .phone ? 3 : 4)
                    if UInt(_isoCurveIndices.count) % (UIDevice.current.userInterfaceIdiom == .phone ? 3 : 4) > 0 {
                        colorCodeLegend.numberOfRows = colorCodeLegend.numberOfRows + 1
                    }
                    colorCodeLegend.numberOfColumns = UInt(_isoCurveIndices.count) > (UIDevice.current.userInterfaceIdiom == .phone ? 3 : 4) ? (UIDevice.current.userInterfaceIdiom == .phone ? 3 : 4) : UInt(_isoCurveIndices.count)

                    var legendEntries:[CPTLegendEntry] = []
                    for i in 0..<_isoCurveIndices.count {
                        let legendEntry = CPTLegendEntry()
                        legendEntry.indexCustomised = UInt(truncating: _isoCurveIndices[i])
                        legendEntry.plotCustomised = plot
                        legendEntry.textStyle = textStyle
                        if( (i == 0 && _isoCurveValues[Int(truncating: _isoCurveIndices[i])].doubleValue == 1000.0 * _isoCurveValues[Int(truncating: _isoCurveIndices[i + 1])].doubleValue) || (i == _isoCurveIndices.count - 1 &&  _isoCurveValues[Int(truncating: _isoCurveIndices[i])].doubleValue == 1000 * _isoCurveValues[Int(truncating: _isoCurveIndices[i - 1])].doubleValue) ) {
                            legendEntry.titleCustomised = "Discontinuous"
                        }
                        else {
                            legendEntry.titleCustomised = String(format:"%0.2f", _isoCurveValues[Int(truncating: _isoCurveIndices[i])].doubleValue)
                        }
                        legendEntry.lineStyleCustomised = _isoCurveLineStyles[Int(truncating: _isoCurveIndices[i])]
                        legendEntries.append(legendEntry)
                    }
                    colorCodeLegend.setNewLegendEntries(NSMutableArray(array: legendEntries))
                }
            }
            colorCodeLegend.cornerRadius = 5.0
            colorCodeLegend.rowMargin = 5.0
            colorCodeLegend.paddingLeft = 6.0
            colorCodeLegend.paddingTop = 6.0
            colorCodeLegend.paddingRight = 6.0
            colorCodeLegend.paddingBottom = 6.0
            colorCodeLegend.delegate = self
            colourCodeAnnotation?.contentLayer = colorCodeLegend
//            colorCodeLegend.setLayoutChanged()
            graph.plotAreaFrame?.plotArea?.addAnnotation(colourCodeAnnotation)
            colorCodeLegend.position = CGPoint(x: (graph.plotAreaFrame?.plotArea?.bounds.width ?? 150.0) * 0.5, y: 70.0)
        }
    }

    private func removeColourCodeAnnotation() {
        if let _colourCodeAnnotation = colourCodeAnnotation,
           let annotations = graph.plotAreaFrame?.plotArea?.annotations,
           annotations.contains(_colourCodeAnnotation) {
            graph.plotAreaFrame?.plotArea?.removeAnnotation(_colourCodeAnnotation)
            colourCodeAnnotation = nil
        }
    }
    
    // MARK: -
    // MARK: Segue
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "showContourManagerPopOver") || (segue.identifier == "showContourManager") {
            contourManagerViewController = (segue.destination as? ContourManagerViewController)
            contourManagerViewController?.contourManagerRecords = self.contourManagerRecords
            contourManagerViewController?.contourManagerCounter = self.contourManagerCounter
            contourManagerViewController?.delegate = self
            if (segue.identifier == "showContourManagerPopOver") {
                contourManagerViewController?.popoverPresentationController?.delegate = self
                if let _tappedContourManagerButton = tappedContourManagerButton {
                    contourManagerViewController?.popoverPresentationController?.sourceView = self.view
                    contourManagerViewController?.popoverPresentationController?.sourceRect = _tappedContourManagerButton.frame
                }
                contourManagerViewController?.popoverPresentationController?.permittedArrowDirections = .down
                contourManagerViewController?.popoverPresentationController?.backgroundColor = UIColor.init(red: 1.0, green: 0.75, blue: 0.793, alpha: 1.0)
            }
            shouldPerformSegue(withIdentifier: segue.identifier!, sender: self)
        }
    }
    
    // MARK: -
    // MARK: Button Navigation of Plot
    
    func createNavigationButtons(_ view: UIView, target: Any, actions: [Selector]) {
        
        let scrollUpButton = UIButton(frame: CGRect(x: 0.0, y: 0.0, width: 32.0, height: 32.0))
        scrollUpButton.setImage(UIImage(systemName: "arrowtriangle.up.fill"), for: .normal)
        scrollUpButton.addTarget(target, action: actions[0], for: .touchUpInside)
        view.addSubview(scrollUpButton)
        let scrollDownButton = UIButton(frame: CGRect(x: 0.0, y: 0.0, width: 32.0, height: 32.0))
        scrollDownButton.setImage(UIImage(systemName: "arrowtriangle.down.fill"), for: .normal)
        scrollDownButton.addTarget(target, action: actions[1], for: .touchUpInside)
        view.addSubview(scrollDownButton)
        let scrollLeftButton = UIButton(frame: CGRect(x: 0.0, y: 0.0, width: 32.0, height: 32.0))
        scrollLeftButton.setImage(UIImage(systemName: "arrowtriangle.left.fill"), for: .normal)
        scrollLeftButton.addTarget(target, action: actions[2], for: .touchUpInside)
        view.addSubview(scrollLeftButton)
        let scrollRightButton = UIButton(frame: CGRect(x: 0.0, y: 0.0, width: 32.0, height: 32.0))
        scrollRightButton.setImage(UIImage(systemName: "arrowtriangle.right.fill"), for: .normal)
        scrollRightButton.addTarget(target, action: actions[3], for: .touchUpInside)
        view.addSubview(scrollRightButton)
        
        scrollDownButton.translatesAutoresizingMaskIntoConstraints = false
        view.addConstraints([
            NSLayoutConstraint(item: scrollDownButton, attribute: .bottom, relatedBy: .equal, toItem: view, attribute: .bottom, multiplier: 1.0, constant: -32.0),
            NSLayoutConstraint(item: scrollDownButton, attribute: .trailing, relatedBy: .equal, toItem: view, attribute: .trailing, multiplier: 1.0, constant: -32.0),
            NSLayoutConstraint(item: scrollDownButton, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 0.0, constant: 32.0),
            NSLayoutConstraint(item: scrollDownButton, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 0.0, constant: 32.0)
        ])
        scrollUpButton.translatesAutoresizingMaskIntoConstraints = false
        view.addConstraints([
            NSLayoutConstraint(item: scrollUpButton, attribute: .bottom, relatedBy: .equal, toItem: scrollDownButton, attribute: .top, multiplier: 1.0, constant: -4.0),
            NSLayoutConstraint(item: scrollUpButton, attribute: .centerX, relatedBy: .equal, toItem: scrollDownButton, attribute: .centerX, multiplier: 1.0, constant: 0.0),
            NSLayoutConstraint(item: scrollUpButton, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 0.0, constant: 32.0),
            NSLayoutConstraint(item: scrollUpButton, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 0.0, constant: 32.0)
        ])
        
        scrollRightButton.translatesAutoresizingMaskIntoConstraints = false
        view.addConstraints([
            NSLayoutConstraint(item: scrollRightButton, attribute: .bottom, relatedBy: .equal, toItem: scrollDownButton, attribute: .top, multiplier: 1.0, constant: 16.0),
            NSLayoutConstraint(item: scrollRightButton, attribute: .leading, relatedBy: .equal, toItem: scrollDownButton, attribute: .trailing, multiplier: 1.0, constant: -4.0),
            NSLayoutConstraint(item: scrollRightButton, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 0.0, constant: 32.0),
            NSLayoutConstraint(item: scrollRightButton, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 0.0, constant: 32.0)
        ])
        scrollLeftButton.translatesAutoresizingMaskIntoConstraints = false
        view.addConstraints([
            NSLayoutConstraint(item: scrollLeftButton, attribute: .bottom, relatedBy: .equal, toItem: scrollDownButton, attribute: .top, multiplier: 1.0, constant: 16.0),
            NSLayoutConstraint(item: scrollLeftButton, attribute: .trailing, relatedBy: .equal, toItem: scrollDownButton, attribute: .leading, multiplier: 1.0, constant: 4.0),
            NSLayoutConstraint(item: scrollLeftButton, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 0.0, constant: 32.0),
            NSLayoutConstraint(item: scrollLeftButton, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 0.0, constant: 32.0)
        ])
    }
    
    @objc func scrollUpButton(_ sender: Any) {
        if let _plotSpace = self.graph.defaultPlotSpace as? CPTXYPlotSpace {
            let newYPlotRange = CPTPlotRange(location: NSNumber(value:_plotSpace.yRange.locationDouble + _plotSpace.yRange.lengthDouble / 8.0), length: _plotSpace.yRange.length)
            _plotSpace.yRange = newYPlotRange
        }
    }
    
    @objc func scrollDownButton(_ sender: Any) {
        if let _plotSpace = self.graph.defaultPlotSpace as? CPTXYPlotSpace {
            let newYPlotRange = CPTPlotRange(location: NSNumber(value:_plotSpace.yRange.locationDouble - _plotSpace.yRange.lengthDouble / 8.0), length: _plotSpace.yRange.length)
            _plotSpace.yRange = newYPlotRange
        }
    }
    
    @objc func scrollLeftButton(_ sender: Any) {
        if let _plotSpace = self.graph.defaultPlotSpace as? CPTXYPlotSpace {
            let newXPlotRange = CPTPlotRange(location: NSNumber(value:_plotSpace.xRange.locationDouble - _plotSpace.xRange.lengthDouble / 6.0), length: _plotSpace.xRange.length)
            _plotSpace.xRange = newXPlotRange
        }
    }
    
    @objc func scrollRightButton(_ sender: Any) {
        if let _plotSpace = self.graph.defaultPlotSpace as? CPTXYPlotSpace {
            let newXPlotRange = CPTPlotRange(location: NSNumber(value:_plotSpace.xRange.locationDouble + _plotSpace.xRange.lengthDouble / 6.0), length: _plotSpace.xRange.length)
            _plotSpace.xRange = newXPlotRange
        }
    }
    
//    func createConfigurationButtons(_ view: UIView) {
//        if let _currentContour = self.currentContour {
//            let toggleFillButton = UIButton(frame: CGRect(x: 0.0, y: 0.0, width: 32.0, height: 32.0))
//            if _currentContour.fillContours {
//                toggleFillButton.setImage(UIImage(systemName: "waveform.path.ecg.rectangle"), for: .normal)
//            }
//            else {
//                toggleFillButton.setImage(UIImage(systemName: "waveform.path.ecg.rectangle.fill"), for: .normal)
//            }
//            toggleFillButton.addTarget(target, action: #selector(toggleFillContoursButton(_ :)), for: .touchUpInside)
//            view.addSubview(toggleFillButton)
//
//            toggleFillButton.translatesAutoresizingMaskIntoConstraints = false
//            view.addConstraints([
//                NSLayoutConstraint(item: toggleFillButton, attribute: .top, relatedBy: .equal, toItem: view, attribute: .top, multiplier: 1.0, constant: 16.0),
//                NSLayoutConstraint(item: toggleFillButton, attribute: .trailing, relatedBy: .equal, toItem: view, attribute: .trailing, multiplier: 1.0, constant: -32.0),
//                NSLayoutConstraint(item: toggleFillButton, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 0.0, constant: 32.0),
//                NSLayoutConstraint(item: toggleFillButton, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 0.0, constant: 32.0)
//            ])
//
//            let toggleExtrapolateToLimitsRectangleButton = UIButton(frame: CGRect(x: 0.0, y: 0.0, width: 32.0, height: 32.0))
//            if _currentContour.extrapolateToARectangleOfLimits {
//                toggleExtrapolateToLimitsRectangleButton.setImage(UIImage(systemName: "arrow.down.forward.and.arrow.up.backward"), for: .normal)
//            }
//            else {
//                toggleExtrapolateToLimitsRectangleButton.setImage(UIImage(systemName: "arrow.up.backward.and.arrow.down.forward"), for: .normal)
//            }
//            toggleExtrapolateToLimitsRectangleButton.addTarget(target, action: #selector(toggleExtrapolateContoursToLimitsRectangleButton(_ :)), for: .touchUpInside)
//            view.addSubview(toggleExtrapolateToLimitsRectangleButton)
//
//            toggleExtrapolateToLimitsRectangleButton.translatesAutoresizingMaskIntoConstraints = false
//            view.addConstraints([
//                NSLayoutConstraint(item: toggleExtrapolateToLimitsRectangleButton, attribute: .top, relatedBy: .equal, toItem: view, attribute: .top, multiplier: 1.0, constant: 16.0),
//                NSLayoutConstraint(item: toggleExtrapolateToLimitsRectangleButton, attribute: .trailing, relatedBy: .equal, toItem: toggleFillButton, attribute: .leading, multiplier: 1.0, constant: -8.0),
//                NSLayoutConstraint(item: toggleExtrapolateToLimitsRectangleButton, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 0.0, constant: 32.0),
//                NSLayoutConstraint(item: toggleExtrapolateToLimitsRectangleButton, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 0.0, constant: 32.0)
//            ])
//            let toggleSurfaceInterpolationMethodButton = UIButton(frame: CGRect(x: 0.0, y: 0.0, width: 32.0, height: 32.0))
//            if _currentContour.krigingSurfaceInterpolation {
//                toggleSurfaceInterpolationMethodButton.setImage(UIImage(systemName: "d.square"), for: .normal)
//            }
//            else {
//                toggleSurfaceInterpolationMethodButton.setImage(UIImage(systemName: "k.square"), for: .normal)
//            }
//            toggleSurfaceInterpolationMethodButton.addTarget(target, action: #selector(toggleSurfaceInterpolationContoursMethodButton(_ :)), for: .touchUpInside)
//            view.addSubview(toggleSurfaceInterpolationMethodButton)
//
//            toggleSurfaceInterpolationMethodButton.translatesAutoresizingMaskIntoConstraints = false
//            view.addConstraints([
//                NSLayoutConstraint(item: toggleSurfaceInterpolationMethodButton, attribute: .top, relatedBy: .equal, toItem: view, attribute: .top, multiplier: 1.0, constant: 16.0),
//                NSLayoutConstraint(item: toggleSurfaceInterpolationMethodButton, attribute: .trailing, relatedBy: .equal, toItem: toggleExtrapolateToLimitsRectangleButton, attribute: .leading, multiplier: 1.0, constant: -8.0),
//                NSLayoutConstraint(item: toggleSurfaceInterpolationMethodButton, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 0.0, constant: 32.0),
//                NSLayoutConstraint(item: toggleSurfaceInterpolationMethodButton, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 0.0, constant: 32.0)
//            ])
//
//            tappedContourManagerButton = UIButton(frame: CGRect(x: 0.0, y: 0.0, width: 32.0, height: 32.0))
//            if let _tappedContourManagerButton = tappedContourManagerButton {
//                if _currentContour.functionExpression != nil {
//                    _tappedContourManagerButton.setImage(UIImage(systemName: "f.square"), for: .normal)
//                }
//                else {
//                    _tappedContourManagerButton.setImage(UIImage(systemName: "f.square.fill"), for: .normal)
//                }
//                _tappedContourManagerButton.addTarget(target, action: #selector(tappedContourManagerButton(_ :)), for: .touchUpInside)
//                view.addSubview(_tappedContourManagerButton)
//
//                _tappedContourManagerButton.translatesAutoresizingMaskIntoConstraints = false
//                view.addConstraints([
//                    NSLayoutConstraint(item: _tappedContourManagerButton, attribute: .top, relatedBy: .equal, toItem: view, attribute: .top, multiplier: 1.0, constant: 16.0),
//                    NSLayoutConstraint(item: _tappedContourManagerButton, attribute: .trailing, relatedBy: .equal, toItem: toggleSurfaceInterpolationMethodButton, attribute: .leading, multiplier: 1.0, constant: -8.0),
//                    NSLayoutConstraint(item: _tappedContourManagerButton, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 0.0, constant: 32.0),
//                    NSLayoutConstraint(item: _tappedContourManagerButton, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 0.0, constant: 32.0)
//                ])
//            }
//        }
//    }
    func setupConfigurationButtons() {
        if let _currentContour = self.currentContour {
            if let _toggleFillButton = self.toggleFillButton {
                if _currentContour.fillContours {
                    _toggleFillButton.setImage(UIImage(systemName: "waveform.path.ecg.rectangle"), for: .normal)
                }
                else {
                    _toggleFillButton.setImage(UIImage(systemName: "waveform.path.ecg.rectangle.fill"), for: .normal)
                }
            }
            
            if let _toggleExtrapolateToLimitsRectangleButton = self.toggleExtrapolateToLimitsRectangleButton {
                if _currentContour.extrapolateToARectangleOfLimits {
                    _toggleExtrapolateToLimitsRectangleButton.setImage(UIImage(systemName: "arrow.down.forward.and.arrow.up.backward"), for: .normal)
                }
                else {
                    _toggleExtrapolateToLimitsRectangleButton.setImage(UIImage(systemName: "arrow.up.backward.and.arrow.down.forward"), for: .normal)
                }
            }
            
            if let _toggleSurfaceInterpolationMethodButton = self.toggleSurfaceInterpolationMethodButton {
                if _currentContour.krigingSurfaceInterpolation {
                    _toggleSurfaceInterpolationMethodButton.setImage(UIImage(systemName: "d.square"), for: .normal)
                }
                else {
                    _toggleSurfaceInterpolationMethodButton.setImage(UIImage(systemName: "k.square"), for: .normal)
                }
            }
            
            if let _tappedContourManagerButton = self.tappedContourManagerButton {
                if _currentContour.functionExpression != nil {
                    _tappedContourManagerButton.setImage(UIImage(systemName: "f.square"), for: .normal)
                }
                else {
                    _tappedContourManagerButton.setImage(UIImage(systemName: "f.square.fill"), for: .normal)
                }
            }
        }
    }
    
    @IBAction func tappedContourManagerButton(_ sender: Any?) {
        contourManagerViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ContourManager") as? ContourManagerViewController
        
        contourManagerViewController?.contourManagerRecords = self.contourManagerRecords
        contourManagerViewController?.contourManagerCounter = self.contourManagerCounter
        contourManagerViewController?.delegate = self
        if let popover = contourManagerViewController,
            let _sender = sender as? PopoverPresentationSourceView {
            present(popover: popover, from: _sender, size: CGSize(width: 320, height: 400), arrowDirection: .any)
        }
    }
    
    @IBAction func toggleFillContoursButton(_ sender: Any?) {
        if var _currentContour = self.currentContour {
            _currentContour.fillContours = !_currentContour.fillContours
            self.currentContour?.fillContours = _currentContour.fillContours
            if let toggleFillButton = sender as? UIButton {
                if _currentContour.fillContours {
                    toggleFillButton.setImage(UIImage(systemName: "waveform.path.ecg.rectangle.fill"), for: .normal)
                }
                else {
                    toggleFillButton.setImage(UIImage(systemName: "waveform.path.ecg.rectangle"), for: .normal)
                }
                
                if let plot = self.graph.allPlots().first as? CPTContourPlot {
    //                showSpinner("Generating the contour plot, please wait...")
                    var isLegendShowing = false
                    if let _ = colourCodeAnnotation {
                        isLegendShowing = true
                        removeColourCodeAnnotation()
                    }
                    plot.fillIsoCurves = _currentContour.fillContours
                    plot.reloadData()
                    if isLegendShowing {
                        showColourCodeAnnotation(plot)
                    }
                }
            }
        }
    }
    
    @IBAction func toggleExtrapolateContoursToLimitsRectangleButton(_ sender: Any?) {
        if var _currentContour = self.currentContour,
           _currentContour.functionExpression == nil {
            _currentContour.extrapolateToARectangleOfLimits = !_currentContour.extrapolateToARectangleOfLimits
            self.currentContour?.extrapolateToARectangleOfLimits = _currentContour.extrapolateToARectangleOfLimits
            if let toggleExtrapolateToLimitsRectangleButton = sender as? UIButton {
                if _currentContour.extrapolateToARectangleOfLimits {
                    toggleExtrapolateToLimitsRectangleButton.setImage(UIImage(systemName: "arrow.down.forward.and.arrow.up.backward"), for: .normal)
                }
                else {
                    toggleExtrapolateToLimitsRectangleButton.setImage(UIImage(systemName: "arrow.up.backward.and.arrow.down.forward"), for: .normal)
                }
//                showSpinner("Generating the contour plot, please wait...")
                
                self.graph.legend?.removePlot(withIdentifier: (_currentContour.functionExpression == nil ? "function" : "data") as NSCoding & NSCopying & NSObjectProtocol)
                self.graph.removePlot(withIdentifier: (_currentContour.functionExpression == nil ? "function" : "data") as NSCoding & NSCopying & NSObjectProtocol)
                
                if let contourPlot = setupPlot(self.graph) {
                    self.graph.add(contourPlot)
                    self.graph.legend?.add(contourPlot)
                }
                
                if let plot = self.graph.allPlots().first as? CPTContourPlot {
                    plot.extrapolateToLimits = _currentContour.extrapolateToARectangleOfLimits
                    plot.fillIsoCurves = _currentContour.fillContours
                    self.dataBlockSources?.removeAll()
                    searchForLimits()
                    var deltaX = (maxX - minX) / 20.0
                    var deltaY = (maxY - minY) / 20.0
                    if !_currentContour.extrapolateToARectangleOfLimits && _currentContour.functionExpression == nil {
                        if _currentContour.krigingSurfaceInterpolation { // in order to prevent any borders make extra 25% on all 4 sides
                            deltaX = (maxX - minX) / 4.0
                            deltaY = (maxY - minY) / 4.0
                        }
                        else {
                            deltaX = (maxX - minX) / 10.0
                            deltaY = (maxY - minY) / 10.0
                        }
                    }
                    minX -= deltaX
                    maxX += deltaX
                    minY -= deltaY
                    maxY += deltaY
                    
                    
                    let ratio = graph.bounds.size.width / graph.bounds.size.height
                     // Setup plot space
                    if let plotSpace = graph.defaultPlotSpace as? CPTXYPlotSpace {
                        if ratio > 1 {
                            plotSpace.yRange = CPTPlotRange(location: NSNumber(value: minY - deltaY), length:  NSNumber(value: maxY - minY + 2.0 * deltaY))
                            let xRange = CPTMutablePlotRange(location: NSNumber(value: minX - deltaX), length: NSNumber(value: maxX - minX + 2.0 * deltaX))
                            xRange.expand(byFactor: NSNumber(value: ratio))
                            plotSpace.xRange = xRange
                        }
                        else {
                            plotSpace.xRange = CPTPlotRange(location:  NSNumber(value: minX - deltaX), length: NSNumber(value: maxX - minX + 2.0 * deltaX))
                            let yRange = CPTMutablePlotRange(location: NSNumber(value: minY - deltaY), length:  NSNumber(value: maxY - minY + 2.0 * deltaY))
                            yRange.expand(byFactor: NSNumber(value: 1 / ratio))
                            plotSpace.yRange = yRange
                        }
                    }
                    
                    
                    let plotDataSource = setupContoursDataSource(plot: plot, minX: minX, maxX: maxX, minY: minY, maxY: maxY)
                    if let _plotDataSource = plotDataSource {
                        self.dataBlockSources?.append(_plotDataSource)
                    }
                    if let _dataSourceBlock = plotDataSource?.dataSourceBlock {
                        plot.dataSource = self
                        plot.updateDataSourceBlock(_dataSourceBlock)
                    }
                    
                    var isLegendShowing = false
                    if let _ = colourCodeAnnotation {
                        isLegendShowing = true
                        removeColourCodeAnnotation()
                    }
                    plot.fillIsoCurves = _currentContour.fillContours;
                    
                    if isLegendShowing {
                        showColourCodeAnnotation(plot)
                    }
                }
            }
        }
    }
    
    @IBAction func toggleSurfaceInterpolationContoursMethodButton(_ sender: Any?) {
        if var _currentContour = self.currentContour,
           _currentContour.functionExpression == nil {
            _currentContour.krigingSurfaceInterpolation = !_currentContour.krigingSurfaceInterpolation
            self.currentContour?.krigingSurfaceInterpolation = _currentContour.krigingSurfaceInterpolation
            if let toggleSurfaceInterpolationMethodButton = sender as? UIButton {
                if _currentContour.krigingSurfaceInterpolation {
                    toggleSurfaceInterpolationMethodButton.setImage(UIImage(systemName: "d.square"), for: .normal)
                }
                else {
                    toggleSurfaceInterpolationMethodButton.setImage(UIImage(systemName: "k.square"), for: .normal)
                }
               
                if let plot = self.graph.allPlots().first as? CPTContourPlot {
//                    showSpinner("Generating the contour plot, please wait...")
                    self.dataBlockSources?.removeAll()
                    searchForLimits()
                    var deltaX = (maxX - minX) / 20.0
                    var deltaY = (maxY - minY) / 20.0
                    if !_currentContour.extrapolateToARectangleOfLimits && _currentContour.functionExpression == nil {
                        if _currentContour.krigingSurfaceInterpolation { // in order to prevent any borders make extra 25% on all 4 sides
                            deltaX = (maxX - minX) / 4.0
                            deltaY = (maxY - minY) / 4.0
                        }
                        else {
                            deltaX = (maxX - minX) / 10.0
                            deltaY = (maxY - minY) / 10.0
                        }
                        plot.limits = [NSNumber(value: minX), NSNumber(value: maxX), NSNumber(value: minY), NSNumber(value: maxY)]
                    }
                    let plotDataSource = setupContoursDataSource(plot: plot, minX: minX, maxX: maxX, minY: minY, maxY: maxY)
                    if let _plotDataSource = plotDataSource {
                        self.dataBlockSources?.append(_plotDataSource)
                    }
                    
                    minX -= deltaX
                    maxX += deltaX
                    minY -= deltaY
                    maxY += deltaY
                    
                    let ratio = graph.bounds.size.width / graph.bounds.size.height
                     // Setup plot space
                    if let plotSpace = graph.defaultPlotSpace as? CPTXYPlotSpace {
                        if ratio > 1 {
                            plotSpace.yRange = CPTPlotRange(location: NSNumber(value: minY - deltaY), length:  NSNumber(value: maxY - minY + 2.0 * deltaY))
                            let xRange = CPTMutablePlotRange(location: NSNumber(value: minX - deltaX), length: NSNumber(value: maxX - minX + 2.0 * deltaX))
                            xRange.expand(byFactor: NSNumber(value: ratio))
                            plotSpace.xRange = xRange
                        }
                        else {
                            plotSpace.xRange = CPTPlotRange(location:  NSNumber(value: minX - deltaX), length: NSNumber(value: maxX - minX + 2.0 * deltaX))
                            let yRange = CPTMutablePlotRange(location: NSNumber(value: minY - deltaY), length:  NSNumber(value: maxY - minY + 2.0 * deltaY))
                            yRange.expand(byFactor: NSNumber(value: 1 / ratio))
                            plotSpace.yRange = yRange
                        }
                    }
                    
                    
                    if let _dataSourceBlock = plotDataSource?.dataSourceBlock {
                        plot.dataSource = self
                        plot.updateDataSourceBlock(_dataSourceBlock)
                    }
                    
                    var isLegendShowing = false
                    if let _ = colourCodeAnnotation {
                        isLegendShowing = true
                        removeColourCodeAnnotation()
                    }
                    plot.fillIsoCurves = _currentContour.fillContours;
                    
                    if isLegendShowing {
                        showColourCodeAnnotation(plot)
                    }
                }
            }
        }
    }
    
    // MARK: -
    // MARK: ContourManagerViewControllerDelegate methods
    
    func contourManagerViewControllerChoice(_ contourManagerViewController: ContourManagerViewController, userSelectedChoiceChanged changed: Bool, contourManagerCounter: Int) {
        self.contourManagerCounter = contourManagerCounter
        
        if let popoverPresentationController = contourManagerViewController.popoverPresentationController {
            popoverPresentationController.presentingViewController.dismiss(animated: true)
        }
        
        currentContour = contourManagerRecords[contourManagerCounter]
        if let _currentContour = self.currentContour {
            if _currentContour.functionExpression != nil {
                tappedContourManagerButton?.setImage(UIImage(systemName: "f.square"), for: .normal)
            }
            else {
                tappedContourManagerButton?.setImage(UIImage(systemName: "f.square.fill"), for: .normal)
            }
//            showSpinner("Generating the contour plot, please wait...")
            
            self.graph.legend?.removePlot(withIdentifier: (_currentContour.functionExpression != nil ? "data" : "function") as NSCoding & NSCopying & NSObjectProtocol)
            self.graph.removePlot(withIdentifier: (_currentContour.functionExpression != nil  ? "data" : "function") as NSCoding & NSCopying & NSObjectProtocol)
            
            if let contourPlot = setupPlot(self.graph) {
                self.graph.add(contourPlot)
                self.graph.legend?.add(contourPlot)
                
            }
            if let plot = self.graph.allPlots().first as? CPTContourPlot {
                var isLegendShowing = false
                if let _ = colourCodeAnnotation {
                    isLegendShowing = true
                    removeColourCodeAnnotation()
                }
                plot.fillIsoCurves = _currentContour.fillContours;
                if isLegendShowing {
                    showColourCodeAnnotation(plot)
                }
            }
        }
    }
    
    // MARK: -
    // MARK: UIPopoverPresentationControllerDelegate methods
    
    func popoverPresentationControllerDidDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) {
        contourManagerViewController = nil
    }
    
    // MARK: -
    // MARK: Gesture Delegates
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        return true
    }
    
    // MARK: -
    // MARK: UILongPressGestureRecognizer
    
    @objc func toggleContourLegend(_ gestureRecognizer: UILongPressGestureRecognizer) {
        if gestureRecognizer.state == .began && gestureRecognizer.view == hostingView {
//            let tapPoint: CGPoint = gestureRecognizer.location(in: hostingView)
            if let _ = colourCodeAnnotation {
                removeColourCodeAnnotation()
            }
            else {
                if let plot = self.graph.allPlots().first as? CPTContourPlot {
                    showColourCodeAnnotation(plot)
                }
            }
        }
    }
    
    // MARK: -
    // MARK: Spinner View
    
    private func showSpinner(_ message: String?) {
//        if self.spinner == nil {
//            self.spinner = SpinnerView(frame: CGRect(x: 0, y: 0, width: 280, height: 280))
//            self.spinner?.translatesAutoresizingMaskIntoConstraints = false
//            if let _spinner = self.spinner {
//                _spinner.translatesAutoresizingMaskIntoConstraints = false
//                view.addSubview(_spinner)
//                _spinner.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
//                _spinner.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
//                _spinner.widthAnchor.constraint(equalToConstant: 280).isActive = true
//                _spinner.heightAnchor.constraint(equalToConstant: 280).isActive = true
//            }
//        }
//        if let _spinner = self.spinner {
//            if let _message = message {
//                _spinner.message = _message
//            }
//            _spinner.isHidden = false
//            view.bringSubviewToFront(_spinner)
//        }
    
       
   //     DispatchQueue.main.async {
//            self.addChild(self.spinner)
//            self.spinner.view.frame = self.view.frame
//            self.view.addSubview(self.spinner.view)
//            self.view.sendSubviewToBack(self.hostingView!)
//            self.spinner.didMove(toParent: self)
//   //     }
    }
    
    
    // MARK: -
    // MARK:  Hull Convex Points methods
    
    
    private func quickHullOnPlotData(plotdata: [DataStructure]?) -> [ConvexHullPoint] {
        var point: ConvexHullPoint
        var convexHullPoints: [ConvexHullPoint] = []
        if var _plotdata = plotdata {
            if _plotdata.count < 2 {
                point = ConvexHullPoint(point: CGPoint(x: _plotdata[0].x, y: _plotdata[0].y), index: 0)
                convexHullPoints.append(point)
                if _plotdata.count == 2 {
                    point = ConvexHullPoint(point: CGPoint(x: _plotdata[1].x, y: _plotdata[1].y), index: 1)
                    convexHullPoints.append(point)
                }
                return convexHullPoints
            }
            else {
                _plotdata.sort(by: { $0.x < $1.x } )
                var pts: [ConvexHullPoint] = []
                for i in 1..<_plotdata.count - 1 {
                    point = ConvexHullPoint(point: CGPoint(x: _plotdata[i].x, y: _plotdata[i].y), index: i)
                    point.point = CGPoint(x: _plotdata[i].x, y: _plotdata[i].y);
                    point.index = i
                    pts.append(point)
                }
                
                // p1 and p2 are outer most points and thus are part of the hull
                let p1: ConvexHullPoint = ConvexHullPoint(point: CGPoint(x: _plotdata[0].x, y: _plotdata[0].y), index: 0)
                // left most point
                convexHullPoints.append(p1)
                let p2: ConvexHullPoint = ConvexHullPoint(point: CGPoint(x: _plotdata[_plotdata.count - 1].x, y: _plotdata[_plotdata.count - 1].y), index: _plotdata.count - 1)
                // right most point
                convexHullPoints.append(p2)

                // points to the right of oriented line from p1 to p2
                var s1: [ConvexHullPoint] = []
                // points to the right of oriented line from p2 to p1
                var s2: [ConvexHullPoint] = []

                // p1 to p2 line
                let lineVec1 = CGPoint(x: p2.point.x - p1.point.x, y: p2.point.y - p1.point.y)
                var pVec1: CGPoint
                var sign1: CGFloat
                for i in 0..<pts.count {
                    point = pts[i]
                    pVec1 = CGPoint(x: point.point.x - p1.point.x, y: point.point.y - p1.point.y)
                    sign1 = lineVec1.x * pVec1.y - pVec1.x * lineVec1.y // cross product to check on which side of the line point p is.
                    if sign1 > 0  { // right of p1 p2 line (in a normal xy coordinate system this would be < 0 but due to the weird iPhone screen coordinates this is > 0
                        s1.append(point)
                    }
                    else { // right of p2 p1 line
                        s2.append(point)
                    }
                }
                // find new hull points
                findHull(points: s1, p1: p1, p2: p2, convexHullPoints: &convexHullPoints)
                findHull(points: s2, p1: p2, p2: p1, convexHullPoints: &convexHullPoints)
            }
        }
        return convexHullPoints
    }

    
    private func findHull(points: [ConvexHullPoint], p1: ConvexHullPoint, p2: ConvexHullPoint, convexHullPoints: inout [ConvexHullPoint]) -> Void {
        
        // if set of points is empty there are no points to the right of this line so this line is part of the hull.
        if points.isEmpty {
            return
        }
        
        var pts = points
        if var maxPoint: ConvexHullPoint = pts.first {
            var maxDist: CGFloat = -1
            for p in pts { // for every point check the distance from our line
                let dist = distance(from: p, to: (p1, p2))
                if dist > maxDist { // if distance is larger than current maxDist remember new point p
                    maxDist = dist
                    maxPoint = p
                }
            }
            // insert point with max distance from line in the convexHull after p1
            if let index = convexHullPoints.firstIndex(of: p1) {
                convexHullPoints.insert(maxPoint, at: index + 1)
            }
            // remove maxPoint from points array as we are going to split this array in points left and right of the line
            if let index = pts.firstIndex(of: maxPoint) {
                pts.remove(at: index)
            }
            
            // points to the right of oriented line from p1 to p2
            var s1 = [ConvexHullPoint]()

            // points to the right of oriented line from p2 to p1
            var s2 = [ConvexHullPoint]()

            // p1 to maxPoint line
            let lineVec1 = CGPoint(x: maxPoint.point.x - p1.point.x, y: maxPoint.point.y - p1.point.y)
            // maxPoint to p2 line
            let lineVec2 = CGPoint(x: p2.point.x - maxPoint.point.x, y: p2.point.y - maxPoint.point.y)

            for p in pts { // per point check if point is to right or left of p1 to p2 line
                let pVec1 = CGPoint(x: p.point.x - p1.point.x, y: p.point.y - p1.point.y)
                let sign1 = lineVec1.x * pVec1.y - pVec1.x * lineVec1.y // cross product to check on which side of the line point p is.
                let pVec2 = CGPoint(x: p.point.x - maxPoint.point.x, y: p.point.y - maxPoint.point.y) // vector from p2 to p
                let sign2 = lineVec2.x * pVec2.y - pVec2.x * lineVec2.y // sign to check is p is to the right or left of lineVec2

                if sign1 > 0 { // right of p1 p2 line (in a normal xy coordinate system this would be < 0 but due to the weird iPhone screen coordinates this is > 0
                    s1.append(p)
                }
                else if sign2 > 0 { // right of p2 p1 line
                    s2.append(p)
                }
            }
            
            // find new hull points
            findHull(points: s1, p1: p1, p2: maxPoint, convexHullPoints: &convexHullPoints)
            findHull(points: s2, p1: maxPoint, p2: p2, convexHullPoints: &convexHullPoints)
        }
    }
    
    private func distance(from p: ConvexHullPoint, to line: (ConvexHullPoint, ConvexHullPoint)) -> CGFloat {
      // If line.0 and line.1 are the same point, they don't define a line (and, besides,
      // would cause division by zero in the distance formula). Return the distance between
      // line.0 and point p instead.
        if __CGPointEqualToPoint(line.0.point, line.1.point) {
            return sqrt(pow(p.point.x - line.0.point.x, 2) + pow(p.point.y - line.0.point.y, 2))
      }

      // from Deza, Michel Marie; Deza, Elena (2013), Encyclopedia of Distances (2nd ed.), Springer, p. 86, ISBN 9783642309588
        return abs((line.1.point.y - line.0.point.y) * p.point.x
        - (line.1.point.x - line.0.point.x) * p.point.y
        + line.1.point.x * line.0.point.y
        - line.1.point.y * line.0.point.x)
        / sqrt(pow(line.1.point.y - line.0.point.y, 2) + pow(line.1.point.x - line.0.point.x, 2))
    }

    
    private let data = [DataStructure(x: 57.333333, y: 206.207746, z: 0.0),
                                   DataStructure(x: 75.250000, y: 206.207746, z: 0.0),
                                   DataStructure(x: 93.166667, y: 206.207746, z: 0.0),
                                   DataStructure(x: 111.083333, y: 206.207746, z: 0.0),
                                   DataStructure(x: 129.000000, y: 206.207746, z: 0.0),
                                   DataStructure(x: 146.916667, y: 206.207746, z: 0.0),
                                   DataStructure(x: 164.833333, y: 206.207746, z: 0.0),
                                   DataStructure(x: 182.750000, y: 206.207746, z: 0.0),
                                   DataStructure(x: 200.666667, y: 206.207746, z: 0.0),
                                   DataStructure(x: 218.583333, y: 206.207746, z: 0.0),
                                   DataStructure(x: 236.500000, y: 206.207746, z: 0.0),
                                   DataStructure(x: 254.416667, y: 206.207746, z: 0.0),
                                   DataStructure(x: 272.333333, y: 206.207746, z: 0.0),
                                   DataStructure(x: 290.250000, y: 206.207746, z: 0.0),
                                   DataStructure(x: 57.333333, y: 223.444762, z: 0.0),
                                   DataStructure(x: 75.250000, y: 223.444762, z: 0.0),
                                   DataStructure(x: 93.166667, y: 223.444762, z: 0.0),
                                   DataStructure(x: 111.083333, y: 223.444762, z: 0.0),
                                   DataStructure(x: 129.000000, y: 223.444762, z: 0.0),
                                   DataStructure(x: 146.916667, y: 223.444762, z: 0.0),
                                   DataStructure(x: 164.833333, y: 223.444762, z: 0.0),
                                   DataStructure(x: 182.750000, y: 223.444762, z: 0.0),
                                   DataStructure(x: 200.666667, y: 223.444762, z: 0.0),
                                   DataStructure(x: 218.583333, y: 223.444762, z: 0.0),
                                   DataStructure(x: 236.500000, y: 223.444762, z: 0.0),
                                   DataStructure(x: 254.416667, y: 223.444762, z: 0.0),
                                   DataStructure(x: 272.333333, y: 223.444762, z: 0.0),
                                   DataStructure(x: 290.250000, y: 223.444762, z: 0.0),
                                   DataStructure(x: 57.333333, y: 240.681778, z: 0.0),
                                   DataStructure(x: 75.250000, y: 240.681778, z: 0.0),
                                   DataStructure(x: 93.166667, y: 240.681778, z: 0.0),
                                   DataStructure(x: 111.083333, y: 240.681778, z: 0.0),
                                   DataStructure(x: 129.000000, y: 240.681778, z: 0.0),
                                   DataStructure(x: 146.916667, y: 240.681778, z: 0.0),
                                   DataStructure(x: 164.833333, y: 240.681778, z: 0.0),
                                   DataStructure(x: 182.750000, y: 240.681778, z: 0.0),
                                   DataStructure(x: 200.666667, y: 240.681778, z: 0.0),
                                   DataStructure(x: 218.583333, y: 240.681778, z: 0.0),
                                   DataStructure(x: 236.500000, y: 240.681778, z: 0.0),
                                   DataStructure(x: 254.416667, y: 240.681778, z: 0.0),
                                   DataStructure(x: 272.333333, y: 240.681778, z: 0.0),
                                   DataStructure(x: 290.250000, y: 240.681778, z: 0.0),
                                   DataStructure(x: 57.333333, y: 257.918794, z: 0.0),
                                   DataStructure(x: 75.250000, y: 257.918794, z: 0.0),
                                   DataStructure(x: 93.166667, y: 257.918794, z: 0.0),
                                   DataStructure(x: 111.083333, y: 257.918794, z: 0.0),
                                   DataStructure(x: 129.000000, y: 257.918794, z: 0.0),
                                   DataStructure(x: 146.916667, y: 257.918794, z: 0.0),
                                   DataStructure(x: 164.833333, y: 257.918794, z: 0.0),
                                   DataStructure(x: 182.750000, y: 257.918794, z: 0.0),
                                   DataStructure(x: 200.666667, y: 257.918794, z: 0.0),
                                   DataStructure(x: 218.583333, y: 257.918794, z: 0.0),
                                   DataStructure(x: 236.500000, y: 257.918794, z: 0.0),
                                   DataStructure(x: 254.416667, y: 257.918794, z: 0.0),
                                   DataStructure(x: 272.333333, y: 257.918794, z: 0.0),
                                   DataStructure(x: 290.250000, y: 257.918794, z: 0.0),
                                   DataStructure(x: 308.166667, y: 257.918794, z: 0.0),
                                   DataStructure(x: 57.333333, y: 275.155810, z: 0.0),
                                   DataStructure(x: 75.250000, y: 275.155810, z: 0.0),
                                   DataStructure(x: 93.166667, y: 275.155810, z: 0.0),
                                   DataStructure(x: 111.083333, y: 275.155810, z: 0.0),
                                   DataStructure(x: 129.000000, y: 275.155810, z: 0.0),
                                   DataStructure(x: 146.916667, y: 275.155810, z: 0.0),
                                   DataStructure(x: 164.833333, y: 275.155810, z: 0.0),
                                   DataStructure(x: 182.750000, y: 275.155810, z: 0.0),
                                   DataStructure(x: 200.666667, y: 275.155810, z: 0.0),
                                   DataStructure(x: 218.583333, y: 275.155810, z: 0.0),
                                   DataStructure(x: 236.500000, y: 275.155810, z: 0.0),
                                   DataStructure(x: 254.416667, y: 275.155810, z: 0.0),
                                   DataStructure(x: 272.333333, y: 275.155810, z: 0.0),
                                   DataStructure(x: 290.250000, y: 275.155810, z: 0.0),
                                   DataStructure(x: 308.166667, y: 275.155810, z: 0.0),
                                   DataStructure(x: 57.333333, y: 292.392826, z: 0.0),
                                   DataStructure(x: 75.250000, y: 292.392826, z: 0.0),
                                   DataStructure(x: 93.166667, y: 292.392826, z: 0.0),
                                   DataStructure(x: 111.083333, y: 292.392826, z: 0.0),
                                   DataStructure(x: 129.000000, y: 292.392826, z: 0.0),
                                   DataStructure(x: 146.916667, y: 292.392826, z: 0.0),
                                   DataStructure(x: 164.833333, y: 292.392826, z: 0.0),
                                   DataStructure(x: 182.750000, y: 292.392826, z: 0.0),
                                   DataStructure(x: 200.666667, y: 292.392826, z: 0.0),
                                   DataStructure(x: 218.583333, y: 292.392826, z: 0.0),
                                   DataStructure(x: 236.500000, y: 292.392826, z: 0.0),
                                   DataStructure(x: 254.416667, y: 292.392826, z: 0.0),
                                   DataStructure(x: 272.333333, y: 292.392826, z: 0.0),
                                   DataStructure(x: 290.250000, y: 292.392826, z: 0.0),
                                   DataStructure(x: 308.166667, y: 292.392826, z: 0.0),
                                   DataStructure(x: 57.333333, y: 309.629842, z: 0.0),
                                   DataStructure(x: 75.250000, y: 309.629842, z: 0.0),
                                   DataStructure(x: 93.166667, y: 309.629842, z: 0.0),
                                   DataStructure(x: 111.083333, y: 309.629842, z: 0.0),
                                   DataStructure(x: 129.000000, y: 309.629842, z: 0.0),
                                   DataStructure(x: 146.916667, y: 309.629842, z: 0.0),
                                   DataStructure(x: 164.833333, y: 309.629842, z: 0.0),
                                   DataStructure(x: 182.750000, y: 309.629842, z: 0.0),
                                   DataStructure(x: 200.666667, y: 309.629842, z: 0.0),
                                   DataStructure(x: 218.583333, y: 309.629842, z: 0.0),
                                   DataStructure(x: 236.500000, y: 309.629842, z: 0.0),
                                   DataStructure(x: 254.416667, y: 309.629842, z: 0.0),
                                   DataStructure(x: 272.333333, y: 309.629842, z: 0.0),
                                   DataStructure(x: 290.250000, y: 309.629842, z: 0.0),
                                   DataStructure(x: 308.166667, y: 309.629842, z: 0.0),
                                   DataStructure(x: 57.333333, y: 326.866857, z: 0.0),
                                   DataStructure(x: 75.250000, y: 326.866857, z: 0.0),
                                   DataStructure(x: 93.166667, y: 326.866857, z: 0.0),
                                   DataStructure(x: 111.083333, y: 326.866857, z: 0.0),
                                   DataStructure(x: 129.000000, y: 326.866857, z: 0.0),
                                   DataStructure(x: 146.916667, y: 326.866857, z: 0.0),
                                   DataStructure(x: 164.833333, y: 326.866857, z: 0.0),
                                   DataStructure(x: 182.750000, y: 326.866857, z: 0.0),
                                   DataStructure(x: 200.666667, y: 326.866857, z: 0.0),
                                   DataStructure(x: 218.583333, y: 326.866857, z: 0.0),
                                   DataStructure(x: 236.500000, y: 326.866857, z: 0.0),
                                   DataStructure(x: 254.416667, y: 326.866857, z: 0.0),
                                   DataStructure(x: 272.333333, y: 326.866857, z: 0.0),
                                   DataStructure(x: 290.250000, y: 326.866857, z: 0.0),
                                   DataStructure(x: 308.166667, y: 326.866857, z: 0.0),
                                   DataStructure(x: 57.333333, y: 344.103873, z: 0.0),
                                   DataStructure(x: 75.250000, y: 344.103873, z: 0.0),
                                   DataStructure(x: 93.166667, y: 344.103873, z: 0.0),
                                   DataStructure(x: 111.083333, y: 344.103873, z: 0.0),
                                   DataStructure(x: 129.000000, y: 344.103873, z: 0.0),
                                   DataStructure(x: 146.916667, y: 344.103873, z: 0.0),
                                   DataStructure(x: 164.833333, y: 344.103873, z: 0.0),
                                   DataStructure(x: 182.750000, y: 344.103873, z: 0.0),
                                   DataStructure(x: 200.666667, y: 344.103873, z: 0.0),
                                   DataStructure(x: 218.583333, y: 344.103873, z: 0.0),
                                   DataStructure(x: 236.500000, y: 344.103873, z: 0.0),
                                   DataStructure(x: 254.416667, y: 344.103873, z: 0.0),
                                   DataStructure(x: 290.250000, y: 344.103873, z: 0.0),
                                   DataStructure(x: 308.166667, y: 344.103873, z: 0.0),
                                   DataStructure(x: 57.333333, y: 361.340889, z: 0.0),
                                   DataStructure(x: 75.250000, y: 361.340889, z: 0.0),
                                   DataStructure(x: 93.166667, y: 361.340889, z: 0.0),
                                   DataStructure(x: 111.083333, y: 361.340889, z: 0.0),
                                   DataStructure(x: 129.000000, y: 361.340889, z: 0.0),
                                   DataStructure(x: 146.916667, y: 361.340889, z: 0.0),
                                   DataStructure(x: 164.833333, y: 361.340889, z: 0.0),
                                   DataStructure(x: 182.750000, y: 361.340889, z: 0.0),
                                   DataStructure(x: 200.666667, y: 361.340889, z: 0.0),
                                   DataStructure(x: 218.583333, y: 361.340889, z: 0.0),
                                   DataStructure(x: 236.500000, y: 361.340889, z: 0.0),
                                   DataStructure(x: 254.416667, y: 361.340889, z: 0.0),
                                   DataStructure(x: 272.333333, y: 361.340889, z: 0.0),
                                   DataStructure(x: 290.250000, y: 361.340889, z: 0.0),
                                   DataStructure(x: 308.166667, y: 361.340889, z: 0.0),
                                   DataStructure(x: 57.333333, y: 378.577905, z: 0.0),
                                   DataStructure(x: 75.250000, y: 378.577905, z: 0.0),
                                   DataStructure(x: 93.166667, y: 378.577905, z: 0.0),
                                   DataStructure(x: 111.083333, y: 378.577905, z: 0.0),
                                   DataStructure(x: 129.000000, y: 378.577905, z: 0.0),
                                   DataStructure(x: 146.916667, y: 378.577905, z: 0.0),
                                   DataStructure(x: 164.833333, y: 378.577905, z: 0.0),
                                   DataStructure(x: 182.750000, y: 378.577905, z: 0.0),
                                   DataStructure(x: 200.666667, y: 378.577905, z: 0.0),
                                   DataStructure(x: 218.583333, y: 378.577905, z: 0.0),
                                   DataStructure(x: 236.500000, y: 378.577905, z: 0.0),
                                   DataStructure(x: 254.416667, y: 378.577905, z: 0.0),
                                   DataStructure(x: 272.333333, y: 378.577905, z: 0.0),
                                   DataStructure(x: 290.250000, y: 378.577905, z: 0.0),
                                   DataStructure(x: 308.166667, y: 378.577905, z: 0.0),
                                   DataStructure(x: 326.083333, y: 378.577905, z: 0.0),
                                   DataStructure(x: 57.333333, y: 395.814921, z: 0.0),
                                   DataStructure(x: 75.250000, y: 395.814921, z: 0.0),
                                   DataStructure(x: 93.166667, y: 395.814921, z: 0.0),
                                   DataStructure(x: 111.083333, y: 395.814921, z: 0.0),
                                   DataStructure(x: 129.000000, y: 395.814921, z: 0.0),
                                   DataStructure(x: 146.916667, y: 395.814921, z: 0.0),
                                   DataStructure(x: 164.833333, y: 395.814921, z: 0.0),
                                   DataStructure(x: 182.750000, y: 395.814921, z: 0.0),
                                   DataStructure(x: 200.666667, y: 395.814921, z: 0.0),
                                   DataStructure(x: 218.583333, y: 395.814921, z: 0.0),
                                   DataStructure(x: 236.500000, y: 395.814921, z: 0.0),
                                   DataStructure(x: 254.416667, y: 395.814921, z: 0.0),
                                   DataStructure(x: 272.333333, y: 395.814921, z: 0.0),
                                   DataStructure(x: 290.250000, y: 395.814921, z: 0.0),
                                   DataStructure(x: 308.166667, y: 395.814921, z: 0.0),
                                   DataStructure(x: 326.083333, y: 395.814921, z: 0.0),
                                   DataStructure(x: 344.000000, y: 395.814921, z: 0.0),
                                   DataStructure(x: 57.333333, y: 413.051937, z: 0.0),
                                   DataStructure(x: 75.250000, y: 413.051937, z: 0.0),
                                   DataStructure(x: 93.166667, y: 413.051937, z: 0.0),
                                   DataStructure(x: 111.083333, y: 413.051937, z: 0.0),
                                   DataStructure(x: 129.000000, y: 413.051937, z: 0.0),
                                   DataStructure(x: 146.916667, y: 413.051937, z: 0.0),
                                   DataStructure(x: 164.833333, y: 413.051937, z: 0.0),
                                   DataStructure(x: 182.750000, y: 413.051937, z: 0.0),
                                   DataStructure(x: 218.583333, y: 413.051937, z: 0.0),
                                   DataStructure(x: 236.500000, y: 413.051937, z: 0.0),
                                   DataStructure(x: 254.416667, y: 413.051937, z: 0.0),
                                   DataStructure(x: 272.333333, y: 413.051937, z: 0.0),
                                   DataStructure(x: 290.250000, y: 413.051937, z: 0.0),
                                   DataStructure(x: 308.166667, y: 413.051937, z: 0.0),
                                   DataStructure(x: 326.083333, y: 413.051937, z: 0.0),
                                   DataStructure(x: 344.000000, y: 413.051937, z: 0.0),
                                   DataStructure(x: 361.916667, y: 413.051937, z: 0.0),
                                   DataStructure(x: 379.833333, y: 413.051937, z: 0.0),
                                   DataStructure(x: 57.333333, y: 430.288952, z: 0.0),
                                   DataStructure(x: 75.250000, y: 430.288952, z: 0.0),
                                   DataStructure(x: 93.166667, y: 430.288952, z: 0.0),
                                   DataStructure(x: 111.083333, y: 430.288952, z: 0.0),
                                   DataStructure(x: 129.000000, y: 430.288952, z: 0.0),
                                   DataStructure(x: 146.916667, y: 430.288952, z: 0.0),
                                   DataStructure(x: 164.833333, y: 430.288952, z: 0.0),
                                   DataStructure(x: 182.750000, y: 430.288952, z: 0.0),
                                   DataStructure(x: 200.666667, y: 430.288952, z: 0.0),
                                   DataStructure(x: 218.583333, y: 430.288952, z: 0.0),
                                   DataStructure(x: 236.500000, y: 430.288952, z: 0.0),
                                   DataStructure(x: 254.416667, y: 430.288952, z: 0.0),
                                   DataStructure(x: 272.333333, y: 430.288952, z: 0.0),
                                   DataStructure(x: 290.250000, y: 430.288952, z: 0.0),
                                   DataStructure(x: 308.166667, y: 430.288952, z: 0.0),
                                   DataStructure(x: 326.083333, y: 430.288952, z: 0.0),
                                   DataStructure(x: 344.000000, y: 430.288952, z: 0.0),
                                   DataStructure(x: 361.916667, y: 430.288952, z: 0.0),
                                   DataStructure(x: 379.833333, y: 430.288952, z: 0.0),
                                   DataStructure(x: 397.750000, y: 430.288952, z: 0.0),
                                   DataStructure(x: 415.666667, y: 430.288952, z: 0.0),
                                   DataStructure(x: 433.583333, y: 430.288952, z: 0.0),
                                   DataStructure(x: 451.500000, y: 430.288952, z: 0.0),
                                   DataStructure(x: 469.416667, y: 430.288952, z: 0.0),
                                   DataStructure(x: 487.333333, y: 430.288952, z: 0.0),
                                   DataStructure(x: 505.250000, y: 430.288952, z: 0.0),
                                   DataStructure(x: 523.166667, y: 430.288952, z: 0.0),
                                   DataStructure(x: 541.083333, y: 430.288952, z: 0.0),
                                   DataStructure(x: 559.000000, y: 430.288952, z: 0.0),
                                   DataStructure(x: 576.916667, y: 430.288952, z: 0.0),
                                   DataStructure(x: 594.833333, y: 430.288952, z: 0.0),
                                   DataStructure(x: 612.750000, y: 430.288952, z: 0.0),
                                   DataStructure(x: 630.666667, y: 430.288952, z: 0.0),
                                   DataStructure(x: 111.083333, y: 447.525968, z: 0.0),
                                   DataStructure(x: 129.000000, y: 447.525968, z: 0.0),
                                   DataStructure(x: 146.916667, y: 447.525968, z: 0.0),
                                   DataStructure(x: 164.833333, y: 447.525968, z: 0.0),
                                   DataStructure(x: 182.750000, y: 447.525968, z: 0.0),
                                   DataStructure(x: 200.666667, y: 447.525968, z: 0.0),
                                   DataStructure(x: 218.583333, y: 447.525968, z: 0.0),
                                   DataStructure(x: 236.500000, y: 447.525968, z: 0.0),
                                   DataStructure(x: 254.416667, y: 447.525968, z: 0.0),
                                   DataStructure(x: 272.333333, y: 447.525968, z: 0.0),
                                   DataStructure(x: 290.250000, y: 447.525968, z: 0.0),
                                   DataStructure(x: 308.166667, y: 447.525968, z: 0.0),
                                   DataStructure(x: 326.083333, y: 447.525968, z: 0.0),
                                   DataStructure(x: 344.000000, y: 447.525968, z: 0.0),
                                   DataStructure(x: 361.916667, y: 447.525968, z: 0.0),
                                   DataStructure(x: 379.833333, y: 447.525968, z: 0.0),
                                   DataStructure(x: 397.750000, y: 447.525968, z: 0.0),
                                   DataStructure(x: 415.666667, y: 447.525968, z: 0.0),
                                   DataStructure(x: 433.583333, y: 447.525968, z: 0.0),
                                   DataStructure(x: 451.500000, y: 447.525968, z: 0.0),
                                   DataStructure(x: 469.416667, y: 447.525968, z: 0.0),
                                   DataStructure(x: 505.250000, y: 447.525968, z: 0.0),
                                   DataStructure(x: 523.166667, y: 447.525968, z: 0.0),
                                   DataStructure(x: 541.083333, y: 447.525968, z: 0.0),
                                   DataStructure(x: 559.000000, y: 447.525968, z: 0.0),
                                   DataStructure(x: 576.916667, y: 447.525968, z: 0.0),
                                   DataStructure(x: 594.833333, y: 447.525968, z: 0.0),
                                   DataStructure(x: 612.750000, y: 447.525968, z: 0.0),
                                   DataStructure(x: 630.666667, y: 447.525968, z: 0.0),
                                   DataStructure(x: 236.500000, y: 464.762984, z: 0.0),
                                   DataStructure(x: 254.416667, y: 464.762984, z: 0.0),
                                   DataStructure(x: 272.333333, y: 464.762984, z: 0.0),
                                   DataStructure(x: 290.250000, y: 464.762984, z: 0.0),
                                   DataStructure(x: 308.166667, y: 464.762984, z: 0.0),
                                   DataStructure(x: 326.083333, y: 464.762984, z: 0.0),
                                   DataStructure(x: 344.000000, y: 464.762984, z: 0.0),
                                   DataStructure(x: 361.916667, y: 464.762984, z: 0.0),
                                   DataStructure(x: 379.833333, y: 464.762984, z: 0.0),
                                   DataStructure(x: 397.750000, y: 464.762984, z: 0.0),
                                   DataStructure(x: 415.666667, y: 464.762984, z: 0.0),
                                   DataStructure(x: 433.583333, y: 464.762984, z: 0.0),
                                   DataStructure(x: 451.500000, y: 464.762984, z: 0.0),
                                   DataStructure(x: 469.416667, y: 464.762984, z: 0.0),
                                   DataStructure(x: 487.333333, y: 464.762984, z: 0.0),
                                   DataStructure(x: 505.250000, y: 464.762984, z: 0.0),
                                   DataStructure(x: 523.166667, y: 464.762984, z: 0.0),
                                   DataStructure(x: 541.083333, y: 464.762984, z: 0.0),
                                   DataStructure(x: 559.000000, y: 464.762984, z: 0.0),
                                   DataStructure(x: 576.916667, y: 464.762984, z: 0.0),
                                   DataStructure(x: 594.833333, y: 464.762984, z: 0.0),
                                   DataStructure(x: 612.750000, y: 464.762984, z: 0.0),
                                   DataStructure(x: 630.666667, y: 464.762984, z: 0.0),
                                   DataStructure(x: 254.416667, y: 482.000000, z: 0.0),
                                   DataStructure(x: 272.333333, y: 482.000000, z: 0.0),
                                   DataStructure(x: 290.250000, y: 482.000000, z: 0.0),
                                   DataStructure(x: 308.166667, y: 482.000000, z: 0.0),
                                   DataStructure(x: 326.083333, y: 482.000000, z: 0.0),
                                   DataStructure(x: 361.916667, y: 482.000000, z: 0.0),
                                   DataStructure(x: 379.833333, y: 482.000000, z: 0.0),
                                   DataStructure(x: 397.750000, y: 482.000000, z: 0.0),
                                   DataStructure(x: 415.666667, y: 482.000000, z: 0.0),
                                   DataStructure(x: 433.583333, y: 482.000000, z: 0.0),
                                   DataStructure(x: 451.500000, y: 482.000000, z: 0.0),
                                   DataStructure(x: 469.416667, y: 482.000000, z: 0.0),
                                   DataStructure(x: 487.333333, y: 482.000000, z: 0.0),
                                   DataStructure(x: 505.250000, y: 482.000000, z: 0.0),
                                   DataStructure(x: 523.166667, y: 482.000000, z: 0.0),
                                   DataStructure(x: 541.083333, y: 482.000000, z: 0.0),
                                   DataStructure(x: 559.000000, y: 482.000000, z: 0.0),
                                   DataStructure(x: 576.916667, y: 482.000000, z: 0.0),
                                   DataStructure(x: 594.833333, y: 482.000000, z: 0.0),
                                   DataStructure(x: 612.750000, y: 482.000000, z: 0.0),
                                   DataStructure(x: 630.666667, y: 482.000000, z: 0.0),
                                   DataStructure(x: 272.333333, y: 499.237016, z: 0.0),
                                   DataStructure(x: 290.250000, y: 499.237016, z: 0.0),
                                   DataStructure(x: 308.166667, y: 499.237016, z: 0.0),
                                   DataStructure(x: 326.083333, y: 499.237016, z: 0.0),
                                   DataStructure(x: 344.000000, y: 499.237016, z: 0.0),
                                   DataStructure(x: 361.916667, y: 499.237016, z: 0.0),
                                   DataStructure(x: 379.833333, y: 499.237016, z: 0.0),
                                   DataStructure(x: 397.750000, y: 499.237016, z: 0.0),
                                   DataStructure(x: 415.666667, y: 499.237016, z: 0.0),
                                   DataStructure(x: 433.583333, y: 499.237016, z: 0.0),
                                   DataStructure(x: 451.500000, y: 499.237016, z: 0.0),
                                   DataStructure(x: 469.416667, y: 499.237016, z: 0.0),
                                   DataStructure(x: 487.333333, y: 499.237016, z: 0.0),
                                   DataStructure(x: 505.250000, y: 499.237016, z: 0.0),
                                   DataStructure(x: 523.166667, y: 499.237016, z: 0.0),
                                   DataStructure(x: 541.083333, y: 499.237016, z: 0.0),
                                   DataStructure(x: 559.000000, y: 499.237016, z: 0.0),
                                   DataStructure(x: 576.916667, y: 499.237016, z: 0.0),
                                   DataStructure(x: 594.833333, y: 499.237016, z: 0.0),
                                   DataStructure(x: 612.750000, y: 499.237016, z: 0.0),
                                   DataStructure(x: 630.666667, y: 499.237016, z: 0.0),
                                   DataStructure(x: 272.333333, y: 516.474032, z: 0.0),
                                   DataStructure(x: 290.250000, y: 516.474032, z: 0.0),
                                   DataStructure(x: 308.166667, y: 516.474032, z: 0.0),
                                   DataStructure(x: 326.083333, y: 516.474032, z: 0.0),
                                   DataStructure(x: 344.000000, y: 516.474032, z: 0.0),
                                   DataStructure(x: 361.916667, y: 516.474032, z: 0.0),
                                   DataStructure(x: 379.833333, y: 516.474032, z: 0.0),
                                   DataStructure(x: 397.750000, y: 516.474032, z: 0.0),
                                   DataStructure(x: 415.666667, y: 516.474032, z: 0.0),
                                   DataStructure(x: 433.583333, y: 516.474032, z: 0.0),
                                   DataStructure(x: 451.500000, y: 516.474032, z: 0.0),
                                   DataStructure(x: 469.416667, y: 516.474032, z: 0.0),
                                   DataStructure(x: 487.333333, y: 516.474032, z: 0.0),
                                   DataStructure(x: 505.250000, y: 516.474032, z: 0.0),
                                   DataStructure(x: 523.166667, y: 516.474032, z: 0.0),
                                   DataStructure(x: 541.083333, y: 516.474032, z: 0.0),
                                   DataStructure(x: 559.000000, y: 516.474032, z: 0.0),
                                   DataStructure(x: 576.916667, y: 516.474032, z: 0.0),
                                   DataStructure(x: 594.833333, y: 516.474032, z: 0.0),
                                   DataStructure(x: 612.750000, y: 516.474032, z: 0.0),
                                   DataStructure(x: 630.666667, y: 516.474032, z: 0.0),
                                   DataStructure(x: 290.250000, y: 533.711048, z: 0.0),
                                   DataStructure(x: 308.166667, y: 533.711048, z: 0.0),
                                   DataStructure(x: 326.083333, y: 533.711048, z: 0.0),
                                   DataStructure(x: 344.000000, y: 533.711048, z: 0.0),
                                   DataStructure(x: 361.916667, y: 533.711048, z: 0.0),
                                   DataStructure(x: 379.833333, y: 533.711048, z: 0.0),
                                   DataStructure(x: 397.750000, y: 533.711048, z: 0.0),
                                   DataStructure(x: 415.666667, y: 533.711048, z: 0.0),
                                   DataStructure(x: 433.583333, y: 533.711048, z: 0.0),
                                   DataStructure(x: 451.500000, y: 533.711048, z: 0.0),
                                   DataStructure(x: 469.416667, y: 533.711048, z: 0.0),
                                   DataStructure(x: 487.333333, y: 533.711048, z: 0.0),
                                   DataStructure(x: 505.250000, y: 533.711048, z: 0.0),
                                   DataStructure(x: 523.166667, y: 533.711048, z: 0.0),
                                   DataStructure(x: 541.083333, y: 533.711048, z: 0.0),
                                   DataStructure(x: 559.000000, y: 533.711048, z: 0.0),
                                   DataStructure(x: 576.916667, y: 533.711048, z: 0.0),
                                   DataStructure(x: 594.833333, y: 533.711048, z: 0.0),
                                   DataStructure(x: 612.750000, y: 533.711048, z: 0.0),
                                   DataStructure(x: 630.666667, y: 533.711048, z: 0.0),
                                   DataStructure(x: 290.250000, y: 550.948063, z: 0.0),
                                   DataStructure(x: 308.166667, y: 550.948063, z: 0.0),
                                   DataStructure(x: 326.083333, y: 550.948063, z: 0.0),
                                   DataStructure(x: 344.000000, y: 550.948063, z: 0.0),
                                   DataStructure(x: 361.916667, y: 550.948063, z: 0.0),
                                   DataStructure(x: 379.833333, y: 550.948063, z: 0.0),
                                   DataStructure(x: 397.750000, y: 550.948063, z: 0.0),
                                   DataStructure(x: 415.666667, y: 550.948063, z: 0.0),
                                   DataStructure(x: 433.583333, y: 550.948063, z: 0.0),
                                   DataStructure(x: 451.500000, y: 550.948063, z: 0.0),
                                   DataStructure(x: 469.416667, y: 550.948063, z: 0.0),
                                   DataStructure(x: 487.333333, y: 550.948063, z: 0.0),
                                   DataStructure(x: 505.250000, y: 550.948063, z: 0.0),
                                   DataStructure(x: 523.166667, y: 550.948063, z: 0.0),
                                   DataStructure(x: 541.083333, y: 550.948063, z: 0.0),
                                   DataStructure(x: 559.000000, y: 550.948063, z: 0.0),
                                   DataStructure(x: 576.916667, y: 550.948063, z: 0.0),
                                   DataStructure(x: 594.833333, y: 550.948063, z: 0.0),
                                   DataStructure(x: 612.750000, y: 550.948063, z: 0.0),
                                   DataStructure(x: 630.666667, y: 550.948063, z: 0.0),
                                   DataStructure(x: 290.250000, y: 568.185079, z: 0.0),
                                   DataStructure(x: 308.166667, y: 568.185079, z: 0.0),
                                   DataStructure(x: 326.083333, y: 568.185079, z: 0.0),
                                   DataStructure(x: 344.000000, y: 568.185079, z: 0.0),
                                   DataStructure(x: 361.916667, y: 568.185079, z: 0.0),
                                   DataStructure(x: 379.833333, y: 568.185079, z: 0.0),
                                   DataStructure(x: 397.750000, y: 568.185079, z: 0.0),
                                   DataStructure(x: 415.666667, y: 568.185079, z: 0.0),
                                   DataStructure(x: 433.583333, y: 568.185079, z: 0.0),
                                   DataStructure(x: 451.500000, y: 568.185079, z: 0.0),
                                   DataStructure(x: 469.416667, y: 568.185079, z: 0.0),
                                   DataStructure(x: 487.333333, y: 568.185079, z: 0.0),
                                   DataStructure(x: 505.250000, y: 568.185079, z: 0.0),
                                   DataStructure(x: 523.166667, y: 568.185079, z: 0.0),
                                   DataStructure(x: 541.083333, y: 568.185079, z: 0.0),
                                   DataStructure(x: 559.000000, y: 568.185079, z: 0.0),
                                   DataStructure(x: 576.916667, y: 568.185079, z: 0.0),
                                   DataStructure(x: 594.833333, y: 568.185079, z: 0.0),
                                   DataStructure(x: 612.750000, y: 568.185079, z: 0.0),
                                   DataStructure(x: 630.666667, y: 568.185079, z: 0.0),
                                   DataStructure(x: 290.250000, y: 585.422095, z: 0.0),
                                   DataStructure(x: 308.166667, y: 585.422095, z: 0.0),
                                   DataStructure(x: 326.083333, y: 585.422095, z: 0.0),
                                   DataStructure(x: 344.000000, y: 585.422095, z: 0.0),
                                   DataStructure(x: 361.916667, y: 585.422095, z: 0.0),
                                   DataStructure(x: 379.833333, y: 585.422095, z: 0.0),
                                   DataStructure(x: 397.750000, y: 585.422095, z: 0.0),
                                   DataStructure(x: 415.666667, y: 585.422095, z: 0.0),
                                   DataStructure(x: 433.583333, y: 585.422095, z: 0.0),
                                   DataStructure(x: 451.500000, y: 585.422095, z: 0.0),
                                   DataStructure(x: 469.416667, y: 585.422095, z: 0.0),
                                   DataStructure(x: 487.333333, y: 585.422095, z: 0.0),
                                   DataStructure(x: 505.250000, y: 585.422095, z: 0.0),
                                   DataStructure(x: 523.166667, y: 585.422095, z: 0.0),
                                   DataStructure(x: 541.083333, y: 585.422095, z: 0.0),
                                   DataStructure(x: 559.000000, y: 585.422095, z: 0.0),
                                   DataStructure(x: 576.916667, y: 585.422095, z: 0.0),
                                   DataStructure(x: 594.833333, y: 585.422095, z: 0.0),
                                   DataStructure(x: 612.750000, y: 585.422095, z: 0.0),
                                   DataStructure(x: 630.666667, y: 585.422095, z: 0.0),
                                   DataStructure(x: 290.250000, y: 602.659111, z: 0.0),
                                   DataStructure(x: 308.166667, y: 602.659111, z: 0.0),
                                   DataStructure(x: 326.083333, y: 602.659111, z: 0.0),
                                   DataStructure(x: 344.000000, y: 602.659111, z: 0.0),
                                   DataStructure(x: 361.916667, y: 602.659111, z: 0.0),
                                   DataStructure(x: 379.833333, y: 602.659111, z: 0.0),
                                   DataStructure(x: 397.750000, y: 602.659111, z: 0.0),
                                   DataStructure(x: 415.666667, y: 602.659111, z: 0.0),
                                   DataStructure(x: 433.583333, y: 602.659111, z: 0.0),
                                   DataStructure(x: 451.500000, y: 602.659111, z: 0.0),
                                   DataStructure(x: 469.416667, y: 602.659111, z: 0.0),
                                   DataStructure(x: 487.333333, y: 602.659111, z: 0.0),
                                   DataStructure(x: 505.250000, y: 602.659111, z: 0.0),
                                   DataStructure(x: 523.166667, y: 602.659111, z: 0.0),
                                   DataStructure(x: 541.083333, y: 602.659111, z: 0.0),
                                   DataStructure(x: 559.000000, y: 602.659111, z: 0.0),
                                   DataStructure(x: 576.916667, y: 602.659111, z: 0.0),
                                   DataStructure(x: 594.833333, y: 602.659111, z: 0.0),
                                   DataStructure(x: 612.750000, y: 602.659111, z: 0.0),
                                   DataStructure(x: 630.666667, y: 602.659111, z: 0.0),
                                   DataStructure(x: 290.250000, y: 619.896127, z: 0.0),
                                   DataStructure(x: 326.083333, y: 619.896127, z: 0.0),
                                   DataStructure(x: 344.000000, y: 619.896127, z: 0.0),
                                   DataStructure(x: 361.916667, y: 619.896127, z: 0.0),
                                   DataStructure(x: 379.833333, y: 619.896127, z: 0.0),
                                   DataStructure(x: 397.750000, y: 619.896127, z: 0.0),
                                   DataStructure(x: 415.666667, y: 619.896127, z: 0.0),
                                   DataStructure(x: 433.583333, y: 619.896127, z: 0.0),
                                   DataStructure(x: 451.500000, y: 619.896127, z: 0.0),
                                   DataStructure(x: 469.416667, y: 619.896127, z: 0.0),
                                   DataStructure(x: 487.333333, y: 619.896127, z: 0.0),
                                   DataStructure(x: 505.250000, y: 619.896127, z: 0.0),
                                   DataStructure(x: 523.166667, y: 619.896127, z: 0.0),
                                   DataStructure(x: 541.083333, y: 619.896127, z: 0.0),
                                   DataStructure(x: 559.000000, y: 619.896127, z: 0.0),
                                   DataStructure(x: 576.916667, y: 619.896127, z: 0.0),
                                   DataStructure(x: 594.833333, y: 619.896127, z: 0.0),
                                   DataStructure(x: 612.750000, y: 619.896127, z: 0.0),
                                   DataStructure(x: 630.666667, y: 619.896127, z: 0.0),
                                   DataStructure(x: 290.250000, y: 637.133143, z: 0.0),
                                   DataStructure(x: 308.166667, y: 637.133143, z: 0.0),
                                   DataStructure(x: 326.083333, y: 637.133143, z: 0.0),
                                   DataStructure(x: 344.000000, y: 637.133143, z: 0.0),
                                   DataStructure(x: 361.916667, y: 637.133143, z: 0.0),
                                   DataStructure(x: 379.833333, y: 637.133143, z: 0.0),
                                   DataStructure(x: 397.750000, y: 637.133143, z: 0.0),
                                   DataStructure(x: 415.666667, y: 637.133143, z: 0.0),
                                   DataStructure(x: 433.583333, y: 637.133143, z: 0.0),
                                   DataStructure(x: 451.500000, y: 637.133143, z: 0.0),
                                   DataStructure(x: 469.416667, y: 637.133143, z: 0.0),
                                   DataStructure(x: 487.333333, y: 637.133143, z: 0.0),
                                   DataStructure(x: 505.250000, y: 637.133143, z: 0.0),
                                   DataStructure(x: 523.166667, y: 637.133143, z: 0.0),
                                   DataStructure(x: 541.083333, y: 637.133143, z: 0.0),
                                   DataStructure(x: 559.000000, y: 637.133143, z: 0.0),
                                   DataStructure(x: 576.916667, y: 637.133143, z: 0.0),
                                   DataStructure(x: 594.833333, y: 637.133143, z: 0.0),
                                   DataStructure(x: 612.750000, y: 637.133143, z: 0.0),
                                   DataStructure(x: 630.666667, y: 637.133143, z: 0.0),
                                   DataStructure(x: 290.250000, y: 654.370158, z: 0.0),
                                   DataStructure(x: 308.166667, y: 654.370158, z: 0.0),
                                   DataStructure(x: 326.083333, y: 654.370158, z: 0.0),
                                   DataStructure(x: 344.000000, y: 654.370158, z: 0.0),
                                   DataStructure(x: 361.916667, y: 654.370158, z: 0.0),
                                   DataStructure(x: 379.833333, y: 654.370158, z: 0.0),
                                   DataStructure(x: 397.750000, y: 654.370158, z: 0.0),
                                   DataStructure(x: 415.666667, y: 654.370158, z: 0.0),
                                   DataStructure(x: 433.583333, y: 654.370158, z: 0.0),
                                   DataStructure(x: 451.500000, y: 654.370158, z: 0.0),
                                   DataStructure(x: 469.416667, y: 654.370158, z: 0.0),
                                   DataStructure(x: 487.333333, y: 654.370158, z: 0.0),
                                   DataStructure(x: 505.250000, y: 654.370158, z: 0.0),
                                   DataStructure(x: 523.166667, y: 654.370158, z: 0.0),
                                   DataStructure(x: 541.083333, y: 654.370158, z: 0.0),
                                   DataStructure(x: 559.000000, y: 654.370158, z: 0.0),
                                   DataStructure(x: 576.916667, y: 654.370158, z: 0.0),
                                   DataStructure(x: 594.833333, y: 654.370158, z: 0.0),
                                   DataStructure(x: 612.750000, y: 654.370158, z: 0.0),
                                   DataStructure(x: 630.666667, y: 654.370158, z: 0.0),
                                   DataStructure(x: 290.250000, y: 671.607174, z: 0.0),
                                   DataStructure(x: 308.166667, y: 671.607174, z: 0.0),
                                   DataStructure(x: 326.083333, y: 671.607174, z: 0.0),
                                   DataStructure(x: 344.000000, y: 671.607174, z: 0.0),
                                   DataStructure(x: 361.916667, y: 671.607174, z: 0.0),
                                   DataStructure(x: 379.833333, y: 671.607174, z: 0.0),
                                   DataStructure(x: 397.750000, y: 671.607174, z: 0.0),
                                   DataStructure(x: 415.666667, y: 671.607174, z: 0.0),
                                   DataStructure(x: 433.583333, y: 671.607174, z: 0.0),
                                   DataStructure(x: 451.500000, y: 671.607174, z: 0.0),
                                   DataStructure(x: 469.416667, y: 671.607174, z: 0.0),
                                   DataStructure(x: 487.333333, y: 671.607174, z: 0.0),
                                   DataStructure(x: 505.250000, y: 671.607174, z: 0.0),
                                   DataStructure(x: 523.166667, y: 671.607174, z: 0.0),
                                   DataStructure(x: 541.083333, y: 671.607174, z: 0.0),
                                   DataStructure(x: 559.000000, y: 671.607174, z: 0.0),
                                   DataStructure(x: 576.916667, y: 671.607174, z: 0.0),
                                   DataStructure(x: 594.833333, y: 671.607174, z: 0.0),
                                   DataStructure(x: 612.750000, y: 671.607174, z: 0.0),
                                   DataStructure(x: 630.666667, y: 671.607174, z: 0.0),
                                   DataStructure(x: 290.250000, y: 688.844190, z: 0.0),
                                   DataStructure(x: 308.166667, y: 688.844190, z: 0.0),
                                   DataStructure(x: 326.083333, y: 688.844190, z: 0.0),
                                   DataStructure(x: 344.000000, y: 688.844190, z: 0.0),
                                   DataStructure(x: 361.916667, y: 688.844190, z: 0.0),
                                   DataStructure(x: 379.833333, y: 688.844190, z: 0.0),
                                   DataStructure(x: 397.750000, y: 688.844190, z: 0.0),
                                   DataStructure(x: 415.666667, y: 688.844190, z: 0.0),
                                   DataStructure(x: 433.583333, y: 688.844190, z: 0.0),
                                   DataStructure(x: 451.500000, y: 688.844190, z: 0.0),
                                   DataStructure(x: 469.416667, y: 688.844190, z: 0.0),
                                   DataStructure(x: 487.333333, y: 688.844190, z: 0.0),
                                   DataStructure(x: 505.250000, y: 688.844190, z: 0.0),
                                   DataStructure(x: 523.166667, y: 688.844190, z: 0.0),
                                   DataStructure(x: 541.083333, y: 688.844190, z: 0.0),
                                   DataStructure(x: 559.000000, y: 688.844190, z: 0.0),
                                   DataStructure(x: 576.916667, y: 688.844190, z: 0.0),
                                   DataStructure(x: 594.833333, y: 688.844190, z: 0.0),
                                   DataStructure(x: 612.750000, y: 688.844190, z: 0.0),
                                   DataStructure(x: 630.666667, y: 688.844190, z: 0.0),
                                   DataStructure(x: 290.250000, y: 706.081206, z: 0.0),
                                   DataStructure(x: 308.166667, y: 706.081206, z: 0.0),
                                   DataStructure(x: 326.083333, y: 706.081206, z: 0.0),
                                   DataStructure(x: 344.000000, y: 706.081206, z: 0.0),
                                   DataStructure(x: 361.916667, y: 706.081206, z: 0.0),
                                   DataStructure(x: 379.833333, y: 706.081206, z: 0.0),
                                   DataStructure(x: 397.750000, y: 706.081206, z: 0.0),
                                   DataStructure(x: 415.666667, y: 706.081206, z: 0.0),
                                   DataStructure(x: 433.583333, y: 706.081206, z: 0.0),
                                   DataStructure(x: 451.500000, y: 706.081206, z: 0.0),
                                   DataStructure(x: 469.416667, y: 706.081206, z: 0.0),
                                   DataStructure(x: 487.333333, y: 706.081206, z: 0.0),
                                   DataStructure(x: 505.250000, y: 706.081206, z: 0.0),
                                   DataStructure(x: 523.166667, y: 706.081206, z: 0.0),
                                   DataStructure(x: 541.083333, y: 706.081206, z: 0.0),
                                   DataStructure(x: 559.000000, y: 706.081206, z: 0.0),
                                   DataStructure(x: 576.916667, y: 706.081206, z: 0.0),
                                   DataStructure(x: 594.833333, y: 706.081206, z: 0.0),
                                   DataStructure(x: 612.750000, y: 706.081206, z: 0.0),
                                   DataStructure(x: 630.666667, y: 706.081206, z: 0.0),
                                   DataStructure(x: 290.250000, y: 723.318222, z: 0.0),
                                   DataStructure(x: 308.166667, y: 723.318222, z: 0.0),
                                   DataStructure(x: 326.083333, y: 723.318222, z: 0.0),
                                   DataStructure(x: 344.000000, y: 723.318222, z: 0.0),
                                   DataStructure(x: 361.916667, y: 723.318222, z: 0.0),
                                   DataStructure(x: 379.833333, y: 723.318222, z: 0.0),
                                   DataStructure(x: 397.750000, y: 723.318222, z: 0.0),
                                   DataStructure(x: 415.666667, y: 723.318222, z: 0.0),
                                   DataStructure(x: 433.583333, y: 723.318222, z: 0.0),
                                   DataStructure(x: 451.500000, y: 723.318222, z: 0.0),
                                   DataStructure(x: 469.416667, y: 723.318222, z: 0.0),
                                   DataStructure(x: 487.333333, y: 723.318222, z: 0.0),
                                   DataStructure(x: 505.250000, y: 723.318222, z: 0.0),
                                   DataStructure(x: 523.166667, y: 723.318222, z: 0.0),
                                   DataStructure(x: 541.083333, y: 723.318222, z: 0.0),
                                   DataStructure(x: 559.000000, y: 723.318222, z: 0.0),
                                   DataStructure(x: 576.916667, y: 723.318222, z: 0.0),
                                   DataStructure(x: 594.833333, y: 723.318222, z: 0.0),
                                   DataStructure(x: 612.750000, y: 723.318222, z: 0.0),
                                   DataStructure(x: 630.666667, y: 723.318222, z: 0.0),
                                   DataStructure(x: 290.250000, y: 740.555238, z: 0.0),
                                   DataStructure(x: 308.166667, y: 740.555238, z: 0.0),
                                   DataStructure(x: 326.083333, y: 740.555238, z: 0.0),
                                   DataStructure(x: 344.000000, y: 740.555238, z: 0.0),
                                   DataStructure(x: 361.916667, y: 740.555238, z: 0.0),
                                   DataStructure(x: 379.833333, y: 740.555238, z: 0.0),
                                   DataStructure(x: 397.750000, y: 740.555238, z: 0.0),
                                   DataStructure(x: 415.666667, y: 740.555238, z: 0.0),
                                   DataStructure(x: 433.583333, y: 740.555238, z: 0.0),
                                   DataStructure(x: 451.500000, y: 740.555238, z: 0.0),
                                   DataStructure(x: 469.416667, y: 740.555238, z: 0.0),
                                   DataStructure(x: 487.333333, y: 740.555238, z: 0.0),
                                   DataStructure(x: 505.250000, y: 740.555238, z: 0.0),
                                   DataStructure(x: 523.166667, y: 740.555238, z: 0.0),
                                   DataStructure(x: 541.083333, y: 740.555238, z: 0.0),
                                   DataStructure(x: 559.000000, y: 740.555238, z: 0.0),
                                   DataStructure(x: 576.916667, y: 740.555238, z: 0.0),
                                   DataStructure(x: 594.833333, y: 740.555238, z: 0.0),
                                   DataStructure(x: 612.750000, y: 740.555238, z: 0.0),
                                   DataStructure(x: 630.666667, y: 740.555238, z: 0.0),
                                   DataStructure(x: 290.250000, y: 757.792254, z: 0.0),
                                   DataStructure(x: 308.166667, y: 757.792254, z: 0.0),
                                   DataStructure(x: 326.083333, y: 757.792254, z: 0.0),
                                   DataStructure(x: 344.000000, y: 757.792254, z: 0.0),
                                   DataStructure(x: 361.916667, y: 757.792254, z: 0.0),
                                   DataStructure(x: 379.833333, y: 757.792254, z: 0.0),
                                   DataStructure(x: 397.750000, y: 757.792254, z: 0.0),
                                   DataStructure(x: 415.666667, y: 757.792254, z: 0.0),
                                   DataStructure(x: 433.583333, y: 757.792254, z: 0.0),
                                   DataStructure(x: 451.500000, y: 757.792254, z: 0.0),
                                   DataStructure(x: 469.416667, y: 757.792254, z: 0.0),
                                   DataStructure(x: 487.333333, y: 757.792254, z: 0.0),
                                   DataStructure(x: 505.250000, y: 757.792254, z: 0.0),
                                   DataStructure(x: 523.166667, y: 757.792254, z: 0.0),
                                   DataStructure(x: 541.083333, y: 757.792254, z: 0.0),
                                   DataStructure(x: 559.000000, y: 757.792254, z: 0.0),
                                   DataStructure(x: 576.916667, y: 757.792254, z: 0.0),
                                   DataStructure(x: 594.833333, y: 757.792254, z: 0.0),
                                   DataStructure(x: 612.750000, y: 757.792254, z: 0.0),
                                   DataStructure(x: 630.666667, y: 757.792254, z: 0.0)]
}

extension String {
    
    // MARK: -
    // MARK: Insert Linebreak into a String at X intervals and without breaking a word
    
    func splitWithLineBreaks(byCount n: Int, breakableCharacterSet: CharacterSet = CharacterSet(charactersIn: " ")) -> (outString: String, noLines: Int) {
        
        precondition(n > 0)
        guard !self.isEmpty && self.count > n else { return (self, 1) }

        var string = String(self)
        var startIndex = string.startIndex

        repeat {
            // Break a string into lines.
            var endIndex = string[string.index(after: startIndex)...].firstIndex(of: "\n") ?? string.endIndex
            if self.distance(from: startIndex, to: endIndex) > n {
                let wrappedLine = string[startIndex..<endIndex].split(byCount: n, breakableCharacters: breakableCharacterSet.characters())
                string.replaceSubrange(startIndex..<endIndex, with: wrappedLine)
                endIndex = string.index(startIndex, offsetBy: wrappedLine.count)
            }

            startIndex = endIndex
        } while startIndex < string.endIndex
        let nolines = Array<String>(string.components(separatedBy: "\n")).count
        return (string, nolines)
    }
    
}

extension Substring {
    
    func split(byCount n: Int, breakableCharacters: [Character]) -> String {
        var line = String(self)
        var lineStartIndex = self.startIndex
        
        while line.distance(from: lineStartIndex, to: line.endIndex) > n {
            let maxLineEndIndex = line.index(lineStartIndex, offsetBy: n)

            if breakableCharacters.contains(self[maxLineEndIndex]) {
                // If line terminates at a breakable character, replace that character with a newline
                line.replaceSubrange(maxLineEndIndex...maxLineEndIndex, with: "\n")
                lineStartIndex = line.index(after: maxLineEndIndex)
            } else if let index = line[lineStartIndex..<maxLineEndIndex].lastIndex(where: { breakableCharacters.contains($0) }) {
                // Otherwise, find a breakable character that is between lineStartIndex and maxLineEndIndex
                line.replaceSubrange(index...index, with: "\n")
                lineStartIndex = index
            } else {
                // Finally, forcible break a word
                line.insert("\n", at: maxLineEndIndex)
                lineStartIndex = maxLineEndIndex
            }
        }

        return line
    }
}

extension CharacterSet {
    func characters() -> [Character] {
        // A Unicode scalar is any Unicode code point in the range U+0000 to U+D7FF inclusive or U+E000 to U+10FFFF inclusive.
        return codePoints().compactMap { UnicodeScalar($0) }.map { Character($0) }
    }

    func codePoints() -> [Int] {
        var result: [Int] = []
        var plane = 0
        // following documentation at https://developer.apple.com/documentation/foundation/nscharacterset/1417719-bitmaprepresentation
        for (i, w) in bitmapRepresentation.enumerated() {
            let k = i % 8193
            if k == 8192 {
                // plane index byte
                plane = Int(w) << 13
                continue
            }
            let base = (plane + k) << 3
            for j in 0 ..< 8 where w & 1 << j != 0 {
                result.append(base + j)
            }
        }
        return result
    }
}
