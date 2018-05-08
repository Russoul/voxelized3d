module amdc;

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
import graphics;
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

    qef.n = cast(ubyte)dim;

    qef.minimizer = centroid + minimizer;

}

Node!(float)* sample(alias DenFn3)(ref DenFn3 f, Vector3!float offset, float a, size_t cellCount, size_t accuracy){



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
            grid[indexCell(x,y,z)] = cast(Node!float*)n;
        }else if(config == 255){ //fully inside
            auto n = cast(HomogeneousNode!float*) malloc(HomogeneousNode!(float).sizeof);
            (*n).__node_type__ = NODE_TYPE_HOMOGENEOUS;
            (*n).isPositive = false;
            grid[indexCell(x,y,z)] = cast(Node!float*)n;
        }else{ //heterogeneous
            auto edges = whichEdgesAreSignedAll(config);

            auto n = cast(HeterogeneousNode!float*) malloc(HeterogeneousNode!(float).sizeof);
            (*n).__node_type__ = NODE_TYPE_HETEROGENEOUS;


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
    
    auto curDepth = 0;

    while(curSize != 1){
        curSize /= 2;
        curDepth += 1;

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

// void generateIndices(Node!(float)* node, Cube!float bounds, ref Array!(Vector3!float) vertexBuffer){
//     foreachHeterogeneousLeaf!((node, bounds) => {
//         auto minimizer = solveQEF((*node).qef);
//         vertexBuffer.insertBack(minimizer);
//         (*node).index = cast(uint) vertexBuffer.length - 1;
//     })(node, bounds);
// }


auto faceProcTable = edgePairs; //cellProc ->12 faceProc's
auto faceProcTable2 = [vecS!([1,3]), vecS!([2,0]), vecS!([1,3]), vecS!([2,0]),
                       vecS!([1,3]), vecS!([2,0]), vecS!([1,3]), vecS!([2,0]),
                       vecS!([4,5]), vecS!([5,4]), vecS!([5,4]), vecS!([5,4]) ]; //face pairs
auto faceProcTable3 = [vecS!([0,1,5,4]), vecS!([1,2,6,5]), vecS!([3,2,6,7]), vecS!([0,3,7,4]), vecS!([3,2,1,0]), vecS!([7,6,5,4])]; //faceProc ->4 faceProc's
auto faceProcTable4 = [[[5,4, 8,9,11,10], [4,0, 0,4,2,6], [0,1, 9,8,10,11], [1,5, 4,0,6,2]],
                       [[6,5, 9,10,8,11], [5,1, 1,5,3,7], [1,2, 10,9,11,8], [2,6, 5,1,7,3]],
                       [[6,7, 11,10,8,9], [7,3, 2,6,0,4], [3,2, 10,11,9,8], [2,6, 6,2,4,0]],
                       [[7,4, 8,11,9,10], [4,0, 3,7,1,5], [0,3, 11,8,10,9], [3,7, 7,3,5,1]],
                       [[1,0, 3,1,7,5], [0,3, 2,0,6,4], [3,2, 1,3,5,7], [2,1, 0,2,4,6]],
                       [[5,4, 7,5,3,1], [4,7, 6,4,2,0], [7,6, 5,7,1,3], [6,5, 4,6,0,2]]]; //faceProc ->4 edgeProc's
auto faceProcTable5 = [ //faceProc face type -> edgeProc dir
    [2,1,2,1], [2,0,2,0], [2,1,2,1], [2,0,2,0], [0,1,0,1], [0,1,0,1]
];

auto edgeProcTable = [vecS!([0,1,5,4, 5,7,3,1]), vecS!([1,2,6,5, 6,4,0,2]), vecS!([2,3,7,6, 5,7,3,1]), vecS!([3,0,4,7, 6,4,0,2]), vecS!([0,1,2,3, 10,11,8,9]), vecS!([4,5,6,7, 10,11,8,9])]; //cellProc ->6 edgeProc


Vector2!uint[12] edgeProcTable2 = [
                                    vecS!([0u,1u]),
                                    vecS!([1u,2u]),
                                    vecS!([3u,2u]),
                                    vecS!([0u,3u]),

                                    vecS!([4u,5u]),
                                    vecS!([5u,6u]),
                                    vecS!([7u,6u]),
                                    vecS!([4u,7u]),

                                    vecS!([0u,4u]),
                                    vecS!([1u,5u]),
                                    vecS!([2u,6u]),
                                    vecS!([3u,7u]),
];

void faceProc(RenderVertFragDef renderer, Node!(float)* a, Node!(float)* b, uint ai, uint bi){

    
    switch(nodeType(a)){
        case NODE_TYPE_INTERIOR:

            auto aint = cast( InteriorNode!(float)* ) a;
            auto t1 = faceProcTable3[ai];
            auto n1 = &faceProcTable4[ai];

            
            switch(nodeType(b)){
                case NODE_TYPE_INTERIOR: //both nodes are internal
                    auto bint = cast( InteriorNode!(float)* ) b;

                    auto t2 = faceProcTable3[bi];
                    auto n2 = &faceProcTable4[bi];

                    foreach(i;0..4){
                        faceProc(renderer, aint.children[t1[i]], bint.children[t2[i]], ai, bi);
                        
                        edgeProc(renderer, aint.children[(*n1)[i][0]], aint.children[(*n1)[i][1]], bint.children[(*n2)[i][0]], bint.children[(*n2)[i][1]], (*n1)[i][2], (*n1)[i][3], (*n1)[i][4], (*n1)[i][5]);
                    }

                    break;

                default:
                    foreach(i;0..4){
                        faceProc(renderer, aint.children[t1[i]], b, ai, bi);

                        edgeProc(renderer, aint.children[(*n1)[i][0]], aint.children[(*n1)[i][1]], b, b, (*n1)[i][2], (*n1)[i][3], (*n1)[i][4], (*n1)[i][5]);
                    }

                    break;
            }

            break;
            
        default:

            switch(nodeType(b)){
                case NODE_TYPE_INTERIOR:
                    auto bint = cast( InteriorNode!(float)* ) b;

                    auto t2 = faceProcTable3[bi];
                    auto n2 = &faceProcTable4[bi];

                    foreach(i;0..4){
                        faceProc(renderer, a, bint.children[t2[i]], ai, bi);

                        edgeProc(renderer, a, a, bint.children[(*n2)[i][0]], bint.children[(*n2)[i][1]], (*n2)[i][2], (*n2)[i][3], (*n2)[i][4], (*n2)[i][5]);
                    }

                    break;

                default:
                    break;
            }

            break;
    }
}



void edgeProc(RenderVertFragDef renderer, Node!(float)* a, Node!(float)* b, Node!(float)* c, Node!(float)* d, size_t ai, size_t bi, size_t ci, size_t di){
    auto types = [nodeType(a), nodeType(b), nodeType(c), nodeType(d)];
    auto nodes = [a,b,c,d];
    auto configs = [ai,bi,ci,di];

    if(types[0] == NODE_TYPE_HOMOGENEOUS || types[1] == NODE_TYPE_HOMOGENEOUS || types[2] == NODE_TYPE_HOMOGENEOUS || types[3] == NODE_TYPE_HOMOGENEOUS){
        return;
    }

    if(types[0] != NODE_TYPE_INTERIOR && types[1] != NODE_TYPE_INTERIOR && types[2] != NODE_TYPE_INTERIOR && types[3] != NODE_TYPE_INTERIOR){ //none of the nodes are interior
        //all nodes are heterogeneous
        //TODO make the condition computation faster ^^^ only one check is needed if NODE_TYPE_X are set correctly
        //generate 
       

        Vector3!float[4] pos;
        Vector3!float color = vecS!([1.0F,1.0F,1.0F]);
        Vector3!float normal;

        size_t index = -1;
        size_t minInvDepth = size_t.max; //== find node with max depth
        

        foreach(i;0..4){
            auto node = cast(HeterogeneousNode!float*) nodes[i];
            auto p = edgePairs[configs[i]];
            auto p1 = (node.cornerSigns >> p.x) & 1;
            auto p2 = (node.cornerSigns >> p.y) & 1;

            if(p1 != p2 && node.depth < minInvDepth){
                index = i;
                minInvDepth = node.depth;
            }
        }

        if(index == -1) return;

        foreach(i;0..4){
            auto node = cast(HeterogeneousNode!float*) nodes[i];
            //auto minimizer = solveQEF((*node).qef); //TODO DUPLICATION, use buffers to calc this one time
            pos[i] = node.qef.minimizer;
            
              
        }

        auto node = (* cast(HeterogeneousNode!float*) nodes[index]);

        normal = node.hermiteData[configs[index]].normal;

        addTriangleColorNormal(renderer, Triangle!(float,3)(pos[0], pos[1], pos[2]),color, normal);

        addTriangleColorNormal(renderer, Triangle!(float,3)(pos[0], pos[2], pos[3]),color, normal);

        

        

    }else{//subdivide
        Node!(float)*[4] sub1;
        Node!(float)*[4] sub2;
        foreach(i;0..4){
            if(types[i] != NODE_TYPE_INTERIOR){
                sub1[i] = nodes[i];
                sub2[i] = nodes[i];
            }else{
                auto interior = cast( InteriorNode!(float)* ) nodes[i];
                auto p = edgeProcTable2[configs[i]];
                sub1[i] = interior.children[p.x];
                sub2[i] = interior.children[p.y];
            }
        }

        edgeProc(renderer, sub1[0], sub1[1], sub1[2], sub1[3], ai, bi, ci, di);
        edgeProc(renderer, sub2[0], sub2[1], sub2[2], sub2[3], ai, bi, ci, di);
    }
}

void cellProc(RenderVertFragDef renderer, Node!(float)* node){
    switch(nodeType(node)){
        case NODE_TYPE_INTERIOR:
            auto interior = cast( InteriorNode!(float)* ) node;
            auto ch = (*interior).children;

            foreach(i;0..8){
                auto c = ch[i];
                cellProc(renderer, c); //ok
            }

            foreach(i;0..12){
                auto pair = faceProcTable[i];
                auto facePair = faceProcTable2[i];
                faceProc(renderer, ch[pair[0]], ch[pair[1]], facePair[0], facePair[1]); //ok
            }

            foreach(i;0..6){
                auto tuple8 = edgeProcTable[i];
                edgeProc(renderer, ch[tuple8.x], ch[tuple8.y], ch[tuple8.z], ch[tuple8.w], tuple8[4], tuple8[5], tuple8[6], tuple8[7]);
            }


            break;
            
        default: break;
    }
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