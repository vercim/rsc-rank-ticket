# ServerScriptStorage/System

It includes modules accessible to only for the server. 
Some of the modules deal directly with sensitive information, such as hit detection, damage calculation, 
and the tracking of cooldowns and states. Consequently, I do not grant the client direct access to them. 
Instead, access is provided solely through specific public API functions.

### Includes
- CombatEngine — core attack/block logic: combo progression, cooldown gating, triggers hit-window animations and reacts to incoming blocked hits.
- CooldownController — generic per-player, per-action cooldown tracking (set, check, and read remaining cooldowns).
- HitHandler — resolves combat hits via shapecast hitboxes, calculates damage with block-angle mitigation, and triggers hit sounds/VFX.
- MoveController — stacking movement-speed debuffs (e.g. slow on hit/block) with timed, GUID-tracked auto-removal.
- StateController — generic per-player state machine (Attacking/Blocking/Equipping) with optional auto-expiry and client-side debug replication.
- WeaponController — manages equipped weapon per player, persists weapon data via DataStore, and exposes weapon module/animation lookups to the rest of the system.

> An important caveat: the repository also contained other modules that might have been imported in the provided code,
> but I did not include them as they are not directly related to the system under discussion.
