cmake_minimum_required(VERSION 3.9)
project(voxelizedBindings)

set(CMAKE_CXX_STANDARD 11)

set(CMAKE_C_COMPILER=/usr/bin/clang)
set(CMAKE_CXX_COMPILER=/usr/bin/clang++)

include_directories(include)

find_package(CUDA QUIET REQUIRED)

set(CMAKE_VERBOSE_MAKEFILE ON)

link_directories(${CUDA_TOOLKIT_ROOT_DIR}/lib64)

#set(
#        CUDA_NVCC_FLAGS
#        ${CUDA_NVCC_FLAGS};
#        -arch=compute_30 -rdc=false -lcudadevrt -Xptxas -O3 -Xcompiler -O3# not needed for static lib
#)

find_package(OpenMP)
if (OPENMP_FOUND)
    message("USING OPENMP !")
    set (CMAKE_C_FLAGS "${CMAKE_C_FLAGS} ${OpenMP_C_FLAGS}")
    set (CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${OpenMP_CXX_FLAGS}")
    set (CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} ${OpenMP_EXE_LINKER_FLAGS}")

    set(
            CUDA_NVCC_FLAGS
            ${CUDA_NVCC_FLAGS};
            -Xcompiler -fopenmp
    )

endif()

#set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -msse4.1") //SIMD noise (not used for now)

include_directories(.)

set(CONTOURING  contouring/eigen.cpp contouring/eigen.h contouring/GeoCommon.h contouring/HashMap.h contouring/PLYReader.h contouring/PLYWriter.h contouring/octree.cpp contouring/octree.h contouring/intersection.h contouring/qef.cpp)

cuda_add_library(voxelizedBindings STATIC helper_math.h FastNoise.h FastNoise.cpp cuda_noise.cuh lib.cpp sampling.cu glad.c ${CONTOURING})

install(TARGETS voxelizedBindings DESTINATION /usr/local/lib)

add_executable(DC contouring/dc.cpp)

target_link_libraries(DC voxelizedBindings)