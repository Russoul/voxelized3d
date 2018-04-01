module render;

import util;
import graphics;
import arraylist;

class RenderVertFrag{
    size_t renderMode;
    string shaderName;
    abstract bool construct();
    abstract bool deconstruct();
    abstract bool draw();
    abstract void reset();
    
}

class RenderVertFragDef : RenderVertFrag{
    ArrayList!float vertexPool;
    ArrayList!int indexPool;
    uint vertexCount; //32 bit
    size_t VBO;
    size_t VAO;
    size_t EBO;
    bool constructed;

    void delegate() setAttribPtrs;

    this(string name, size_t mode, void delegate() setAttribPtrs){
        this.shaderName = name;
        this.renderMode = mode;
        this.setAttribPtrs = setAttribPtrs;
    }
    
    override bool construct(){
        if (constructed) return false;

        size_t gen;
        glGenVertexArrays(1, &gen);
        VAO = gen;
        glGenBuffers(1, &gen);
        VBO = gen;
        glGenBuffers(1, &gen);
        EBO = gen;

        glBindVertexArray(VAO);
        glBindBuffer(GL_ARRAY_BUFFER, VBO);
        glBufferData(GL_ARRAY_BUFFER, vertexPool.size(), cast(const void *) vertexPool.array, GL_STATIC_DRAW);
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, EBO);
        glBufferData(GL_ELEMENT_ARRAY_BUFFER, indexPool.size(), cast(const void *) indexPool.array, GL_STATIC_DRAW);
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
        glDrawElements(renderMode, indexPool.size(), GL_UNSIGNED_INT, 0);
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