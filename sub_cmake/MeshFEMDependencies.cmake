# Prepare dependencies
#
# For each third-party library, if the appropriate target doesn't exist yet,
# download it via external project, and add_subdirectory to build it alongside
# this project.

### Configuration
set(MESHFEM_ROOT "${CMAKE_CURRENT_LIST_DIR}/..")
set(MESHFEM_EXTERNAL "${MESHFEM_ROOT}/3rdparty")

# Make MESHFEM_EXTERNAL path available also to parent projects.
get_directory_property(hasParent PARENT_DIRECTORY)
if (hasParent)
    set(MESHFEM_EXTERNAL "${MESHFEM_EXTERNAL}" PARENT_SCOPE)
endif()

# Download and update 3rdparty libraries
list(APPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_LIST_DIR})
list(REMOVE_DUPLICATES CMAKE_MODULE_PATH)
include(MeshFEMDownloadExternal)

################################################################################
# Required libraries
################################################################################

# C++11 threads
find_package(Threads REQUIRED) # provides Threads::Threads

# Boost library
if(NOT TARGET meshfem::boost)
    # Try to use system boost; downloading it with cmake-boost downloads around 800MB of stuff...
    find_package(Boost 1.83 COMPONENTS filesystem system program_options REQUIRED)
    if (NOT Boost_FOUND)
        include(boost)
    endif()

    add_library(meshfem_boost INTERFACE)
    add_library(meshfem::boost ALIAS meshfem_boost)
    if(TARGET Boost::filesystem AND TARGET Boost::system AND TARGET Boost::program_options)
        target_link_libraries(meshfem_boost INTERFACE
            Boost::filesystem
            Boost::system
            Boost::program_options
        )
    else()
        # When CMake and Boost versions are not in sync, imported targets may not be available... (sigh)
        target_include_directories(meshfem_boost SYSTEM INTERFACE ${Boost_INCLUDE_DIRS})
        target_link_libraries(meshfem_boost INTERFACE ${Boost_LIBRARIES})
    endif()
endif()

# Catch2
find_package(Catch2 REQUIRED)
if(NOT TARGET Catch2::Catch2 AND (CMAKE_SOURCE_DIR STREQUAL PROJECT_SOURCE_DIR))
    meshfem_download_catch()
    add_subdirectory(${MESHFEM_EXTERNAL}/Catch2)
    list(APPEND CMAKE_MODULE_PATH ${MESHFEM_EXTERNAL}/Catch2/contrib)
endif()

# Eigen3 library
find_package(Eigen3 REQUIRED)
if(NOT TARGET Eigen3::Eigen)
    add_library(meshfem_eigen INTERFACE)
    meshfem_download_eigen()
    target_include_directories(meshfem_eigen SYSTEM INTERFACE ${MESHFEM_EXTERNAL}/eigen)
    # target_include_directories(meshfem_eigen SYSTEM INTERFACE
    #                            $<BUILD_INTERFACE:${MESHFEM_EXTERNAL}/eigen>
    #                            $<INSTALL_INTERFACE:3rdparty/eigen>)
    add_library(Eigen3::Eigen ALIAS meshfem_eigen)
    # install(TARGETS meshfem_eigen
    #         EXPORT MeshFEMDummyExport)

    # # Hack to work around Ceres' export needing `meshfem_eigen` to be exported.
    # install(EXPORT MeshFEMDummyExport
    #         NAMESPACE MeshFEMDummy::
    #         DESTINATION libMeshFEM/cmake/Dummy
    #         FILE MeshFEMDummyTargets.cmake)
endif()

# json library
find_package(nlohmann_json REQUIRED)
if(NOT TARGET json::json)
    if(TARGET nlohmann_json::nlohmann_json)
        add_library(json::json ALIAS nlohmann_json::nlohmann_json)
    else()
        add_library(meshfem_json INTERFACE)
        meshfem_download_json()
        target_include_directories(meshfem_json SYSTEM INTERFACE ${MESHFEM_EXTERNAL}/json)
        target_include_directories(meshfem_json SYSTEM INTERFACE ${MESHFEM_EXTERNAL}/json/nlohmann)
        add_library(json::json ALIAS meshfem_json)
    endif()
endif()

# Optional library
find_package(optional-lite REQUIRED)
if(NOT TARGET optional::optional)
    if(TARGET nonstd::optional-lite)
        add_library(optional::optional ALIAS nonstd::optional-lite)
    else()
        meshfem_download_optional()
        add_library(optional_lite INTERFACE)
        target_include_directories(optional_lite SYSTEM INTERFACE ${MESHFEM_EXTERNAL}/optional/include)
        add_library(optional::optional ALIAS optional_lite)
    endif()
endif()

# TBB library
find_package(TBB REQUIRED)
if(MESHFEM_WITH_TBB AND NOT TARGET tbb::tbb)
    if(TARGET onetbb::onetbb)
        add_library(tbb::tbb ALIAS onetbb::onetbb)
    else()
        set(TBB_BUILD_STATIC OFF CACHE BOOL " " FORCE)
        set(TBB_BUILD_SHARED ON CACHE BOOL " " FORCE)
        set(TBB_BUILD_TBBMALLOC ON CACHE BOOL " " FORCE) # needed for CGAL's parallel mesher
        set(TBB_BUILD_TBBMALLOC_PROXY OFF CACHE BOOL " " FORCE)
        set(TBB_BUILD_TESTS OFF CACHE BOOL " " FORCE)

        meshfem_download_tbb()
        add_subdirectory(${MESHFEM_EXTERNAL}/tbb tbb EXCLUDE_FROM_ALL)
        #set_property(TARGET tbb_static tbb_def_files PROPERTY FOLDER "dependencies")
        #set_target_properties(tbb_static PROPERTIES COMPILE_FLAGS "-Wno-implicit-fallthrough -Wno-missing-field-initializers -Wno-unused-parameter -Wno-keyword-macro")

        add_library(tbb_tbb INTERFACE)
        target_include_directories(tbb_tbb SYSTEM INTERFACE ${MESHFEM_EXTERNAL}/tbb/include)
        target_link_libraries(tbb_tbb INTERFACE tbbmalloc tbb)
        add_library(tbb::tbb ALIAS tbb_tbb)
        meshfem_target_hide_warnings(tbb_tbb)
    endif()
endif()

# Triangle library
if(NOT TARGET triangle::triangle)
    #meshfem_download_triangle()
    add_subdirectory(${MESHFEM_EXTERNAL}/triangle triangle)
    target_include_directories(triangle SYSTEM INTERFACE ${MESHFEM_EXTERNAL}/triangle)
    add_library(triangle::triangle ALIAS triangle)
endif()

# Spectra library
find_package(spectra REQUIRED)
if(NOT TARGET spectra::spectra)
    if(TARGET Spectra::Spectra)
        add_library(meshfem::spectra ALIAS Spectra::Spectra)
    else()
        meshfem_download_spectra()
        add_library(meshfem_spectra INTERFACE)
        target_include_directories(meshfem_spectra SYSTEM INTERFACE ${MESHFEM_EXTERNAL}/spectra/include)
        add_library(meshfem::spectra ALIAS meshfem_spectra)
    endif()
endif()

# TinyExpr library
if(NOT TARGET tinyexpr::tinyexpr)
    #meshfem_download_tinyexpr()
    add_library(meshfem_tinyexpr ${MESHFEM_EXTERNAL}/tinyexpr/tinyexpr.c)
    target_include_directories(meshfem_tinyexpr SYSTEM PUBLIC ${MESHFEM_EXTERNAL}/tinyexpr)
    add_library(tinyexpr::tinyexpr ALIAS meshfem_tinyexpr)
endif()

# Cholmod solver
# find_package(CHOLMOD REQUIRED) # provides cholmod::cholmod

# UmfPack solver
# find_package(UMFPACK REQUIRED) # provides umfpack::umfpack

################################################################################
# Optional libraries
################################################################################

# Ceres
if (MESHFEM_WITH_CERES AND NOT TARGET ceres::ceres)
    if (MESHFEM_PREFER_SYSTEM_CERES)
        find_package(Ceres QUIET)
         if(CERES_FOUND)
             add_library(ceres_lib INTERFACE)
             target_include_directories(ceres_lib SYSTEM INTERFACE  ${CERES_INCLUDE_DIRS})
             target_link_libraries(ceres_lib INTERFACE MeshFEM ${CERES_LIBRARIES})
             add_library(ceres::ceres ALIAS ceres_lib)
         endif()
    endif()
    if (NOT TARGET ceres::ceres)
        meshfem_download_ceres()
        list(APPEND CMAKE_MODULE_PATH ${MESHFEM_EXTERNAL}/ceres/cmake)
        find_package(Glog)
        if (NOT GLOG_FOUND)
            # Only fall back to MINIGLOG when glog is not installed.
            # Otherwise we will get linker errors if the code linking
            # to `ceres` mistakenly brings in the full `glog.h` due to
            # its include path order.
            option(MINIGLOG "" ON)
        else()
            option(MINIGLOG "" OFF)
        endif()
        set(BUILD_TESTING OFF CACHE BOOL " " FORCE)
        set(BUILD_DOCUMENTATION OFF CACHE BOOL " " FORCE)
        set(BUILD_EXAMPLES OFF CACHE BOOL " " FORCE)
        set(BUILD_BENCHMARKS OFF CACHE BOOL " " FORCE)
        get_target_property(EIGEN_INCLUDE_DIR_HINTS Eigen3::Eigen INTERFACE_INCLUDE_DIRECTORIES)
        set(EIGEN_PREFER_EXPORTED_EIGEN_CMAKE_CONFIGURATION FALSE)
        add_subdirectory(${MESHFEM_EXTERNAL}/ceres)
        add_library(ceres::ceres ALIAS ceres)
        meshfem_target_hide_warnings(ceres)
    endif()
elseif(NOT TARGET ceres::ceres)
    message(STATUS "Google's ceres-solver not found; MaterialOptimization_cli won't be built")
endif()
