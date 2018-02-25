module CollisionHelpers
    exposing
        ( getCollidingTiles
        , calculatePlayerAttributesFromCollision
        )

import Dict exposing (Dict)
import GamePlatform exposing (Platform)
import Coordinates exposing (pixelToGridConversion, gridToPixelConversion, gridSquareSize)
import Vector2 as V2 exposing (getX, getY)
import GameTypes
    exposing
        ( Vector
        , IntVector
        , Player
        , PlayerState
            ( OnTheGround
            , Jumping
            , SlidingOnWall
            )
        , vectorFloatToInt
        , vectorIntToFloat
        , intVectorAdd
        )


getCollidingTiles : Vector -> IntVector -> Dict IntVector Platform -> List IntVector
getCollidingTiles playerLocation playerSize platforms =
    let
        ( playerX, playerY ) =
            playerLocation

        ( playerWidth, playerHeight ) =
            playerSize

        playerLeftSide =
            floor playerX

        playerRightSide =
            ceiling (playerX + toFloat playerWidth - 1)

        playerBottom =
            floor playerY

        playerTop =
            ceiling (playerY + toFloat playerHeight - 1)

        playerTopLeft =
            ( playerLeftSide, playerTop )

        playerTopRight =
            ( playerRightSide, playerTop )

        playerBottomLeft =
            ( playerLeftSide, playerBottom )

        playerBottomRight =
            ( playerRightSide, playerBottom )

        topLeftTileCoord =
            playerTopLeft
                |> vectorIntToFloat
                |> pixelToGridConversion
                |> gridToPixelConversion
                |> vectorFloatToInt

        topRightTileCoord =
            playerTopRight
                |> vectorIntToFloat
                |> pixelToGridConversion
                |> gridToPixelConversion
                |> vectorFloatToInt

        bottomLeftTileCoord =
            playerBottomLeft
                |> vectorIntToFloat
                |> pixelToGridConversion
                |> gridToPixelConversion
                |> vectorFloatToInt

        bottomRightTileCoord =
            playerBottomRight
                |> vectorIntToFloat
                |> pixelToGridConversion
                |> gridToPixelConversion
                |> vectorFloatToInt
    in
        [ topLeftTileCoord, topRightTileCoord, bottomLeftTileCoord, bottomRightTileCoord ]


calculatePlayerAttributesFromCollision : Float -> Float -> Vector -> Vector -> PlayerState -> IntVector -> List IntVector -> Dict IntVector Platform -> ( Vector, Vector, PlayerState )
calculatePlayerAttributesFromCollision groundFriction wallFriction location velocity playerState playerSize gridCoordinates platforms =
    ------------ This function is craaaaazy looking だが this will get cleaned up when friction is desided apon--------------
    case gridCoordinates of
        [] ->
            ( location, velocity, playerState )

        gridCoordinate :: rest ->
            case Dict.get gridCoordinate platforms of
                Nothing ->
                    calculatePlayerAttributesFromCollision groundFriction wallFriction location velocity playerState playerSize rest platforms

                Just _ ->
                    let
                        ( locationDisplacement, velocityDisplacement, newPlayerState ) =
                            getCollisionDisplacementVector groundFriction wallFriction playerState location playerSize gridCoordinate ( 64, 64 ) platforms

                        newLocation =
                            V2.add location locationDisplacement

                        ( velocityX, velocityY ) =
                            velocity

                        newVelocity =
                            ( velocityX * getX velocityDisplacement, velocityY * getY velocityDisplacement )
                    in
                        calculatePlayerAttributesFromCollision groundFriction wallFriction newLocation newVelocity newPlayerState playerSize rest platforms


getCollisionDisplacementVector : Float -> Float -> PlayerState -> Vector -> IntVector -> IntVector -> IntVector -> Dict IntVector Platform -> ( Vector, Vector, PlayerState )
getCollisionDisplacementVector groundFriction wallFriction playerState boxOneXY boxOneWH boxTwoXY boxTwoWH platforms =
    let
        ( boxOneHalfWidth, boxOneHalfHeight ) =
            V2.divideBy 2 (vectorIntToFloat boxOneWH)

        ( boxTwoHalfWidth, boxTwoHalfHeight ) =
            V2.divideBy 2 (vectorIntToFloat boxTwoWH)

        verticalDistanceBetweenCenters =
            abs (getY boxOneXY - toFloat (getY boxTwoXY))

        minnimumVerticalDistanceBetweenCenters =
            (boxOneHalfHeight + boxTwoHalfHeight)

        horizontalDistanceBetweenCenters =
            abs (getX boxOneXY - toFloat (getX boxTwoXY))

        minnimumHorizontalDistanceBetweenCenters =
            (boxOneHalfWidth + boxTwoHalfWidth)

        boxOneIsAboveBoxTwo =
            getY boxOneXY > toFloat (getY boxTwoXY)

        amountOverlappingVertically =
            max (minnimumVerticalDistanceBetweenCenters - verticalDistanceBetweenCenters) 0

        boxOneIsRightOfBoxTwo =
            getX boxOneXY > toFloat (getX boxTwoXY)

        amountOverlappingHorizontally =
            max (minnimumHorizontalDistanceBetweenCenters - horizontalDistanceBetweenCenters) 0

        noDisplacement =
            ( ( 0, 0 ), ( 1, 1 ), playerState )

        noFriction =
            1

        fullStop =
            0
    in
        case amountOverlappingVertically <= amountOverlappingHorizontally of
            True ->
                case boxOneIsAboveBoxTwo of
                    True ->
                        case canDisplaceUp boxTwoXY platforms of
                            True ->
                                ( ( 0, amountOverlappingVertically ), ( groundFriction, fullStop ), OnTheGround )

                            False ->
                                noDisplacement

                    False ->
                        case canDisplaceDown boxTwoXY platforms of
                            True ->
                                ( ( 0, -amountOverlappingVertically ), ( noFriction, fullStop ), playerState )

                            False ->
                                noDisplacement

            False ->
                case boxOneIsRightOfBoxTwo of
                    True ->
                        case canDisplaceRight boxTwoXY platforms of
                            True ->
                                ( ( amountOverlappingHorizontally, 0 ), ( fullStop, wallFriction ), SlidingOnWall )

                            False ->
                                noDisplacement

                    False ->
                        case canDisplaceLeft boxTwoXY platforms of
                            True ->
                                ( ( -amountOverlappingHorizontally, 0 ), ( fullStop, wallFriction ), SlidingOnWall )

                            False ->
                                noDisplacement


canDisplaceLeft : IntVector -> Dict IntVector Platform -> Bool
canDisplaceLeft platformLocation platforms =
    let
        ( width, height ) =
            gridSquareSize

        leftNeighbor =
            intVectorAdd platformLocation ( -width, 0 )
    in
        not (Dict.member leftNeighbor platforms)


canDisplaceRight : IntVector -> Dict IntVector Platform -> Bool
canDisplaceRight platformLocation platforms =
    let
        ( width, height ) =
            gridSquareSize

        rightNeighbor =
            intVectorAdd platformLocation ( width, 0 )
    in
        not (Dict.member rightNeighbor platforms)


canDisplaceUp : IntVector -> Dict IntVector Platform -> Bool
canDisplaceUp platformLocation platforms =
    let
        ( width, height ) =
            gridSquareSize

        aboveNeighbor =
            intVectorAdd platformLocation ( 0, height )
    in
        not (Dict.member aboveNeighbor platforms)


canDisplaceDown : IntVector -> Dict IntVector Platform -> Bool
canDisplaceDown platformLocation platforms =
    let
        ( width, height ) =
            gridSquareSize

        belowNeighbor =
            intVectorAdd platformLocation ( 0, -height )
    in
        not (Dict.member belowNeighbor platforms)
