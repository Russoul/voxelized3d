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
        auto s = f(p);
        ubyte b = 0;
        if(s < 0.0){
            b = 1;
        }
        signedGrid[indexDensity(x,y,z)] = b;
    }


    pragma(inline,true)
    void loadCell(size_t x, size_t y, size_t z){

        auto cellMin = offset + Vector3!float([x * a, y * a, z * a]);
        immutable auto bounds = cube(x,y,z);

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
            }

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

        bool inited = false;
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

void foreachHeterogeneousLeaf(alias f)(Node!(float)* node, Cube!float bounds){
    final switch(nodeType(node)){
        case NODE_TYPE_HOMOGENEOUS:
            break;
        case NODE_TYPE_HETEROGENEOUS:
            f( cast(HeterogeneousNode!float*)  node, bounds);
            break;
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
            
    }
}