//
//  _CPTContourEnumerations.h
//  CorePlot
//
//  Created by Steve Wainwright on 13/05/2022.
//

#ifndef _CPTContourEnumerations_h
#define _CPTContourEnumerations_h

/**
 *  @brief Enumeration of contour  border dimension & direction
 **/
typedef NS_ENUM (int, CPTContourBorderDimensionDirection) {
    CPTContourBorderDimensionDirectionXForward     = 0,   ///< contour border dimension & direction along x and small to large dimension
    CPTContourBorderDimensionDirectionYForward     = 1,   ///< contour border dimension & direction along y and small to large dimension
    CPTContourBorderDimensionDirectionXBackward    = 2,   ///< contour border dimension & direction along x and large to small dimension
    CPTContourBorderDimensionDirectionYBackward    = 3,    ///< contour border dimension & direction along y and large to small dimension
    CPTContourBorderDimensionDirectionNone         = 4
};

/**
 *  @brief Enumeration of contour  border dimension & direction
 **/
typedef NS_ENUM (int, CPTContourIntersectionOrdering) {
    CPTContourIntersectionOrderingDistances       = 0,   ///< contour intersection ordering by distance from reference point
    CPTContourIntersectionOrderingDistancesAngles = 1,   ///< contour  intersection ordering by distance then angle from reference point
    CPTContourIntersectionOrderingAngles          = 2    ///< contour intersection ordering by distance then angle
};

/**
 *  @brief Enumeration of contour  polygon status
 **/
typedef NS_ENUM (int, CPTContourPolygonStatus) {
    CPTContourPolygonStatusNotCreated = 0,   ///< contour polygon was not created
    CPTContourPolygonStatusCreated = 1,   ///< contour polygon was created
    CPTContourPolygonStatusAlreadyExists  = 2    ///< contour polygon was already exists
};

/**
 *  @brief Enumeration of contour inner, outer or both search
 **/
typedef NS_ENUM (int, CPTContourSearchType) {
    CPTContourSearchTypeInner = 0,   ///< contour inner search
    CPTContourSearchTypeOuter = 1,   ///< contour outer search
    CPTContourSearchTypeBoth  = 2    ///< contour search both ways
};

/**
 *  @brief Enumeration of contour inner, outer or both search
 **/
typedef NS_ENUM (int, CPTContourBetweenNodeRotation) {
    CPTContourBetweenNodeRotationNone = 0,   ///< no contour between nodes
    CPTContourBetweenNodeRotationClockwise = 1,   ///<  clockwise contour between nodes
    CPTContourBetweenNodeRotationAnticlockwise = 2    ///<  anticlockwise contour between nodes
};

#endif /* _CPTContourEnumerations_h */
