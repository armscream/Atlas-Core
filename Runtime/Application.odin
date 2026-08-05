// Application.odin
package Runtime

import "core:mem"

//
// ================================================================
// Application State
// ================================================================
//
Application_State :: enum u8 {
	Created,
	Initialized,
	Running,
	Stopping,
	Shutdown,
}

//
// ================================================================
// Application
// ================================================================
//
Application :: struct {
	name:      string,
	allocator: mem.Allocator,
	runtime:   Runtime,
	state:     Application_State,
}

//
// ================================================================
// Create
// ================================================================
//
application_init :: proc(app: ^Application, name: string, allocator: mem.Allocator) {
	app^ = Application {
		name      = name,
		allocator = allocator,
		state     = .Created,
	}
	runtime_init(&app.runtime, allocator)
	app.state = .Initialized
}

//
// ================================================================
// Start
// ================================================================
//
application_start :: proc(app: ^Application) -> bool {
	if app.state != .Initialized {
		return false
	}
	if !runtime_start(&app.runtime) {
		return false
	}
	app.state = .Running
	return true
}

//
// ================================================================
// Shutdown
// ================================================================
//
application_shutdown :: proc(app: ^Application) {
	if app.state == .Shutdown {
		return}
	app.state = .Stopping
	runtime_shutdown(&app.runtime)
	app.state = .Shutdown
}
