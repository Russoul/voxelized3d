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



//for each cell configuration(of 256 possible) tells if there are edges {0,3,8} in that cell, {-2} is used to stop reading the array(of 3 elements) futher
int[3][256] specialTable1 = [
                            [-2, -2, -2],
                            [0, 3, 8],
                            [0, -2, -2],
                            [3, 8, -2],
                            [-2, -2, -2],
                            [0, 3, 8],
                            [0, -2, -2],
                            [3, 8, -2],
                            [3, -2, -2],
                            [0, 8, -2],
                            [0, 3, -2],
                            [8, -2, -2],
                            [3, -2, -2],
                            [0, 8, -2],
                            [0, 3, -2],
                            [8, -2, -2],
                            [8, -2, -2],
                            [0, 3, -2],
                            [0, 8, -2],
                            [3, -2, -2],
                            [8, -2, -2],
                            [0, 3, -2],
                            [0, 8, -2],
                            [3, -2, -2],
                            [3, 8, -2],
                            [0, -2, -2],
                            [0, 3, 8],
                            [-2, -2, -2],
                            [3, 8, -2],
                            [0, -2, -2],
                            [0, 3, 8],
                            [-2, -2, -2],
                            [-2, -2, -2],
                            [0, 3, 8],
                            [0, -2, -2],
                            [3, 8, -2],
                            [-2, -2, -2],
                            [0, 3, 8],
                            [0, -2, -2],
                            [3, 8, -2],
                            [3, -2, -2],
                            [0, 8, -2],
                            [0, 3, -2],
                            [8, -2, -2],
                            [3, -2, -2],
                            [0, 8, -2],
                            [0, 3, -2],
                            [8, -2, -2],
                            [8, -2, -2],
                            [0, 3, -2],
                            [0, 8, -2],
                            [3, -2, -2],
                            [8, -2, -2],
                            [0, 3, -2],
                            [0, 8, -2],
                            [3, -2, -2],
                            [3, 8, -2],
                            [0, -2, -2],
                            [0, 3, 8],
                            [-2, -2, -2],
                            [3, 8, -2],
                            [0, -2, -2],
                            [0, 3, 8],
                            [-2, -2, -2],
                            [-2, -2, -2],
                            [0, 3, 8],
                            [0, -2, -2],
                            [3, 8, -2],
                            [-2, -2, -2],
                            [0, 3, 8],
                            [0, -2, -2],
                            [3, 8, -2],
                            [3, -2, -2],
                            [0, 8, -2],
                            [0, 3, -2],
                            [8, -2, -2],
                            [3, -2, -2],
                            [0, 8, -2],
                            [0, 3, -2],
                            [8, -2, -2],
                            [8, -2, -2],
                            [0, 3, -2],
                            [0, 8, -2],
                            [3, -2, -2],
                            [8, -2, -2],
                            [0, 3, -2],
                            [0, 8, -2],
                            [3, -2, -2],
                            [3, 8, -2],
                            [0, -2, -2],
                            [0, 3, 8],
                            [-2, -2, -2],
                            [3, 8, -2],
                            [0, -2, -2],
                            [0, 3, 8],
                            [-2, -2, -2],
                            [-2, -2, -2],
                            [0, 3, 8],
                            [0, -2, -2],
                            [3, 8, -2],
                            [-2, -2, -2],
                            [0, 3, 8],
                            [0, -2, -2],
                            [3, 8, -2],
                            [3, -2, -2],
                            [0, 8, -2],
                            [0, 3, -2],
                            [8, -2, -2],
                            [3, -2, -2],
                            [0, 8, -2],
                            [0, 3, -2],
                            [8, -2, -2],
                            [8, -2, -2],
                            [0, 3, -2],
                            [0, 8, -2],
                            [3, -2, -2],
                            [8, -2, -2],
                            [0, 3, -2],
                            [0, 8, -2],
                            [3, -2, -2],
                            [3, 8, -2],
                            [0, -2, -2],
                            [0, 3, 8],
                            [-2, -2, -2],
                            [3, 8, -2],
                            [0, -2, -2],
                            [0, 3, 8],
                            [-2, -2, -2],
                            [-2, -2, -2],
                            [0, 3, 8],
                            [0, -2, -2],
                            [3, 8, -2],
                            [-2, -2, -2],
                            [0, 3, 8],
                            [0, -2, -2],
                            [3, 8, -2],
                            [3, -2, -2],
                            [0, 8, -2],
                            [0, 3, -2],
                            [8, -2, -2],
                            [3, -2, -2],
                            [0, 8, -2],
                            [0, 3, -2],
                            [8, -2, -2],
                            [8, -2, -2],
                            [0, 3, -2],
                            [0, 8, -2],
                            [3, -2, -2],
                            [8, -2, -2],
                            [0, 3, -2],
                            [0, 8, -2],
                            [3, -2, -2],
                            [3, 8, -2],
                            [0, -2, -2],
                            [0, 3, 8],
                            [-2, -2, -2],
                            [3, 8, -2],
                            [0, -2, -2],
                            [0, 3, 8],
                            [-2, -2, -2],
                            [-2, -2, -2],
                            [0, 3, 8],
                            [0, -2, -2],
                            [3, 8, -2],
                            [-2, -2, -2],
                            [0, 3, 8],
                            [0, -2, -2],
                            [3, 8, -2],
                            [3, -2, -2],
                            [0, 8, -2],
                            [0, 3, -2],
                            [8, -2, -2],
                            [3, -2, -2],
                            [0, 8, -2],
                            [0, 3, -2],
                            [8, -2, -2],
                            [8, -2, -2],
                            [0, 3, -2],
                            [0, 8, -2],
                            [3, -2, -2],
                            [8, -2, -2],
                            [0, 3, -2],
                            [0, 8, -2],
                            [3, -2, -2],
                            [3, 8, -2],
                            [0, -2, -2],
                            [0, 3, 8],
                            [-2, -2, -2],
                            [3, 8, -2],
                            [0, -2, -2],
                            [0, 3, 8],
                            [-2, -2, -2],
                            [-2, -2, -2],
                            [0, 3, 8],
                            [0, -2, -2],
                            [3, 8, -2],
                            [-2, -2, -2],
                            [0, 3, 8],
                            [0, -2, -2],
                            [3, 8, -2],
                            [3, -2, -2],
                            [0, 8, -2],
                            [0, 3, -2],
                            [8, -2, -2],
                            [3, -2, -2],
                            [0, 8, -2],
                            [0, 3, -2],
                            [8, -2, -2],
                            [8, -2, -2],
                            [0, 3, -2],
                            [0, 8, -2],
                            [3, -2, -2],
                            [8, -2, -2],
                            [0, 3, -2],
                            [0, 8, -2],
                            [3, -2, -2],
                            [3, 8, -2],
                            [0, -2, -2],
                            [0, 3, 8],
                            [-2, -2, -2],
                            [3, 8, -2],
                            [0, -2, -2],
                            [0, 3, 8],
                            [-2, -2, -2],
                            [-2, -2, -2],
                            [0, 3, 8],
                            [0, -2, -2],
                            [3, 8, -2],
                            [-2, -2, -2],
                            [0, 3, 8],
                            [0, -2, -2],
                            [3, 8, -2],
                            [3, -2, -2],
                            [0, 8, -2],
                            [0, 3, -2],
                            [8, -2, -2],
                            [3, -2, -2],
                            [0, 8, -2],
                            [0, 3, -2],
                            [8, -2, -2],
                            [8, -2, -2],
                            [0, 3, -2],
                            [0, 8, -2],
                            [3, -2, -2],
                            [8, -2, -2],
                            [0, 3, -2],
                            [0, 8, -2],
                            [3, -2, -2],
                            [3, 8, -2],
                            [0, -2, -2],
                            [0, 3, 8],
                            [-2, -2, -2],
                            [3, 8, -2],
                            [0, -2, -2],
                            [0, 3, 8],
                            [-2, -2, -2],
                            ];

//maps:
//  0 -> 0
//  3 -> 1
//  8 -> 2
size_t[12] specialTable2 = [0,1,0,1,0,1,0,1,2,2,2,2];

//tells where to find an edge given cell its local(to a cell) index
//returns zero vector if the edge is located in the given vertex(for edges {0,3,8}) else returns an (cell) offset vector ( [0..1,0..1,0..1] ) (always non-negative)
Vector3!(size_t)[12] specialTable3 = [
    vec3!size_t(0,0,0),
    vec3!size_t(1,0,0),
    vec3!size_t(0,0,1),
    vec3!size_t(0,0,0),

    vec3!size_t(0,1,0),
    vec3!size_t(1,1,0),
    vec3!size_t(0,1,1),
    vec3!size_t(0,1,0),

    vec3!size_t(0,0,0),
    vec3!size_t(1,0,0),
    vec3!size_t(1,0,1),
    vec3!size_t(0,0,1)
];

//TODO move this to a better place(because it is also used outside of the isosurface extraction problem)
Vector3!float[8] cornerPoints = [
                                    vecS!([0.0f,0.0f,0.0f]),
                                    vecS!([1.0f,0.0f,0.0f]), //clockwise starting from zero y min
                                    vecS!([1.0f,0.0f,1.0f]),
                                    vecS!([0.0f,0.0f,1.0f]),


                                    vecS!([0.0f,1.0f,0.0f]),
                                    vecS!([1.0f,1.0f,0.0f]), //y max
                                    vecS!([1.0f,1.0f,1.0f]),
                                    vecS!([0.0f,1.0f,1.0f])
];


Vector2!uint[12] edgePairs = [
                                    vecS!([0u,1u]),
                                    vecS!([1u,2u]),
                                    vecS!([3u,2u]),
                                    vecS!([0u,3u]),

                                    vecS!([4u,5u]),
                                    vecS!([5u,6u]),
                                    vecS!([7u,6u]),
                                    vecS!([4u,7u]),

                                    vecS!([4u,0u]),
                                    vecS!([1u,5u]),
                                    vecS!([2u,6u]),
                                    vecS!([3u,7u]),
];

//uniform hermite data
struct HermiteData(T){ //one of those for each edge that exhibits a sign change
    Vector3!float intersection;
    Vector3!float normal;
}

struct UniformVoxelStorage(T){
    uint cellCount;
    T* grid; //of length `(cellCount+2)^3` //extra one is needed
    HermiteData!(T)** edgeInfo; //of length (cellCount+1)^3
    //extra one cell in each axis is required for edgeInfo because each cell contains only 3 tagged edges (number 0, 3 and 8 in the edge table)

    this(uint cellCount){
        this.cellCount = cellCount;

        import core.stdc.stdlib : malloc;

        grid = cast(float*) malloc((cellCount + 2) * (cellCount + 2) * (cellCount + 2) * T.sizeof); //initialization is not needed as each value will be set anyway


        edgeInfo = cast(HermiteData!(T)**) malloc((cellCount + 1)*(cellCount + 1)*(cellCount + 1) * (HermiteData!(T)*).sizeof);

        memset(&edgeInfo[0], 0, (HermiteData!(T)*).sizeof * (cellCount + 1) * (cellCount + 1) * (cellCount + 1)); //initialize all pointers to null
    }

    @disable this(this);

    ~this(){
        import core.stdc.stdlib : free;

        free(grid); 
        // foreach(i; 0..(cellCount + 1)*(cellCount + 1)*(cellCount + 1)){
        //     free(edgeInfo[i]);
        // }
        //clearing dependends on sampling method ! on gpu its monolith array, on cpu its scattered arrays each of them needs to be freed


        free(edgeInfo);
    }
}


