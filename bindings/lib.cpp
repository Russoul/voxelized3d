#include <iostream>

#include "FastNoise.h"

extern "C" {


    void* allocFastNoise(){
        FastNoise noise;
        auto * ptr = static_cast<FastNoise *>(malloc(sizeof(FastNoise)));
        *ptr = noise;
        return ptr;
    }

    void freeFastNoise(void* noise){
        free(noise);
    }

    void setFrequency(void* noise, FN_DECIMAL freq){
        ((FastNoise*)noise)->SetFrequency(freq);
    }

    void setSeed(void* noise, int seed){
        ((FastNoise*)noise)->SetSeed(seed);
    }

    void setNoiseType(void* noise, FastNoise::NoiseType type){
        ((FastNoise*)noise)->SetNoiseType(type);
    }

    FN_DECIMAL getValue(void* noise, FN_DECIMAL x, FN_DECIMAL y, FN_DECIMAL z){
        return ((FastNoise*)noise)->GetValue(x,y,z);
    }

    FN_DECIMAL getPerlin(void* noise, FN_DECIMAL x, FN_DECIMAL y, FN_DECIMAL z){
        return ((FastNoise*)noise)->GetValue(x,y,z);
    }
};

#include <sys/resource.h>

extern "C" void setStackSize(size_t MB)
{
    const rlim_t kStackSize = MB * 1024 * 1024;   // min stack size = 16 MB
    struct rlimit rl;
    int result;

    result = getrlimit(RLIMIT_STACK, &rl);
    if (result == 0)
    {
        if (rl.rlim_cur < kStackSize)
        {
            rl.rlim_cur = kStackSize;
            result = setrlimit(RLIMIT_STACK, &rl);
            if (result != 0)
            {
                fprintf(stderr, "setrlimit returned result = %d\n", result);
            }
        }
    }

}