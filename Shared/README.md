# ReplicatedStorage/Shared

It includes modules accessible to both the server and the client. 
For the most part, none of them pose a significant risk of exploitation, so they are placed in a shared repository for convenience.

### Includes
- AnimationController — loads and manages animation tracks per character (play/pause/stop, marker-based callbacks for hit-windows, auto-cleanup on player leave).
- InputController — binds raw attack/block input via ContextActionService and relays it to the server through remotes.

> An important caveat: the repository also contained other modules that might have been imported in the provided code,
> but I did not include them as they are not directly related to the system under discussion.
