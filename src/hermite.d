module hermite;


import std.math;
import std.stdio;
import std.container.array;
import std.container.slist;
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
    uint index;//index of the minimizer (one for each minimizer)
    Array!uint indices;//indexing into vertexBuffer TODO switch to SList ?

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

struct VoxelRenderData(T){ //this structure is used for storing topology/geometry in an efficient way

    alias PolygonIndex = Tuple!(uint, "i", bool, "isQuad");

    Array!float vertexBuffer;
    Array!uint indexBufferTriangles;
    Array!uint indexBufferQuads;
    Array!(HeterogeneousNode!T*) ptr; //TODO preallocate arrays based on estimate vertex/triangle count ?
    Array!(SList!PolygonIndex) polygons;


    //we use two separate index buffers for triangles and quads
    //quads allow us to safe extra memory by sending only 4 vertices to GPU vs 6 when using triangles to render a quad

    //all arrays are indexed the same way, all have equal size

    auto VERTEX_SIZE = VERTEX_SIZE_POS_COLOR_NORMAL;

    void preallocateBuffersBasedOnNodeCount(){
        //vertexBuffer.reserve(ptr.length * VERTEX_SIZE);
        //vertexBuffer.length = ptr.length * VERTEX_SIZE;

        polygons.reserve(ptr.length);
        polygons.length = ptr.length;

        foreach(i;0..ptr.length){
            polygons[i] = SList!(PolygonIndex)();
        }
    }

    private void addFloat3(Vector3!float v){
        vertexBuffer.insertBack(v.x);
        vertexBuffer.insertBack(v.y);
        vertexBuffer.insertBack(v.z);
    }

    private void setFloat3(uint i, Vector3!float v){
        vertexBuffer[i] = v.x;
        vertexBuffer[i+1] = v.y;
        vertexBuffer[i+2] = v.z;
    }

    private uint getVertexCount(){
        return cast(uint)vertexBuffer.length / VERTEX_SIZE;
    }

    private void addTriangleColorNormal(HeterogeneousNode!T*[3] nodes, Vector3!float[3] tri, Vector3!float color, Vector3!float normal){

        foreach(i;0..3){
            addFloat3(tri[i]);
            addFloat3(color);
            addFloat3(normal);

            nodes[i].indices.insertBack(getVertexCount() - 1);

            indexBufferTriangles.insertBack(getVertexCount() - 1);
        }


        auto geoIndex = cast(uint)indexBufferTriangles.length / 3 - 1;

        PolygonIndex index;
        index.i = geoIndex;
        index.isQuad = false;

        foreach(i;0..3){
            polygons[nodes[i].index].insertFront(index);
        }
    }

    private void addQuadrilateralColorNormal(HeterogeneousNode!T*[4] nodes, Vector3!float[4] pos, Vector3!float color, Vector3!float normal){

        auto indexPre = getVertexCount();

        foreach(i;0..4){
            addFloat3(pos[i]);
            addFloat3(color);
            addFloat3(normal);

            nodes[i].indices.insertBack(getVertexCount() - 1);
        }



        indexBufferQuads.insertBack(indexPre);
        indexBufferQuads.insertBack(indexPre + 1);
        indexBufferQuads.insertBack(indexPre + 2);

        indexBufferQuads.insertBack(indexPre);
        indexBufferQuads.insertBack(indexPre + 2);
        indexBufferQuads.insertBack(indexPre + 3);

        auto geoIndex = cast(uint)indexBufferQuads.length / 6 - 1;

        PolygonIndex index;
        index.i = geoIndex;
        index.isQuad = true;


        foreach(i;0..4){
            polygons[nodes[i].index].insertFront(index);
        }

    }

    void addTriangle(T)(HeterogeneousNode!T*[3] nodes, Vector3!float[3] pos,
                       Vector3!float color, Vector3!float normal){     
        addTriangleColorNormal(nodes, pos, color, normal);
    }

    void addQuadrilateral(HeterogeneousNode!T*[4] nodes, Vector3!float[4] pos,
                       Vector3!float color, Vector3!float normal){
        addQuadrilateralColorNormal(nodes, pos, color, normal);
    }

    private void removeFrontPolygon(uint POLYGON_SIZE)(uint topologyIndex, ref Array!uint indexBuffer){
        
        uint offset = topologyIndex * POLYGON_SIZE;

        foreach(i;0..POLYGON_SIZE){ //remove vertices that are pointed by indices of the polygon
            uint index = offset + i; //indices point to continious 3 to 4 vertices
            //memcpy(&vertexBuffer[0] + index, &vertexBuffer[0] + index + VERTEX_SIZE * POLYGON_SIZE, float.sizeof *  VERTEX_SIZE * POLYGON_SIZE);
            //^^ better not move the whole thing as ALL indices will be invalidated but instead move the last one to the current deleted one
            //one problem arises: some polygons are of size 3 and some of size 4
        }

        memcpy(&indexBuffer[0] + offset, &indexBuffer[0] + offset + POLYGON_SIZE, indexBuffer.length - offset);

        polygons[nodeIndex].popFront();

        foreach(ref list; polygons){
            foreach(ref item; list){
                if(item.i >= offset){//actually offset + POLYGON_SIZE but it is the same as no polygons remain that refer to that range
                    item.i -= POLYGON_SIZE;
                }
            }
        }

    }


    private void removeFrontPolygon(uint nodeIndex){
        uint ps = polygons[nodeIndex].front.i; //dont forget to pop it
        bool isQuad = polygons[nodeIndex].front.isQuad;

       if(isQuad){
           removeFrontPolygon!(4)(ps, indexBufferQuads);
       }else{
           removeFrontPolygon!(3)(ps, indexBufferTriangles);
       }

       polygons[nodeIndex].popFront();
    }

    private void removeVertex1(uint vertexIndex){
        if(polygons[vertexIndex].empty) return;

        removeFrontPolygon(vertexIndex);

        removeVertex1(vertexIndex);
    }

    private void removeVertex(uint vertexIndex){
        removeVertex1(vertexIndex);

        memcpy();
    }

    private void removeNodeData(HeterogeneousNode!T* node){

        SList!uint* ps = &polygons[node.index];

        foreach(i;node.indices){//index into vertex buffer

        }

        foreach(p; *ps){
            uint[POLYGON_SIZE] polygonIndices;
            foreach(i;0..POLYGON_SIZE){
                polygonIndices[i] = indexBuffer[p * POLYGON_SIZE + i];
            }
        }
    }

    RenderVertFragDef makeColorNormalRenderer(){
        auto renderer = new RenderVertFragDef("lighting", GL_TRIANGLES, () => setAttribPtrsNormal());

        //writeln("makeColorNormalRenderer1");
        //stdout.flush();

        renderer.vertexPool = vertexBuffer;
        renderer.indexPool.reserve(indexBufferTriangles.length + indexBufferQuads.length);
        renderer.indexPool.length = indexBufferTriangles.length + indexBufferQuads.length;

        if(indexBufferTriangles.length > 0)//is can be zero when the grid is not simplified
            memcpy(&renderer.indexPool[0], &indexBufferTriangles[0], uint.sizeof * indexBufferTriangles.length);
       
        if(indexBufferQuads.length > 0)
            memcpy(&renderer.indexPool[0] + indexBufferTriangles.length, &indexBufferQuads[0], uint.sizeof * indexBufferQuads.length);

        renderer.vertexCount = cast(uint)vertexBuffer.length / VERTEX_SIZE;

        return renderer;
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

