module math;

import std.math;
import std.container.array;
import std.stdio;

import util;
import traits;
import matrix;



struct Triangle(T, size_t N){
    Vector!(T, N) p1;
    Vector!(T, N) p2;
    Vector!(T, N) p3;
}

struct Plane(T){
    Vector3!T point;
    Vector3!T normal;
}


struct Square(T){
    Vector2!T center;
    T extent;
}

struct Cube(T){
    Vector3!T center;
    T extent;
}

struct Line(T, size_t N){
    Vector!(T, N) start;
    Vector!(T, N) end;
}

struct Sphere(T){
    Vector3!(T) center;
    T rad;
}

struct OBB(T){
    Vector3!T center;
    Vector3!T right;
    Vector3!T up;
    Vector3!T extent; // {right,up,look}
}

//about memory layout of matrices in opengl:
//https://stackoverflow.com/questions/17717600/confusion-between-c-and-opengl-matrix-order-row-major-vs-column-major

//column-major
Matrix4!(float) perspectiveProjection(float fovy, float aspect, float near, float far){
    auto top = near * cast(float)tan(cast(float)PI / 180.0F * fovy / 2.0F);
    auto bottom = -top;
    auto right = top * aspect;
    auto left = -right;

    return Matrix4!(float)([
        2.0F * near / (right - left), 0.0F, (right + left) / (right - left), 0.0F,
        0.0F, 2.0F * near / (top - bottom), (top + bottom) / (top - bottom), 0.0F,
        0.0F, 0.0F, -(far + near) / (far - near), -2.0F * far * near / (far - near),
        0.0F, 0.0F, -1.0F, 0.0F
    ]);
}


//column-major
Matrix4!(float) viewDir(Vector3!float pos, Vector3!float look, Vector3!float up){
    auto za = -look;
    auto xa = up.cross(za);
    auto ya = za.cross(xa);

    return Matrix4!float([xa.x, ya.x, za.x, 0.0F,
                   xa.y, ya.y, za.y, 0.0F,
                   xa.z, ya.z, za.z, 0.0F,
                   -xa.dot(pos), -ya.dot(pos), -za.dot(pos), 1.0F]).transpose();
}


Matrix4!(float) translation(Vector3!float deltaX){
    return Matrix4!float([1,0,0,deltaX.x,
                          0,1,0,deltaX.y,
                          0,0,1,deltaX.z,
                          0,0,0,1]);
}


//u - unit vector that specifies the axis of rotation
//theta - angle in radians
Matrix4!(float) rotation(Vector3!float u, float theta){
    float sinTheta = sin(theta);
    float cosTheta = cos(theta);

    return Matrix4!float([
        cosTheta + u.x * u.x * (1.0F - cosTheta), u.x * u.y * (1.0F - cosTheta) - u.z * sinTheta, u.x * u.z * (1.0F - cosTheta) + u.y * sinTheta, 0.0,
        u.y * u.x * (1.0F - cosTheta) + u.z * sinTheta, cosTheta + u.y * u.y * (1.0F - cosTheta), u.y * u.z * (1.0F - cosTheta) - u.x * sinTheta, 0.0,
        u.z * u.x * (1.0F - cosTheta) - u.y * sinTheta, u.z * u.y * (1.0F - cosTheta) + u.x * sinTheta, cosTheta + u.z * u.z * (1.0F - cosTheta), 0.0,
        0.0F, 0.0F, 0.0F, 1.0F
    ]);
}

//projection operator (v is projected on u)
void proj(ref Array!float v, ref Array!float u, out Array!float res){

    float vu = 0;
    float uu = 0;

    for(size_t i = 0; i < v.length; ++i){
        vu += v[i] * u[i];
        uu += u[i] * u[i];
    }

    auto k = vu / uu;

    for(size_t i = 0; i < v.length; ++i){
        res[i] = u[i] * k;
    }
}


void proj(T, size_t N)(const ref Matrix!(T,N,1) v, const ref Matrix!(T,N,1) u, out Matrix!(T,N,1) res){
    auto vu = dot(v,u);
    auto uu = dot(u,u);
    auto k = vu/uu;

    for(size_t i = 0; i < N; ++i){
        res[i] = u[i] * k;
    }
}


bool areEqual(T, size_t N, size_t M)(const ref Matrix!(T,N,M) a, const ref Matrix!(T,N,M) b, T eps){
    foreach(i; 0..N){
        foreach(j; 0..M){
            if( abs(a[i,j] - b[i,j]) > eps )
                return false;
        }
    }

    return true;
}

void gramSchmidt(T, size_t N, size_t M)(const ref Matrix!(T,N,M) input, out Matrix!(T,N,M) output) if(M <= N){
    for(size_t i = 0; i < M; ++i){

        auto iC = input.column(i);
        Vector!(T,N) difference = iC;

        T[N] tempAr;
        Vector!(T,N) temp = {tempAr};


        for(size_t j = 0; j < i; ++j){
            auto oC = output.column(j);
            proj(iC, oC, temp);

            difference = difference - temp;
        }

        for(size_t k = 0; k < N; ++k){
            output[k,i] = difference[k];
        }
    }

    for(size_t i = 0; i < M; ++i){
        auto column = output.column(i);

        auto norm_ = column.norm();

        for(size_t j = 0; j < N; ++j){
            output[j,i] /= norm_;
        }
    }
}