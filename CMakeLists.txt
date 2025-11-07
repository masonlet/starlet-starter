cmake_minimum_required(VERSION 3.20)
set(PROJECT_NAME StarletStarter)
set(SRC_DIR "${CMAKE_CURRENT_SOURCE_DIR}/src")
set(INC_DIR "${CMAKE_CURRENT_SOURCE_DIR}/inc")
set(ASSET_DIR "${CMAKE_CURRENT_SOURCE_DIR}/assets")

project(${PROJECT_NAME})
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_SUPPRESS_REGENERATION ON)

file(GLOB_RECURSE SOURCES        CONFIGURE_DEPENDS ${SRC_DIR}/*.cpp)
file(GLOB_RECURSE HEADERS        CONFIGURE_DEPENDS ${INC_DIR}/*.hpp)
file(GLOB_RECURSE ASSET_SHADERS  CONFIGURE_DEPENDS "${ASSET_DIR}/shaders/*")
file(GLOB_RECURSE ASSET_MODELS   CONFIGURE_DEPENDS "${ASSET_DIR}/models/*")
file(GLOB_RECURSE ASSET_SCENES   CONFIGURE_DEPENDS "${ASSET_DIR}/scenes/*")
file(GLOB_RECURSE ASSET_TEXTURES CONFIGURE_DEPENDS "${ASSET_DIR}/textures/*")

add_executable(${PROJECT_NAME} ${SOURCES} ${HEADERS})
file(TO_CMAKE_PATH "${ASSET_DIR}" ASSET_PATH)
target_compile_definitions(${PROJECT_NAME} PRIVATE ASSET_DIR="${ASSET_PATH}")

# Visual Studio organization
source_group(TREE ${SRC_DIR} PREFIX "Source Files" FILES ${SOURCES})
source_group(TREE ${INC_DIR} PREFIX "Header Files" FILES ${HEADERS})

add_custom_target(Assets SOURCES ${ASSET_SHADERS} ${ASSET_MODELS} ${ASSET_SCENES} ${ASSET_TEXTURES})
set_target_properties(Assets PROPERTIES FOLDER "Assets")
source_group("Assets\\Shaders"  FILES ${ASSET_SHADERS})
source_group("Assets\\Models"   FILES ${ASSET_MODELS})
source_group("Assets\\Scenes"   FILES ${ASSET_SCENES})
source_group("Assets\\Textures" FILES ${ASSET_TEXTURES})

target_include_directories(${PROJECT_NAME} PUBLIC "${INC_DIR}")

if(NOT BUILD_LOCAL)
  include(FetchContent)
  FetchContent_Declare(StarletEngine GIT_REPOSITORY https://github.com/masonlet/starletengine.git GIT_TAG main)
  FetchContent_Declare(StarletMath GIT_REPOSITORY https://github.com/masonlet/starletmath.git GIT_TAG main)
  FetchContent_Declare(StarletSerializer GIT_REPOSITORY https://github.com/masonlet/starletserializer.git GIT_TAG main)
  FetchContent_Declare(StarletScene GIT_REPOSITORY https://github.com/masonlet/starletscene.git GIT_TAG main)
  FetchContent_Declare(StarletGraphics GIT_REPOSITORY https://github.com/masonlet/starletgraphics.git GIT_TAG main)
  FetchContent_Declare(StarletControls GIT_REPOSITORY https://github.com/masonlet/starletcontrols.git GIT_TAG main)
  FetchContent_MakeAvailable(StarletEngine StarletMath StarletSerializer StarletScene StarletGraphics StarletControls)
endif()
target_link_libraries(${PROJECT_NAME} PUBLIC StarletEngine StarletMath StarletSerializer StarletScene StarletGraphics StarletControls)

set_property(GLOBAL PROPERTY USE_FOLDERS ON)
set_property(GLOBAL PROPERTY PREDEFINED_TARGETS_FOLDER "External")

# Output directories
set_target_properties(${PROJECT_NAME} PROPERTIES
    RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin"
    ARCHIVE_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/lib"
    LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/lib"
    VS_DEBUGGER_WORKING_DIRECTORY "$<TARGET_FILE_DIR:${PROJECT_NAME}>"
)

# Default Project
set_property(DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR} PROPERTY VS_STARTUP_PROJECT ${PROJECT_NAME})
