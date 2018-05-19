module amdcTaken;

import std.math;
import std.stdio;
import std.container.array;
import std.typecons;
import std.conv;
import core.stdc.string;
import std.datetime.stopwatch;
import std.parallelism;
import std.range;

import core.stdc.stdlib : malloc;

import math;
import matrix;
import util;
import traits;
import bindings;
import render;
import hermite;

import umdc;


Array!uint whichEdgesAreSignedAll(uint config){//TODO make special table for this

    int* entry = &edgeTable[config][0];


    auto edges = Array!uint();
    edges.reserve(3);

    for(size_t i = 0; i < 16; ++i){
        auto k = entry[i];
        if(k >= 0){
            edges.insertBack(k);
        }else if(k == -1){
            continue;
        }else{
            return edges;
        }
    }

    return edges;
}


void constructQEF(const ref Array!(Plane!float) planes, Vector3!float centroid, out QEF!float qef){
    auto n = planes.length;
    auto Ab = Array!float();
    Ab.reserve(n * 4);
    Ab.length = n * 4;

    import lapacke;

    for(size_t i = 0; i < n; ++i){
        Ab[4*i]   = planes[i].normal.x;
        Ab[4*i+1] = planes[i].normal.y;
        Ab[4*i+2] = planes[i].normal.z;

        Ab[4*i+3] = planes[i].normal.dot(planes[i].point - centroid);
    }

    

    float[4] tau;


    LAPACKE_sgeqrf(LAPACK_ROW_MAJOR, cast(int)n, 4, &Ab[0], 4, tau.ptr);

    auto A = zero!(float,3,3)();
    for(size_t i = 0; i < 3; ++i){
        for(size_t j = i; j < 3; ++j){
            A[i,j] = Ab[4*i + j];
        }
    }

    auto b = vec3!float(Ab[3], Ab[7], Ab[11]);

    qef.a11 = Ab[0];
    qef.a12 = Ab[1];
    qef.a13 = Ab[2];
    qef.a22 = Ab[5];
    qef.a23 = Ab[6];
    qef.a33 = Ab[10];

    qef.b1 = Ab[3];
    qef.b2 = Ab[7];
    qef.b3 = Ab[11];
    
    if(n >= 4){ //TODO ?
        qef.r = Ab[15];
    }else{
        qef.r = 0;
    }

    qef.massPoint = centroid;

    


    auto U = zero!(float,3,3);
    auto VT = U;

    auto S = zero!(float,3,1);

    float[2] cache;

    LAPACKE_sgesvd(LAPACK_ROW_MAJOR, 'A', 'A', 3, 3, A.array.ptr, 3, S.array.ptr, U.array.ptr, 3, VT.array.ptr, 3, cache.ptr);


    size_t dim = 3;

    foreach(i;0..3){
        if(S[i].abs() < 0.1F){
            --dim;
            S[i] = 0.0F;
        }else{
            S[i] = 1.0F / S[i];
        }
    }

    auto Sm = diag3(S[0], S[1], S[2]);

    auto pinv = mult(mult(VT.transpose(), Sm), U.transpose());

    auto minimizer = mult(pinv, b);

    //qef.n = cast(ubyte)dim;

    qef.minimizer = centroid + minimizer;

}

Node!(float)* sample(alias DenFn3)(ref DenFn3 f, Vector3!float offset, float a, size_t cellCount, size_t accuracy){

    ubyte maxDepth = cast(ubyte) log2(cellCount);

    

    auto size = cellCount;


    Array!ubyte signedGrid = Array!(ubyte)(); //TODO bit fields ?
    signedGrid.reserve((size + 1) * (size + 1) * (size + 1));
    signedGrid.length = (size + 1) * (size + 1) * (size + 1);
    

    Array!(Node!(float)*) grid = Array!(Node!(float)*)();
    grid.reserve(size * size * size);
    grid.length = size * size * size;


    pragma(inline,true)
    size_t indexDensity(size_t x, size_t y, size_t z){
        return z * (size + 1) * (size + 1) + y * (size + 1) + x;
    }


    pragma(inline,true)
    size_t indexCell(size_t x, size_t y, size_t z, size_t s = size){
        return z * s * s + y * s + x;
    }


    pragma(inline,true)
    Cube!float cube(size_t x, size_t y, size_t z){//cube bounds of a cell in the grid
        return Cube!float(offset + Vector3!float([(x + 0.5F)*a, (y + 0.5F) * a, (z + 0.5F) * a]), a / 2.0F);
    }

    pragma(inline, true)
    void sampleGridAt(size_t x, size_t y, size_t z){
        auto p = offset + vec3!float(x * a, y * a, z * a);
        immutable auto s = f(p);
        ubyte b;
        if(s < 0.0){
            b = 1;
        }
        signedGrid[indexDensity(x,y,z)] = b;
    }


    pragma(inline,true)
    void loadCell(size_t x, size_t y, size_t z){

        auto cellMin = offset + Vector3!float([x * a, y * a, z * a]);
        //immutable auto bounds = cube(x,y,z);

        uint config;


        if(signedGrid[indexDensity(x,y,z)]){
            config |= 1;
        }
        if(signedGrid[indexDensity(x+1,y,z)]){
            config |= 2;
        }
        if(signedGrid[indexDensity(x+1,y,z+1)]){
            config |= 4;
        }
        if(signedGrid[indexDensity(x,y,z+1)]){
            config |= 8;
        }

        if(signedGrid[indexDensity(x,y+1,z)]){
            config |= 16;
        }
        if(signedGrid[indexDensity(x+1,y+1,z)]){
            config |= 32;
        }
        if(signedGrid[indexDensity(x+1,y+1,z+1)]){
            config |= 64;
        }
        if(signedGrid[indexDensity(x,y+1,z+1)]){
            config |= 128;
        }

        if(config == 0){ //fully outside
            auto n = cast(HomogeneousNode!float*) malloc(HomogeneousNode!(float).sizeof);
            (*n).__node_type__ = NODE_TYPE_HOMOGENEOUS;
            (*n).isPositive = true;
            (*n).depth = maxDepth;
            grid[indexCell(x,y,z)] = cast(Node!float*)n;
        }else if(config == 255){ //fully inside
            auto n = cast(HomogeneousNode!float*) malloc(HomogeneousNode!(float).sizeof);
            (*n).__node_type__ = NODE_TYPE_HOMOGENEOUS;
            (*n).isPositive = false;
            (*n).depth = maxDepth;
            grid[indexCell(x,y,z)] = cast(Node!float*)n;
        }else{ //heterogeneous
            auto edges = whichEdgesAreSignedAll(config);

            auto n = cast(HeterogeneousNode!float*) malloc(HeterogeneousNode!(float).sizeof);
            (*n).__node_type__ = NODE_TYPE_HETEROGENEOUS;
            (*n).depth = maxDepth;


            auto planes = Array!(Plane!float)();
            Vector3!float centroid = zero3!float();

            foreach(curEntry; edges){
                import core.stdc.stdlib : malloc;
                HermiteData!(float)* data = cast(HermiteData!(float)*)malloc((HermiteData!float).sizeof); //TODO needs to be cleared

                auto corners = edgePairs[curEntry];
                auto edge = Line!(float,3)(cellMin + cornerPoints[corners.x] * a, cellMin + cornerPoints[corners.y] * a);
                auto intersection = sampleSurfaceIntersection!(DenFn3)(edge, cast(uint)accuracy.log2() + 1, f);
                auto normal = calculateNormal!(DenFn3)(intersection, a/1024.0F, f); //TODO division by 1024 is improper for very high sizes


                *data = HermiteData!float(intersection, normal);
                (*n).hermiteData[curEntry] = data;
                (*n).cornerSigns = cast(ubyte) config;

                centroid = centroid + intersection;
                planes.insertBack(Plane!float(intersection, normal));
            }

            centroid = centroid / planes.length;

            QEF!float qef;

            constructQEF(planes, centroid, qef);

            (*n).qef = qef;

            grid[indexCell(x,y,z)] = cast(Node!float*)n;
        }


    }


    pragma(inline,true)
    void simplify(size_t i, size_t j, size_t k, ref Array!(Node!(float)*) sparseGrid,
     ref Array!(Node!(float)*) denseGrid, size_t curSize, size_t curDepth){//depth is inverted

        auto n0 = denseGrid[indexCell(2*i, 2*j, 2*k, 2*curSize)];
        auto n1 = denseGrid[indexCell(2*i+1, 2*j, 2*k, 2*curSize)];
        auto n2 = denseGrid[indexCell(2*i+1, 2*j, 2*k+1, 2*curSize)];
        auto n3 = denseGrid[indexCell(2*i, 2*j, 2*k+1, 2*curSize)];

        auto n4 = denseGrid[indexCell(2*i, 2*j+1, 2*k, 2*curSize)];
        auto n5 = denseGrid[indexCell(2*i+1, 2*j+1, 2*k, 2*curSize)];
        auto n6 = denseGrid[indexCell(2*i+1, 2*j+1, 2*k+1, 2*curSize)];
        auto n7 = denseGrid[indexCell(2*i, 2*j+1, 2*k+1, 2*curSize)];

        Node!(float)*[8] nodes = [n0,n1,n2,n3,n4,n5,n6,n7];

        bool inited;
        bool isPositive;

        pragma(inline, true)
        void setInterior(){
            auto interior = cast(InteriorNode!(float)*) malloc(InteriorNode!(float).sizeof);
            (*interior).children = nodes;
            (*interior).depth = cast(ubyte) curDepth;
            (*interior).__node_type__ = NODE_TYPE_INTERIOR;

            sparseGrid[indexCell(i,j,k, curSize)] = cast(Node!(float)*)interior;
        }
        
        foreach(node; nodes){
            auto cur = (*node).__node_type__;
            if(cur == NODE_TYPE_HETEROGENEOUS || cur == NODE_TYPE_INTERIOR){
                setInterior();
                return;
            }else{ //homogeneous
                if(!inited){
                    inited = true;
                    isPositive = (*(cast(HomogeneousNode!(float)*) node)).isPositive;
                }else{
                    if((*(cast(HomogeneousNode!(float)*) node)).isPositive != isPositive){
                        setInterior();
                        return;
                    }
                }
            }  
        }

        //all cells are fully in or out
        auto homo = cast(HomogeneousNode!(float)*) malloc(HomogeneousNode!(float).sizeof);
        (*homo).isPositive = isPositive; 
        (*homo).depth = cast(ubyte) curDepth;
        (*homo).__node_type__ = NODE_TYPE_HOMOGENEOUS;

        sparseGrid[indexCell(i,j,k, curSize)] = cast(Node!(float)*)homo;
    }


    foreach(i; parallel(iota(0, (size+1) * (size+1) * (size+1) ))){
        auto z = i / (size+1) / (size+1);
        auto y = i / (size+1) % (size+1);
        auto x = i % (size+1);

        sampleGridAt(x,y,z);
    }

    foreach(i; parallel(iota(0, size * size * size ))){
        auto z = i / size / size;
        auto y = i / size % size;
        auto x = i % size;

        loadCell(x,y,z);
    }

    auto curSize = size;
    
    auto curDepth = maxDepth;

    while(curSize != 1){
        curSize /= 2;
        curDepth -= 1;

        Array!(Node!(float)*) sparseGrid = Array!(Node!(float)*)();
        sparseGrid.reserve(curSize * curSize * curSize);
        sparseGrid.length = (curSize * curSize * curSize);

        foreach(i; parallel(iota(0, curSize * curSize * curSize ))){
            auto z = i / curSize / curSize;
            auto y = i / curSize % curSize;
            auto x = i % curSize;

            simplify(x,y,z, sparseGrid, grid, curSize, curDepth);

            
        }

        grid = sparseGrid;
    }

    Node!(float)* tree = grid[0]; //grid contains only one element here

    return tree;

}


Vector3!float solveQEF(ref QEF!float qef){

    auto A = mat3!float(
        qef.a11, qef.a12, qef.a13,
        qef.a12, qef.a22, qef.a23,
        qef.a13, qef.a23, qef.a33
    );

    auto b = vec3!float(qef.b1, qef.b2, qef.b3);

    auto U = zero!(float,3,3);
    auto VT = U;

    auto S = zero!(float,3,1);

    float[2] cache;

    import lapacke;
    auto res = LAPACKE_sgesvd(LAPACK_ROW_MAJOR, 'A', 'A', 3, 3, A.array.ptr, 3, S.array.ptr, U.array.ptr, 3, VT.array.ptr, 3, cache.ptr);


    foreach(i;0..3){
        if(S[i].abs() < 0.1F){
            S[i] = 0.0F;
        }else{
            S[i] = 1.0F / S[i];
        }
    }

    auto Sm = diag3(S[0], S[1], S[2]);

    auto pinv = mult(mult(VT.transpose(), Sm), U.transpose());

    auto minimizer = mult(pinv, b);


    return minimizer;

}


void foreachHeterogeneousLeaf(alias f)(Node!(float)* node, Cube!float bounds){
    final switch(nodeType(node)){
        case NODE_TYPE_INTERIOR:
            auto interior = cast( InteriorNode!(float)* ) node;
            auto ch = (*interior).children;

            foreach(i;0..8){
                auto c = ch[i];
                auto tr = cornerPointsOrigin[i] * bounds.extent / 2;
                auto newBounds = Cube!(float)(bounds.center + tr, bounds.extent/2);

                foreachHeterogeneousLeaf!(f)(c, newBounds);
            }
            break;

        case NODE_TYPE_HOMOGENEOUS:
            break;
        case NODE_TYPE_HETEROGENEOUS:
            f( cast(HeterogeneousNode!float*)  node, bounds);
            break;

    }
}


void foreachLeaf(alias f)(Node!(float)* node, Cube!float bounds){
    final switch(nodeType(node)){
        case NODE_TYPE_INTERIOR:
            auto interior = cast( InteriorNode!(float)* ) node;
            auto ch = (*interior).children;

            foreach(i;0..8){
                auto c = ch[i];
                auto tr = cornerPointsOrigin[i] * bounds.extent / 2;
                auto newBounds = Cube!(float)(bounds.center + tr, bounds.extent/2);

                foreachLeaf!(f)(c, newBounds);
            }
            break;

        case NODE_TYPE_HOMOGENEOUS:
            f(node, bounds);
            break;
        case NODE_TYPE_HETEROGENEOUS:
            f(node, bounds);
            break;

    }
}


void faceProc(RenderVertFragDef dat, Node!float*[2] node, int dir, ref AdaptiveVoxelStorage!float storage){
    if(nodeType(node[0]) == NODE_TYPE_HOMOGENEOUS || nodeType(node[1]) == NODE_TYPE_HOMOGENEOUS){
        return;
    }

    auto type = [nodeType(node[0]), nodeType(node[1])];

    if(type[0] == NODE_TYPE_INTERIOR || type[1] == NODE_TYPE_INTERIOR){
        Node!float*[2] fcd;

        foreach(i;0..4){
            int[2] c = [faceProcFaceMask[dir][i][0], faceProcFaceMask[dir][i][1]];
            foreach(j;0..2){
                if(type[j] != NODE_TYPE_INTERIOR){
                    fcd[j] = node[j];
                }else{
                    fcd[j] = (*asInterior!float(node[j])).children[c[j]];
                }
            }

            faceProc(dat, fcd, faceProcFaceMask[dir][i][2], storage);
        }

        int[4][2] orders = [[ 0, 0, 1, 1 ], [ 0, 1, 0, 1 ]] ;

        Node!float*[4] ecd;

        foreach(i;0..4){
            int[4] c = [faceProcEdgeMask[dir][i][1], faceProcEdgeMask[dir][i][2], 
                        faceProcEdgeMask[dir][i][3], faceProcEdgeMask[dir][i][4]];
            int[4]* order = &orders[faceProcEdgeMask[dir][i][0]];
            foreach(j;0..4){
                if(type[(*order)[j]] != NODE_TYPE_INTERIOR){
                    ecd[j] = node[(*order)[j]];
                }else{
                    ecd[j] = (*asInterior!float(node[(*order)[j]])).children[c[j]];
                }
            }
            edgeProc(dat, ecd, faceProcEdgeMask[dir][i][5], storage);
        }
    }
}

void edgeProc(RenderVertFragDef dat, Node!float*[4] node, int dir, ref AdaptiveVoxelStorage!float storage){
    auto type = [nodeType(node[0]), nodeType(node[1]), nodeType(node[2]), nodeType(node[3])];

    if(type[0] == NODE_TYPE_HOMOGENEOUS || type[1] == NODE_TYPE_HOMOGENEOUS || type[2] == NODE_TYPE_HOMOGENEOUS || type[3] == NODE_TYPE_HOMOGENEOUS){
        return;
    }

    if(type[0] != NODE_TYPE_INTERIOR && type[1] != NODE_TYPE_INTERIOR && type[2] != NODE_TYPE_INTERIOR && type[3] != NODE_TYPE_INTERIOR){
        processEdge(dat, node, dir, storage);
    }else{
        Node!float*[4] ecd;
        foreach(i;0..2){
            int[4] c = [edgeProcEdgeMask[dir][i][0],
                        edgeProcEdgeMask[dir][i][1],
                        edgeProcEdgeMask[dir][i][2],
                        edgeProcEdgeMask[dir][i][3]];
            foreach(j;0..4){
                if(type[j] != NODE_TYPE_INTERIOR){
                    ecd[j] = node[j];
                }else{
                    ecd[j] = (*asInterior!float(node[j])).children[c[j]];
                }
            }

            edgeProc(dat, ecd, edgeProcEdgeMask[dir][i][4], storage);
        }
    }
}

void processEdge(RenderVertFragDef dat, Node!float*[4] node, int dir, ref AdaptiveVoxelStorage!float storage){
    
    auto color = vec3!float(1.0F,1.0F,1.0F);
    
    int type, ht, minht = storage.maxDepth + 1, mini = -1;
    int[4] sc, flip = [0,0,0,0];
    int flip2;


    foreach(i;0..4){
        auto lnode = asHetero(node[i]);
        int ed = processEdgeMask[dir][i];
        int c1 = edgevmap[ed][0];
        int c2 = edgevmap[ed][1];

        if( (*lnode).depth < minht){
            minht = (*lnode).depth;
            mini = i;
            if( (*lnode).getSign(cast(ubyte)c1) > 0){
                flip2 = 1;
            }else{
                flip2 = 0;
            }
        }

        if( (*lnode).getSign(cast(ubyte)c1) == (*lnode).getSign(cast(ubyte)c2) ){
            sc[i] = 0;
        }else{
            sc[i] = 1;
        }
    }

    if( sc[mini] == 1 ){

        auto nodes = [asHetero!float(node[0]), asHetero!float(node[1]), asHetero!float(node[2]), asHetero!float(node[3])];

        if(flip2 == 0){
            if(nodes[0] == nodes[1]){//same nodes => triangle
                addTriangleLinesColor(dat, Triangle!(float,3)( (*nodes[0]).qef.minimizer, (*nodes[3]).qef.minimizer, (*nodes[2]).qef.minimizer ), color);
            }else if(nodes[1] == nodes[3]){
                addTriangleLinesColor(dat, Triangle!(float,3)( (*nodes[0]).qef.minimizer, (*nodes[1]).qef.minimizer, (*nodes[2]).qef.minimizer ), color);
            }else if(nodes[3] == nodes[2]){
                addTriangleLinesColor(dat, Triangle!(float,3)( (*nodes[0]).qef.minimizer, (*nodes[1]).qef.minimizer, (*nodes[3]).qef.minimizer ), color);
            }else if(nodes[2] == nodes[0]){
                addTriangleLinesColor(dat, Triangle!(float,3)( (*nodes[1]).qef.minimizer, (*nodes[3]).qef.minimizer, (*nodes[2]).qef.minimizer ), color);
            }else{
                addTriangleLinesColor(dat, Triangle!(float,3)( (*nodes[0]).qef.minimizer, (*nodes[1]).qef.minimizer, (*nodes[3]).qef.minimizer ), color);
                addTriangleLinesColor(dat, Triangle!(float,3)( (*nodes[0]).qef.minimizer, (*nodes[3]).qef.minimizer, (*nodes[2]).qef.minimizer ), color);
            }
        }else{
            if(nodes[0] == nodes[1]){//same nodes => triangle
                addTriangleLinesColor(dat, Triangle!(float,3)( (*nodes[0]).qef.minimizer, (*nodes[2]).qef.minimizer, (*nodes[3]).qef.minimizer ), color);
            }else if(nodes[1] == nodes[3]){
                addTriangleLinesColor(dat, Triangle!(float,3)( (*nodes[0]).qef.minimizer, (*nodes[2]).qef.minimizer, (*nodes[1]).qef.minimizer ), color);
            }else if(nodes[3] == nodes[2]){
                addTriangleLinesColor(dat, Triangle!(float,3)( (*nodes[0]).qef.minimizer, (*nodes[3]).qef.minimizer, (*nodes[1]).qef.minimizer ), color);
            }else if(nodes[2] == nodes[0]){
                addTriangleLinesColor(dat, Triangle!(float,3)( (*nodes[1]).qef.minimizer, (*nodes[2]).qef.minimizer, (*nodes[3]).qef.minimizer ), color);
            }else{
                addTriangleLinesColor(dat, Triangle!(float,3)( (*nodes[0]).qef.minimizer, (*nodes[3]).qef.minimizer, (*nodes[1]).qef.minimizer ), color);
                addTriangleLinesColor(dat, Triangle!(float,3)( (*nodes[0]).qef.minimizer, (*nodes[2]).qef.minimizer, (*nodes[3]).qef.minimizer ), color);
            }
        }
    }
    
}

void cellProc(RenderVertFragDef dat, Node!float* node, ref AdaptiveVoxelStorage!float storage){
    if(nodeType(node) == NODE_TYPE_HOMOGENEOUS) return;

    auto type = nodeType(node);

    if(type == NODE_TYPE_INTERIOR){
        auto inode = asInterior(node);
        foreach(i;0..8){
            cellProc(dat, (*inode).children[i], storage);
        }

        foreach(i;0..12){
            int[2] c = [cellProcFaceMask[i][0], cellProcFaceMask[i][1]];
            Node!float*[2] fcd;
            fcd[0] = (*inode).children[c[0]];
            fcd[1] = (*inode).children[c[1]];
            faceProc(dat, fcd, cellProcFaceMask[i][2], storage);
        }

        foreach(i;0..6){
            int[4] c = [ cellProcEdgeMask[i][0], cellProcEdgeMask[i][1], cellProcEdgeMask[i][2], cellProcEdgeMask[i][3] ];
            Node!float*[4] ecd;
            foreach(j;0..4){
                ecd[j] = (*inode).children[c[j]];
            }

            edgeProc(dat, ecd, cellProcEdgeMask[i][4], storage);
        }
    }
}


// map from the 12 edges of the cube to the 8 vertices.
// example: edge 0 connects vertices 0,4
const int[2][12] edgevmap = [[0,4],[1,5],[2,6],[3,7],[0,2],[1,3],[4,6],[5,7],[0,1],[2,3],[4,5],[6,7]];
const int[3] edgemask = [ 5, 3, 6 ];

// direction from parent st to each of the eight child st
// st is the corner of the cube with minimum (x,y,z) coordinates
const int[3][8] vertMap = [[0,0,0],[0,0,1],[0,1,0],[0,1,1],[1,0,0],[1,0,1],[1,1,0],[1,1,1]] ;

// map from the 6 faces of the cube to the 4 vertices that bound the face
const int[4][6] faceMap = [[4, 8, 5, 9], [6, 10, 7, 11],[0, 8, 1, 10],[2, 9, 3, 11],[0, 4, 2, 6],[1, 5, 3, 7]] ;

// first used by cellProcCount()
// used in cellProcContour(). 
// between 8 child-nodes there are 12 faces.
// first two numbers are child-pairs, to be processed by faceProcContour()
// the last number is "dir" ?
const int[3][12] cellProcFaceMask = [[0,4,0],[1,5,0],[2,6,0],[3,7,0],[0,2,1],[4,6,1],[1,3,1],[5,7,1],[0,1,2],[2,3,2],[4,5,2],[6,7,2]] ;

// then used in cellProcContour() when calling edgeProc()
// between 8 children there are 6 common edges
// table lists the 4 children that share the edge
// the last number is "dir" ?
const int[5][6] cellProcEdgeMask = [[0,1,2,3,0],[4,5,6,7,0],[0,4,1,5,1],[2,6,3,7,1],[0,2,4,6,2],[1,3,5,7,2]] ;

// usde by faceProcCount()
const int[3][4][3] faceProcFaceMask = [
	[[4,0,0],[5,1,0],[6,2,0],[7,3,0]],
	[[2,0,1],[6,4,1],[3,1,1],[7,5,1]],
	[[1,0,2],[3,2,2],[5,4,2],[7,6,2]]
] ;
const int[6][4][3] faceProcEdgeMask = [
	[[1,4,0,5,1,1],[1,6,2,7,3,1],[0,4,6,0,2,2],[0,5,7,1,3,2]],
	[[0,2,3,0,1,0],[0,6,7,4,5,0],[1,2,0,6,4,2],[1,3,1,7,5,2]],
	[[1,1,0,3,2,0],[1,5,4,7,6,0],[0,1,5,0,4,1],[0,3,7,2,6,1]]
];
const int[5][2][3] edgeProcEdgeMask = [
	[[3,2,1,0,0],[7,6,5,4,0]],
	[[5,1,4,0,1],[7,3,6,2,1]],
	[[6,4,2,0,2],[7,5,3,1,2]],
];
const int[4][3] processEdgeMask = [[3,2,1,0],[7,5,6,4],[11,10,9,8]] ;

const int[3][4][3] dirCell = [
	[[0,-1,-1],[0,-1,0],[0,0,-1],[0,0,0]],
	[[-1,0,-1],[-1,0,0],[0,0,-1],[0,0,0]],
	[[-1,-1,0],[-1,0,0],[0,-1,0],[0,0,0]]
];
const int[4][3] dirEdge = [
	[3,2,1,0],
	[7,6,5,4],
	[11,10,9,8]
];
