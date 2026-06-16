# rsc-rank-ticket
Attachments for the Roblox Studio community scripter application.

Owner: `kino.tea` (discord)

### Description
This repository contains the core of a server-authoritative melee combat system. It covers the full combat loop: client input is forwarded to the server, validated against per-player states and cooldowns, and resolved into animation-driven attacks.

Each weapon defines its own combo length, damage values, and animation set. hits are detected through `shapecast hitboxes` lib.

Supporting generic per-player state tracking to prevent overlapping actions, and persistent per-player weapon data backed by DataStore.

### Structure
The repository is divided into two parts: `System` and `Shared` (corresponding to Server and Client sides). 
This structure is intended to make the code easier to understand. Additionally, each part includes its own README file describing and explaining its contents.

The total volume is approximately ~1,300 lines of code.

> Ticket opened on June 17, 2026
