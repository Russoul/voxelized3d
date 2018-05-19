module matrix;

import std.stdio;
import std.traits;
import std.math;

import core.simd;

import util;
import traits;



//stack allocated(value type semantics)
struct Matrix(T, size_t N, size_t M){ //TODO support SIMD
	static if (is(T == float) && N == 3 && M == 1 && is(float3))
		float3 array;	//SIMD float3
	else
		T[N * M] array; //stores by row, static on-stack array


	//indexing of a matrix
	pragma(inline,true)
	ref T opIndex(size_t i, size_t j) {
		return array[i * M + j];
	}

    pragma(inline,true)
	T opIndex(size_t i, size_t j) const {
		return array[i * M + j];
	}


	
	static if(N == 1 || M == 1){
		
		//indexing of a vector
		pragma(inline,true)
		ref T opIndex(size_t i) {
			
			return array[i];
		}

        pragma(inline,true)
		T opIndex(size_t i) const {
			return array[i];
		}


        pragma(inline,true)
		T x() const{
			return array[0];
		}
	}

	static if(N >= 2 && M == 1 || N == 1 && M >= 2){
	    pragma(inline,true)
		T y() const{
			return array[1];
		}
	}
	

	static if(N >= 3 && M == 1 || N == 1 && M >= 3){
	    pragma(inline,true)
		T z() const{
			return array[2];
		}
	}

	static if(N >= 4 && M == 1 || N == 1 && M >= 4){
	    pragma(inline,true)
		T w() const{
			return array[3];
		}

        static if(N >= 4 && M == 1){
            pragma(inline,true)
            Vector!(T,3) xyz() const{
                return Vector!(T,3)([x, y, z]);
            }
        }
	}

	pragma(inline,true)
	auto opUnary(string op)() if (op == "-"){
		static if (is(T == float) && N == 3 && M == 1 && is(float3))
			typeof(array) res = -array;
		else
			typeof(array) res = -array[];

		return Matrix!(T,N,M)(res);
	}

    pragma(inline,true)
	auto opBinary(string op)(Matrix!(T,N,M) other) const{
		static if(op == "+"){
			static if (is(T == float) && N == 3 && M == 1 && is(float3))
				typeof(this.array) res = this.array + other.array;
			else
				T[N] res = this.array[] + other.array[];
			return Matrix!(T,N,M)(res);
		}       
		else static if (op == "-"){
			static if (is(T == float) && N == 3 && M == 1 && is(float3))
				typeof(this.array) res = this.array - other.array;
			else
				T[N] res = this.array[] - other.array[];
			return Matrix!(T,N,M)(res);
		}

		else static if (op == "*"){
			T accum = zero!T();

			for(int i = 0; i < N; ++i){
				accum += this.array[i] * other.array[i];
			}

			return accum;
		}  

		
	}

    pragma(inline,true)
	auto opBinary(string op)(T k) const{
	    static if(op == "*"){
	        T[N * M] res = array;
	        for(size_t i = 0; i < N * M; ++i){
	            res[i] *= k;
	        }

	        return Matrix!(T,N,M)(res);
	    }

	    static if(op == "/"){
            T[N * M] res = array;
            for(size_t i = 0; i < N * M; ++i){
                res[i] /= k;
            }

            return Matrix!(T,N,M)(res);
        }
	}


	pragma(inline,true)
	Matrix!(R, N, M) mapf(R)(R function(T) f){ //f : T => R
		R[N*M] res;

		foreach(i;0..N){
			foreach(j;0..M){
				res[i*M + j] = f(this[i,j]);  
			}
		}

		return Matrix!(R,N,M)(res);
	}

    pragma(inline,true)
	T0 fold(T0)(T0 accum, T0 function(T,T0) f){
		for(size_t i = 0; i < N; ++i){
			accum = f(array[i], accum);
		}

		return accum;
	}
}

pragma(inline,true)
Matrix!(T,N,M) zero(T, size_t N, size_t M)(){
    typeof(Matrix!(T,N,M).array) res;
    foreach(i; 0..N*M){
        res[i] = traits.zero!T();
    }

    return Matrix!(T,N,M)(res);
}

pragma(inline, true)
Vector3!T zero3(T)(){
	auto z = traits.zero!T();
	return vec3!T(z,z,z);
}

pragma(inline,true)
T norm(T, size_t N)(Matrix!(T,N,1) a){
    return sqrt(dot(a,a));
}

pragma(inline,true)
auto normalize(T, size_t N)(Matrix!(T, N, 1) a){
    return a / norm(a);
}

pragma(inline,true)
auto dot(T, size_t N)(Matrix!(T, N, 1) a, Matrix!(T, N, 1) b){
	
    T res = traits.zero!T();
	
	for(size_t i = 0; i < N; ++i){
		res += a.array[i] * b.array[i];
	}


	return res;
}



pragma(inline,true)
auto cross(T)(Matrix!(T,3,1) a, Matrix!(T,3,1) b){
	return Vector3!T([a[1]*b[2] - b[1]*a[2], a[2]*b[0] - a[0]*b[2], a[0]*b[1] - b[0] * a[1]]);
}

pragma(inline,true)
Matrix!(T,M,N) transpose(T, size_t N, size_t M)(Matrix!(T,N,M) a){
	T[M*N] res;

	for(size_t i = 0; i < N; ++i){
		for(size_t j = 0; j < M; ++j){
			res[j * N + i] = a[i,j];
		}
	}

	return Matrix!(T,M,N)(res);
}

pragma(inline,true)
Vector!(T,M) row(T, size_t N, size_t M)(Matrix!(T,N,M) a, size_t index){
    T[M] res;

    for(size_t i = 0; i < M; ++i){
        res[i] = a[index, i];
    }

    return Vector!(T,M)(res);
}

pragma(inline,true)
Vector!(T,N) column(T, size_t N, size_t M)(Matrix!(T,N,M) a, size_t index){
    T[N] res;

    for(size_t i = 0; i < N; ++i){
        res[i] = a[i, index];
    }

    return Vector!(T,N)(res);
}

pragma(inline,true)
Matrix!(T,N,P) mult(T, size_t N, size_t M, size_t P)(Matrix!(T,N,M) a, Matrix!(T,M,P) b){
    T[N*P] ar;
    auto res = Matrix!(T,N,P)(ar);

    for(size_t i = 0; i < N; ++i){
        for(size_t j = 0; j < P; ++j){
            res[i,j] = dot(row(a, i), column(b, j));
        }
    }

    return res;
}

//column vector
alias Vector(T,size_t N) = Matrix!(T,N,1);
alias RowVector(T, size_t M) = Matrix!(T,1,M);

alias Vector2(T) = Vector!(T,2);
alias Vector3(T) = Vector!(T,3);
alias Vector4(T) = Vector!(T,4);
alias MatrixN(T,size_t N) = Matrix!(T,N,N);
alias Matrix2(T) = MatrixN!(T,2);
alias Matrix3(T) = MatrixN!(T,3);
alias Matrix4(T) = MatrixN!(T,4);

//calculated statically (at compile time)
auto vecS(alias val)() {
	alias T = ForeachType!(typeof(val));
	enum N  = val.length;

	static if (is(T == float) && N == 3 && is(float3)){
		float3 ret;
		ret.array[0] = val[0];
		ret.array[1] = val[1]; 
		ret.array[2] = val[2];  
		return Vector!(T,N)(ret);
	}else{
		return Vector!(T,N)(cast(typeof(Matrix!(T,N,1).array)) val);
	}

	
}

//calculated statically (at compile time)
auto matS(alias val)() {
	alias T = typeof(val[0][0]);
	enum N  = val.length;
	enum M = val[0].length;

	T[N * M] ret;

	for(int i = 0;i < N;++i){
		for(int j = 0;j < M; ++j){
			ret[i * M + j] = val[i][j];
		}
	}

	return Matrix!(T,N,M)(ret);
}

pragma(inline,true)
Vector2!T vec2(T)(T x, T y){
    return Vector2!T([x,y]);
}

pragma(inline,true)
Vector3!T vec3(T)(T x, T y, T z){
    return Vector3!T([x,y,z]);
}

pragma(inline,true)
Matrix3!T mat3(T)(T a11, T a12, T a13,
                  T a21, T a22, T a23,
                  T a31, T a32, T a33){
    return Matrix!(T,3,3)([
        a11, a12, a13,
        a21, a22, a23,
        a31, a32, a33
    ]);
}

pragma(inline,true)
Matrix3!T diag3(T)(T a11, T a22, T a33){
    T z = traits.zero!T();
    return Matrix!(T,3,3)([
            a11, z, z,
            z, a22, z,
            z, z,  a33
        ]);
}
