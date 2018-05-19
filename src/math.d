module math;

import std.math;
import std.container.array;
import std.stdio;
import std.conv;

import util;
import traits;
import matrix;



struct Triangle(T, size_t N){
    Vector!(T, N) p1;
    Vector!(T, N) p2;
    Vector!(T, N) p3;
}

struct Rectangle3(T){
    Vector3!T center;
    Vector3!T right;
    Vector3!T up;
    Vector2!T extent;
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

bool checkLinePlaneIntersection(T)(ref Line!(T, 3) line, Plane!T plane, ref T ret){
    auto t = (plane.point - line.start).dot(plane.normal) / (line.end - line.start).dot(plane.normal);
    if(0 < t && t < 1.0){
        ret = t;
        return true;
    }else{
        return false;
    }
}

bool checkLine3Rectangle3Intersection(T)(ref Line!(T,3) line, ref Rectangle3!(T) rec, ref T t){
    if(checkLinePlaneIntersection!T(line, Plane!T(rec.center, rec.right.cross(rec.up)), t)){
        auto ret = line.start + (line.end - line.start) * t;
        auto min = rec.center - rec.right * rec.extent[0] - rec.up * rec.extent[1]; 
        auto d1 = dot(rec.right * (rec.extent[0] * 2), ret - min);
        if(0 < d1 && d1 < (2 * rec.extent[0]) * (2 * rec.extent[0]) ){
            auto d2 = dot(rec.up * (rec.extent[1] * 2), ret - min);
            return 0 < d2 && d2 < (2 * rec.extent[1]) * (2 * rec.extent[1]);
        }else{
            return false;
        }
    }else{
        return false;
    }
}

void genCubeRectangleFaces(T)(ref Cube!(T) cube, ref Rectangle3!(T)[6] faces){
    auto ext = vec2!T(cube.extent, cube.extent);

    auto right = vec3!T(1,0,0);
    auto up    = vec3!T(0,1,0);
    auto look  = vec3!T(0,0,1);

    faces[0] = Rectangle3!(T)(cube.center - right * cube.extent, vec3!T(0,0,1), vec3!T(0,1,0), ext);
    faces[1] = Rectangle3!(T)(cube.center + right * cube.extent, vec3!T(0,0,-1), vec3!T(0,1,0), ext);
    faces[2] = Rectangle3!(T)(cube.center - up * cube.extent, vec3!T(1,0,0), vec3!T(0,0,1), ext);
    faces[3] = Rectangle3!(T)(cube.center + up * cube.extent, vec3!T(1,0,0), vec3!T(0,0,-1), ext);
    faces[4] = Rectangle3!(T)(cube.center - look * cube.extent, vec3!T(-1,0,0), vec3!T(0,1,0), ext);
    faces[5] = Rectangle3!(T)(cube.center + look * cube.extent, vec3!T(1,0,0), vec3!T(0,1,0), ext);

}

bool checkLine3CubeIntersection(T)(ref Line!(T,3) line, ref Cube!(T) cube, ref T ret){

    Rectangle3!T[6] faces;

    genCubeRectangleFaces(cube, faces);

    foreach(i;0..6){
        auto inter = checkLine3Rectangle3Intersection(line, faces[i], ret);

        if(inter){
            return true;
        }
    }

    return false;
}

Vector3!T cubeMin(T)(Cube!T cube){
    return cube.center - Vector3!T([cube.extent, cube.extent, cube.extent]);
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

    return matrix.transpose(Matrix4!float([xa.x, ya.x, za.x, 0.0F,
                   xa.y, ya.y, za.y, 0.0F,
                   xa.z, ya.z, za.z, 0.0F,
                   -xa.dot(pos), -ya.dot(pos), -za.dot(pos), 1.0F]));
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


pragma(inline, true)
private size_t indexMatrix(size_t colCount, size_t i, size_t j){
    return i * colCount + j;
}

void transpose(T)(T* A, size_t n, size_t m, T* AT){
    foreach(i; 0..m){
        foreach(j; 0..n){
            AT[indexMatrix(n, i, j)] = A[indexMatrix(m, j, i)];

        }
    }
}

//A = aij[n * m]; B = bij[m * k]; C = cij[n*k];
void mult(T)(T* A, T* B, size_t n, size_t m, size_t k, T* C){
    foreach(i; 0..n){
        foreach(j; 0..k){
            T cij = traits.zero!T();
            foreach(l; 0..m){
                cij += A[indexMatrix(m, i, l)] * B[indexMatrix(k, l, j)];
            }

            C[indexMatrix(k, i, j)] = cij;
        }
    }
}

Vector!(T,N) average(T, size_t N)(const ref Array!(Matrix!(T,N,1)) vectors){
    Vector!(T,N) result = zero!(T,N,1);

    foreach(ref v; vectors[]){
        result = result + v;
    }

    return result / vectors.length;

}

//TODO test it better, looks like it does not work correctly
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

//TODO test it better, looks like it does not work correctly
void qr(T, size_t N, size_t M)(const ref Matrix!(T,N,M) A, out Matrix!(T,N,M) Q, out Matrix!(T,M,M) R) if(M <= N){
    gramSchmidt(A, Q);

    for(size_t i = 0; i < M; ++i){  //calculate elements of upper triangular matrix
        for(size_t j = i; j < M; ++j){
            R[i,j] = Q.column(i).dot(A.column(j));
        }
    }

    for(size_t i = 0; i < M; ++i){  //zero out all elements below main diagonal
        for(size_t j = 0; j < i; ++j){
            R[i,j] = traits.zero!T();
        }
    }
}


//solve linear system: Rx = b where R is n * n upper triangular matrix (just back substitute)
void solveRxb(T, size_t N)(const ref Matrix!(T,N,N) R, const ref Matrix!(T,N,1) b, out Matrix!(T,N,1) x){
    for(int i = N - 1; i >= 0; --i){ //here `i` must be SIGNED integral number !
        T sum = traits.zero!T();
        for(size_t j = i + 1; j < N; ++j){
            sum += R[i,j] * x[j];
        }

        x[i] = (b[i] - sum) / R[i,i];
    }
}


bool checkPointInsideCube(const ref Vector3!float point, const ref Cube!float cube){
    return point.x < cube.center.x + cube.extent && point.x > cube.center.x - cube.extent &&
    point.y < cube.center.y + cube.extent && point.y > cube.center.y - cube.extent &&
    point.z < cube.center.z + cube.extent && point.z > cube.center.z - cube.extent;
}


// for reducing two upper triangular systems of equations into 1
//mat1 and mat2 are 4 by 4 matrices
void qr ( float *mat1, float *mat2, float *rvalue )
{
	int i, j;
	float [ 4 ] [ 8 ] temp1 ;

	for ( i = 0; i < 4; i++ )
	{
		for ( j = 0; j < i; j++ )
		{
			temp1 [ i ] [ j ] = 0;
			temp1 [ i + 4 ] [ j ] = 0;
		}
		for ( j = i; j < 4; j++ )
		{
			temp1 [ i ] [ j ] = mat1 [ ( 7 * i - i * i ) / 2 + j ];
			temp1 [ i + 4 ] [ j ] = mat2 [ ( 7 * i - i * i ) / 2 + j ];
		}
	}

	qr ( temp1, 8, rvalue );
}

// WARNING: destroys eqs in the process
private void qr (ref float[4][8] eqs, int num, float *rvalue )
{
	int i, j, k;

	qr ( eqs, num, 0.000001f );
	for ( i = 0; i < 10; i++ )
	{
		rvalue [ i ] = 0;
	}

	k = 0;
	for ( i = 0; i < num && i < 4; i++ )
	{
		for ( j = i; j < 4; j++ )
		{
			rvalue [ k++ ] = eqs [ i ] [ j ];
		}
	}
}

private void qr (ref float[4][8] eqs, int num, float tol )
{
	int i, j, k;
	float a, b, mag, temp;

	for ( i = 0; i < 4 && i < num; i++ )
	{
		for ( j = i + 1; j < num; j++ )
		{
			a = eqs [ i ] [ i ];
			b = eqs [ j ] [ i ];

			if ( fabs ( a ) > 0.000001f || fabs ( b ) > 0.000001f )
			{
				mag = cast(float)sqrt ( a * a + b * b );
				a /= mag;
				b /= mag;

				for ( k = 0; k < 4; k++ )
				{
					temp = a * eqs [ i ] [ k ] + b * eqs [ j ] [ k ];
					eqs [ j ] [ k ] = b * eqs [ i ] [ k ] - a * eqs [ j ] [ k ];
					eqs [ i ] [ k ] = temp;
				}
			}
		}
		for ( j = i - 1; j >= 0; j-- )
		{
			if ( eqs [ j ] [ j ] < 0.000001f && eqs [ j ] [ j ] > -0.000001f )
			{
				a = eqs [ i ] [ i ];
				b = eqs [ j ] [ i ];

				if ( fabs ( a ) > 0.000001f || fabs ( b ) > 0.000001f )
				{
					mag = cast(float)sqrt ( a * a + b * b );
					a /= mag;
					b /= mag;

					for ( k = 0; k < 4; k++ )
					{
						temp = a * eqs [ i ] [ k ] + b * eqs [ j ] [ k ];
						eqs [ j ] [ k ] = b * eqs [ i ] [ k ] - a * eqs [ j ] [ k ];
						eqs [ i ] [ k ] = temp;
					}
				}
			}
		}
	}

}

extern(C){
    float qef_solve_d(float* AtA_tri, float* Atb, float* massPoint, float* minimizer);
}
