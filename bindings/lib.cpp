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
