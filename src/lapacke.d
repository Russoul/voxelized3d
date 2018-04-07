module lapacke;

//QR decomposition for float n * m matrix
const int LAPACK_ROW_MAJOR = 101;
const int LAPACK_COL_MAJOR = 102;
extern (C) int LAPACKE_sgeqrf(int matrixLayout, int rowCount, int colCount, float* a, int lda, float* tau);
