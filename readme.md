# Love2D SDK Documentation

The Love2D sdk can be installed by downloading the latest version as well as the required luapb library from [GitHub](https://github.com/planetary-processing/). You can then import the sdk with `require(“sdk.sdk”)`.

The SDK object returned will have functions:

| Method                                  | Parameters                                             | Description                                                       |
| --------------------------------------- | ------------------------------------------------------ | ----------------------------------------------------------------- |
| `sdk.init(game_id, username, password)` | `game_id: int`, `username: string`, `password: string` | Called to initialize.                                             |
| `sdk.update()`                          | None                                                   | Call this method each frame.                                      |
| `sdk.message(msg)`                      | `msg: table`                                           | Send a message to the player entity on the server.                |
| `sdk.event(event)`                      | `event: table`                                         | Called when the server fires an arbitrary event (not implemented).|

And variables:

| Variable       | Description                                     |
| -------------- | ----------------------------------------------- |
| `sdk.entities` | List of entities the client can see.            |
| `sdk.uuid`     | UUID of the player associated with this client. |

Within love.load you need to run sdk.init(game_id, username, password) where game_idis found on your control panel and the username and password are your player’s username and password which you are responsible for capturing from them.

Within love.update you need to run sdk.update.

You can then access all the entities within sdk.entities (which can be iterated over) and the entity ID of the player associated with this client as sdk.uuid, note that this means you can access the player entity with sdk.entities[sdk.uuid].

You can call sdk.move(dx, dy) to move your player entity and sdk.message(msg) to send a message to the player entity on the server (i.e. to command it to perform an action).

You can implement the sdk.event(event) message yourself (in the same way one does with love.update) and it will be called when it receives an event from the server.

The entity type for the Love2D SDK is different to that in the server, it is defined as such:

### Entity

###### Fields

| Field    | Type   | Description                  |
| -------- | ------ | ---------------------------- |
| EntityID | string | UUID of the entity.          |
| X        | float  | X coordinate in world units. |
| Y        | float  | Y coordinate in world units. |
| Data     | []byte | Public data of the entity.   |
| Type     | string | Type of the entity.          |
