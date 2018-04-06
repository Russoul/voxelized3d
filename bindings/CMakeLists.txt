cmake_minimum_required(VERSION 3.11)
project(voxelizedBindings)

set(CMAKE_CXX_STANDARD 11)

set(CMAKE_C_COMPILER=/usr/bin/clang)
set(CMAKE_CXX_COMPILER=/usr/bin/clang)

include_directories(../native/include)

add_library(voxelizedBindings STATIC FastNoise.h lib.cpp)