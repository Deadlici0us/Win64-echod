cmake_minimum_required(VERSION 3.10)
project(win64-echod LANGUAGES C ASM_MASM)

add_executable(echod main.asm utils.asm network.asm)

# Ensure MASM can find our .inc files in the source directory
target_compile_options(echod PRIVATE /I${CMAKE_CURRENT_SOURCE_DIR})

# --- Build Type Logic ---
if(CMAKE_BUILD_TYPE STREQUAL "Debug" OR NOT CMAKE_BUILD_TYPE)
    message(STATUS "Configuring for DEBUG build")
    target_compile_options(echod PRIVATE /Zi)
    target_link_options(echod PRIVATE /DEBUG /INCREMENTAL:YES)
else()
    message(STATUS "Configuring for RELEASE build")
    # Linker optimizations belong ONLY in Release
    target_link_options(echod PRIVATE /OPT:REF /OPT:ICF /INCREMENTAL:NO)
endif()

# --- Linker Configuration ---
set_target_properties(echod PROPERTIES LINKER_LANGUAGE C)

# Note: We removed /OPT:REF from here so it doesn't break Debug mode
target_link_options(echod PRIVATE /ENTRY:main /SUBSYSTEM:CONSOLE)

target_link_libraries(echod PRIVATE Ws2_32)