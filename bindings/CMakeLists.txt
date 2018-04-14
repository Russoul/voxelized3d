cmake_minimum_required(VERSION 3.11)
project(voxelizedBindings)

set(CMAKE_CXX_STANDARD 11)

set(CMAKE_C_COMPILER=/usr/bin/clang)
set(CMAKE_CXX_COMPILER=/usr/bin/clang)

include_directories(../native/include)

find_package(CUDA QUIET REQUIRED)

set(CMAKE_VERBOSE_MAKEFILE ON)

link_directories(${CUDA_TOOLKIT_ROOT_DIR}/lib64)

set(
        CUDA_NVCC_FLAGS
        ${CUDA_NVCC_FLAGS};
        -arch=compute_30 -rdc=false -lcudadevrt -Xptxas -O3 -Xcompiler -O3# not needed for static lib
)

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

cuda_add_library(voxelizedBindings STATIC helper_math.h FastNoise.h FastNoise.cpp cuda_noise.cuh lib.cpp sampling.cu)