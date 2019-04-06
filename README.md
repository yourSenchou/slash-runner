# Todo
* No generic vectors, custom types for specific things(these vectors and intVectors are driving me nuts already)
* maybe separate things from how they are rendered???
  - See if this idea breaks down with opaque types.
* GamePlatform and the game map are different concepts. Make a game map that owns things and the locations they are at.
  - `GamePlatform` does not need its own file.
* `Dict IntVector GamePlatform.Platform` is really just the game map.(Platforms, layout, enemies spawning points?)
* Collision needs an overhaul
* All types should live in there home file
* Should GameFeel be stored in NormalPlay's model or stay in Main????
* MouseHelpers, should it be its own module???
* Clean up/little tasks
  - Get window width and height from flags not initial Cmd
  - `Tuple.second Coordinates.gridSquareSize` is not straightforward... `gridSquareWidth` might be.

## Refactor order (This will solve a lot of the todos above)
1. V2 and Coordinates need to be a new way of representing locations, sizes and speeds or something
2. GamePlatform needs to be used in or become a new GameMap or something
3. Using the two above Collision needs an overhaul
