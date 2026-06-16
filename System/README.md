# ServerScriptStorage/System

It includes modules accessible to only for the server. 
Some of the modules deal directly with sensitive information, such as hit detection, damage calculation, 
and the tracking of cooldowns and states. Consequently, I do not grant the client direct access to them. 
Instead, access is provided solely through specific public API functions.

### Includes
- CombatEngine
- CooldownController
- HitHandler
- MoveController
- StateController
- WeaponController

> An important caveat: the repository also contained other modules that might have been imported in the provided code,
> but I did not include them as they are not directly related to the system under discussion.
