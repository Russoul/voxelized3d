import util;
import traits;
import matrix;
import std.math;

double PI = 3.14159265359;


struct Triangle(T, size_t N){
    Vector!(T, N) p1;
    Vector!(T, N) p2;
    Vector!(T, N) p3;
}

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