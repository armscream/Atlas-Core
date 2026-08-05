// Registry.odin
package Services

import "core:mem"

//
// ================================================================
// Registry
// ================================================================
//
Service_Registry :: struct {
	allocator:    mem.Allocator,
	//
	// Service storage
	//
	services:     [dynamic]Service_Instance,
	//
	// Free slots for reuse
	//
	free_indices: [dynamic]u32,
	initialized:  bool,
	running:      bool,
}

//
// ================================================================
// Init
// ================================================================
//
service_registry_init :: proc(registry: ^Service_Registry, allocator: mem.Allocator) {
	registry^ = Service_Registry {
		allocator = allocator,
	}
	registry.services = make([dynamic]Service_Instance, allocator)
	registry.free_indices = make([dynamic]u32, allocator)
}

//
// ================================================================
// Destroy
// ================================================================
//
service_registry_destroy :: proc(registry: ^Service_Registry) {
	delete(registry.services)
	delete(registry.free_indices)
	registry^ = {}
}

//
// ================================================================
// Register
// ================================================================
//
service_registry_register :: proc(
	registry: ^Service_Registry,
	descriptor: Service_Descriptor,
	instance: rawptr,
	type_id: typeid,
	vtable: ^Service_VTable,
) -> Service_Handle {
	service := Service_Instance {
		descriptor = descriptor,
		instance   = instance,
		vtable     = vtable,
		type_id    = type_id,
		state      = .Registered,
		generation = 1,
		active     = true,
	}
	//
	// Reuse old slot
	//
	if len(registry.free_indices) > 0 {
		index := pop(&registry.free_indices)
		registry.services[index] = service
		return Service_Handle{index = index, generation = service.generation}
	}
	//
	// Append new slot
	//
	index := u32(len(registry.services))
	append(&registry.services, service)
	return Service_Handle{index = index, generation = service.generation}
}

//
// ================================================================
// Validate Handle
// ================================================================
//
service_registry_validate :: proc(registry: ^Service_Registry, handle: Service_Handle) -> bool {
	if handle.index >= u32(len(registry.services)) {
		return false
	}
	service := &registry.services[handle.index]
	return service.active && service.generation == handle.generation
}

//
// ================================================================
// Resolve Handle
// ================================================================
//
service_registry_resolve :: proc(
	registry: ^Service_Registry,
	handle: Service_Handle,
) -> ^Service_Instance {
	if !service_registry_validate(registry, handle) {
		return nil
	}
	return &registry.services[handle.index]
}

//
// ================================================================
// Remove
// ================================================================
//
service_registry_remove :: proc(registry: ^Service_Registry, handle: Service_Handle) {
	service := service_registry_resolve(registry, handle)
	if service == nil {
		return
	}
	if service.state == .Running {
		if service.vtable.stop != nil {
			service.vtable.stop(service.instance)
		}
	}
	if service.vtable.shutdown != nil {
		service.vtable.shutdown(service.instance)
	}
	service.active = false
	service.generation += 1
	append(&registry.free_indices, handle.index)
}

//
// ================================================================
// Typed Access
// ================================================================
//
service_get :: proc(registry: ^Service_Registry, $T: typeid) -> ^T {
	for service in registry.services {
		if !service.active {
			continue
		}
		if service.type_id == T {
			return cast(^T)service.instance
		}
	}
	return nil
}