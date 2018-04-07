module tests;

import std.stdio;
import std.math;
import std.container.array;

import matrix;
import math;
import util;


unittest{ //matrix
    auto a = Vector3!float([1,2,3]);

    auto i = Vector3!float([1,0,0]);
    auto j = Vector3!float([0,1,0]);
    auto k = Vector3!float([0,0,1]);

    auto A = Matrix2!float([1,2,
                            3,4]);
    auto AT = Matrix2!float([1,3,
                             2,4]);


    auto theta = cast(float)PI/3.0;
    auto B = Matrix2!float([cos(theta), -sin(theta),
                            sin(theta), cos(theta)]);

    assert(dot(a,a) == 14);
    assert(cross(i,j) == k);
    assert(transpose(A) == AT);

    assert(-A == Matrix2!float([-1,-2,
                                -3,-4]));


    assert(mult(B, transpose(B)) == Matrix2!float([1,0,0,1]));

    assert(mult(A, Vector2!float([1,0])) == Vector2!float([1, 3]));


    auto identity2 = matS!([
        [1.0F, 0.0F],
        [0.0F, 1.0F],
    ]);

    auto identity3 = matS!([
        [1.0F, 0.0F, 0.0F],
        [0.0F, 1.0F, 0.0F],
        [0.0F, 0.0F, 1.0F]
    ]);

    auto res = zero!(float, 3,3);

    gramSchmidt(identity3, res);

    assert(identity3 == res);

    auto dirs = matS!([
        [1.0F, 1.0F],
        [-0.5F,1.0F],
        [-0.2F,1.0F]
    ]);

    auto resDirs = dirs;

    gramSchmidt(dirs, resDirs);



    auto tranposedDirs = transpose(resDirs);
    auto res1 = mult(tranposedDirs, resDirs);

    assert(areEqual(res1, identity2, 0.0001F)); //for matrix Q with orthonormal columns: transpose(Q) * Q == I


    void qrTest(){
        auto A = matS!([
            [12.0F, -51.0F, 4.0F],
            [6.0F, 167.0F, -68.0F],
            [-4.0F, 24.0F, -41.0F]
        ]);

        auto Q = zero!(float,3,3);
        auto R = zero!(float,3,3);

        qr(A,Q,R);

        writeln(Q);
        writeln(R);

        auto RExact = matS!([[14.0F, 21.0F, -14.0F], [0.0F, 175.0F, -70.0F], [0.0F, 0.0F, 35.0F]]);

        assert(areEqual(R, RExact, 0.001F));
    }

    qrTest();




}
