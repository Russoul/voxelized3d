module hermite;


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

alias FP = float;

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
Vector3!FP[8] cornerPoints = [
                                    vec3!FP(0.0,0.0,0.0),
                                    vec3!FP(1.0,0.0,0.0), //clockwise starting from zero y min
                                    vec3!FP(1.0,0.0,1.0),
                                    vec3!FP(0.0,0.0,1.0),


                                    vec3!FP(0.0,1.0,0.0),
                                    vec3!FP(1.0,1.0,0.0), //y max
                                    vec3!FP(1.0,1.0,1.0),
                                    vec3!FP(0.0,1.0,1.0)
];

Vector3!float[8] cornerPointsf = [
                                    vec3!float(0.0,0.0,0.0),
                                    vec3!float(1.0,0.0,0.0), //clockwise starting from zero y min
                                    vec3!float(1.0,0.0,1.0),
                                    vec3!float(0.0,0.0,1.0),


                                    vec3!float(0.0,1.0,0.0),
                                    vec3!float(1.0,1.0,0.0), //y max
                                    vec3!float(1.0,1.0,1.0),
                                    vec3!float(0.0,1.0,1.0)
];

Vector3!FP[8] cornerPointsOrigin = [
                                    vec3!FP(-1.0,-1.0,-1.0),
                                    vec3!FP(1.0,-1.0,-1.0), //clockwise starting rom zero y min
                                    vec3!FP(1.0,-1.0,1.0),
                                    vec3!FP(-1.0,-1.0,1.0),


                                    vec3!FP(-1.0,1.0,-1.0),
                                    vec3!FP(1.0,1.0,-1.0), //y max
                                    vec3!FP(1.0,1.0,1.0),
                                    vec3!FP(-1.0,1.0,1.0)
];


const Vector2!uint[12] edgePairs = [
                                    vecS!([0u,1u]),
                                    vecS!([1u,2u]),
                                    vecS!([3u,2u]),
                                    vecS!([0u,3u]),

                                    vecS!([4u,5u]),
                                    vecS!([5u,6u]),
                                    vecS!([7u,6u]),
                                    vecS!([4u,7u]),

                                    vecS!([4u,0u]), //TODO can I change 4,0 to 0,4 here ?
                                    vecS!([1u,5u]),
                                    vecS!([2u,6u]),
                                    vecS!([3u,7u]),
];

//uniform hermite data
struct HermiteData(T){ //one of those for each edge that exhibits a sign change
    Vector3!T intersection;
    //T intersection; //alpha component along the edge, [0;1]
    Vector3!T normal;
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
        //clearing depends on sampling method ! on gpu its monolith array, on cpu its scattered arrays each of them needs to be freed


        free(edgeInfo);
    }
}


struct QEF(T){
    T a11;
    T a12;
    T a13;
    T a22;
    T a23;
    T a33;

    T b1;
    T b2;
    T b3;

    T r;

    Vector3!T massPoint;

    //ubyte n; //mass point dimension
    Vector3!T minimizer;//relative to mass point
}

const ubyte NODE_TYPE_INTERIOR = 1;
const ubyte NODE_TYPE_HOMOGENEOUS = 2;
const ubyte NODE_TYPE_HETEROGENEOUS = 3;


struct Node(T){//used just to avoid void* and store Node type(avoiding polymorphism)
    ubyte __node_type__;
    ubyte depth; //INVERTED! depth
} 

struct InteriorNode(T){
    ubyte __node_type__ = NODE_TYPE_INTERIOR;
    ubyte depth; //INVERTED! depth

    ubyte cornerSigns; //signs or corner points (1 bit - negative, 0 bit - positive)
    QEF!T qef; //merged qef
    Node!(T)*[8] children; //Node* can be any of 3 kind of nodes
}


struct HomogeneousNode(T){ //TODO tell D to make this struct 1 byte long(if possible)
    ubyte __node_type__ = NODE_TYPE_HOMOGENEOUS;
    ubyte depth; //INVERTED! depth

    bool isPositive; //sign of the corner samples
}

//Leaf node
struct HeterogeneousNode(T){
    ubyte __node_type__ = NODE_TYPE_HETEROGENEOUS;
    ubyte depth;

    ubyte cornerSigns; //signs or corner points (1 bit - negative, 0 bit - positive or zero)
    //same as config in umdc


    QEF!T qef;
    HermiteData!(T)*[12] hermiteData; //for each edge, set to null's automatically
    //uint index;//index into vertexBuffer of all minimizers (see how it is done in secret sause, prob remove it from here)

    ubyte getSign(ubyte p){
        return (cornerSigns >> p) & 1;
    }
}

struct AdaptiveVoxelStorage(T){
    uint cellCount; //cell count in one axis in dense uniform grid (when maximum tree depth is reached)
    ubyte maxDepth;
    Node!(T)* root;

    this(uint cellCount, Node!T* root){
        this.cellCount = cellCount;
        this.root = root;
        this.maxDepth = cast(ubyte) log2(cellCount);
    }
}


ubyte nodeType(T)(Node!(T)* node){
    return (*node).__node_type__;
}

InteriorNode!(T)* asInterior(T)(Node!T* node){
    return cast(InteriorNode!T*) node;
}

HeterogeneousNode!(T)* asHetero(T)(Node!T* node){
    return cast(HeterogeneousNode!T*) node;
}

HomogeneousNode!(T)* asHomo(T)(Node!T* node){
    return cast(HomogeneousNode!T*) node;
}

