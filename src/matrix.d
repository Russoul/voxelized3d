module matrix;

import std.stdio;
import std.traits;
import util;
import traits;

struct Matrix(T, size_t N, size_t M){ //TODO support SIMD
	T[N * M] array; //stores by row


	//indexing of a matrix
	ref T opIndex(size_t i, size_t j) {
		return array[i * N + j];
	}

	T opIndex(size_t i, size_t j) const {
		return array[i * N + j];
	}


	
	static if(N == 1 || M == 1){
		
		//indexing of a vector
		ref T opIndex(size_t i) {
			
			return array[i];
		}

		T opIndex(size_t i) const {
			static assert(N == 1 || M == 1);
			return array[i];
		}

		static if (N * M == 3){
			auto cross(Matrix!(T,N,M) other){
				T[N*M] array = [this[1]*other[2] - this[2]*other[1], -this[0]*other[2] + this[2]*other[0], this[0]*other[1] - this[1]*other[0]];
				static if(N == 3) return Matrix!(T,3,1)(array);
				static if(M == 3) return Matrix!(T,1,3)(array);
				
			}
		}
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

	


	T0 fold(T0)(T0 accum, T0 function(T,T0) f){
		for(size_t i = 0; i < N; ++i){
			accum = f(array[i], accum);
		}

		return accum;
	}
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

auto vec(alias val)() {
  alias T = ForeachType!(typeof(val));
  enum N  = val.length;
  return Vector!(T,N)(cast(T[N]) val);
}

auto mat(alias val)() { //TODO test perfomance ?
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