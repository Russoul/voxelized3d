module density;

import math;
import matrix;
import bindings;
import std.math;

T octaveNoise(T)(void* noise, size_t octaves, float persistence, T x, T y, T z){
        T total = 0.0F;
        T frequency = 1.0F;
        T amplitude = 1.0F;
        T maxValue = 0.0;

        T k = pow(2.0, octaves - 1);

        foreach(i; 0..octaves){
            total += getValue(noise, x * frequency / k, y * frequency / k, z * frequency / k);
            maxValue += amplitude;
            amplitude *= persistence;
            frequency *= 2.0;
        }

        return total / maxValue;
    }

struct DenUnion(T, alias Den1, alias Den2){
        Den1 f1;
        Den2 f2;

        @nogc T opCall(Vector3!T v){
            auto d1 = f1(v);
            auto d2 = f2(v);

            return fmin(d1, d2);
        }
    }

    struct DenIntersection(T, alias Den1, alias Den2){
        Den1 f1;
        Den2 f2;

        @nogc T opCall(Vector3!T v){
            auto d1 = f1(v);
            auto d2 = f2(v);

            return fmax(d1, d2);
        }
    }

    struct DenDifference(T, alias Den1, alias Den2){
        Den1 f1;
        Den2 f2;

        @nogc T opCall(Vector3!T v){
            auto d1 = f1(v);
            auto d2 = f2(v);

            return fmax(d1, -d2);
        }
    }

    struct DenFn3(T){
        void* noise;//TODO problem here, probably should craate a simple C wrapper to simplify things

        Cube!T cube;

        this(void* noise, Cube!T cube){
            this.cube = cube;
            this.noise = noise;
            import std.datetime;
            auto currentTime = Clock.currTime();
            import core.stdc.time;
            time_t unixTime = core.stdc.time.time(null);
            //setSeed(noise, cast(int) unixTime);
        }

        @nogc T opCall(Vector3!T v){

            auto den = (octaveNoise(noise, 8, 0.72, v.x/1.0, 0, v.z/1.0) + 1)/2 * cube.extent * 2 * 0.7;
            //writeln(den);
            return (v.y - (cube.center.y - cube.extent)) - den;
        }
    }

    struct DenSphere(T){
        Sphere!T sph;

        @nogc T opCall(Vector3!T v){
            return (sph.center - v).dot(sph.center - v) - sph.rad * sph.rad;
        }
    }

    struct DenZPos(T){
        T z;

        @nogc T opCall(Vector3!T v){
            return z - v.z;
        }
    }

    struct DenZNeg(T){
        T z;

        @nogc T opCall(Vector3!T v){
            return v.z - z;
        }
    }

    struct DenYPos(T){
        T y;

        @nogc T opCall(Vector3!T v){
            return y - v.y;
        }
    }

    struct DenYNeg(T){
        T y;

        @nogc T opCall(Vector3!T v){
            return v.y - y;
        }
    }

    struct DenXPos(T){
        T x;

        @nogc T opCall(Vector3!T v){
            return x - v.x;
        }
    }

    struct DenXNeg(T){
        T x;

        @nogc T opCall(Vector3!T v){
            return v.x - x;
        }
    }


    struct DenHalfSpace(T){
        Plane!T plane;

        @nogc T opCall(Vector3!T v){
            return -dot(plane.normal,v - plane.point);
        }
    }





    struct DenOBB(T){

        alias I1 = DenIntersection!(T,DenHalfSpace!T,DenHalfSpace!T);
        alias I2 = DenIntersection!(T,DenHalfSpace!T,DenHalfSpace!T);
        alias I3 = DenIntersection!(T,DenHalfSpace!T,DenHalfSpace!T);
        alias I4 = DenIntersection!(T,I1, I2);
        DenIntersection!(T,I4, I3) i;

        this(OBB!T obb){
            auto look = cross(obb.up,obb.right);
            DenHalfSpace!T zp = {{obb.center - look * obb.extent.z, look}};
            DenHalfSpace!T zn = {{obb.center + look * obb.extent.z, -look}};

            DenHalfSpace!T yp = {{obb.center - obb.up * obb.extent.y, obb.up}};
            DenHalfSpace!T yn = {{obb.center + obb.up * obb.extent.y, -obb.up}};

            DenHalfSpace!T xp = {{obb.center - obb.right * obb.extent.x, obb.right}};
            DenHalfSpace!T xn = {{obb.center + obb.right * obb.extent.x, -obb.right}};

            DenIntersection!(T,DenHalfSpace!T,DenHalfSpace!T) i1 = {zp,zn};
            DenIntersection!(T,DenHalfSpace!T,DenHalfSpace!T) i2 = {yp,yn};
            DenIntersection!(T,DenHalfSpace!T,DenHalfSpace!T) i3 = {xp,xn};

            DenIntersection!(T,typeof(i1), typeof(i2)) i4 = {i1,i2};
            DenIntersection!(T,typeof(i4), typeof(i3)) i = {i4,i3};

            this.i = i;
        }

        @nogc T opCall(Vector3!T v){
            return i(v);
        }
    }

    struct DenCube(T){

        alias I1 = DenIntersection!(T,DenZPos!T,DenZNeg!T);
        alias I2 = DenIntersection!(T,DenYPos!T,DenYNeg!T);
        alias I3 = DenIntersection!(T,DenXPos!T,DenXNeg!T);
        alias I4 = DenIntersection!(T,I1, I2);
        DenIntersection!(T,I4, I3) i;

        this(Cube!T cube){
            DenZPos!T zp = {cube.center.z - cube.extent};
            DenZNeg!T zn = {cube.center.z + cube.extent};

            DenYPos!T yp = {cube.center.y - cube.extent};
            DenYNeg!T yn = {cube.center.y + cube.extent};

            DenXPos!T xp = {cube.center.x - cube.extent};
            DenXNeg!T xn = {cube.center.x + cube.extent};

            DenIntersection!(T,DenZPos!T,DenZNeg!T) i1 = {zp,zn};
            DenIntersection!(T,DenYPos!T,DenYNeg!T) i2 = {yp,yn};
            DenIntersection!(T,DenXPos!T,DenXNeg!T) i3 = {xp,xn};

            DenIntersection!(T,typeof(i1), typeof(i2)) i4 = {i1,i2};
            DenIntersection!(T,typeof(i4), typeof(i3)) i = {i4,i3};

            this.i = i;
        }

        @nogc T opCall(Vector3!T v){
            return i(v);
        }
    }

    struct DenSphereDisplacement(T){
        Sphere!T sph;
        void* noise;

        @nogc T opCall(Vector3!T v){
            T disp = (getValue(noise, v.x/20,v.y/20,v.z/20)+2)/4;
            return (sph.center - v).dot(sph.center - v) - sph.rad * sph.rad * disp;
        }
    }