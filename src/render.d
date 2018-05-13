module render;

import std.conv;
import std.stdio;
import std.container.array;

import util;
import graphics;
import matrix;
import math;

import hermite;


class RenderVertFrag{
    size_t renderMode;
    string shaderName;
    abstract bool construct();
    abstract bool deconstruct();
    abstract bool draw();
    abstract void reset();
    
}

class RenderVertFragDef : RenderVertFrag{
    Array!float vertexPool;
    Array!uint indexPool; //uint is 32bit
    uint vertexCount = 0; //TODO do we need this ? it can be computed as vertexPool.size / VERTEX_SIZE
    size_t VBO;
    size_t VAO;
    size_t EBO;
    bool constructed = false;

    void delegate() setAttribPtrs;

    this(string name, int mode, void delegate() setAttribPtrs){
        this.shaderName = name;
        this.renderMode = mode;
        this.setAttribPtrs = setAttribPtrs;

        vertexPool = Array!float();
        indexPool = Array!uint();

        vertexPool.reserve(1000); //TODO make it better
        indexPool.reserve(1000);  //
    }
    
    override bool construct(){
        if (constructed || vertexPool.length == 0 || indexPool.length == 0) return false;

        

        size_t gen;
        glGenVertexArrays(1, &gen);
        VAO = gen;
        glGenBuffers(1, &gen);
        VBO = gen;
        glGenBuffers(1, &gen);
        EBO = gen;

        

        glBindVertexArray(VAO);
        glBindBuffer(GL_ARRAY_BUFFER, VBO);


        glBufferData(GL_ARRAY_BUFFER, vertexPool.length * float.sizeof, cast(const void *) &vertexPool[0], GL_STATIC_DRAW);
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, EBO);
        glBufferData(GL_ELEMENT_ARRAY_BUFFER, indexPool.length * uint.sizeof, cast(const void *) &indexPool[0], GL_STATIC_DRAW);
        setAttribPtrs();
        

        glBindBuffer(GL_ARRAY_BUFFER, 0);
        glBindVertexArray(0);

        this.constructed = true;

        return true; 
    }

    override bool deconstruct(){
        if(!constructed) return false;

        glDeleteVertexArrays(1, &VAO);
        glDeleteBuffers(1, &VBO);
        glDeleteBuffers(1, &EBO);

        constructed = false;

        return true;
    }

    override bool draw(){
        if(!constructed) return false;

        glBindVertexArray(VAO);
        glDrawElements(renderMode, indexPool.length, GL_UNSIGNED_INT, 0);
        glBindVertexArray(0);

        return true;
    }

    override void reset(){
        vertexPool.clear();
        indexPool.clear();
        vertexCount = 0;

    }

}

enum VERTEX_SIZE_POS_COLOR = 6;
enum VERTEX_SIZE_POS_COLOR_NORMAL = 9;

void setAttribPtrsColor(){
    glVertexAttribPointer(0,3, GL_FLOAT, false, VERTEX_SIZE_POS_COLOR * 4, 0);
    glEnableVertexAttribArray(0);
    glVertexAttribPointer(1,3,GL_FLOAT, false, VERTEX_SIZE_POS_COLOR * 4, 3 * 4);
    glEnableVertexAttribArray(1);
}

void setAttribPtrsNormal(){
    glVertexAttribPointer(0,3, GL_FLOAT, false, VERTEX_SIZE_POS_COLOR_NORMAL * 4, 0);
    glEnableVertexAttribArray(0);
    glVertexAttribPointer(1,3,GL_FLOAT, false, VERTEX_SIZE_POS_COLOR_NORMAL * 4, 3 * 4);
    glEnableVertexAttribArray(1);
    glVertexAttribPointer(2,3,GL_FLOAT, false, VERTEX_SIZE_POS_COLOR_NORMAL * 4, 6 * 4);
    glEnableVertexAttribArray(2);
}


private void addFloat3(RenderVertFragDef dat, Vector3!float v){
    dat.vertexPool.insertBack(v.x);
    dat.vertexPool.insertBack(v.y);
    dat.vertexPool.insertBack(v.z);
}

private void addIndices(size_t N)(RenderVertFragDef dat, uint[N] ind, uint offset){
    foreach(i; ind){
        dat.indexPool.insertBack(i + offset);
    }
}


void addLine3Color(RenderVertFragDef dat, Line!(float, 3) line, Vector3!float color){
    addFloat3(dat, line.start);
    addFloat3(dat, color);

    addFloat3(dat, line.end);
    addFloat3(dat, color);

    dat.indexPool.insertBack(dat.vertexCount);
    dat.indexPool.insertBack(1 + dat.vertexCount);

    dat.vertexCount += 2;
}


void addCubeBounds(RenderVertFragDef dat, Cube!float cube, Vector3!float color){
    auto ext = Vector3!float([cube.extent, cube.extent, cube.extent]);
    foreach(i; 0..8){
        auto corner = cube.center - ext + cornerPointsf[i] * cube.extent * 2.0;

        addFloat3(dat, corner);
        addFloat3(dat, color);
    }

    uint[24] indices = [0, 1, 1, 2, 2, 3, 3, 0,   4, 5, 5, 6, 6, 7, 7, 4,   0, 4, 1, 5, 2, 6, 3, 7];

    addIndices(dat, indices, dat.vertexCount);

    dat.vertexCount += 8;

}

void addTriangleLinesColor(RenderVertFragDef dat, Triangle!(float, 3) tri, Vector3!float color){
    addFloat3(dat, tri.p1);
    addFloat3(dat, color);

    addFloat3(dat, tri.p2);
    addFloat3(dat, color);

    addFloat3(dat, tri.p3);
    addFloat3(dat, color);

    dat.indexPool.insertBack(dat.vertexCount);
    dat.indexPool.insertBack(1 + dat.vertexCount);

    dat.indexPool.insertBack(1 + dat.vertexCount);
    dat.indexPool.insertBack(2 + dat.vertexCount);

    dat.indexPool.insertBack(2 + dat.vertexCount);
    dat.indexPool.insertBack(dat.vertexCount);

    dat.vertexCount += 3;
}

void addTriangleColor(RenderVertFragDef dat, Triangle!(float, 3) tri, Vector3!float color){
    addFloat3(dat, tri.p1);
    addFloat3(dat, color);

    addFloat3(dat, tri.p2);
    addFloat3(dat, color);

    addFloat3(dat, tri.p3);
    addFloat3(dat, color);

    dat.indexPool.insertBack(dat.vertexCount);
    dat.indexPool.insertBack(1 + dat.vertexCount);
    dat.indexPool.insertBack(2 + dat.vertexCount);

    dat.vertexCount += 3;
}

void addTriangleColorNormal(RenderVertFragDef dat, Triangle!(float, 3) tri, Vector3!float color, Vector3!float normal){
    addFloat3(dat, tri.p1);
    addFloat3(dat, color);
    addFloat3(dat, normal);

    addFloat3(dat, tri.p2);
    addFloat3(dat, color);
    addFloat3(dat, normal);

    addFloat3(dat, tri.p3);
    addFloat3(dat, color);
    addFloat3(dat, normal);

    dat.indexPool.insertBack(dat.vertexCount);
    dat.indexPool.insertBack(1 + dat.vertexCount);
    dat.indexPool.insertBack(2 + dat.vertexCount);

    dat.vertexCount += 3;
}

void addTriangleColorNormal(RenderVertFragDef dat, Triangle!(float, 3) tri, Triangle!(float,3) color, Vector3!float normal){
    addFloat3(dat, tri.p1);
    addFloat3(dat, color.p1);
    addFloat3(dat, normal);

    addFloat3(dat, tri.p2);
    addFloat3(dat, color.p2);
    addFloat3(dat, normal);

    addFloat3(dat, tri.p3);
    addFloat3(dat, color.p3);
    addFloat3(dat, normal);

    dat.indexPool.insertBack(dat.vertexCount);
    dat.indexPool.insertBack(1 + dat.vertexCount);
    dat.indexPool.insertBack(2 + dat.vertexCount);

    dat.vertexCount += 3;
}