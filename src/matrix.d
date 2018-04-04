module matrix;

import std.stdio;
import std.traits;
import util;
import traits;
import std.math;

//stack allocated(value type semantics)
struct Matrix(T, size_t N, size_t M){ //TODO support SIMD
	T[N * M] array; //stores by row, static on-stack array


	//indexing of a matrix
	ref T opIndex(size_t i, size_t j) {
		return array[i * M + j];
	}

	T opIndex(size_t i, size_t j) const {
		return array[i * M + j];
	}


	
	static if(N == 1 || M == 1){
		
		//indexing of a vector
		ref T opIndex(size_t i) {
			
			return array[i];
		}

		T opIndex(size_t i) const {
			return array[i];
		}



		T x() const{
			return array[0];
		}
	}

	static if(N >= 2 && M == 1 || N == 1 && M >= 2){
		T y() const{
			return array[1];
		}
	}
	

	static if(N >= 3 && M == 1 || N == 1 && M >= 3){
		T z() const{
			return array[2];
		}
	}

	static if(N >= 4 && M == 1 || N == 1 && M >= 4){
		T w() const{
			return array[3];
		}

        static if(N >= 4 && M == 1){
            Vector!(T,3) xyz() const{
                return Vector!(T,3)([x, y, z]);
            }
        }
	}

	
	auto opUnary(string op)() if (op == "-"){
		T[N * M] res;

		for(size_t i = 0; i < N * M; ++i){
			res[i] = -this.array[i];
		}

		return Matrix!(T,N,M)(res);
	}

	auto opBinary(string op)(Matrix!(T,N,M) other) const{
		static if(op == "+"){
			T[N] res = this.array[] + other.array[];
			return Matrix!(T,N,M)(res);
		}       
		else static if (op == "-"){
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


	T0 fold(T0)(T0 accum, T0 function(T,T0) f){
		for(size_t i = 0; i < N; ++i){
			accum = f(array[i], accum);
		}

		return accum;
	}
}


T norm(T, size_t N)(Matrix!(T,N,1) a){
    return sqrt(dot(a,a));
}

auto normalize(T, size_t N)(Matrix!(T, N, 1) a){
    return a / norm(a);
}

auto dot(T, size_t N)(Matrix!(T, N, 1) a, Matrix!(T, N, 1) b){
	
    T res = zero!T();
	
	for(size_t i = 0; i < N; ++i){
		res += a.array[i] * b.array[i];
	}


	return res;
}


auto cross(T)(Matrix!(T,3,1) a, Matrix!(T,3,1) b){
	return Vector3!T([a[1]*b[2] - b[1]*a[2], a[2]*b[0] - a[0]*b[2], a[0]*b[1] - b[0] * a[1]]);
}


auto transpose(T, size_t N, size_t M)(Matrix!(T,N,M) a){
	T[N*M] res;

	for(size_t i = 0; i < N; ++i){
		for(size_t j = 0; j < M; ++j){
			res[j * N + i] = a[i,j];
		}
	}

	return Matrix!(T,N,M)(res);
}


Vector!(T,M) row(T, size_t N, size_t M)(Matrix!(T,N,M) a, size_t index){
    T[M] res;

    for(size_t i = 0; i < M; ++i){
        res[i] = a[index, i];
    }

    return Vector!(T,M)(res);
}

Vector!(T,N) column(T, size_t N, size_t M)(Matrix!(T,N,M) a, size_t index){
    T[N] res;

    for(size_t i = 0; i < N; ++i){
        res[i] = a[i, index];
    }

    return Vector!(T,N)(res);
}

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
  return Vector!(T,N)(cast(T[N]) val);
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



