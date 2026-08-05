------------- Atlas-Core

Atlas-Core is the runtime foundation for Atlas applications. It provides application lifecycle management, service orchestration, background execution, storage abstractions, configuration, commands, synchronization, and other common infrastructure shared across all Atlas applications.

Atlas-Core intentionally contains no UI or cryptographic implementation. These are provided by Atlas-RMGUI and Atlas-Crypto through service interfaces.

Not implemented in Core:
Atlas-Crypto - Closed-source encryption library. Simply exposes: Crypto-Service.
Atlas-RMGUI - Retained-Mode GUI useful outside of the atlas framework.
Atlas Applications - Would depend on the frameworks above.

Directory Structure:
Atlas-Core
│
├── Runtime
│   ├── Application/
│   ├── Platform/
│   ├── Workspace/
│   └── Services/
│
├── Framework
│   ├── Commands/
│   ├── Events/
│   ├── Tasks/
│   ├── Plugins/
│   ├── Undo/
│   └── Documents/
│
├── Data
│   ├── Database/
│   ├── Storage/
│   ├── Filesystem/
│   ├── Sync/
│   └── Networking/
│
├── System
│   ├── Configuration/
│   ├── Settings/
│   ├── Localization/
│   └── Logging/

--------------------------Conventions----------------------------:
Public: uses Pacal_Case
proc() : snake_case
Consts : UPPER_CASE
Private: snake_case

-----Memory Ownership-----:

Atlas will never hide allocations.

Every subsystem receives an allocator.

Example

manager: Service_Manager

service_manager_init(
    &manager,
    allocator,
)

Destroy always mirrors Init.

NO Globals.

Simple Public API Style:
app := atlas.application_create(...)

atlas.register_service(...)

atlas.register_plugin(...)

atlas.run(app)