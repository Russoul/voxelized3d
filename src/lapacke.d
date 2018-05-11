module lapacke;

//QR decomposition for float n * m matrix
const int LAPACK_ROW_MAJOR = 101;
const int LAPACK_COL_MAJOR = 102;
extern (C) int LAPACKE_sgeqrf(int matrixLayout, size_t rowCount, size_t colCount, float* a, size_t lda, float* tau);
extern (C) int LAPACKE_dgeqrf(int matrixLayout, size_t rowCount, size_t colCount, double* a, size_t lda, double* tau);

//SVD decomposition for float n * m matrix
extern (C) int LAPACKE_sgesvd(int matrix_layout, char jobu, char jobvt, size_t rowCount,
 size_t colCount, float* a, size_t lda, float* s, float* u, size_t ldu, float* vt, size_t ldvt, float* superb);
extern (C) int LAPACKE_dgesvd(int matrix_layout, char jobu, char jobvt, size_t rowCount,
 size_t colCount, double* a, size_t lda, double* s, double* u, size_t ldu, double* vt, size_t ldvt, double* superb);