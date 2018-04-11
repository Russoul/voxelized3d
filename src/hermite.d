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
    Array!(HermiteData!(T)[3]) data; //of length `(cellCount+1)^3`
    Array!(HermiteData!(T)[3]*) edgeInfo; //of length (cellCount+1)^3
    //extra one cell in each axis is required for data and edgeInfo because each cell contains only 3 tagged edges (number 3, 4 and 11 in the edge table)

    this(size_t cellCount){
        this.cellCount = cellCount;

        grid = Array!(T)(); //initialization is not needed as each value will be set anyway
        grid.reserve( (cellCount + 1) * (cellCount + 1) * (cellCount + 1));
        grid.length = (cellCount + 1) * (cellCount + 1) * (cellCount + 1);

        data = Array!(HermiteData!(T)[3])();
        data.reserve((cellCount + 1)*(cellCount + 1)*(cellCount + 1));
        //data.length = cellCount*cellCount*cellCount;

        edgeInfo = Array!(HermiteData!(T)[3]*)();
        edgeInfo.reserve((cellCount + 1)*(cellCount + 1)*(cellCount + 1));
        edgeInfo.length = (cellCount + 1)*(cellCount + 1)*(cellCount + 1);

        memset(&edgeInfo[0], 0, (HermiteData!(T)[3]*).sizeof * (cellCount + 1) * (cellCount + 1) * (cellCount + 1)); //initialize all pointers to null
    }
}


