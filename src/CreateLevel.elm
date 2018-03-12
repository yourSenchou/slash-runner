module CreateLevel
    exposing
        ( LevelCreateState
        , initialLevelCreateState
        , updatePlayStateAfterKeyPress
        , updatePlayStateAfterMouseClick
        , renderLevelCreateScreen
        )

import Screens.NormalPlay exposing (NormalPlayState, initialNormalPlayState, renderNormalPlay)
import Game.TwoD.Render as Render exposing (Renderable)
import Game.TwoD.Camera as Camera
import Keyboard.Extra
import GameTypes exposing (Vector, vectorIntToFloat)
import MouseHelpers exposing (mouseToGridInPixels)
import Enemy exposing (Enemy, EnemyMovement(NoMovement, LinePath, Walk), LineMovementSpec)
import CustomEncoders exposing (levelDataEncodeHandler)
import GamePlatform exposing (Platform, platformSize, PlatformType(Normal, Dangerous))
import Color
import Coordinates exposing (gridSquareSize)
import Vector2 as V2
import Dict


type alias LevelCreateState =
    { itemToPlace : ItemToBePlace
    , cursorLocation : Vector
    , cursorActive : Bool
    , locationForCameraToFollow : Vector
    , playState : NormalPlayState
    }


initialLevelCreateState : LevelCreateState
initialLevelCreateState =
    { itemToPlace = PlaceNothing
    , cursorLocation = ( 0, 0 )
    , cursorActive = False
    , playState = initialNormalPlayState
    , locationForCameraToFollow = ( 0, 0 )
    }


type ItemToBePlace
    = PlaceNothing
    | ANormalPlatform
    | ADangerousPlatform
    | AStaticEnemy
    | AnEnemyOnTrack
    | AWalkingEnemy
    | Remove


updatePlayStateAfterKeyPress : Keyboard.Extra.State -> LevelCreateState -> LevelCreateState
updatePlayStateAfterKeyPress keyboardState levelCreateState =
    let
        { itemToPlace, playState } =
            levelCreateState

        pressedKeys =
            Keyboard.Extra.pressedDown keyboardState

        newEnemies =
            if List.member Keyboard.Extra.CharR pressedKeys then
                playState.permanentEnemies
            else if List.member Keyboard.Extra.CharH pressedKeys && List.member Keyboard.Extra.CharG pressedKeys then
                []
            else
                playState.enemies

        newPlatforms =
            if List.member Keyboard.Extra.CharH pressedKeys && List.member Keyboard.Extra.CharG pressedKeys then
                Dict.empty
            else
                playState.platforms

        { player, camera } =
            playState

        ( newPlayer, newCamera ) =
            if List.member Keyboard.Extra.CharR pressedKeys then
                let
                    newPlayer =
                        { player
                            | x = 0
                            , y = 0
                            , vx = 0
                            , vy = 0
                        }

                    newCamera =
                        Camera.moveTo ( 64, 64 ) playState.camera
                in
                    ( newPlayer, newCamera )
            else
                ( playState.player, playState.camera )

        newNormalPlayState =
            { playState
                | enemies = newEnemies
                , platforms = newPlatforms
                , player = newPlayer
                , camera = newCamera
            }

        newItemToPlace =
            if List.member Keyboard.Extra.Number0 pressedKeys then
                PlaceNothing
            else if List.member Keyboard.Extra.Number1 pressedKeys then
                ANormalPlatform
            else if List.member Keyboard.Extra.Number2 pressedKeys then
                AStaticEnemy
            else if List.member Keyboard.Extra.Number3 pressedKeys then
                ADangerousPlatform
            else if List.member Keyboard.Extra.Number4 pressedKeys then
                AnEnemyOnTrack
            else if List.member Keyboard.Extra.Number5 pressedKeys then
                AWalkingEnemy
            else if List.member Keyboard.Extra.Number9 pressedKeys then
                Remove
            else
                itemToPlace
    in
        { levelCreateState
            | itemToPlace = newItemToPlace
            , playState = newNormalPlayState
        }


updatePlayStateAfterMouseClick : Vector -> Vector -> Bool -> Keyboard.Extra.State -> LevelCreateState -> ( LevelCreateState, Maybe String )
updatePlayStateAfterMouseClick windowSize cursorLocation cursorActive keyboardState levelCreateState =
    let
        ( width, height ) =
            platformSize

        { itemToPlace, playState } =
            levelCreateState

        newPosition =
            mouseToGridInPixels windowSize playState.camera cursorLocation

        newNormalPlatform =
            Platform Normal

        newDangerousPlatform =
            Platform Dangerous

        newPlatforms =
            case itemToPlace of
                PlaceNothing ->
                    playState.platforms

                Remove ->
                    case cursorActive of
                        True ->
                            Dict.remove newPosition playState.platforms

                        False ->
                            playState.platforms

                AStaticEnemy ->
                    playState.platforms

                AnEnemyOnTrack ->
                    playState.platforms

                AWalkingEnemy ->
                    playState.platforms

                ANormalPlatform ->
                    case cursorActive of
                        True ->
                            if Dict.member newPosition playState.platforms then
                                playState.platforms
                            else
                                Dict.insert newPosition newNormalPlatform playState.platforms

                        False ->
                            playState.platforms

                ADangerousPlatform ->
                    if Dict.member newPosition playState.platforms then
                        Dict.remove newPosition playState.platforms
                    else
                        Dict.insert newPosition newDangerousPlatform playState.platforms

        floatPosition =
            vectorIntToFloat newPosition

        newStaticEnemy =
            Enemy floatPosition 0 ( 64, 64 ) NoMovement True

        startNode =
            V2.add floatPosition ( -128, 0 )

        endNode =
            V2.add floatPosition ( 128, 0 )

        newEnemyOnTrack =
            Enemy floatPosition 0 ( 64, 64 ) (LinePath (LineMovementSpec startNode endNode floatPosition 1)) True

        newWalkingEnemy =
            Enemy floatPosition 0 ( 64, 64 ) (Walk floatPosition) True

        newEnemies =
            case itemToPlace of
                PlaceNothing ->
                    playState.permanentEnemies

                Remove ->
                    playState.permanentEnemies

                ANormalPlatform ->
                    playState.permanentEnemies

                ADangerousPlatform ->
                    playState.permanentEnemies

                AStaticEnemy ->
                    if List.member newStaticEnemy.startingLocation (List.map (\enemy -> enemy.startingLocation) playState.permanentEnemies) then
                        List.filter (\enemy -> not (enemy.startingLocation == newStaticEnemy.startingLocation)) playState.permanentEnemies
                    else
                        [ newStaticEnemy ]
                            |> List.append playState.permanentEnemies

                AnEnemyOnTrack ->
                    if List.member newEnemyOnTrack.startingLocation (List.map (\enemy -> enemy.startingLocation) playState.permanentEnemies) then
                        List.filter (\enemy -> not (enemy.startingLocation == newEnemyOnTrack.startingLocation)) playState.permanentEnemies
                    else
                        [ newEnemyOnTrack ]
                            |> List.append playState.permanentEnemies

                AWalkingEnemy ->
                    if List.member newWalkingEnemy.startingLocation (List.map (\enemy -> enemy.startingLocation) playState.permanentEnemies) then
                        List.filter (\enemy -> not (enemy.startingLocation == newWalkingEnemy.startingLocation)) playState.permanentEnemies
                    else
                        [ newWalkingEnemy ]
                            |> List.append playState.permanentEnemies

        newPlayState =
            { playState
                | platforms = newPlatforms
                , enemies = newEnemies
                , permanentEnemies = newEnemies
            }

        pressedKeys =
            Keyboard.Extra.pressedDown keyboardState

        encodedLevelData =
            if List.member Keyboard.Extra.Shift pressedKeys && List.member Keyboard.Extra.CharS pressedKeys then
                Just (levelDataEncodeHandler newPlayState.platforms newPlayState.permanentEnemies)
            else
                Nothing

        newLevelCreateState =
            { levelCreateState
                | playState = newPlayState
            }
    in
        ( newLevelCreateState, encodedLevelData )


renderLevelCreateScreen : Vector -> LevelCreateState -> List Renderable
renderLevelCreateScreen windowSize levelCreateState =
    let
        { itemToPlace, cursorLocation, playState } =
            levelCreateState

        newMouseLocation =
            mouseToGridInPixels windowSize playState.camera cursorLocation
    in
        List.concat
            [ [ renderCursorBlock itemToPlace (vectorIntToFloat newMouseLocation) ]
            , renderNormalPlay playState
            ]


renderCursorBlock : ItemToBePlace -> Vector -> Renderable
renderCursorBlock itemToBePlace location =
    let
        mouseColor =
            case itemToBePlace of
                PlaceNothing ->
                    Color.black

                Remove ->
                    Color.brown

                ANormalPlatform ->
                    Color.charcoal

                ADangerousPlatform ->
                    Color.yellow

                AStaticEnemy ->
                    Color.red

                AnEnemyOnTrack ->
                    Color.orange

                AWalkingEnemy ->
                    Color.purple
    in
        Render.shape
            Render.rectangle
            { color = mouseColor
            , position = location
            , size = vectorIntToFloat gridSquareSize
            }
