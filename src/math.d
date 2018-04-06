module math;

import util;
import traits;
import matrix;
import std.math;


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