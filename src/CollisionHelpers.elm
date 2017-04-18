module CollisionHelpers exposing (setByPlatform, getSideCollidingWithEnemies)

import GameTypes exposing (Vector)
import Wall exposing (Wall)
import Enemy exposing (Enemy)
import Collision2D


------------------------------------------------------------------
-- collision with enemies
------------------------------------------------------------------


isCollidingWithEnemy : Vector -> Vector -> Enemy -> Maybe Collision2D.Side
isCollidingWithEnemy entityLocation entitySize enemy =
    let
        ( x, y ) =
            entityLocation

        ( width, height ) =
            entitySize

        ( enemyX, enemyY ) =
            enemy.location

        ( enemyWidth, enemyHeight ) =
            enemy.size

        entityHitbox =
            Collision2D.rectangle x y width height

        enemyHitbox =
            Collision2D.rectangle enemyX enemyY enemyWidth enemyHeight
    in
        Collision2D.rectangleSide entityHitbox enemyHitbox


getSideCollidingWithEnemies : Vector -> Vector -> List Enemy -> Maybe Collision2D.Side -> Maybe Collision2D.Side
getSideCollidingWithEnemies location size enemies side =
    case enemies of
        [] ->
            side

        enemy :: rest ->
            case isCollidingWithEnemy location size enemy of
                Just side ->
                    getSideCollidingWithEnemies location size rest (Just side)

                Nothing ->
                    getSideCollidingWithEnemies location size rest side



------------------------------------------------------------------
-- collision with platforms
------------------------------------------------------------------


isCollidingWithPlatform : Vector -> Vector -> Wall -> Maybe Collision2D.Side
isCollidingWithPlatform entityLocation entitySize wall =
    let
        ( x, y ) =
            entityLocation

        ( width, height ) =
            entitySize

        ( wallX, wallY ) =
            wall.location

        ( wallWidth, wallHeight ) =
            wall.size

        entityHitbox =
            Collision2D.rectangle x y width height

        wallHitbox =
            Collision2D.rectangle wallX wallY wallWidth wallHeight
    in
        Collision2D.rectangleSide entityHitbox wallHitbox


setByPlatform : Vector -> Vector -> List Wall -> Maybe Collision2D.Side -> ( Vector, Maybe Collision2D.Side )
setByPlatform location size walls lastSide =
    case walls of
        [] ->
            ( location, lastSide )

        wall :: rest ->
            case isCollidingWithPlatform location size wall of
                Just side ->
                    setByPlatform (setEntity location size wall side) size rest (Just side)

                Nothing ->
                    setByPlatform location size rest lastSide


setEntity : Vector -> Vector -> Wall -> Collision2D.Side -> Vector
setEntity entityLocation entitySize wall side =
    let
        ( x, y ) =
            entityLocation

        ( entityWidth, entityHeight ) =
            entitySize

        ( wallX, wallY ) =
            wall.location

        ( wallWidth, wallHeight ) =
            wall.size

        minVerticalDistanceApart =
            entityHeight / 2 + wallHeight / 2

        minHorizontalDistanceApart =
            entityWidth / 2 + wallWidth / 2
    in
        case side of
            Collision2D.Top ->
                ( x, wallY - minVerticalDistanceApart )

            Collision2D.Bottom ->
                ( x, wallY + minVerticalDistanceApart )

            Collision2D.Right ->
                if y > wallY + wallHeight / 2 then
                    ( x, wallY + minVerticalDistanceApart )
                else
                    ( wallX - minHorizontalDistanceApart, y )

            Collision2D.Left ->
                if y > wallY + wallHeight / 2 then
                    ( x, wallY + minVerticalDistanceApart )
                else
                    ( wallX + minHorizontalDistanceApart, y )
