module tests;

import std.stdio;
import matrix;
import math;
import util;
import std.math;

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

}
