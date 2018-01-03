module MouseHelpers exposing (mouseToGridInPixels)

import GamePlatform exposing (platformSize)
import Coordinates exposing (gameSize, convertMouseCoorToGameCoor, convertToGameUnits, pixelToGridConversion, gridToPixelConversion, calculateCanvasSize)
import Game.TwoD.Camera as Camera exposing (Camera)
import GameTypes exposing (Vector)


mouseToGridInPixels : Vector -> Camera -> Vector -> Vector
mouseToGridInPixels windowSize camera mousePosition =
    let
        ( width, height ) =
            platformSize

        canvasSize =
            calculateCanvasSize windowSize

        ( windowWidth, _ ) =
            windowSize

        ( canvasWidth, _ ) =
            canvasSize

        xOffset =
            (windowWidth - canvasWidth) / 2

        newPosition =
            mousePosition
                |> (\( x, y ) -> ( x - xOffset, y ))
                |> convertToGameUnits canvasSize
                |> convertMouseCoorToGameCoor camera
                |> (\( x, y ) -> ( x + width / 2, y + height / 2 ))
                |> pixelToGridConversion
                |> gridToPixelConversion
    in
        newPosition
