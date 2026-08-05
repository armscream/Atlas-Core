// Service.odin
package Services

import "core:mem"

//
// ================================================================
// Service States
// ================================================================
//

Service_State :: enum u8 {
	Unregistered,
	Registered,
	Initialized,
	Running,
	Stopped,
	Shutdown,
}

//
// ================================================================
// Service Flags
// ================================================================
//

Service_Flag :: enum u32 {
	None        = 0,
	Auto_Start  = 1 << 0,
	Required    = 1 << 1,
	Thread_Safe = 1 << 2,
}

Service_Flags :: distinct bit_set[Service_Flag;u32]

//
// ================================================================
// Service Version
// ================================================================
//

Version :: struct {
	major: u16,
	minor: u16,
	patch: u16,
}

//
// ================================================================
// Service Identifier
// ================================================================
//

Service_ID :: distinct u64

INVALID_SERVICE_ID :: Service_ID(0)

//
// ================================================================
// Service Descriptor
// ================================================================
//
Service_Descriptor :: struct {
	id:          Service_ID,
	name:        string,
	version:     Version,
	flags:       Service_Flags,
	dependencies: []Service_ID,
	priority:    i32, // deterministic startup ordering
}

//
// ================================================================
// Service Lifecycle
// ================================================================
//

Service_Initialize_Proc :: proc(service: rawptr, allocator: mem.Allocator) -> bool

Service_Start_Proc :: proc(service: rawptr) -> bool

Service_Stop_Proc :: proc(service: rawptr)

Service_Shutdown_Proc :: proc(service: rawptr)

//
// ================================================================
// Service VTable
// ================================================================
//

Service_VTable :: struct {
	initialize: Service_Initialize_Proc,
	start:      Service_Start_Proc,
	stop:       Service_Stop_Proc,
	shutdown:   Service_Shutdown_Proc,
}

//
// ================================================================
// Service Handle
// ================================================================
//
Service_Handle :: struct {
	index:      u32,
	generation: u32,
}

INVALID_SERVICE_HANDLE :: Service_Handle {
	index      = 0xFFFF_FFFF,
	generation = 0,
}

//
// ================================================================
// Service Instance
// ================================================================
//
Service_Instance :: struct {
	descriptor: Service_Descriptor,
	state:      Service_State,
	instance:   rawptr,
	vtable:     ^Service_VTable,
	type_id:    typeid,
	generation: u32,
	active:     bool,
}
