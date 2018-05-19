module amdc;

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

import core.stdc.stdlib : malloc, free;

import math;
import matrix;
import util;
import traits;
import graphics;
import render;
import hermite;

import umdc : edgeTable, sampleSurfaceIntersection, calculateNormal;

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


void constructQEF1(T)(const ref Array!(Plane!T) planes, Vector3!T centroid, out QEF!T qef){
    auto n = planes.length;
    auto Ab = Array!T();
    Ab.reserve(n * 4);
    Ab.length = n * 4;


    //auto Ab = zero!(float, 12,4);

    

    import lapacke;

    for(size_t i = 0; i < n; ++i){
        Ab[4*i+0]   = planes[i].normal.x;
        Ab[4*i+1] = planes[i].normal.y;
        Ab[4*i+2] = planes[i].normal.z;

        Ab[4*i+3] = planes[i].normal.dot(planes[i].point - centroid);
    }

    //TODO test ATA * x = ATb
    // auto A1 = Array!T();
    // A1.reserve(n * 3);
    // A1.length = n * 3;

    // for(size_t i = 0; i < n; ++i){
    //     A1[3*i+0] = planes[i].normal.x;
    //     A1[3*i+1] = planes[i].normal.y;
    //     A1[3*i+2] = planes[i].normal.z;
    // }

    // auto AT = Array!T();
    // AT.reserve(3 * n);
    // AT.length = 3 * n;

    // transpose(&A1[0], n, 3, &AT[0]);

    // Matrix3!T ATA;

    // mult(&AT[0], &A1[0], 3,n,3, &ATA[0,0]);

    // auto b1 = Array!T();
    // b1.reserve(n);
    // b1.length = n;

    // foreach(i;0..n){
    //     b1[i] = planes[i].normal.dot(planes[i].point - centroid);
    // }


    // Vector3!T ATB;

    // mult(&AT[0], &b1[0], 3,3,1, &ATB[0]);



    T[4] tau;

    static if( is(T == float) )
        LAPACKE_sgeqrf(LAPACK_ROW_MAJOR, cast(int)n, 4, &Ab[0], 4, tau.ptr);
    else static if( is(T == double) )
        LAPACKE_dgeqrf(LAPACK_ROW_MAJOR, cast(int)n, 4, &Ab[0], 4, tau.ptr);
    else
        panic!void("not implemented");


    auto A = zero!(T,3,3)();
    for(size_t i = 0; i < 3; ++i){
        for(size_t j = i; j < 3; ++j){
            A[i,j] = Ab[4*i + j];
        }
    }



    auto b = vec3!T(Ab[3], Ab[7], Ab[11]);


    T rs;
    if(n >= 4){
        rs = Ab[15] * Ab[15];
    }else{
        rs = 0;
    }


    qef.a11 = A[0,0];
    qef.a12 = A[0,1];
    qef.a13 = A[0,2];
    qef.a22 = A[1,1];
    qef.a23 = A[1,2];
    qef.a33 = A[2,2];
    qef.b1 = b[0];
    qef.b2 = b[1];
    qef.b3 = b[2];
    qef.r = rs;
    qef.massPoint = centroid;


    auto U = zero!(T,3,3);
    auto VT = U;

    auto S = zero!(T,3,1);

    T[2] cache;

    //TODO use method for sym matrices
    static if( is(T == float) )
        LAPACKE_sgesvd(LAPACK_ROW_MAJOR, 'A', 'A', 3, 3, A.array.ptr, 3, S.array.ptr, U.array.ptr, 3, VT.array.ptr, 3, cache.ptr);
    else static if( is(T == double) )
        LAPACKE_dgesvd(LAPACK_ROW_MAJOR, 'A', 'A', 3, 3, A.array.ptr, 3, S.array.ptr, U.array.ptr, 3, VT.array.ptr, 3, cache.ptr);
    else
        panic!void("not implemented");


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

    qef.minimizer = minimizer;


    //qef.n = cast(ubyte)dim;

}


//this QEF representation uses QR decomposition and primary - floats
void constructQEF(T)(const ref Array!(Plane!T) planes, Vector3!T centroid, out QEF!T qef){

    import lapacke;

    auto n = planes.length;
    auto Ab = Array!T();
    Ab.reserve(n * 4);
    Ab.length = n * 4;


    for(size_t i = 0; i < n; ++i){
        Ab[4*i+0]   = planes[i].normal.x;
        Ab[4*i+1] = planes[i].normal.y;
        Ab[4*i+2] = planes[i].normal.z;

        Ab[4*i+3] = planes[i].normal.dot(planes[i].point - centroid);
    }

    T[4] tau;

    static if( is(T == float) )
        LAPACKE_sgeqrf(LAPACK_ROW_MAJOR, cast(int)n, 4, &Ab[0], 4, tau.ptr);
    else static if( is(T == double) )
        LAPACKE_dgeqrf(LAPACK_ROW_MAJOR, cast(int)n, 4, &Ab[0], 4, tau.ptr);
    else
        panic!void("not implemented");


    T rs;
    if(n >= 4){
        rs = Ab[15] * Ab[15];
    }else{
        rs = 0;
    }


    qef.a11 = Ab[0];
    qef.a12 = Ab[1];
    qef.a13 = Ab[2];
    qef.a22 = Ab[5];
    qef.a23 = Ab[6];
    qef.a33 = Ab[10];
    qef.b1 = Ab[3];
    qef.b2 = Ab[7];
    qef.b3 = Ab[11];
    qef.r = rs;
    qef.massPoint = centroid;


}

void solveQEF(T)(ref QEF!T qef){


    Matrix3!T A = zero!(T,3,3);

    A[0,0] = qef.a11;
    A[0,1] = qef.a12;
    A[0,2] = qef.a13;
    A[1,1] = qef.a22;
    A[1,2] = qef.a23;
    A[2,2] = qef.a33;

    Vector3!T b;
    b[0] = qef.b1;
    b[1] = qef.b2;
    b[2] = qef.b3;



    import lapacke;

   
    auto U = zero!(T,3,3);
    auto VT = U;

    auto S = zero!(T,3,1);

    T[2] cache;

    //TODO use method for sym matrices
    static if( is(T == float) )
        LAPACKE_sgesvd(LAPACK_ROW_MAJOR, 'A', 'A', 3, 3, A.array.ptr, 3, S.array.ptr, U.array.ptr, 3, VT.array.ptr, 3, cache.ptr);
    else static if( is(T == double) )
        LAPACKE_dgesvd(LAPACK_ROW_MAJOR, 'A', 'A', 3, 3, A.array.ptr, 3, S.array.ptr, U.array.ptr, 3, VT.array.ptr, 3, cache.ptr);
    else
        panic!void("not implemented");


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

    qef.minimizer = minimizer;

}



bool mergeQEFs1(T)(QEF!T** qef, size_t count, out QEF!T collapsed, T thres){

    auto Ab = Array!T();
    Ab.reserve(16 * count);
    Ab.length = 16 * count;

    import lapacke;



    foreach(i;0..count){
       Ab[16*i + 0] = qef[i].a11;
       Ab[16*i + 1] = qef[i].a12;
       Ab[16*i + 2] = qef[i].a13;
       Ab[16*i + 3] = qef[i].b1;
       Ab[16*i + 4] = 0;
       Ab[16*i + 5] = qef[i].a22;
       Ab[16*i + 6] = qef[i].a23;
       Ab[16*i + 7] = qef[i].b2;
       Ab[16*i + 8] = 0;
       Ab[16*i + 9] = 0;
       Ab[16*i + 10] = qef[i].a33;
       Ab[16*i + 11] = qef[i].b3;
       Ab[16*i + 12] = 0;
       Ab[16*i + 13] = 0;
       Ab[16*i + 14] = 0;
       Ab[16*i + 15] = qef[i].r;
    }

    

    T[4] tau;

    static if( is(T == float) )
        LAPACKE_sgeqrf(LAPACK_ROW_MAJOR, 4 * cast(int)count, 4, &Ab[0], 4, tau.ptr);
    else static if( is(T == double) )
        LAPACKE_dgeqrf(LAPACK_ROW_MAJOR, 4 * cast(int)count, 4, &Ab[0], 4, tau.ptr);
    else
        panic!void("not implemented");

    //writeln("after");
    //writeln(Ab.array);

    collapsed.r = Ab[15] * Ab[15];


    if(collapsed.r > thres){
        return false;
    }

    auto A = zero!(T,3,3)();
    for(size_t i = 0; i < 3; ++i){
        for(size_t j = i; j < 3; ++j){
            A[i,j] = Ab[4*i + j];
        }
    }

    auto b = vec3!T(Ab[3], Ab[7], Ab[11]);

    collapsed.a11 = Ab[0];
    collapsed.a12 = Ab[1];
    collapsed.a13 = Ab[2];
    collapsed.a22 = Ab[5];
    collapsed.a23 = Ab[6];
    collapsed.a33 = Ab[10];

    collapsed.b1 = Ab[3];
    collapsed.b2 = Ab[7];
    collapsed.b3 = Ab[11];
    
    size_t dim = qef[0].n;
    Vector3!T centroid = qef[0].massPoint;
    size_t ccount = 1;
    
    

    foreach(j;1..count){
        if(qef[j].n == dim){
            centroid = centroid + qef[j].massPoint;
            ccount += 1;
        }
        else if(qef[j].n > dim){
            dim = qef[j].n;
            centroid = qef[j].massPoint;
            ccount = 1;
        }
    }

    

    centroid = centroid / ccount;


    //writeln(centroid);


    collapsed.massPoint = centroid;
    collapsed.n = cast(ubyte)dim;

    


    auto U = zero!(T,3,3);
    auto VT = U;

    auto S = zero!(T,3,1);

    T[2] cache;

    static if( is(T == float) )
        LAPACKE_sgesvd(LAPACK_ROW_MAJOR, 'A', 'A', 3, 3, A.array.ptr, 3, S.array.ptr, U.array.ptr, 3, VT.array.ptr, 3, cache.ptr);
    else static if( is(T == double) )
        LAPACKE_dgesvd(LAPACK_ROW_MAJOR, 'A', 'A', 3, 3, A.array.ptr, 3, S.array.ptr, U.array.ptr, 3, VT.array.ptr, 3, cache.ptr);
    else
        panic!void("not implemented");

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

    

    collapsed.minimizer = minimizer;


    return true;

}

bool mergeQEFs(T)(QEF!T** qef, size_t count, out QEF!T collapsed, T thres){

    auto Ab = Array!T();
    Ab.reserve(16 * count);
    Ab.length = 16 * count;

    import lapacke;

    foreach(i;0..count){
       Ab[16*i + 0] = qef[i].a11;
       Ab[16*i + 1] = qef[i].a12;
       Ab[16*i + 2] = qef[i].a13;
       Ab[16*i + 3] = qef[i].b1;
       Ab[16*i + 4] = 0;
       Ab[16*i + 5] = qef[i].a22;
       Ab[16*i + 6] = qef[i].a23;
       Ab[16*i + 7] = qef[i].b2;
       Ab[16*i + 8] = 0;
       Ab[16*i + 9] = 0;
       Ab[16*i + 10] = qef[i].a33;
       Ab[16*i + 11] = qef[i].b3;
       Ab[16*i + 12] = 0;
       Ab[16*i + 13] = 0;
       Ab[16*i + 14] = 0;
       Ab[16*i + 15] = qef[i].r;
    }

    

    T[4] tau;

    static if( is(T == float) )
        LAPACKE_sgeqrf(LAPACK_ROW_MAJOR, 4 * cast(int)count, 4, &Ab[0], 4, tau.ptr);
    else static if( is(T == double) )
        LAPACKE_dgeqrf(LAPACK_ROW_MAJOR, 4 * cast(int)count, 4, &Ab[0], 4, tau.ptr);
    else
        panic!void("not implemented");


    collapsed.r = Ab[15] * Ab[15];


    if(collapsed.r > thres){
        return false;
    }


    collapsed.a11 = Ab[0];
    collapsed.a12 = Ab[1];
    collapsed.a13 = Ab[2];
    collapsed.a22 = Ab[5];
    collapsed.a23 = Ab[6];
    collapsed.a33 = Ab[10];

    collapsed.b1 = Ab[3];
    collapsed.b2 = Ab[7];
    collapsed.b3 = Ab[11];
    
    Vector3!T centroid = qef[0].massPoint;
    size_t ccount = 1;
    
    

    foreach(j;1..count){
        centroid = centroid + qef[j].massPoint;
        ccount += 1;
    }

    centroid = centroid / ccount;

    collapsed.massPoint = centroid;

    return true;

}

Node!(T)* sample(T, alias DenFn3, bool SIMPLIFY)(ref DenFn3 f, Vector3!T offset, T a, size_t cellCount, size_t accuracy,
     T thres, ref VoxelRenderData!T renderData){

    ubyte maxDepth = cast(ubyte) log2(cellCount);
    

    auto size = cellCount;


    Array!ubyte signedGrid = Array!(ubyte)(); //TODO bit fields ?
    signedGrid.reserve((size + 1) * (size + 1) * (size + 1));
    signedGrid.length = (size + 1) * (size + 1) * (size + 1);
    

    Array!(Node!(T)*) grid = Array!(Node!(T)*)();
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
    Cube!T cube(size_t x, size_t y, size_t z){//cube bounds of a cell in the grid
        return Cube!T(offset + Vector3!T([(x + 0.5F)*a, (y + 0.5F) * a, (z + 0.5F) * a]), a / 2.0F);
    }

    pragma(inline, true)
    void sampleGridAt(size_t x, size_t y, size_t z){
        auto p = offset + vec3!T(x * a, y * a, z * a);
        immutable auto s = f(p);
        ubyte b;
        if(s < 0.0){
            b = 1;
        }
        signedGrid[indexDensity(x,y,z)] = b;
    }


    pragma(inline,true)
    void loadCell(size_t x, size_t y, size_t z){

        auto cellMin = offset + Vector3!T([x * a, y * a, z * a]);
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
            auto n = cast(HomogeneousNode!T*) malloc(HomogeneousNode!(T).sizeof);
            (*n).__node_type__ = NODE_TYPE_HOMOGENEOUS;
            (*n).isPositive = true;
            (*n).depth = maxDepth;
            grid[indexCell(x,y,z)] = cast(Node!T*)n;
        }else if(config == 255){ //fully inside
            auto n = cast(HomogeneousNode!T*) malloc(HomogeneousNode!(T).sizeof);
            (*n).__node_type__ = NODE_TYPE_HOMOGENEOUS;
            (*n).isPositive = false;
            (*n).depth = maxDepth;
            grid[indexCell(x,y,z)] = cast(Node!T*)n;
        }else{ //heterogeneous
            auto edges = whichEdgesAreSignedAll(config);

            auto n = cast(HeterogeneousNode!T*) malloc(HeterogeneousNode!(T).sizeof);
            (*n).__node_type__ = NODE_TYPE_HETEROGENEOUS;
            (*n).depth = maxDepth;

            HermiteData!T*[12] zeroedData;
            n.hermiteData = zeroedData;


            auto planes = Array!(Plane!T)();
            Vector3!T centroid = zero3!T();

            foreach(curEntry; edges){
                import core.stdc.stdlib : malloc;
                HermiteData!(T)* data = cast(HermiteData!(T)*)malloc((HermiteData!T).sizeof); //TODO needs to be cleared

                auto corners = edgePairs[curEntry];
                auto edge = Line!(T,3)(cellMin + cornerPoints[corners.x] * a, cellMin + cornerPoints[corners.y] * a);
                auto intersection = sampleSurfaceIntersection!(T, DenFn3)(edge, cast(uint)accuracy.log2() + 1, f);
                auto normal = calculateNormal!(T, DenFn3)(intersection, a/1024.0, f); //TODO division by 1024 is improper for very high sizes


                *data = HermiteData!T(intersection, normal);
                (*n).hermiteData[curEntry] = data;
                (*n).cornerSigns = cast(ubyte) config;

                centroid = centroid + intersection;
                planes.insertBack(Plane!T(intersection, normal));
            }

            centroid = centroid / planes.length;

            QEF!T qef;

            constructQEF!T(planes, centroid, qef);

            (*n).qef = qef;

            grid[indexCell(x,y,z)] = cast(Node!T*)n;
        }


    }


    pragma(inline,true)
    void simplify(size_t i, size_t j, size_t k, ref Array!(Node!(T)*) sparseGrid,//TODO this func is used not only for simplificatin, prob rename
     ref Array!(Node!(T)*) denseGrid, size_t curSize, size_t curDepth){//depth is inverted

        auto n0 = denseGrid[indexCell(2*i, 2*j, 2*k, 2*curSize)];
        auto n1 = denseGrid[indexCell(2*i+1, 2*j, 2*k, 2*curSize)];
        auto n2 = denseGrid[indexCell(2*i+1, 2*j, 2*k+1, 2*curSize)];
        auto n3 = denseGrid[indexCell(2*i, 2*j, 2*k+1, 2*curSize)];

        auto n4 = denseGrid[indexCell(2*i, 2*j+1, 2*k, 2*curSize)];
        auto n5 = denseGrid[indexCell(2*i+1, 2*j+1, 2*k, 2*curSize)];
        auto n6 = denseGrid[indexCell(2*i+1, 2*j+1, 2*k+1, 2*curSize)];
        auto n7 = denseGrid[indexCell(2*i, 2*j+1, 2*k+1, 2*curSize)];

        Node!(T)*[8] nodes = [n0,n1,n2,n3,n4,n5,n6,n7];

        size_t homoCount = 0;
        bool isPositive;

        QEF!T*[8] qefs;
        size_t qefCount = 0;

        pragma(inline, true)
        void setInterior(){
            auto interior = cast(InteriorNode!(T)*) malloc(InteriorNode!(T).sizeof);
            (*interior).children = nodes;
            (*interior).depth = cast(ubyte) curDepth;
            (*interior).__node_type__ = NODE_TYPE_INTERIOR;

            foreach(i;0..8){
                auto child = nodes[i];
                if(nodeType(child) == NODE_TYPE_HETEROGENEOUS){
                    auto het = asHetero!T(child);
                    solveQEF(het.qef);
                }
            }

            sparseGrid[indexCell(i,j,k, curSize)] = cast(Node!(T)*)interior;
        }
        
        
        foreach(node; nodes){
            auto cur = (*node).__node_type__;
            if(cur == NODE_TYPE_INTERIOR){
                setInterior();
                return;
            }else if(cur == NODE_TYPE_HOMOGENEOUS) { //homogeneous
                isPositive = (*(cast(HomogeneousNode!(T)*) node)).isPositive;
                homoCount += 1;
            }else{ //heterogeneous
                qefs[qefCount] = &asHetero!T(node).qef;
                qefCount += 1;
            }  
        }

        //all same homo or homo + hetero
        if(homoCount == 8){
             //all cells are fully in or out
            auto homo = cast(HomogeneousNode!(T)*) malloc(HomogeneousNode!(T).sizeof);
            (*homo).isPositive = isPositive; 
            (*homo).depth = cast(ubyte) curDepth;
            (*homo).__node_type__ = NODE_TYPE_HOMOGENEOUS;

            sparseGrid[indexCell(i,j,k, curSize)] = cast(Node!(T)*)homo;

            foreach(l;0..8){
                free(nodes[l]);
            }
        }else{
            static if(SIMPLIFY){
                QEF!T mergedQEF;
                bool merged = mergeQEFs(qefs.ptr, qefCount, mergedQEF, thres);
                if(merged){
                    auto hetero = cast(HeterogeneousNode!(T)*) malloc(HeterogeneousNode!(T).sizeof);
                    hetero.depth = cast(ubyte) curDepth;
                    hetero.__node_type__ = NODE_TYPE_HETEROGENEOUS;
                    hetero.qef = mergedQEF;
                    hetero.cornerSigns = 0;
                    foreach(l;0..8){
                        if(nodes[l].__node_type__ == NODE_TYPE_HOMOGENEOUS){
                            hetero.cornerSigns |= !asHomo!T(nodes[l]).isPositive << l;
                        }else{
                            hetero.cornerSigns |= ((asHetero!T(nodes[l]).cornerSigns >> l) & 1) << l;
                        }
                    }

                    HermiteData!T*[12] data;

                    foreach(o;0..12){
                        foreach(l;0..8){
                            if(nodes[l].__node_type__ == NODE_TYPE_HETEROGENEOUS){
                                auto hnode = asHetero!T(nodes[l]);
                                if(hnode.hermiteData[o]){
                                    if(!data[o]){
                                        data[o] = cast(HermiteData!T*) malloc((HermiteData!T).sizeof);
                                        data[o].normal = zero3!T();
                                        data[o].intersection = zero3!T(); //TODO do we even need this ?
                                    }

                                    data[o].normal = data[o].normal + hnode.hermiteData[o].normal;

                                }
                            }
                        }

                        if(data[o])
                            data[o].normal = data[o].normal.normalize();
                    }

                    hetero.hermiteData = data;

                    sparseGrid[indexCell(i,j,k, curSize)] = cast(Node!(T)*)hetero;

                    foreach(l;0..8){
                        free(nodes[l]);
                    }

                    //setInterior();//TODO
                }else{
                    setInterior();
                }
            }else{
                setInterior();
            }
            

            
        }

       

       
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

        Array!(Node!(T)*) sparseGrid = Array!(Node!(T)*)();
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

    Node!(T)* tree = grid[0]; //grid contains only one element here

    auto indexNode = delegate(HeterogeneousNode!T* het, Cube!T bounds){
        renderData.ptr.insertBack(het);//cannot be run in parallel
        //auto ind = Array!uint();
        //memcpy(&het.indices, &ind, (Array!uint).sizeof);//this is needed instead of regular `=` because `indices` is not initialized correcty (with malloc)
        het.index = cast(uint)renderData.ptr.length - 1;

        Vector3!float normal = zero3!float();
        size_t normalCount;
        foreach(i;0..12){
            if(het.hermiteData[i]){
                normal = normal + het.hermiteData[i].normal;
                normalCount += 1;
            }
        }

        normal = normal / normalCount;

        renderData.addFloat3(het.qef.minimizer + het.qef.massPoint);
        renderData.addFloat3(vec3!float(1.0F, 1.0F, 1.0F));
        renderData.addFloat3(normal);
    };

    auto ext = vec3!T(a * size / 2,a * size / 2,a * size / 2);

    auto bounds = Cube!T(offset + ext, ext.x);

    foreachHeterogeneousLeaf!(T, indexNode)(tree, bounds);

    return tree;

}


auto faceProcTable2 = [1, 0, 1, 0,
                       1, 0, 1, 0,
                       2, 2, 2, 2]; //face dir table
auto faceProcTable3 = [[3,2,6,7,  0,1,5,4], [1,2,6,5,  0,3,7,4], [7,6,5,4,  3,2,1,0]]; //faceProc ->4 faceProc's
auto faceProcTable4 = [[[6,7,4,5,  11,10,9,8], [3,7,4,0,  6,2,0,4], [2,3,0,1,  11,10,9,8], [2,6,5,1,  6,2,0,4]],//
                       [[5,6,7,4,  10,9,8,11], [6,2,3,7,  1,5,7,3], [1,2,3,0,  10,9,8,11], [5,1,0,4,  1,5,7,3]],
                       [[4,5,1,0,  5,7,3,1], [7,4,0,3,  4,6,2,0], [7,6,2,3,  5,7,3,1], [6,5,1,2,  4,6,2,0]]]; //faceProc ->4 edgeProc's

auto edgeProcTable = [[0,1,5,4, 5,7,3,1],
                      [5,6,2,1, 2,0,4,6], 
                      [6,7,3,2, 3,1,5,7], 
                      [3,0,4,7, 4,6,2,0], 
                      [3,2,1,0, 9,8,11,10], 
                      [7,6,5,4, 9,8,11,10]]; //cellProc ->6 edgeProc


auto edgeProcTable2 = [
                                    [0u,1u],
                                    [1u,2u],
                                    [3u,2u],
                                    [0u,3u],

                                    [4u,5u],
                                    [5u,6u],
                                    [7u,6u],
                                    [4u,7u],

                                    [0u,4u],
                                    [1u,5u],
                                    [2u,6u],
                                    [3u,7u],
];

void faceProc(T)(ref VoxelRenderData!T renderer, Node!(T)* a, Node!(T)* b, uint dir){


    if(nodeType(a) == NODE_TYPE_HOMOGENEOUS || nodeType(b) == NODE_TYPE_HOMOGENEOUS){
        return;
    }


    auto n = &faceProcTable4[dir];
    auto t = &faceProcTable3[dir];
    
    switch(nodeType(a)){
        case NODE_TYPE_INTERIOR:

            auto aint = cast( InteriorNode!(T)* ) a;
            

            
            switch(nodeType(b)){
                case NODE_TYPE_INTERIOR: //both nodes are internal
                    auto bint = cast( InteriorNode!(T)* ) b;
             

                    foreach(i;0..4){
                        faceProc(renderer, aint.children[(*t)[i]], bint.children[(*t)[i+4]], dir); //ok
                        
                        edgeProc(renderer, aint.children[(*n)[i][0]], aint.children[(*n)[i][1]], bint.children[(*n)[i][2]], bint.children[(*n)[i][3]], (*n)[i][4], (*n)[i][5], (*n)[i][6], (*n)[i][7]); //ok
                    }

                    break;

                default:
                    foreach(i;0..4){
                        faceProc(renderer, aint.children[(*t)[i]], b, dir); //ok

                        edgeProc(renderer, aint.children[(*n)[i][0]], aint.children[(*n)[i][1]], b, b, (*n)[i][4], (*n)[i][5], (*n)[i][6], (*n)[i][7]); //ok
                    }

                    break;
            }

            break;
            
        default:

            switch(nodeType(b)){
                case NODE_TYPE_INTERIOR:
                    auto bint = cast( InteriorNode!(T)* ) b;


                    foreach(i;0..4){
                        faceProc(renderer, a, bint.children[(*t)[i+4]], dir); //ok

                        edgeProc(renderer, a, a, bint.children[(*n)[i][2]], bint.children[(*n)[i][3]], (*n)[i][4], (*n)[i][5], (*n)[i][6], (*n)[i][7]); //ok
                    }

                    break;

                default:
                    break;
            }

            break;
    }
}

static int CALLS = 0;
void edgeProc(T)(ref VoxelRenderData!T renderer, Node!(T)* a, Node!(T)* b, Node!(T)* c, Node!(T)* d, size_t ai, size_t bi, size_t ci, size_t di){
    auto types = [nodeType(a), nodeType(b), nodeType(c), nodeType(d)];
    auto nodes = [a,b,c,d];
    auto configs = [ai,bi,ci,di];
    

    if(types[0] != NODE_TYPE_INTERIOR && types[1] != NODE_TYPE_INTERIOR && types[2] != NODE_TYPE_INTERIOR && types[3] != NODE_TYPE_INTERIOR){ //none of the nodes are interior
        //all nodes are heterogeneous
        //TODO make the condition computation faster ^^^ only one check is needed if NODE_TYPE_X are set correctly

        if(types[0] == NODE_TYPE_HOMOGENEOUS || types[1] == NODE_TYPE_HOMOGENEOUS || types[2] == NODE_TYPE_HOMOGENEOUS || types[3] == NODE_TYPE_HOMOGENEOUS){
            return;
        }
       
        

        CALLS += 1;

        Vector3!float[4] pos;
        Vector3!float color = vecS!([1.0F,1.0F,1.0F]);
        Vector3!float normal;

        int index = -1;
        int maxDepth = -1;
        bool flip2;

        int[4] sc;
        

        foreach(i;0..4){
            auto node = cast(HeterogeneousNode!T*) nodes[i];
            auto p = edgeProcTable2[configs[i]]; //TODO
            auto p1 = (node.cornerSigns >> p[0]) & 1;
            auto p2 = (node.cornerSigns >> p[1]) & 1;

            if(node.depth > maxDepth){
                index = i;
                maxDepth = node.depth;

                if(p1 == 0){
                    flip2 = true;
                }
            }

            if(p1 != p2){
                sc[i] = 1;
            }else{
                sc[i] = 0;
            }

            static if( is(T == double) )
                pos[i] = (node.qef.minimizer + node.qef.massPoint).mapf(x => cast(float)x);
            else static if( is(T == float) ){
                pos[i] = (node.qef.minimizer + node.qef.massPoint);
            }
            else{
                panic!void("not implemented");
            }

        }

        if(sc[index] == 0) return;

        auto node = (* cast(HeterogeneousNode!T*) nodes[index]);

        static if( is(T == double) )
            normal = node.hermiteData[configs[index]].normal.mapf(x => cast(float) x);
        else static if( is(T == float) ){
            normal = node.hermiteData[configs[index]].normal;
        }
        else{
            panic!void("not implemented");
        }

        auto hnodes = [asHetero!T(nodes[0]),asHetero!T(nodes[1]),asHetero!T(nodes[2]),asHetero!T(nodes[3])];


        //TODO fix incorrect (inverted) triangle indexing
        if(!flip2){
            if(nodes[0] == nodes[1]){//same nodes => triangle
                //renderer.addTriangle([hnodes[0], hnodes[2], hnodes[3]], [pos[0], pos[2], pos[3]], color, normal);
                renderer.addTriangle([hnodes[0], hnodes[2], hnodes[3]]);
            //}else if(nodes[1] == nodes[3]){ //no possible
            }else if(nodes[3] == nodes[2]){
                //renderer.addTriangle([hnodes[0], hnodes[1], hnodes[3]], [pos[0], pos[1], pos[3]], color, normal);
                renderer.addTriangle([hnodes[0], hnodes[1], hnodes[3]]);
            //}else if(nodes[2] == nodes[0]){ //not possible
            }else{
                //renderer.addTriangle([hnodes[0], hnodes[1], hnodes[2]], [pos[0], pos[1], pos[2]], color, normal);
                //renderer.addTriangle([hnodes[0], hnodes[2], hnodes[3]], [pos[0], pos[2], pos[3]], color, normal);

                renderer.addTriangle([hnodes[0], hnodes[1], hnodes[2]]);
                renderer.addTriangle([hnodes[0], hnodes[2], hnodes[3]]);
            }
        }else{
            if(nodes[0] == nodes[1]){//same nodes => triangle
                //renderer.addTriangle([hnodes[0], hnodes[3], hnodes[2]], [pos[0], pos[3], pos[2]], color, normal);
                renderer.addTriangle([hnodes[0], hnodes[3], hnodes[2]]);
            //}else if(nodes[1] == nodes[3]){
            }else if(nodes[3] == nodes[2]){
                //renderer.addTriangle([hnodes[0], hnodes[3], hnodes[1]], [pos[0], pos[3], pos[1]], color, normal);
                renderer.addTriangle([hnodes[0], hnodes[3], hnodes[1]]);
            //}else if(nodes[2] == nodes[0]){
            }else{
                // renderer.addTriangle([hnodes[0], hnodes[2], hnodes[1]], [pos[0], pos[2], pos[1]], color, normal);
                // renderer.addTriangle([hnodes[0], hnodes[3], hnodes[2]], [pos[0], pos[3], pos[2]], color, normal);

                renderer.addTriangle([hnodes[0], hnodes[2], hnodes[1]]);
                renderer.addTriangle([hnodes[0], hnodes[3], hnodes[2]]);
            }
        }

        

        

        

    }else{//subdivide
        Node!(T)*[4] sub1;
        Node!(T)*[4] sub2;
        foreach(i;0..4){
            if(types[i] != NODE_TYPE_INTERIOR){
                sub1[i] = nodes[i];
                sub2[i] = nodes[i];
            }else{
                auto interior = cast( InteriorNode!(T)* ) nodes[i];
                auto p = edgeProcTable2[configs[i]];
                sub1[i] = interior.children[p[0]];
                sub2[i] = interior.children[p[1]];
            }
        }

        edgeProc(renderer, sub1[0], sub1[1], sub1[2], sub1[3], ai, bi, ci, di);
        edgeProc(renderer, sub2[0], sub2[1], sub2[2], sub2[3], ai, bi, ci, di);
    }
}

void cellProc(T)(ref VoxelRenderData!T renderer, Node!(T)* node){ //ok
    switch(nodeType(node)){
        case NODE_TYPE_INTERIOR:
            auto interior = cast( InteriorNode!(T)* ) node;
            auto ch = (*interior).children;

            foreach(i;0..8){
                auto c = ch[i];
                cellProc(renderer, c); //ok
            }

            foreach(i;0..12){
                auto pair = edgeProcTable2[i];
                auto dir = faceProcTable2[i];
                faceProc(renderer, ch[pair[0]], ch[pair[1]], dir); //ok
            }

            foreach(i;0..6){
                auto tuple8 = &edgeProcTable[i];
                edgeProc(renderer, ch[(*tuple8)[0]], ch[(*tuple8)[1]], ch[(*tuple8)[2]], ch[(*tuple8)[3]],
                                   (*tuple8)[4], (*tuple8)[5], (*tuple8)[6], (*tuple8)[7]);//ok
            }


            break;
            
        default: break;
    }
}

void extract(T)(ref AdaptiveVoxelStorage!T storage, ref VoxelRenderData!T data){
    data.preallocateBuffersBasedOnNodeCount();
    cellProc!T(data, storage.root);
}

void foreachHeterogeneousLeaf(T, alias f)(Node!(T)* node, Cube!T bounds){
    final switch(nodeType(node)){
        case NODE_TYPE_INTERIOR:
            auto interior = cast( InteriorNode!(T)* ) node;
            auto ch = (*interior).children;

            foreach(i;0..8){
                auto c = ch[i];
                auto tr = cornerPointsOrigin[i] * bounds.extent / 2;
                auto newBounds = Cube!(T)(bounds.center + tr, bounds.extent/2);

                foreachHeterogeneousLeaf!(T, f)(c, newBounds);
            }
            break;

        case NODE_TYPE_HOMOGENEOUS:
            break;
        case NODE_TYPE_HETEROGENEOUS:
            f( cast(HeterogeneousNode!T*)  node, bounds);
            break;

    }
}


void foreachLeaf(T, alias f)(Node!(T)* node, Cube!T bounds){
    final switch(nodeType(node)){
        case NODE_TYPE_INTERIOR:
            auto interior = cast( InteriorNode!(T)* ) node;
            auto ch = (*interior).children;

            foreach(i;0..8){
                auto c = ch[i];
                auto tr = cornerPointsOrigin[i] * bounds.extent / 2;
                auto newBounds = Cube!(T)(bounds.center + tr, bounds.extent/2);

                foreachLeaf!(T, f)(c, newBounds);
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

