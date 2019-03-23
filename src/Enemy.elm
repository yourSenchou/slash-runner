module Enemy exposing
    ( Enemy
    , EnemyMovement(..)
    , LineMovementSpec
    )

import Color
import Game.TwoD.Render as Render exposing (Renderable)
import GameTypes exposing (IntVector, Vector, vectorDecoder, vectorIntToFloat)
import Json.Decode exposing (Decoder)
import Json.Decode.Pipeline exposing (hardcoded, required)
import V2


type alias Enemy =
    { startingLocation : Vector
    , timeExisted : Int
    , size : IntVector
    , movement : EnemyMovement
    , directionLeft : Bool
    }


type EnemyMovement
    = NoMovement
    | LinePath LineMovementSpec
    | Walk Vector


type alias LineMovementSpec =
    { startNode : Vector
    , endNode : Vector
    , currentLocation : Vector
    , speed : Float
    }


updateLinePath : Int -> Vector -> LineMovementSpec -> Vector
updateLinePath timeExisted startingLocation linePathSpec =
    let
        { startNode, endNode } =
            linePathSpec

        halfWayPoint =
            V2.sub endNode startNode
                |> V2.divideBy 2

        newLocation =
            halfWayPoint
                |> V2.scale (sin (toFloat timeExisted * 0.017))
                |> V2.add startNode
                |> V2.add halfWayPoint
    in
    newLocation



-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
----------------------------------------------------------------------------
----------------------------------------------------------------------------
----------------------------------------------------------------------------
-------------------------------------------------------------------------
-------------------------------------------------------------------------


renderEnemy : Enemy -> List Renderable
renderEnemy enemy =
    let
        x =
            Tuple.first enemy.startingLocation

        y =
            Tuple.second enemy.startingLocation

        ( location, color ) =
            case enemy.movement of
                NoMovement ->
                    ( enemy.startingLocation, Color.red )

                Walk currentLocation ->
                    ( currentLocation, Color.purple )

                LinePath linePathSpec ->
                    ( linePathSpec.currentLocation, Color.orange )

        enemyRenderable =
            Render.shape
                Render.rectangle
                { color = color
                , position = location
                , size = vectorIntToFloat enemy.size
                }

        linePathNodesRenderable =
            case enemy.movement of
                NoMovement ->
                    []

                Walk currentLocation ->
                    []

                LinePath { startNode, endNode } ->
                    let
                        startNodeRenderable =
                            renderLinePathNode startNode

                        endNodeRenderable =
                            renderLinePathNode endNode
                    in
                    [ startNodeRenderable, endNodeRenderable ]
    in
    List.concat
        [ [ enemyRenderable ]
        , linePathNodesRenderable
        ]


renderLinePathNode : Vector -> Renderable
renderLinePathNode location =
    Render.shape Render.circle
        { color = Color.lightBrown
        , position = location
        , size = ( 16, 16 )
        }


enemyDecoder : Decoder Enemy
enemyDecoder =
    Json.Decode.succeed Enemy
        |> required "location" vectorDecoder
        |> hardcoded 0
        |> hardcoded ( 64, 64 )
        |> required "movement" movementDecoder
        |> hardcoded True


movementDecoder : Decoder EnemyMovement
movementDecoder =
    Json.Decode.string
        |> Json.Decode.andThen stringToMovementType


stringToMovementType : String -> Decoder EnemyMovement
stringToMovementType movement =
    case movement of
        "NoMovement" ->
            Json.Decode.succeed NoMovement

        "Walk" ->
            Json.Decode.map Walk vectorDecoder

        "LinePath" ->
            Json.Decode.map LinePath decodeLinePathMovementSpec

        _ ->
            Json.Decode.succeed NoMovement


decodeLinePathMovementSpec : Decoder LineMovementSpec
decodeLinePathMovementSpec =
    Json.Decode.succeed LineMovementSpec
        |> required "startNode" vectorDecoder
        |> required "endNode" vectorDecoder
        |> required "startingLocation" vectorDecoder
        |> required "speed" Json.Decode.float
