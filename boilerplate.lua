local ffi = require("ffi")
local bit = require("bit")

require("vulkan_headers")

local bp = {
    -- 1. THE VOCABULARY
    sys = { idle = 0, boot = 1, kill = 2 },
    win = { w = 1280, h = 720, min_w = 640, min_h = 360 },
    -- EXTRACTION: Added pc_size = 128 to the global config
    cfg = { use_validation = 1, vk_api_version = 4206592, pcount = 1000000, grid_cells = 262144, pc_size = 128 },

    mode = { dual = 0, geom = 1, points = 2, point_cloud_pass = 88 },
    -- [MISSING DATA ADDED BACK FOR SHADER_GEN]
    mode = { dual = 0, geom = 1, points = 2, point_cloud_pass = 88 },

    vk_queue = { graphics = 1, compute = 2, transfer = 4 },
    -- Replace your truncated vk_struct with the full one:
    vk_struct = {
        app_info                             = 0,
        instance_create                      = 1,
        device_queue_create                  = 2,
        device_create                        = 3,
        mem_alloc                            = 5,
        fence_create                         = 8,
        semaphore_create                     = 9,
        buffer_create                        = 12,
        image_create                         = 14,
        image_view_create                    = 15,
        shader_module_create                 = 16,
        pipeline_shader_stage_create         = 18,
        pipeline_vertex_input_state_create   = 19,
        pipeline_input_assembly_state_create = 20,
        pipeline_viewport_state_create       = 22,
        pipeline_rasterization_state_create  = 23,
        pipeline_multisample_state_create    = 24,
        pipeline_depth_stencil_state_create  = 25,
        pipeline_color_blend_state_create    = 26,
        pipeline_dynamic_state_create        = 27,
        graphics_pipeline_create             = 28,
        compute_pipeline_create              = 29,
        pipeline_layout_create               = 30,
        desc_set_layout_create               = 32,
        desc_pool_create                     = 33,
        desc_set_alloc                       = 34,
        write_desc_set                       = 35,
        command_buffer_begin                 = 42,
        image_memory_barrier                 = 45,
        memory_barrier                       = 46,
        submit_info                          = 4,
        rendering_info                       = 1000044000,
        rendering_attachment_info            = 1000044001,
        pipeline_rendering_create            = 1000044002,
        dynamic_rendering_features           = 1000044003,
        extended_dynamic_state_features      = 1000267000,
        extended_dynamic_state2_features     = 1000377000,
        swapchain_create                     = 1000001000,
        present_info                         = 1000001001,
    },

    -- MISSING VOCABULARY NEEDED BY SWAPCHAIN.LUA
    vk_result = {
        success           = 0,
        error_out_of_date = -1000000001,
    },
    vk_format = {
        b8g8r8a8_srgb = 50,
        d32_sfloat    = 126,
    },
    vk_image = {
        view_type_2d           = 1,
        type_2d                = 1,
        tiling_optimal         = 0,
        usage_color_attachment = 16,
        usage_depth_attachment = 32,
        aspect_color           = 1,
        aspect_depth           = 2,
        sample_count_1         = 1,
    },
    vk_layout = {
        undefined                = 0,
        color_attachment_optimal = 2,
        depth_attachment_optimal = 3,
        present_src              = 1000001002,
    },
    vk_swapchain = {
        color_space_srgb_nonlinear = 0,
        composite_alpha_opaque     = 1,
        present_mode_fifo          = 2,
    },

    -- MISSING VOCABULARY NEEDED BY DESCRIPTORS.LUA
    vk_shader_stage = { vert = 1, frag = 16, comp = 32 },
    vk_desc = { ssbo = 7 },

    vk_mem = {
        device_local = 1, host_visible = 2, host_coherent = 4, host_cached = 8,
    },

    c_math_structs = [[
    typedef struct { float m[16]; } mat4_t;

    typedef struct {
        mat4_t viewProj;
        uint32_t soa_upload_idx;
        uint32_t aos_current_idx;
        uint32_t aos_prev_idx;
        uint32_t particle_count;
        float dt;
        float total_time;
        float spread;
        float highlight_power;
        uint32_t algae_color;
        uint32_t water_color;
        uint32_t bg_color_a;
        uint32_t bg_color_b;
        uint32_t target_state;
        uint32_t sorted_idx;
        uint32_t cell_counters_idx;
        uint32_t cell_offsets_idx;
    } PushConstants;

    typedef struct {
        uint32_t target_state;
        uint32_t push_active;
        uint32_t pull_active;
        float mouse_x;
        float mouse_y;
        uint32_t _padding[3];
    } SwarmCommand;

    typedef struct {
        uint64_t pipeline_id;
        uint64_t descriptor_set;
        uint32_t index_count;
        uint32_t instance_count;
        uint32_t first_index;
        int32_t vertex_offset;
        uint32_t first_instance;
        uint16_t pc_offset;
        uint16_t pc_size;
        uint8_t push_constants[128];

        int16_t scissor_x;
        int16_t scissor_y;
        uint16_t scissor_w;
        uint16_t scissor_h;
        uint8_t cull_mode;
        uint8_t depth_test;
        uint8_t depth_write;
        uint8_t depth_compare_op;
        uint8_t front_face;
        uint8_t topology;
        uint8_t _reserved[10];
    } DrawCommand;

    typedef struct {
        uint64_t pipeline_id;
        uint64_t layout_id;
        uint64_t descriptor_set;

        uint32_t group_x;
        uint32_t group_y;
        uint32_t group_z;

        uint16_t pc_offset;
        uint16_t pc_size;

        uint32_t barrier_src_stage;
        uint32_t barrier_dst_stage;
        uint32_t barrier_src_access;
        uint32_t barrier_dst_access;

        uint8_t push_constants[128];
        uint8_t _padding[8];
    } ComputeCommand;

    typedef struct __attribute__((packed, aligned(64))) {
        ComputeCommand* comp_queue;
        uint32_t comp_count;
        uint32_t _pad_comp;

        DrawCommand* draw_queue;
        uint32_t draw_count;
        uint32_t _pad_draw;

        uint64_t gfx_layout;
        uint64_t vertex_buffer;
        uint64_t index_buffer;
        uint64_t swapchain_image;
        uint64_t swapchain_view;
        uint64_t depth_image;
        uint64_t depth_view;
        uint32_t width;
        uint32_t height;

        uint8_t _padding[32];
    } RenderPacket;
    ]],

    c_vk_structs = [[
    typedef struct {
        VkDevice device;
        VkQueue queue;
        VkSwapchainKHR swapchain;
        uint64_t swapchain_images[10];
        uint64_t swapchain_views[10];
        VkSemaphore image_available[10];
        VkSemaphore render_finished[10];
        VkFence in_flight[10];
        void* vkWaitForFences;
        void* vkAcquireNextImageKHR;
        void* vkResetFences;
        void* vkQueueSubmit;
        void* vkQueuePresentKHR;
        void* pfnBegin;
        void* pfnEnd;
        void* pfnSetCullMode;
        void* pfnSetFrontFace;
        void* pfnSetPrimitiveTopology;
        void* pfnSetDepthTestEnable;
        void* pfnSetDepthWriteEnable;
        void* pfnSetDepthCompareOp;
    } RenderThreadInit;
    ]],

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
    },

    compute_pipelines = {
        { name = "clear",      file = "clear_comp.spv" },
        { name = "hash",       file = "hash_comp.spv" },
        { name = "scan_local", file = "scan_local_comp.spv" },
        { name = "scan_group", file = "scan_group_comp.spv" },
        { name = "scan_add",   file = "scan_add_comp.spv" },
        { name = "reorder",    file = "reorder_comp.spv" }
    },
}

-- 3. THE SEQUENCE
bp.sequence = {
    {
        name = "Vulkan Instance",
        action = function(ctx, r)
            local vulkan = require("vulkan_core")
            ctx.vk_runtime = vulkan.create_instance(r.vk_reqs.instance_ext)
            ffi.cdef("void vx_sys_publish_instance(void* instance);")
            ffi.C.vx_sys_publish_instance(ctx.vk_runtime.instance)
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
            local vulkan = require("vulkan_core")
            local surface_ptr = ffi.C.vx_sys_get_surface()
            vulkan.finalize_device_and_swapchain(ctx.vk_runtime, surface_ptr, r.vk_reqs.device_ext)
        end
    },
    {
        name = "Memory Arenas Allocation",
        action = function(ctx, r)
            local memory = require("memory")
            for _, arena in ipairs(r.memory_arenas) do
                memory.CreateHostVisibleBuffer(
                    arena.name, arena.cdef_type, arena.count, arena.usage, ctx.vk_runtime
                )
            end
        end
    },
    -- NEW INJECTIONS: SWAPCHAIN & DESCRIPTORS
    {
        name = "Swapchain Initialization",
        action = function(ctx, r)
            local swapchain = require("swapchain")
            -- We feed it the runtime state and our SSoT window dimensions
            ctx.sc_state = swapchain.Init(ctx.vk_runtime.vk, ctx.vk_runtime, r.win.w, r.win.h)
        end
    },
    {
        name = "Descriptors Matrix",
        action = function(ctx, r)
            local descriptors = require("descriptors")
            local memory = require("memory") -- Fetches the already-populated memory module

            -- Extract the specific handle generated in Stage 4
            local master_gpu_buffer = memory.Buffers["MASTER_GPU_BLOCK"]

            ctx.desc_state = descriptors.Init(ctx.vk_runtime.vk, ctx.vk_runtime.device, master_gpu_buffer)
        end
    },

    {
        name = "Compute Graph Pipelines",
        action = function(ctx, r)
            local compute = require("compute_pipeline")

            -- Fetch the layout created by the Descriptors stage
            local layout = ctx.desc_state.pipelineLayout

            -- Feed the module our dynamically sized requirements
            ctx.comp_state = compute.Init(ctx.vk_runtime.vk, ctx.vk_runtime.device, layout, r.compute_pipelines)
        end
    },
}

return bp
