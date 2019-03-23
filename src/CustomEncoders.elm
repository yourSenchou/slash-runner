module CustomEncoders exposing (encodeEnemy, encodeVector, levelDataEncodeHandler)

import Coordinates exposing (pixelToGridConversion)
import Dict exposing (Dict)
import Enemy
    exposing
        ( Enemy
        , EnemyMovement(..)
        )
import GamePlatform
    exposing
        ( Platform
        , PlatformType(..)
        )
import GameTypes exposing (IntVector, Vector)
import Json.Encode


encodeVector : Vector -> Json.Encode.Value
encodeVector location =
    let
        ( x, y ) =
            pixelToGridConversion location
    in
    Json.Encode.object
        [ ( "x", Json.Encode.float x )
        , ( "y", Json.Encode.float y )
        ]


encodeGridCoordinate : IntVector -> Json.Encode.Value
encodeGridCoordinate gridCoordinate =
    let
        ( x, y ) =
            gridCoordinate
    in
    Json.Encode.object
        [ ( "x", Json.Encode.int x )
        , ( "y", Json.Encode.int y )
        ]


levelDataEncodeHandler : Dict IntVector Platform -> List Enemy -> String
levelDataEncodeHandler platforms enemies =
    let
        encodedPlatforms =
            platforms
                |> Dict.toList

        newPlatforms =
            Json.Encode.list (\( gridCoordinate, platform ) -> encodePlatformAndLocation gridCoordinate platform) encodedPlatforms

        encodedEnemies =
            Json.Encode.list (\enemy -> encodeEnemy enemy) enemies

        encodedlevelData =
            Json.Encode.object
                [ ( "platforms", newPlatforms )
                , ( "enemies", encodedEnemies )
                ]
    in
    Json.Encode.encode 4 encodedlevelData


encodePlatformAndLocation : IntVector -> Platform -> Json.Encode.Value
encodePlatformAndLocation location platform =
    Json.Encode.object
        [ ( "location", encodeGridCoordinate location )
        , ( "platform", encodePlatform platform )
        ]


encodePlatform : Platform -> Json.Encode.Value
encodePlatform platform =
    Json.Encode.object
        [ ( "platformType", encodePlatformType platform.platformType )
        ]


encodeEnemy : Enemy -> Json.Encode.Value
encodeEnemy enemy =
    Json.Encode.object
        [ ( "location", encodeVector enemy.startingLocation )
        , ( "movement", encodeMovement enemy.movement )
        ]


encodeMovement : EnemyMovement -> Json.Encode.Value
encodeMovement movement =
    case movement of
        NoMovement ->
            Json.Encode.string "NoMovement"

        Walk currentLocation ->
            Json.Encode.string "Walk"

        LinePath lineMovementSpec ->
            Json.Encode.object
                [ ( "startNode", encodeVector lineMovementSpec.startNode )
                , ( "endNode", encodeVector lineMovementSpec.endNode )
                , ( "speed", Json.Encode.float lineMovementSpec.speed )
                ]


encodePlatformType : PlatformType -> Json.Encode.Value
encodePlatformType platformType =
    case platformType of
        Normal ->
            Json.Encode.string "Normal"

        Dangerous ->
            Json.Encode.string "Dangerous"
