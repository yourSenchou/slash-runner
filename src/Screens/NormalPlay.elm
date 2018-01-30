module Screens.NormalPlay
    exposing
        ( NormalPlayState
        , initialNormalPlayState
        , renderNormalPlay
        , LevelData
        , createLevel
        , updateNormalPlay
        , jsonToLevelData
        , TempJumpProperties
        )

import Game.TwoD.Render as Render exposing (Renderable)
import Game.TwoD.Camera as Camera exposing (Camera)
import Game.Resources as Resources exposing (Resources)
import Vector2 as V2 exposing (getX, getY)
import GameTypes exposing (Vector, IntVector, Player, vectorFloatToInt)
import Player exposing (renderPlayer)
import Enemy exposing (Enemy)
import GamePlatform exposing (Platform, renderPlatform, platformWithLocationsDecoder)
import Json.Decode exposing (Decoder)
import Json.Decode.Pipeline exposing (decode, required)
import Dict exposing (Dict)
import Coordinates exposing (gameSize, pixelToGridConversion, gridToPixelConversion)
import Color
import Controller
    exposing
        ( ControllerState
        , ButtonState
            ( Pressed
            , Held
            , Released
            , Inactive
            )
        , DPad
            ( Up
            , UpRight
            , Right
            , DownRight
            , Down
            , DownLeft
            , Left
            , UpLeft
            , NoDirection
            )
        )
import CollisionHelpers
    exposing
        ( getCollidingTiles
        , calculateLocationAndVelocityFromCollision
        , getCollisionDisplacementVector
        )


type alias NormalPlayState =
    { player : Player
    , permanentEnemies : List Enemy
    , enemies : List Enemy
    , platforms : Dict IntVector Platform
    , camera : Camera
    , resources : Resources
    }


type alias TempJumpProperties =
    { framesToApex : Float
    , maxJumpHeight : Float
    , minJumpHeight : Float
    }


initialNormalPlayState : NormalPlayState
initialNormalPlayState =
    let
        startingPoint =
            ( -300, 0 )

        ( gameWidth, gameHeight ) =
            gameSize
    in
        { player = Player startingPoint ( 0, 0 ) ( 64, 64 ) 0
        , permanentEnemies = []
        , enemies = []
        , platforms = Dict.empty
        , camera = Camera.fixedWidth gameWidth startingPoint
        , resources = Resources.init
        }


createLevel : LevelData -> NormalPlayState
createLevel levelData =
    let
        startingPoint =
            ( -300, 0 )

        ( gameWidth, gameHeight ) =
            gameSize
    in
        { player = Player startingPoint ( 0, 0 ) ( 64, 64 ) 0
        , platforms = levelData.platforms
        , camera = Camera.fixedWidth gameWidth startingPoint
        , resources = Resources.init
        , permanentEnemies = []
        , enemies = []
        }


type alias LevelData =
    { platforms : Dict IntVector Platform
    }


getPlayerAcceleration : DPad -> Vector
getPlayerAcceleration dPad =
    case dPad of
        Up ->
            ( 0, 0 )

        UpRight ->
            ( 0.3, 0 )

        Right ->
            ( 0.3, 0 )

        DownRight ->
            ( 0.3, 0 )

        Down ->
            ( 0, 0 )

        DownLeft ->
            ( -0.3, 0 )

        Left ->
            ( -0.3, 0 )

        UpLeft ->
            ( -0.3, 0 )

        NoDirection ->
            ( 0, 0 )


capPlayerNegativeYVelocity : Vector -> Vector
capPlayerNegativeYVelocity ( x, y ) =
    ( x, max y -50 )


capPlayerXVelocity : Vector -> Vector
capPlayerXVelocity ( x, y ) =
    ( clamp -50 50 x, y )


calculateYGravityFromJumpProperties : Float -> Float -> Float
calculateYGravityFromJumpProperties maxJumpHeight framesToApex =
    (2 * maxJumpHeight) / (framesToApex * framesToApex)


calculateInitialJumpVelocityFromJumpProperties : Float -> Float -> Float
calculateInitialJumpVelocityFromJumpProperties maxJumpHeight gravity =
    sqrt <| abs (2 * gravity * maxJumpHeight)


calculateEarlyJumpTerminationVelocity : Float -> Float -> Float -> Float -> Float
calculateEarlyJumpTerminationVelocity initialJumpVel gravity maxJumpHeight minJumpHeight =
    sqrt <| abs ((initialJumpVel * initialJumpVel) + (2 * gravity * (maxJumpHeight - minJumpHeight)))


updateNormalPlay : ControllerState -> NormalPlayState -> TempJumpProperties -> NormalPlayState
updateNormalPlay controllerState state tempJumpProperties =
    -- leave this function nice and huge, no need to abstract out to updateplayer, updateenemey or anything
    -- ideally one collision function will take in a player and enemy and return new versions of each
    -- it's ok if Elm code gets long! yay!
    let
        { player, platforms } =
            state

        gravitationalAcceleration =
            calculateYGravityFromJumpProperties tempJumpProperties.maxJumpHeight tempJumpProperties.framesToApex
                |> (\y -> ( 0, -y ))

        initialJumpVelocity =
            calculateInitialJumpVelocityFromJumpProperties tempJumpProperties.maxJumpHeight (getY gravitationalAcceleration)
                |> (\y -> ( getX playerVelocityAfterAcceleration, y ))

        movementAcceleration =
            getPlayerAcceleration controllerState.dPad

        finalPlayerAcceleration =
            List.foldr V2.add
                ( 0, 0 )
                [ gravitationalAcceleration
                , movementAcceleration
                ]

        playerVelocityAfterAcceleration =
            finalPlayerAcceleration
                |> V2.add player.velocity
                |> capPlayerNegativeYVelocity
                |> capPlayerXVelocity

        playerVelocityAfterJump =
            case controllerState.jump of
                Pressed ->
                    initialJumpVelocity

                Held ->
                    playerVelocityAfterAcceleration

                Released ->
                    let
                        earlyJumpTerminationVelocity =
                            calculateEarlyJumpTerminationVelocity (getY initialJumpVelocity) (getY gravitationalAcceleration) tempJumpProperties.maxJumpHeight tempJumpProperties.minJumpHeight
                    in
                        if (getY playerVelocityAfterAcceleration > earlyJumpTerminationVelocity) then
                            ( getX playerVelocityAfterAcceleration, earlyJumpTerminationVelocity )
                        else
                            playerVelocityAfterAcceleration

                Inactive ->
                    playerVelocityAfterAcceleration

        playerLocationAfterMovement =
            V2.add player.location playerVelocityAfterJump

        collidingTileGridCoords =
            getCollidingTiles (vectorFloatToInt playerLocationAfterMovement) playerVelocityAfterJump player.size platforms

        ( playerLocationAfterCollision, playerVelocityAfterCollision ) =
            calculateLocationAndVelocityFromCollision playerLocationAfterMovement playerVelocityAfterJump player.size collidingTileGridCoords platforms

        updatedPlayer =
            { player
                | location = playerLocationAfterCollision
                , velocity = playerVelocityAfterCollision
            }
    in
        { state
            | camera = Camera.follow 0.5 0.17 (V2.sub state.player.location ( -100, -100 )) state.camera
            , player = updatedPlayer
        }


renderNormalPlay : NormalPlayState -> List Renderable
renderNormalPlay state =
    List.concat
        [ (List.map (\( gridCoordinate, platform ) -> renderPlatform Color.grey gridCoordinate) (Dict.toList state.platforms))
        , [ renderPlayer state.resources state.player ]
        ]


jsonToLevelData : Json.Decode.Value -> Result String LevelData
jsonToLevelData levelDataJson =
    Json.Decode.decodeValue levelDataDecoder levelDataJson


levelDataDecoder : Decoder LevelData
levelDataDecoder =
    let
        platforms =
            Json.Decode.list platformWithLocationsDecoder
                |> Json.Decode.map Dict.fromList
    in
        decode LevelData
            |> required "platforms" platforms
