-- @@@ FILE: boilerplate.lua @@@
local ffi = require("ffi")
local bit = require("bit")

local bp = {
    -- 1. THE VOCABULARY (Minimal subset for the lab test)
    sys = { idle = 0, boot = 1, kill = 2 },
    win = { w = 1280, h = 720, min_w = 640, min_h = 360 },
    cfg = { use_validation = 1, vk_api_version = 4206592 },

    vk_queue = { graphics = 1, compute = 2, transfer = 4 },
    vk_struct = {
        app_info = 0, instance_create = 1, device_queue_create = 2,
        device_create = 3, mem_alloc = 5, buffer_create = 12,
        dynamic_rendering_features = 1000044003,
        extended_dynamic_state_features = 1000267000,
        extended_dynamic_state2_features = 1000377000,
    },
    vk_mem = {
        device_local = 1, host_visible = 2, host_coherent = 4, host_cached = 8,
    },

    -- 2. THE REQUIREMENTS
    vk_reqs = {
        instance_ext = { "VK_KHR_get_physical_device_properties2" },
        device_ext = {
            "VK_KHR_swapchain", "VK_KHR_dynamic_rendering",
            "VK_KHR_depth_stencil_resolve", "VK_KHR_create_renderpass2",
            "VK_KHR_multiview", "VK_KHR_maintenance2",
            "VK_EXT_extended_dynamic_state", "VK_EXT_extended_dynamic_state2"
        }
    },

    memory_arenas = {
        { name = "MASTER_INDEX_BLOCK", cdef_type = "uint32_t", count = 3000000, usage = bit.bor(64, 256) },
        { name = "MASTER_GPU_BLOCK", cdef_type = "uint8_t", count = 142606336, usage = bit.bor(32, 128, 256) }
    }
}

-- 3. THE SEQUENCE
bp.sequence = {
    {
        name = "Vulkan Instance",
        action = function(ctx, r)
            local vulkan = require("vulkan_core_new")
            -- FIXED COLLISION: using vk_runtime instead of vk_state
            ctx.vk_runtime = vulkan.create_instance(r.vk_reqs.instance_ext) 
        end
    },
    {
        name = "GLFW Window Boot",
        action = function(ctx, r)
            print("[WEAVER] Ordering C-Core to Boot GLFW Window...")
            ffi.C.vx_sys_set_cmd(r.sys.boot, r.win.w, r.win.h)
            return "AWAIT_SURFACE"
        end
    },
    {
        name = "Vulkan Logical Device",
        action = function(ctx, r)
            local vulkan = require("vulkan_core_new")
            local surface_ptr = ffi.C.vx_sys_get_surface()
            vulkan.finalize_device_and_swapchain(ctx.vk_runtime, surface_ptr, r.vk_reqs.device_ext)
        end
    },
    {
        name = "Memory Arenas Allocation",
        action = function(ctx, r)
            local memory = require("memory_new")
            for _, arena in ipairs(r.memory_arenas) do
                memory.CreateHostVisibleBuffer(
                    arena.name, arena.cdef_type, arena.count, arena.usage, ctx.vk_runtime
                )
            end
        end
    }
}

return bp
