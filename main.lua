-- @@@ FILE: main_new.lua @@@
local ffi = require("ffi")

local bp = require("boilerplate")

ffi.cdef[[
    void* vx_sys_get_surface();
    void vx_sys_set_cmd(int cmd, int w, int h);
    void Sleep(uint32_t dwMilliseconds);
    int usleep(uint32_t usec);
    int vx_core_is_running();
    void vx_core_shutdown();
    void vx_core_mark_finished();
]]

local function sys_sleep(ms)
    if jit.os == "Windows" then
        ffi.C.Sleep(ms)
    else
        ffi.C.usleep(ms * 1000)
    end
end

local function boot_weaver()
    local ctx = {}

    for i, stage in ipairs(bp.sequence) do
        print(string.format("[WEAVER] Executing Stage %d: %s", i, stage.name))

        local signal = stage.action(ctx, bp)

        if signal == "AWAIT_SURFACE" then
            print("[WEAVER] Yielding execution, waiting for C-Core Surface...")
            while ffi.C.vx_sys_get_surface() == nil do
                sys_sleep(10)
                coroutine.yield()
            end
        end
    end

    return ctx
end

local function main()
    print("[LUA IO] Booting Headless Weaver (LABORATORY)...")

    local co = coroutine.create(boot_weaver)
    local status, engine_ctx

    while coroutine.status(co) ~= "dead" do
        status, engine_ctx = coroutine.resume(co)
        if not status then
            error("Fatal Weaver Crash: " .. tostring(engine_ctx))
        end
    end

    print("[LUA IO] Weaver sequence complete! Vulkan and Memory are ALIVE.")

    -- Keep the C-Core window alive for a few seconds to visually verify,
    -- then tell the C-Core to shut down safely.
    print("[LUA IO] Holding state for 3 seconds to verify stability...")
    sys_sleep(3000)

    print("[LUA IO] Triggering Shutdown...")
    ffi.C.vx_core_shutdown()
end

main()
ffi.C.vx_core_mark_finished()
