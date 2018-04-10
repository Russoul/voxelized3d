module hermite.uniform;


import std.math;
import std.stdio;
import std.container.array;
import std.typecons;
import std.conv;
import core.stdc.string;
import std.datetime.stopwatch;
import std.parallelism;
import std.range;

import math;
import matrix;
import util;
import traits;
import graphics;
import render;



//uniform hermite data
struct HermiteData(T){ //one of those for each edge that exhibits a sign change
    Vector3!T intersection;
    Vector3!T normal;
}

struct UniformVoxelStorage(T){
    size_t cellCount;
    Array!T grid; //of length `(cellCount+1)^3`
    Array!(HermiteData!(T)[3]) data; //of length `cellCount^3`

    this(size_t cellCount){
        this.cellCount = cellCount;

        grid = Array!(T)(); //initialization is not need as each values will be set anyway
        grid.reserve( (cellCount + 1) * (cellCount + 1) * (cellCount + 1));
        grid.length = (cellCount + 1) * (cellCount + 1) * (cellCount + 1);

        data = Array!(HermiteData!(T)[3])();
        data.reserve(cellCount*cellCount*cellCount);
        data.length = cellCount*cellCount*cellCount;

        memset(&data[0], 0, 3 * (HermiteData!T).sizeof * cellCount * cellCount * cellCount); //initialize all pointers to null
    }
}


