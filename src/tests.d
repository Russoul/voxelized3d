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

        auto RExact = matS!([[14.0F, 21.0F, -14.0F], [0.0F, 175.0F, -70.0F], [0.0F, 0.0F, 35.0F]]);

        assert(areEqual(R, RExact, 0.001F));

        import lapacke;


        float[3] tau;

        LAPACKE_sgeqrf(LAPACK_ROW_MAJOR, 3, 3, A.array.ptr, 3, tau.ptr);

        writeln("lapacke qr:");
        writeln(A);
    }

    qrTest();


    void linearSystemTest(){
        auto A = matS!([
            [1.0F, 2.0F, 3.0F],
            [0.0F, 4.0F, 7.0F],
            [0.0F, 0.0F, 11.0F]
        ]);

        auto b = vec3(1.0F, 2.0F, 3.0F);

        auto x = zero!(float,3,1);

        solveRxb(A,b,x);

        auto mustBe = Matrix!(float, 3LU, 1LU)([0.136364, 0.0227273, 0.272727]);

        assert(areEqual(x, mustBe, 1e-6F));
    }

    linearSystemTest();

    void qrTest2(){
        auto A = matS!([
            [12.0F, -51.0F],
            [6.0F, 167.0F],
            [-4.0F, 24.0F]
        ]);

        auto Q = zero!(float,3,2);
        auto R = zero!(float,2,2);

        qr(A,Q,R);

        writeln("qr2:");
        writeln(R);


        import lapacke;


        float[3] tau;

        LAPACKE_sgeqrf(LAPACK_ROW_MAJOR, 3, 2, A.array.ptr, 2, tau.ptr);

        writeln("lapacke qr2:");
        writeln(A);

        auto mat = matS!([
                    [12.0F, -51.0F, 1.0F],
                    [6.0F, 167.0F, 1.0F],
                    [-4.0F, 24.0F, 1.0F]
                ]);


        auto U = zero!(float,3,3);
        auto VT = U;

        auto S = zero!(float,3,1);

        float[2] cache;

        auto res = LAPACKE_sgesvd(LAPACK_ROW_MAJOR, 'A', 'A', 3, 3, mat.array.ptr, 3, S.array.ptr, U.array.ptr, 3, VT.array.ptr, 3, cache.ptr);

        writeln("sgesvd:");
        writeln(res);

        writeln("singular values:");
        writeln(S);

        writeln("U:");
        writeln(U);

        writeln("VT:");
        writeln(VT);
    }


    void matTest(){
        float[6] m1 = [1.0F, 2.0F, 3.0F,
                       4.0F, 5.0F, 6.0F];

        auto m1T = new float[3 * 2];


        auto m1TMustBe = [1.0F, 4.0F, 2.0F, 5.0F, 3.0F, 6.0F];

        transpose(m1.ptr, 2,3, m1T.ptr);

        writeln(m1);
        writeln(m1T);

        auto m2 = new float[2*2];

        mult(m1.ptr, m1TMustBe.ptr, 2,3,2, m2.ptr);

        writeln(m2);
    }

    matTest();


    //qrTest2();



}
