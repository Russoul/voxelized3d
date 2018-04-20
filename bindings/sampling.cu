//
// Created by russoul on 12.04.18.
//

#include "helper_math.h"
#include "cuda_noise.cuh"
#include <device_launch_parameters.h>
#include <cstdlib>
#include <iostream>
#include <zconf.h>
#include <vector>
#include <sys/time.h>


#define gpuErrchk(ans) { gpuAssert((ans), __FILE__, __LINE__); }
inline void gpuAssert(cudaError_t code, const char *file, int line, bool abort=true)
{
    if (code != cudaSuccess)
    {
        fprintf(stderr,"GPUassert: %s %s %d\n", cudaGetErrorString(code), file, line);
        if (abort) exit(code);
    }
}

struct vec3f{
    float array[3];
};


__host__ __device__ __forceinline__ vec3f make_vec3f(float x, float y, float z){
    vec3f ret;
    ret.array[0] = x;
    ret.array[1] = y;
    ret.array[2] = z;

    return ret;
}

__host__ __device__ __forceinline__ vec3f operator+(vec3f a, vec3f b){
    vec3f ret;

    ret.array[0] = a.array[0] + b.array[0];
    ret.array[1] = a.array[1] + b.array[1];
    ret.array[2] = a.array[2] + b.array[2];

    return ret;
}

__host__ __device__ __forceinline__ vec3f operator-(vec3f a, vec3f b){
    vec3f ret;

    ret.array[0] = a.array[0] - b.array[0];
    ret.array[1] = a.array[1] - b.array[1];
    ret.array[2] = a.array[2] - b.array[2];

    return ret;
}


__host__ __device__ __forceinline__ vec3f operator*(vec3f a, float k){
    vec3f ret;

    ret.array[0] = a.array[0] * k;
    ret.array[1] = a.array[1] * k;
    ret.array[2] = a.array[2] * k;

    return ret;
}

__host__ __device__ __forceinline__ vec3f operator/(vec3f a, float k){
    vec3f ret;

    ret.array[0] = a.array[0] / k;
    ret.array[1] = a.array[1] / k;
    ret.array[2] = a.array[2] / k;

    return ret;
}

__host__ __device__ __forceinline__ float dot(vec3f a, vec3f b){
    return a.array[0] * b.array[0] + a.array[1] * b.array[1] + a.array[2] * b.array[2];
}

__host__ __device__ __forceinline__ float norm(vec3f a){
    return sqrtf(dot(a,a));
}

__host__ __device__ __forceinline__ vec3f normalize(vec3f a){
    return a / norm(a);
}

__host__ __device__ __forceinline__ vec3f fromFloat3(float3 a){
    return make_vec3f(a.x, a.y, a.z);
}

__host__ __device__ __forceinline__ float3 toFloat3(vec3f a){
    return make_float3(a.array[0], a.array[1], a.array[2]);
}


std::string dump_float3(float3 v){
    return "(x = " + std::to_string(v.x) + ", y = " + std::to_string(v.y) + ", z = " + std::to_string(v.z) + ")";
}

struct Line3{
    float3 start;
    float3 end;
};

//=============== uniform voxel storage ==================
struct HermiteData{
    float3 intersection;
    float3 normal;
};

struct UniformVoxelStorage{
    uint cellCount;
    float* grid;
    HermiteData** edgeInfo;
};
//========================================================


__constant__ int specialTable1[768];

__constant__ uint specialTable2[12];

__constant__ float3 cornerPoints[8];

__constant__ uint2 edgePairs[12];


inline __device__ __host__ uint indexDensity(uint cellCount, uint x, uint y, uint z){
    return z * (cellCount + 2) * (cellCount + 2) + y * (cellCount + 2) + x;
}

inline __device__ __host__ uint indexCell(uint cellCount, uint x, uint y, uint z){
    return z * (cellCount + 1) * (cellCount + 1) + y * (cellCount + 1) + x;
}

inline __device__ float denSphere(float3 offset, float rad, float3 p){
    return dot(p - offset, p - offset) - rad * rad;
}

inline __device__ float octaveNoise(size_t octaves, float persistence, float x, float y, float z, int seed){
    float total = 0.0F;
    float frequency = 1.0F;
    float amplitude = 1.0F;
    float maxValue = 0.0;

    float k = powf(2.0, octaves - 1);

    for (int i = 0; i < octaves; ++i) {
        total += cudaNoise::simplexNoise(make_float3(x * frequency / k, y * frequency / k, z * frequency / k),1, seed);
        maxValue += amplitude;
        amplitude *= persistence;
        frequency *= 2.0;
    }

    return total / maxValue;
}

inline __device__ float denFn(float3 p, int seed, float ymin, float extent){
    auto den = (cudaNoise::repeaterPerlin(make_float3(p.x, 0, p.z), 0.5F, seed, 8, 0.85, 0.95) + 1.01 )/2 * 2 * extent * 0.7F;
    return p.y - ymin - den;
   /* auto den = denSphere(make_float3(2,2,2), 2, p);
    return den;*/

}


inline __device__ void loadDensity(uint x, uint y, uint z, float3 offset, float a, UniformVoxelStorage storage, int seed, float ymin, float extent){
    auto p = offset + make_float3(x * a, y * a, z * a);
    auto den = denFn(p, seed, ymin, extent);
    //printf("%f for px=%f py=%f pz=%f x=%u y=%u z=%u i=%u a=%f size=%u\n", den, p.x, p.y, p.z, x,y,z, indexDensity(storage.cellCount, x,y,z),a,storage.cellCount);


    storage.grid[indexDensity(storage.cellCount, x,y,z)] = den;

    //printf("%f for px=%f py=%f pz=%f x=%u y=%u z=%u i=%u a=%f size=%u\n", storage.grid[indexDensity(storage.cellCount, x,y,z)], p.x, p.y, p.z, x,y,z, indexDensity(storage.cellCount, x,y,z),a,storage.cellCount);
}

__global__ void kernelLoadDensity(float3 offset, float a, UniformVoxelStorage storage, int seed, float ymin, float extent){
    int i = blockIdx.x * blockDim.x + threadIdx.x;

    //printf("kernel bx=%d, tx=%d\n", blockIdx.x, threadIdx.x);

    uint x = i % (storage.cellCount + 2);
    uint y = (i / (storage.cellCount + 2)) % (storage.cellCount + 2);
    uint z = (i / (storage.cellCount + 2) / (storage.cellCount + 2)) % (storage.cellCount + 2);

    loadDensity(x,y,z, offset, a, storage, seed, ymin, extent);
}

__device__ float3 sampleSurfaceIntersection(Line3 line, uint n, int seed, float ymin, float extent){
    auto ext = line.end - line.start;

    auto norm = length(ext);
    auto dir = ext / norm;

    auto center = line.start + ext * 0.5F;
    auto curExt = norm * 0.25F;

    for (int i = 0; i < n; ++i) {
        auto point1 = center - dir * curExt;
        auto point2 = center + dir * curExt;
        auto den1 = fabsf(denFn(point1, seed, ymin, extent));
        auto den2 = fabsf(denFn(point2, seed, ymin, extent));

        if(den1 <= den2){
            center = point1;
        }else{
            center = point2;
        }
    }

    return center;
}

__device__ float3 calculateNormal(float3 point, float eps, int seed, float ymin, float extent){
    float d = denFn(point, seed, ymin, extent);
    return normalize(make_float3(denFn(make_float3(point.x + eps, point.y, point.z), seed, ymin, extent) - d,
                                 denFn(make_float3(point.x, point.y + eps, point.z), seed, ymin, extent) - d,
                                 denFn(make_float3(point.x, point.y, point.z + eps), seed, ymin, extent) - d
    ));
}

__global__ void markCell(uint indexOffset, UniformVoxelStorage storage, bool* marks){
    int i = blockIdx.x * blockDim.x + threadIdx.x + indexOffset;

    uint x = i % (storage.cellCount + 1);
    uint y = (i / (storage.cellCount + 1)) % (storage.cellCount + 1);
    uint z = (i / (storage.cellCount + 1) / (storage.cellCount + 1)) % (storage.cellCount + 1);


    uint config = 0;

    if(storage.grid[indexDensity(storage.cellCount, x,y,z)] < 0.0){
        config |= 1;
    }
    if(storage.grid[indexDensity(storage.cellCount, x+1,y,z)] < 0.0){
        config |= 2;
    }
    if(storage.grid[indexDensity(storage.cellCount, x+1,y,z+1)] < 0.0){
        config |= 4;
    }
    if(storage.grid[indexDensity(storage.cellCount, x,y,z+1)] < 0.0){
        config |= 8;
    }

    if(storage.grid[indexDensity(storage.cellCount, x,y+1,z)] < 0.0){
        config |= 16;
    }
    if(storage.grid[indexDensity(storage.cellCount, x+1,y+1,z)] < 0.0){
        config |= 32;
    }
    if(storage.grid[indexDensity(storage.cellCount, x+1,y+1,z+1)] < 0.0){
        config |= 64;
    }
    if(storage.grid[indexDensity(storage.cellCount, x,y+1,z+1)] < 0.0){
        config |= 128;
    }



    if(specialTable1[3 * config] != -2){
        marks[i] = 1;
    }else{
        marks[i] = 0;
    }
}


bool operator <(float3 a, float3 b){
    if(a.x < b.x){
        return true;
    }else if(a.x > b.x){
        return false;
    }else{
        if(a.y < b.y){
            return true;
        }else if(a.y > b.y){
            return false;
        }else{
            if(a.z < b.z){
                return true;
            }else if(a.z >= b.z){
                return false;
            }
        }
    }
}

//TODO needed ?
//given two points in space (line): find the minimum one of two them (component-wise in lexical order) and then find floating point number alpha = sqrt((middle - min)*(middle - min)/(max - min)*(max - min))
//used for unique alpha identification
float makeAlphaComponent(float3 end1, float3 end2, float3 middle){
    if(end1 < end2){//min = end1, max = end2
        return sqrtf(dot(middle - end1,middle - end1) / dot(end2 - end1, end2 - end1));
    }else{
        return sqrtf(dot(middle - end2,middle - end2) / dot(end2 - end1, end2 - end1));
    }
}

float3 makeMiddleFromAlphaComponent(float3 end1, float3 end2, float alpha){
    if(end1 < end2){
        return end1 + normalize(end2 - end1) * alpha;
    }else{
        return end2 + normalize(end2 - end1) * alpha;
    }
}

__global__ void loadCell(uint indexOffset, float3 offset, float a, uint acc, UniformVoxelStorage storage, int seed, uint* marked, uint markedLen, HermiteData* data, float ymin, float extent){
    uint i_ = blockIdx.x * blockDim.x + threadIdx.x + indexOffset;

    if(i_ >= markedLen) return;


    uint i = marked[i_];

    uint x = i % (storage.cellCount + 1);
    uint y = (i / (storage.cellCount + 1)) % (storage.cellCount + 1);
    uint z = (i / (storage.cellCount + 1) / (storage.cellCount + 1)) % (storage.cellCount + 1);

    auto cellMin = offset + make_float3(x * a, y * a, z * a);

    uint config = 0;

    if(storage.grid[indexDensity(storage.cellCount, x,y,z)] < 0.0){
        config |= 1;
    }
    if(storage.grid[indexDensity(storage.cellCount, x+1,y,z)] < 0.0){
        config |= 2;
    }
    if(storage.grid[indexDensity(storage.cellCount, x+1,y,z+1)] < 0.0){
        config |= 4;
    }
    if(storage.grid[indexDensity(storage.cellCount, x,y,z+1)] < 0.0){
        config |= 8;
    }

    if(storage.grid[indexDensity(storage.cellCount, x,y+1,z)] < 0.0){
        config |= 16;
    }
    if(storage.grid[indexDensity(storage.cellCount, x+1,y+1,z)] < 0.0){
        config |= 32;
    }
    if(storage.grid[indexDensity(storage.cellCount, x+1,y+1,z+1)] < 0.0){
        config |= 64;
    }
    if(storage.grid[indexDensity(storage.cellCount, x,y+1,z+1)] < 0.0){
        config |= 128;
    }



    int* entry = specialTable1 + 3 * config;


    //printf("%u %u %d\n", i, config,  *entry);

    //if(*entry != -2){ this is guaranteed by markCell's
    int curEntry = entry[0];

    while(curEntry != -2){
        auto corners = edgePairs[curEntry];
        Line3 edge = {cellMin + cornerPoints[corners.x] * a, cellMin + cornerPoints[corners.y] * a};
        auto intersection = sampleSurfaceIntersection(edge, acc, seed, ymin, extent);
        auto normal = calculateNormal(intersection, a / 1024.0F, seed, ymin, extent);


        data[3 * i_ + specialTable2[curEntry]] = {intersection, normal};

        curEntry = *(++entry);
    }

    storage.edgeInfo[indexCell(storage.cellCount, x,y,z)] = data + 3 * i_;
    //}
}

extern "C" void testVec3f(float3 a){
    printf("x=%f, y=%f, z=%f\n", a.x, a.y, a.z);
    printf("sizeof float3 = %d\n", sizeof(float3));

}


unsigned long long timeMs(){
    struct timeval tv;

    gettimeofday(&tv, NULL);

    unsigned long long millisecondsSinceEpoch =
            (unsigned long long)(tv.tv_sec) * 1000 +
            (unsigned long long)(tv.tv_usec) / 1000;

    return millisecondsSinceEpoch;
}


extern "C" void sampleGPU(float3 offset, float a, uint acc, UniformVoxelStorage* storage){
    auto size = storage->cellCount;

    printf("info: ox=%f oy=%f oz=%f a=%f\n size=%d", offset.x, offset.y, offset.z, a, size);

    std::cout << "start" << std::endl;
    std::flush(std::cout);

    int seed = static_cast<int>(time(NULL));

    printf("seed=%i\n", seed);

    auto t7 = timeMs();
    cudaDeviceSetLimit(cudaLimitMallocHeapSize, 1024 * 1024 * 1024); //set 1G available memory

    float extent = size * a / 2;
    float ymin = offset.y;

    float* grid_d;
    HermiteData** edgeInfo_d;
    bool* marks_d; //TODO use bitmaps for more efficient storage of bools
    bool* marks = static_cast<bool *>(malloc(sizeof(bool) * (size + 1) * (size + 1) * (size + 1)));
    uint* marked_d;
    HermiteData* data_d;
    gpuErrchk(cudaMalloc(&grid_d, sizeof(float) * (size + 2) * (size + 2) * (size + 2)));
    gpuErrchk(cudaMalloc(&edgeInfo_d, sizeof(HermiteData*) * (size + 1)*(size + 1)*(size + 1)));
    gpuErrchk(cudaMalloc(&marks_d, sizeof(bool) * (size + 1)*(size + 1)*(size + 1)));
    cudaMemset(edgeInfo_d, 0, sizeof(HermiteData*) * (size + 1)*(size + 1)*(size + 1));
    auto t8 = timeMs();
    std::cout << "memory preallocation took " << (t8 - t7) << " ms" << std::endl;



    UniformVoxelStorage storage_d = {size, grid_d, edgeInfo_d};


    //std::cout << "before density" << std::endl;
    auto t1 = timeMs();
    kernelLoadDensity<<<(size+2)*(size+2),(size+2)>>>(offset, a, storage_d, seed, ymin, extent);
    gpuErrchk(cudaDeviceSynchronize());
    auto t2 = timeMs();

    std::cout << "density loading (GPU part) took " << (t2 - t1) << " ms" << std::endl;



    //std::cout << "after density" << std::endl;
    //std::flush(std::cout);

    auto t3 = timeMs();
    markCell<<<(size+1)*(size+1),(size+1)>>>(0, storage_d, marks_d);
    gpuErrchk(cudaDeviceSynchronize());
    auto t4 = timeMs();
    std::cout << "cell marking (GPU part) took " << (t4 - t3) << " ms" << std::endl;
    gpuErrchk(cudaMemcpy(marks, marks_d, sizeof(bool) * (size+1)*(size+1)*(size+1), cudaMemcpyDeviceToHost));

    std::vector<uint> indices;

    auto t10 = timeMs();
    for (uint l = 0; l < (size+1)*(size+1)*(size+1); ++l) {
        if(marks[l]){
            indices.push_back(l);
        }
    }
    auto t11 = timeMs();
    std::cout << "cell marking (CPU part) took " << (t11 - t10) << " ms" << std::endl;

    auto t12 = timeMs();
    gpuErrchk(cudaMalloc(&marked_d, sizeof(uint) * indices.size()));
    gpuErrchk(cudaMemcpy(marked_d, &indices[0], sizeof(uint) * indices.size(), cudaMemcpyHostToDevice));
    gpuErrchk(cudaFree(marks_d));
    gpuErrchk(cudaMalloc(&data_d, sizeof(HermiteData) * 3 * indices.size()));
    auto t13 = timeMs();
    std::cout << "mid allocation took " << (t13 - t12) << " ms" << std::endl;


    std::cout << "index count = " << indices.size() << std::endl;
    std::flush(std::cout);

    uint blockSize = 256;

    uint invokations = indices.size() / blockSize + 1;

    auto t5 = timeMs();
    loadCell<<<invokations,256>>>(0, offset, a, (uint)(log2f(acc) + 1), storage_d, seed, marked_d, indices.size(), data_d, ymin, extent);
    gpuErrchk(cudaDeviceSynchronize());
    auto t6 = timeMs();
    std::cout << "hermite data loading (GPU part) took " << (t6 - t5) << " ms" << std::endl;


    auto t15 = timeMs();
    gpuErrchk(cudaFree(marked_d));
    gpuErrchk(cudaMemcpy(storage->grid, storage_d.grid, sizeof(float) * (size + 2) * (size + 2) * (size + 2), cudaMemcpyDeviceToHost));
    gpuErrchk(cudaFree(grid_d));
    gpuErrchk(cudaMemcpy(storage->edgeInfo, storage_d.edgeInfo, sizeof(HermiteData*) * (size + 1) * (size + 1) * (size + 1), cudaMemcpyDeviceToHost));

    HermiteData* data = static_cast<HermiteData *>(malloc(sizeof(HermiteData) * 3 * indices.size())); //TODO pass back and free
    gpuErrchk(cudaMemcpy(data, data_d, sizeof(HermiteData) * 3 * indices.size(), cudaMemcpyDeviceToHost));


    #pragma omp parallel for
    for (int j = 0; j < (size + 1)*(size + 1)*(size + 1); ++j) {
        HermiteData* ptr_d = storage->edgeInfo[j];

        if(ptr_d){
            storage->edgeInfo[j] = (ptrdiff_t)(ptr_d - data_d) + data;
        }
    }

    gpuErrchk(cudaFree(edgeInfo_d));
    gpuErrchk(cudaFree(data_d));
    auto t16 = timeMs();
    std::cout << "post CPU took " << (t16 - t15) << " ms" << std::endl;

}


extern "C" void setConstantMem(){
    int specialTable1_local[256][3] = {


            {-2, -2, -2},
            {0, 3, 8},
            {0, -2, -2},
            {3, 8, -2},
            {-2, -2, -2},
            {0, 3, 8},
            {0, -2, -2},
            {3, 8, -2},
            {3, -2, -2},
            {0, 8, -2},
            {0, 3, -2},
            {8, -2, -2},
            {3, -2, -2},
            {0, 8, -2},
            {0, 3, -2},
            {8, -2, -2},
            {8, -2, -2},
            {0, 3, -2},
            {0, 8, -2},
            {3, -2, -2},
            {8, -2, -2},
            {0, 3, -2},
            {0, 8, -2},
            {3, -2, -2},
            {3, 8, -2},
            {0, -2, -2},
            {0, 3, 8},
            {-2, -2, -2},
            {3, 8, -2},
            {0, -2, -2},
            {0, 3, 8},
            {-2, -2, -2},
            {-2, -2, -2},
            {0, 3, 8},
            {0, -2, -2},
            {3, 8, -2},
            {-2, -2, -2},
            {0, 3, 8},
            {0, -2, -2},
            {3, 8, -2},
            {3, -2, -2},
            {0, 8, -2},
            {0, 3, -2},
            {8, -2, -2},
            {3, -2, -2},
            {0, 8, -2},
            {0, 3, -2},
            {8, -2, -2},
            {8, -2, -2},
            {0, 3, -2},
            {0, 8, -2},
            {3, -2, -2},
            {8, -2, -2},
            {0, 3, -2},
            {0, 8, -2},
            {3, -2, -2},
            {3, 8, -2},
            {0, -2, -2},
            {0, 3, 8},
            {-2, -2, -2},
            {3, 8, -2},
            {0, -2, -2},
            {0, 3, 8},
            {-2, -2, -2},
            {-2, -2, -2},
            {0, 3, 8},
            {0, -2, -2},
            {3, 8, -2},
            {-2, -2, -2},
            {0, 3, 8},
            {0, -2, -2},
            {3, 8, -2},
            {3, -2, -2},
            {0, 8, -2},
            {0, 3, -2},
            {8, -2, -2},
            {3, -2, -2},
            {0, 8, -2},
            {0, 3, -2},
            {8, -2, -2},
            {8, -2, -2},
            {0, 3, -2},
            {0, 8, -2},
            {3, -2, -2},
            {8, -2, -2},
            {0, 3, -2},
            {0, 8, -2},
            {3, -2, -2},
            {3, 8, -2},
            {0, -2, -2},
            {0, 3, 8},
            {-2, -2, -2},
            {3, 8, -2},
            {0, -2, -2},
            {0, 3, 8},
            {-2, -2, -2},
            {-2, -2, -2},
            {0, 3, 8},
            {0, -2, -2},
            {3, 8, -2},
            {-2, -2, -2},
            {0, 3, 8},
            {0, -2, -2},
            {3, 8, -2},
            {3, -2, -2},
            {0, 8, -2},
            {0, 3, -2},
            {8, -2, -2},
            {3, -2, -2},
            {0, 8, -2},
            {0, 3, -2},
            {8, -2, -2},
            {8, -2, -2},
            {0, 3, -2},
            {0, 8, -2},
            {3, -2, -2},
            {8, -2, -2},
            {0, 3, -2},
            {0, 8, -2},
            {3, -2, -2},
            {3, 8, -2},
            {0, -2, -2},
            {0, 3, 8},
            {-2, -2, -2},
            {3, 8, -2},
            {0, -2, -2},
            {0, 3, 8},
            {-2, -2, -2},
            {-2, -2, -2},
            {0, 3, 8},
            {0, -2, -2},
            {3, 8, -2},
            {-2, -2, -2},
            {0, 3, 8},
            {0, -2, -2},
            {3, 8, -2},
            {3, -2, -2},
            {0, 8, -2},
            {0, 3, -2},
            {8, -2, -2},
            {3, -2, -2},
            {0, 8, -2},
            {0, 3, -2},
            {8, -2, -2},
            {8, -2, -2},
            {0, 3, -2},
            {0, 8, -2},
            {3, -2, -2},
            {8, -2, -2},
            {0, 3, -2},
            {0, 8, -2},
            {3, -2, -2},
            {3, 8, -2},
            {0, -2, -2},
            {0, 3, 8},
            {-2, -2, -2},
            {3, 8, -2},
            {0, -2, -2},
            {0, 3, 8},
            {-2, -2, -2},
            {-2, -2, -2},
            {0, 3, 8},
            {0, -2, -2},
            {3, 8, -2},
            {-2, -2, -2},
            {0, 3, 8},
            {0, -2, -2},
            {3, 8, -2},
            {3, -2, -2},
            {0, 8, -2},
            {0, 3, -2},
            {8, -2, -2},
            {3, -2, -2},
            {0, 8, -2},
            {0, 3, -2},
            {8, -2, -2},
            {8, -2, -2},
            {0, 3, -2},
            {0, 8, -2},
            {3, -2, -2},
            {8, -2, -2},
            {0, 3, -2},
            {0, 8, -2},
            {3, -2, -2},
            {3, 8, -2},
            {0, -2, -2},
            {0, 3, 8},
            {-2, -2, -2},
            {3, 8, -2},
            {0, -2, -2},
            {0, 3, 8},
            {-2, -2, -2},
            {-2, -2, -2},
            {0, 3, 8},
            {0, -2, -2},
            {3, 8, -2},
            {-2, -2, -2},
            {0, 3, 8},
            {0, -2, -2},
            {3, 8, -2},
            {3, -2, -2},
            {0, 8, -2},
            {0, 3, -2},
            {8, -2, -2},
            {3, -2, -2},
            {0, 8, -2},
            {0, 3, -2},
            {8, -2, -2},
            {8, -2, -2},
            {0, 3, -2},
            {0, 8, -2},
            {3, -2, -2},
            {8, -2, -2},
            {0, 3, -2},
            {0, 8, -2},
            {3, -2, -2},
            {3, 8, -2},
            {0, -2, -2},
            {0, 3, 8},
            {-2, -2, -2},
            {3, 8, -2},
            {0, -2, -2},
            {0, 3, 8},
            {-2, -2, -2},
            {-2, -2, -2},
            {0, 3, 8},
            {0, -2, -2},
            {3, 8, -2},
            {-2, -2, -2},
            {0, 3, 8},
            {0, -2, -2},
            {3, 8, -2},
            {3, -2, -2},
            {0, 8, -2},
            {0, 3, -2},
            {8, -2, -2},
            {3, -2, -2},
            {0, 8, -2},
            {0, 3, -2},
            {8, -2, -2},
            {8, -2, -2},
            {0, 3, -2},
            {0, 8, -2},
            {3, -2, -2},
            {8, -2, -2},
            {0, 3, -2},
            {0, 8, -2},
            {3, -2, -2},
            {3, 8, -2},
            {0, -2, -2},
            {0, 3, 8},
            {-2, -2, -2},
            {3, 8, -2},
            {0, -2, -2},
            {0, 3, 8},
            {-2, -2, -2},

    };


    float3 cornerPoints_local[8] = {
            make_float3(0.0f, 0.0f, 0.0f),
            make_float3(1.0f, 0.0f, 0.0f), //clockwise starting from zero y min
            make_float3(1.0f, 0.0f, 1.0f),
            make_float3(0.0f, 0.0f, 1.0f),


            make_float3(0.0f, 1.0f, 0.0f),
            make_float3(1.0f, 1.0f, 0.0f), //y max
            make_float3(1.0f, 1.0f, 1.0f),
            make_float3(0.0f, 1.0f, 1.0f)
    };

    uint2 edgePairs_local[12] = {
            make_uint2(0,1),
            make_uint2(1,2),
            make_uint2(3,2),
            make_uint2(0,3),

            make_uint2(4,5),
            make_uint2(5,6),
            make_uint2(7,6),
            make_uint2(4,7),

            make_uint2(4,0),
            make_uint2(1,5),
            make_uint2(2,6),
            make_uint2(3,7)
    };

    for (int i = 0; i < 256; ++i) {
        gpuErrchk(cudaMemcpyToSymbol(specialTable1, specialTable1_local[i], sizeof(int) * 3, sizeof(int) * 3 * i));
    }


    uint specialTable2_local[12] = {0,1,0,1,0,1,0,1,2,2,2,2};

    gpuErrchk(cudaMemcpyToSymbol(specialTable2, specialTable2_local, sizeof(uint) * 12));


    gpuErrchk(cudaMemcpyToSymbol(cornerPoints, cornerPoints_local, sizeof(float3) * 8));
    gpuErrchk(cudaMemcpyToSymbol(edgePairs, edgePairs_local, sizeof(uint2) * 12));
}