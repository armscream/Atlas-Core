// Manager.odin
package Services

import "core:fmt"

//
// ================================================================
// Service Manager
// ================================================================
//
Service_Manager :: struct {
	registry:    ^Service_Registry,
	start_order: [dynamic]u32,
	running:     bool,
}

//
// ================================================================
// Init
// ================================================================
//
service_manager_init :: proc(manager: ^Service_Manager, registry: ^Service_Registry) {
	manager^ = Service_Manager {
		registry = registry,
	}
	manager.start_order = make([dynamic]u32, registry.allocator)
}

//
// ================================================================
// Destroy
// ================================================================
//
service_manager_destroy :: proc(manager: ^Service_Manager) {
	delete(manager.start_order)
	manager^ = {}
}

//
// ================================================================
// Dependency Lookup
// ================================================================
//
service_manager_find_index :: proc(manager: ^Service_Manager, id: Service_ID) -> int {
	registry := manager.registry
	for i in 0 ..< len(registry.services) {
		service := &registry.services[i]
		if !service.active {
			continue
		}
		if service.descriptor.id == id {
			return i
		}
	}
	return -1
}

//
// ================================================================
// Dependency Graph
// ================================================================
//
service_manager_visit :: proc(
	manager: ^Service_Manager,
	index: u32,
	visited: []bool,
	stack: []bool,
) -> bool {
	if stack[index] {
		fmt.println(
			"Service dependency cycle detected:",
			manager.registry.services[index].descriptor.name,
		)
		return false
	}
	if visited[index] {
		return true
	}
	stack[index] = true
	service := &manager.registry.services[index]
	for dependency in service.descriptor.dependencies {
		dependency_index := service_manager_find_index(manager, dependency)
		if dependency_index < 0 {
			fmt.println("Missing dependency:", dependency, "required by", service.descriptor.name)
			return false
		}
		if !service_manager_visit(manager, u32(dependency_index), visited, stack) {
			return false
		}
	}
	stack[index] = false
	visited[index] = true
	append(&manager.start_order, index)
	return true
}

//
// ================================================================
// Build Startup Order
// ================================================================
//
service_manager_build_order :: proc(manager: ^Service_Manager) -> bool {
	registry := manager.registry
	clear(&manager.start_order)
	count := len(registry.services)
	visited := make([]bool, count, registry.allocator)
	stack := make([]bool, count, registry.allocator)
	defer delete(visited)
	defer delete(stack)
	for i in 0 ..< count {
		if !registry.services[i].active {
			continue
		}
		if !service_manager_visit(manager, u32(i), visited, stack) {
			return false
		}
	}
	return true
}

//
// ================================================================
// Initialize Services
// ================================================================
//
service_manager_initialize :: proc(manager: ^Service_Manager) -> bool {
	for index in manager.start_order {
		service := &manager.registry.services[index]
		if service.state != .Registered {
			continue
		}
		if service.vtable.initialize != nil {
			success := service.vtable.initialize(service.instance, manager.registry.allocator)
			if !success {
				fmt.println("Failed initializing:", service.descriptor.name)
				return false
			}
		}
		service.state = .Initialized
	}
	return true
}

//
// ================================================================
// Start Services
// ================================================================
//
service_manager_start :: proc(manager: ^Service_Manager) -> bool {
	if manager.running {
		return true
	}
	if !service_manager_build_order(manager) {
		return false
	}
	if !service_manager_initialize(manager) {
		return false
	}
	for index in manager.start_order {
		service := &manager.registry.services[index]
		if service.vtable.start != nil {
			success := service.vtable.start(service.instance)
			if !success {
				fmt.println("Failed starting:", service.descriptor.name)
				service_manager_stop(manager)
				return false
			}
		}
		service.state = .Running
	}
	manager.running = true
	return true
}

//
// ================================================================
// Stop Services
// ================================================================
//
service_manager_stop :: proc(manager: ^Service_Manager) {
	if !manager.running {
		return
	}
	for i := len(manager.start_order) - 1; i >= 0; i -= 1 {
		index := manager.start_order[i]
		service := &manager.registry.services[index]
		if service.vtable.stop != nil {
			service.vtable.stop(service.instance)
		}
		service.state = .Stopped
	}
	manager.running = false
}

//
// ================================================================
// Shutdown Services
// ================================================================
//
service_manager_shutdown :: proc(manager: ^Service_Manager) {
	service_manager_stop(manager)
	for i := len(manager.start_order) - 1; i >= 0; i -= 1 {
		index := manager.start_order[i]
		service := &manager.registry.services[index]
		if service.vtable.shutdown != nil {
			service.vtable.shutdown(service.instance)
        }
		service.state = .Shutdown
	}
}