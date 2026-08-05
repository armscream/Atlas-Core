// Runtime.odin
package Runtime

import "../Services"
import "core:mem"

//
// ================================================================
// Atlas Runtime
// ================================================================
//
Runtime :: struct {
	allocator:       mem.Allocator,
	services:        Services.Service_Registry,
	service_manager: Services.Service_Manager,
	running:         bool,
}

//
// ================================================================
// Initialize
// ================================================================
//
runtime_init :: proc(runtime: ^Runtime, allocator: mem.Allocator) {
	runtime^ = Runtime {
		allocator = allocator,
	}
	Services.service_registry_init(&runtime.services, allocator)
	Services.service_manager_init(&runtime.service_manager, &runtime.services)
}

//
// ================================================================
// Shutdown
// ================================================================
//
runtime_shutdown :: proc(runtime: ^Runtime) {
	Services.service_manager_shutdown(&runtime.service_manager)
	Services.service_manager_destroy(&runtime.service_manager)
	Services.service_registry_destroy(&runtime.services)
	runtime^ = {}
}

//
// ================================================================
// Start
// ================================================================
//
runtime_start :: proc(runtime: ^Runtime) -> bool {
	if runtime.running {
		return true
	}
	if !Services.service_manager_start(&runtime.service_manager) {
		return false
	}
	runtime.running = true
	return true
}

//
// ================================================================
// Stop
// ================================================================
//
runtime_stop :: proc(runtime: ^Runtime) {
	if !runtime.running {
		return
	}
	Services.service_manager_stop(&runtime.service_manager)
	runtime.running = false
}