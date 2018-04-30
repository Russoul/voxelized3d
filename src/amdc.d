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

Node!(float)* sample(alias DenFn3)(ref DenFn3 f, Vector3!float offset, float a, size_t accuracy){



    auto size = storage.cellCount;

    Array!(Node!(float)*) grid = Array!(Node!(float)*)();
    grid.reserve(size * size * size);
    grid.length = size * size * size;


    pragma(inline,true)
    size_t indexDensity(size_t x, size_t y, size_t z){
        return z * (size + 1) * (size + 1) + y * (size + 1) + x;
    }

    pragma(inline,true)
    size_t indexCell(size_t x, size_t y, size_t z){
        return z * size * size + y * size + x;
    }

    pragma(inline,true)
    size_t indexCell(size_t x, size_t y, size_t z, size_t s = size){
        return z * s * s + y * s + x;
    }


    pragma(inline,true)
    Cube!float cube(size_t x, size_t y, size_t z){//cube bounds of a cell in the grid
        return Cube!float(offset + Vector3!float([(x + 0.5F)*a, (y + 0.5F) * a, (z + 0.5F) * a]), a / 2.0F);
    }


    pragma(inline,true)
    void loadCell(size_t x, size_t y, size_t z){

        auto cellMin = offset + Vector3!float([x * a, y * a, z * a]);
        auto bounds = cube(x,y,z);

        uint config = 0;


        if(storage.grid[indexDensity(x,y,z)] < 0.0){
            config |= 1;
        }
        if(storage.grid[indexDensity(x+1,y,z)] < 0.0){
            config |= 2;
        }
        if(storage.grid[indexDensity(x+1,y,z+1)] < 0.0){
            config |= 4;
        }
        if(storage.grid[indexDensity(x,y,z+1)] < 0.0){
            config |= 8;
        }

        if(storage.grid[indexDensity(x,y+1,z)] < 0.0){
            config |= 16;
        }
        if(storage.grid[indexDensity(x+1,y+1,z)] < 0.0){
            config |= 32;
        }
        if(storage.grid[indexDensity(x+1,y+1,z+1)] < 0.0){
            config |= 64;
        }
        if(storage.grid[indexDensity(x,y+1,z+1)] < 0.0){
            config |= 128;
        }

        if(config == 0){ //fully outside
            auto n = cast(HomogeneousNode!T*) malloc(HomogeneousNode!(T).sizeof);
            (*n).isPositive = true;
            data[indexCell(x,y,z)] = cast(Node*)n;
        }else if(config == 255){ //fully inside
            auto n = cast(HomogeneousNode!T*) malloc(HomogeneousNode!(T).sizeof);
            (*n).isPositive = false;
            data[indexCell(x,y,z)] = cast(Node*)n;
        }else{ //heterogeneous
            auto edges = whichEdgesAreSignedAll[config];

            auto n = cast(HeterogeneousNode!T*) malloc(HeterogeneousNode!(T).sizeof);

            foreach(curEntry; edges){
                import core.stdc.stdlib : malloc;
                HermiteData!(float)* data = cast(HermiteData!(float)*)malloc((HermiteData!float).sizeof); //TODO needs to be cleared

                auto corners = edgePairs[curEntry];
                auto edge = Line!(float,3)(cellMin + cornerPoints[corners.x] * a, cellMin + cornerPoints[corners.y] * a);
                auto intersection = sampleSurfaceIntersection!(DenFn3)(edge, cast(uint)accuracy.log2() + 1, f);
                auto normal = calculateNormal!(DenFn3)(intersection, a/1024.0F, f); //TODO division by 1024 is improper for very high sizes


                *data = HermiteData!float(intersection, normal);
                (*n).hermiteData[curEntry] = data;
                (*n).cornerSigns = config;
            }
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

        Node*[8] nodes = [n0,n1,n2,n3,n4,n5,n6,n7];

        bool inited = false;
        bool isPositive;

        pragma(inline, true)
        void setInterior(){
            auto interior = cast(InteriorNode!(T)*) malloc(InteriorNode!(T).sizeof);
            (*interior).children = nodes;
            (*interior).depth = curDepth;

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
        auto homo = cast(HomogeneousNode!(T)*) malloc(HomogeneousNode!(T).sizeof);
        *(homo).isPositive = isPositive; 
        (*homo).depth = curDepth;

        sparseGrid[indexCell(i,j,k, curSize)] = cast(Node!(float)*)homo;
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