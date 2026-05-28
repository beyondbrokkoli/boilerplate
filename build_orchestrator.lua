-- build_orchestrator.lua
local VULKAN_SDK_PATH = "C:/VulkanSDK/1.4.341.1"

local function copy_file(source, destination)
    local infile = io.open(source, "rb")
    if not infile then
        print("  [ERROR] Could not find: " .. source)
        return false
    end
    local content = infile:read("*all")
    infile:close()

    local outfile = io.open(destination, "wb")
    if not outfile then
        print("  [ERROR] Could not write to: " .. destination)
        return false
    end
    outfile:write(content)
    outfile:close()
    return true
end

local function run_cmd(cmd)
    local res = os.execute(cmd)
    return (res == true or res == 0)
end

local function compile_engine(platform)
    print("========================================")
    print("   WEAVER LABORATORY ORCHESTRATOR")
    print("   Target Platform: " .. string.upper(platform))
    print("========================================")

    print("\n[0/2] Generating C Header SSoT from Boilerplate...")
    local gen_cmd = 'luajit -e "require(\'shader_gen\').generate(\'registry.glsl\', \'shared_structs.h\')"'

    if not run_cmd(gen_cmd) then
        print("ERROR: Failed to generate SSoT files!")
        os.exit(1)
    end

    if platform == "linux" then
        print("\n[1/2] Compiling Laboratory Host (main.c) ...")
        local linux_build_main = "gcc main.c -O3 -march=x86-64-v3 -Wl,-E -I/usr/include/luajit-2.1 -lglfw -lvulkan -lluajit-5.1 -lm -lpthread -o boot"
        if not run_cmd(linux_build_main) then
            print("ERROR: main.c compilation failed!")
            os.exit(1)
        end

    elseif platform == "win" then
        print("\n[1/2] Compiling Laboratory Host (main.c) ...")
        local LUA_INC = "C:/msys64/mingw64/include/luajit-2.1"
        local win_build_main = string.format(
            'gcc main.c -O3 -march=x86-64-v3 -I"%s" -I"%s/Include" -L"%s/Lib" -lws2_32 -lglfw3 -lvulkan-1 -lluajit-5.1 -lm -o boot.exe',
            LUA_INC, VULKAN_SDK_PATH, VULKAN_SDK_PATH
        )
        if not run_cmd(win_build_main) then
            print("ERROR: boot.exe compilation failed!")
            os.exit(1)
        end

        print("\n[2/2] Packing Windows Dependencies (DLLs)...")
        copy_file("C:/msys64/mingw64/bin/glfw3.dll", "glfw3.dll")
        copy_file("C:/msys64/mingw64/bin/lua51.dll", "lua51.dll")
        print("  |- DLLs copied successfully.")
    else
        print("ERROR: Unknown platform. Use 'linux' or 'win'.")
        os.exit(1)
    end

    print("\n[SUCCESS] Laboratory build complete!\n")
end

-- ==========================================================
-- EXECUTION
-- ==========================================================
local target_platform = arg[1] or "linux"
compile_engine(target_platform)
