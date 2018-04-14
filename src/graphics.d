module graphics;

import util;
import matrix;

//TODO split this file into different modules

struct GlfwWindow{}
struct GlfwMonitor{}

struct GlfwVidMode{
    size_t width;
    size_t height;
    int redBits;
    int greenBits;
    int blueBits;
    size_t refresh_rate;
}

struct WindowInfo{
    size_t width;
    size_t height;
    GlfwWindow* handle;
}

struct Program{
    size_t id;

    int getUniform(string name){
        char[] nullTerminated = (name ~ '\0').dup;

        return glGetUniformLocation(id, cast(const(char)*) nullTerminated.ptr);
    }

    bool isInUse(){
        auto cur = 0;
        glGetIntegerv(GL_CURRENT_PROGRAM, &cur);
        return id == cur;
    }

    void enable(){
        if(!isInUse)
            glUseProgram(id);
    }

    void disable(){
        if(isInUse)
            glUseProgram(0);
    }

    void setBool(string name, bool value){
        glUniform1i(getUniform(name), ifm!(int,"1","0")(value));
    }

    void setInt(string name, int value){
        glUniform1i(getUniform(name), value);
    }

    void setFloat(string name, float value){
        glUniform1f(getUniform(name), value);
    }

    void setFloat2(string name, const Vector!(float,2) float2){
        glUniform2f(getUniform(name), float2[0], float2[1]);
    }

    void setFloat3(string name, const Vector!(float,3) float3){
        glUniform3f(getUniform(name), float3[0], float3[1], float3[2]);
    }

    void setFloat4x4(string name, bool transpose, const ref Matrix4!(float) float4x4){
        import std.stdio;
        import std.conv;
        glUniformMatrix4fv(getUniform(name), 1, transpose, cast(const(float)*) float4x4.array.ptr);
    }
}

alias GLFWglproc = void function();
alias GLADloadproc = void* function(const char *);

extern (C) void glfwInit();
extern (C) void glfwWindowHint(size_t enum_, size_t val);
extern (C) GlfwWindow* glfwCreateWindow(size_t width, size_t height, const char* title, void* ptr1, void* ptr2);
extern (C) void glfwTerminate();
extern (C) void glfwMakeContextCurrent(GlfwWindow* win);
extern (C) void glViewport(size_t x, size_t y, size_t width, size_t height);
extern (C) void glfwSetFramebufferSizeCallback(GlfwWindow* win, void function(GlfwWindow*,size_t,size_t));
extern (C) GLFWglproc glfwGetProcAddress(const char* procName);
extern (C) int gladLoadGLLoader(GLADloadproc);
extern (C) void glfwSetKeyCallback(GlfwWindow* win, void function(GlfwWindow*,int,int,int,int) callback);
extern (C) void glfwSetMouseButtonCallback(GlfwWindow* win, void function(GlfwWindow*, int,int,int) callback);
extern (C) void glfwSetErrorCallback(void function(int, const char*) callback);
extern (C) bool glfwWindowShouldClose(GlfwWindow* win);
extern (C) void glfwSwapBuffers(GlfwWindow* win);
extern (C) void glfwPollEvents();
extern (C) size_t glfwGetKey(const (GlfwWindow*) win, int key);
extern (C) int glfwGetMouseButton(const (GlfwWindow*) win, int button);
extern (C) void glfwSetWindowShouldClose(GlfwWindow* win, bool shouldClose);
extern (C) void glfwSetInputMode(GlfwWindow* win, size_t mode, int value);
extern (C) void glfwGetCursorPos(GlfwWindow* win, double* x, double* y);
extern (C) void glfwGetWindowSize(GlfwWindow* win, size_t* w, size_t* h);
extern (C) GlfwVidMode* glfwGetVideoMode(GlfwMonitor* mon);
extern (C) GlfwMonitor* glfwGetPrimaryMonitor();
extern (C) void glfwSetWindowPos(GlfwWindow* win, size_t x, size_t y);
extern (C) void glfwSwapInterval(int mode);
extern (C) void glClearColor(float r, float g, float b, float a);
extern (C) void glClear(size_t val);
extern (C) const (char)* glGetString(size_t val);
extern (C) void glEnable(size_t val);
extern (C) void glDisable(size_t val);
extern (C) size_t glCreateProgram();
extern (C) size_t glCreateShader(size_t type);
extern (C) void glShaderSource(size_t shader, size_t count, const(const(char *))* sources, size_t* lengths);
extern (C) void glCompileShader(size_t id);
extern (C) void glGetShaderiv(size_t id, size_t param, size_t* res);
extern (C) void glGetShaderInfoLog(size_t shader, size_t maxLen, size_t* len, char* info);
extern (C) void glAttachShader(size_t program, size_t shader);
extern (C) void glLinkProgram(size_t program);
extern (C) void glValidateProgram(size_t program);
extern (C) void glDeleteShader(size_t shader);
extern (C) void glGenVertexArrays(size_t num, size_t* arrays);
extern (C) void glGenBuffers(size_t num, size_t* buffers);
extern (C) void glDeleteVertexArrays(size_t num, const size_t* arrays);
extern (C) void glDeleteBuffers(size_t num, const size_t* buffers);
extern (C) void glBindVertexArray(size_t array);
extern (C) void glBindBuffer(size_t type, size_t buf);
extern (C) void glBufferData(size_t target, size_t size, const(void)* data, size_t usage);
extern (C) void glDrawElements(size_t mode, size_t count, size_t type, size_t indices);
extern (C) void glDrawArrays(size_t mode, size_t startingVertex, size_t vertexCount);
extern (C) void glVertexAttribPointer(size_t index, size_t size, size_t type, bool normalized, size_t stride, size_t offset);
extern (C) void glEnableVertexAttribArray(size_t index);
extern (C) int glGetUniformLocation(size_t program, const(char)* name);
extern (C) void glUniform1i(int loc, int val);
extern (C) void glUniform1f(int loc, float val);
extern (C) void glUniform2f(int loc, float val1, float val2);
extern (C) void glUniform3f(int loc, float v1, float v2, float v3);
extern (C) void glUniform4f(int loc, float v1, float v2, float v3, float v4);
extern (C) void glUniformMatrix4fv(int loc, size_t count, bool transpose, const(float)* mat_col_major);
extern (C) void glUseProgram(size_t id);
extern (C) void glGetIntegerv(size_t param, int* value);
extern (C) size_t glGetError();

// ============ C standard library =======================
//extern (C) void memset(void* ptr, ubyte set, size_t n);

//========================================================


// ============= Fast Noise library ======================

alias FN_DECIMAL = float;
extern (C++){



    struct FastNoise{


            enum Interp { Linear, Hermite, Quintic }

            enum FractalType { FBM, Billow, RigidMulti }

            enum CellularDistanceFunction { Euclidean, Manhattan, Natural }
            enum CellularReturnType { CellValue, NoiseLookup, Distance, Distance2, Distance2Add, Distance2Sub, Distance2Mul, Distance2Div }

            enum NoiseType{
                Value, ValueFractal, Perlin, PerlinFractal, Simplex, SimplexFractal, Cellular, WhiteNoise, Cubic, CubicFractal
            }

           private ubyte[512] m_perm;
           private ubyte[512] m_perm12;


           private int m_seed = 1337;
           private FN_DECIMAL m_frequency = 0.01;
           private Interp m_interp = Interp.Quintic;
           private NoiseType m_noiseType = NoiseType.Simplex;

           private int m_octaves = 3;

           private FN_DECIMAL m_lacunarity = FN_DECIMAL(2);
           private FN_DECIMAL m_gain = FN_DECIMAL(0.5);
           private FractalType m_fractalType = FractalType.FBM;
           private FN_DECIMAL m_fractalBounding;

           private CellularDistanceFunction m_cellularDistanceFunction = CellularDistanceFunction.Euclidean;
           private CellularReturnType m_cellularReturnType = CellularReturnType.CellValue;
           private FastNoise* m_cellularNoiseLookup = null;
           private int m_cellularDistanceIndex0 = 0;
           private int m_cellularDistanceIndex1 = 1;
           private FN_DECIMAL m_cellularJitter = FN_DECIMAL(0.45);

           private FN_DECIMAL m_gradientPerturbAmp = FN_DECIMAL(1);



           FN_DECIMAL GetFrequency(){
               return m_frequency;
           }
           void SetFrequency(FN_DECIMAL frequency){
               m_frequency = frequency;
           }
           NoiseType GetNoiseType() const{
               return m_noiseType;
           }
           void SetNoiseType(NoiseType typee){
               m_noiseType = typee;
           }
           @nogc FN_DECIMAL GetValue(FN_DECIMAL x, FN_DECIMAL y, FN_DECIMAL z) const;
    }
}


//bindings (voxelized)
extern (C){

    //TODO better noise handle (typed)
    void* allocFastNoise();
    void* freeFastNoise(void* noise);
    void setFrequency(void* noise, FN_DECIMAL frequency);
    void setNoiseType(void* noise, FastNoise.NoiseType typee);
    void setSeed(void* noise, int seed);
    @nogc FN_DECIMAL getValue(void* noise, FN_DECIMAL x, FN_DECIMAL y, FN_DECIMAL z);


    import hermite.uniform;


   /* struct UniformVoxelStorageC{ //TODO can we get around using this extra struct ?
        uint cellCount;
        float* grid;
        HermiteData!(float)** edge_info;
    }*/

    struct float3{
        float x;
        float y;
        float z;
    }

    void sampleGPU(float3 offset, float a, uint acc, UniformVoxelStorage!float* storage);
    void setConstantMem(); //TODO free it ?


    void setStackSize(size_t MB);
}

// =======================================================


enum GL_DEPTH_BUFFER_BIT = 0x00000100;
enum GL_STENCIL_BUFFER_BIT = 0x00000400;
enum GL_COLOR_BUFFER_BIT = 0x00004000;
enum GL_FALSE = 0;
enum GL_TRUE = 1;
enum GL_POINTS = 0x0000;
enum GL_LINES = 0x0001;
enum GL_LINE_LOOP = 0x0002;
enum GL_LINE_STRIP = 0x0003;
enum GL_TRIANGLES = 0x0004;
enum GL_TRIANGLE_STRIP = 0x0005;
enum GL_TRIANGLE_FAN = 0x0006;
enum GL_NEVER = 0x0200;
enum GL_LESS = 0x0201;
enum GL_EQUAL = 0x0202;
enum GL_LEQUAL = 0x0203;
enum GL_GREATER = 0x0204;
enum GL_NOTEQUAL = 0x0205;
enum GL_GEQUAL = 0x0206;
enum GL_ALWAYS = 0x0207;
enum GL_ZERO = 0;
enum GL_ONE = 1;
enum GL_SRC_COLOR = 0x0300;
enum GL_ONE_MINUS_SRC_COLOR = 0x0301;
enum GL_SRC_ALPHA = 0x0302;
enum GL_ONE_MINUS_SRC_ALPHA = 0x0303;
enum GL_DST_ALPHA = 0x0304;
enum GL_ONE_MINUS_DST_ALPHA = 0x0305;
enum GL_DST_COLOR = 0x0306;
enum GL_ONE_MINUS_DST_COLOR = 0x0307;
enum GL_SRC_ALPHA_SATURATE = 0x0308;
enum GL_NONE = 0;
enum GL_FRONT_LEFT = 0x0400;
enum GL_FRONT_RIGHT = 0x0401;
enum GL_BACK_LEFT = 0x0402;
enum GL_BACK_RIGHT = 0x0403;
enum GL_FRONT = 0x0404;
enum GL_BACK = 0x0405;
enum GL_LEFT = 0x0406;
enum GL_RIGHT = 0x0407;
enum GL_FRONT_AND_BACK = 0x0408;
enum GL_NO_ERROR = 0;
enum GL_INVALID_ENUM = 0x0500;
enum GL_INVALID_VALUE = 0x0501;
enum GL_INVALID_OPERATION = 0x0502;
enum GL_OUT_OF_MEMORY = 0x0505;
enum GL_CW = 0x0900;
enum GL_CCW = 0x0901;
enum GL_POINT_SIZE = 0x0B11;
enum GL_POINT_SIZE_RANGE = 0x0B12;
enum GL_POINT_SIZE_GRANULARITY = 0x0B13;
enum GL_LINE_SMOOTH = 0x0B20;
enum GL_LINE_WIDTH = 0x0B21;
enum GL_LINE_WIDTH_RANGE = 0x0B22;
enum GL_LINE_WIDTH_GRANULARITY = 0x0B23;
enum GL_POLYGON_MODE = 0x0B40;
enum GL_POLYGON_SMOOTH = 0x0B41;
enum GL_CULL_FACE = 0x0B44;
enum GL_CULL_FACE_MODE = 0x0B45;
enum GL_FRONT_FACE = 0x0B46;
enum GL_DEPTH_RANGE = 0x0B70;
enum GL_DEPTH_TEST = 0x0B71;
enum GL_DEPTH_WRITEMASK = 0x0B72;
enum GL_DEPTH_CLEAR_VALUE = 0x0B73;
enum GL_DEPTH_FUNC = 0x0B74;
enum GL_STENCIL_TEST = 0x0B90;
enum GL_STENCIL_CLEAR_VALUE = 0x0B91;
enum GL_STENCIL_FUNC = 0x0B92;
enum GL_STENCIL_VALUE_MASK = 0x0B93;
enum GL_STENCIL_FAIL = 0x0B94;
enum GL_STENCIL_PASS_DEPTH_FAIL = 0x0B95;
enum GL_STENCIL_PASS_DEPTH_PASS = 0x0B96;
enum GL_STENCIL_REF = 0x0B97;
enum GL_STENCIL_WRITEMASK = 0x0B98;
enum GL_VIEWPORT = 0x0BA2;
enum GL_DITHER = 0x0BD0;
enum GL_BLEND_DST = 0x0BE0;
enum GL_BLEND_SRC = 0x0BE1;
enum GL_BLEND = 0x0BE2;
enum GL_LOGIC_OP_MODE = 0x0BF0;
enum GL_DRAW_BUFFER = 0x0C01;
enum GL_READ_BUFFER = 0x0C02;
enum GL_SCISSOR_BOX = 0x0C10;
enum GL_SCISSOR_TEST = 0x0C11;
enum GL_COLOR_CLEAR_VALUE = 0x0C22;
enum GL_COLOR_WRITEMASK = 0x0C23;
enum GL_DOUBLEBUFFER = 0x0C32;
enum GL_STEREO = 0x0C33;
enum GL_LINE_SMOOTH_HINT = 0x0C52;
enum GL_POLYGON_SMOOTH_HINT = 0x0C53;
enum GL_UNPACK_SWAP_BYTES = 0x0CF0;
enum GL_UNPACK_LSB_FIRST = 0x0CF1;
enum GL_UNPACK_ROW_LENGTH = 0x0CF2;
enum GL_UNPACK_SKIP_ROWS = 0x0CF3;
enum GL_UNPACK_SKIP_PIXELS = 0x0CF4;
enum GL_UNPACK_ALIGNMENT = 0x0CF5;
enum GL_PACK_SWAP_BYTES = 0x0D00;
enum GL_PACK_LSB_FIRST = 0x0D01;
enum GL_PACK_ROW_LENGTH = 0x0D02;
enum GL_PACK_SKIP_ROWS = 0x0D03;
enum GL_PACK_SKIP_PIXELS = 0x0D04;
enum GL_PACK_ALIGNMENT = 0x0D05;
enum GL_MAX_TEXTURE_SIZE = 0x0D33;
enum GL_MAX_VIEWPORT_DIMS = 0x0D3A;
enum GL_SUBPIXEL_BITS = 0x0D50;
enum GL_TEXTURE_1D = 0x0DE0;
enum GL_TEXTURE_2D = 0x0DE1;
enum GL_TEXTURE_WIDTH = 0x1000;
enum GL_TEXTURE_HEIGHT = 0x1001;
enum GL_TEXTURE_BORDER_COLOR = 0x1004;
enum GL_DONT_CARE = 0x1100;
enum GL_FASTEST = 0x1101;
enum GL_NICEST = 0x1102;
enum GL_BYTE = 0x1400;
enum GL_UNSIGNED_BYTE = 0x1401;
enum GL_SHORT = 0x1402;
enum GL_UNSIGNED_SHORT = 0x1403;
enum GL_INT = 0x1404;
enum GL_UNSIGNED_INT = 0x1405;
enum GL_FLOAT = 0x1406;
enum GL_CLEAR = 0x1500;
enum GL_AND = 0x1501;
enum GL_AND_REVERSE = 0x1502;
enum GL_COPY = 0x1503;
enum GL_AND_INVERTED = 0x1504;
enum GL_NOOP = 0x1505;
enum GL_XOR = 0x1506;
enum GL_OR = 0x1507;
enum GL_NOR = 0x1508;
enum GL_EQUIV = 0x1509;
enum GL_INVERT = 0x150A;
enum GL_OR_REVERSE = 0x150B;
enum GL_COPY_INVERTED = 0x150C;
enum GL_OR_INVERTED = 0x150D;
enum GL_NAND = 0x150E;
enum GL_SET = 0x150F;
enum GL_TEXTURE = 0x1702;
enum GL_COLOR = 0x1800;
enum GL_DEPTH = 0x1801;
enum GL_STENCIL = 0x1802;
enum GL_STENCIL_INDEX = 0x1901;
enum GL_DEPTH_COMPONENT = 0x1902;
enum GL_RED = 0x1903;
enum GL_GREEN = 0x1904;
enum GL_BLUE = 0x1905;
enum GL_ALPHA = 0x1906;
enum GL_RGB = 0x1907;
enum GL_RGBA = 0x1908;
enum GL_POINT = 0x1B00;
enum GL_LINE = 0x1B01;
enum GL_FILL = 0x1B02;
enum GL_KEEP = 0x1E00;
enum GL_REPLACE = 0x1E01;
enum GL_INCR = 0x1E02;
enum GL_DECR = 0x1E03;
enum GL_VENDOR = 0x1F00;
enum GL_RENDERER = 0x1F01;
enum GL_VERSION = 0x1F02;
enum GL_EXTENSIONS = 0x1F03;
enum GL_NEAREST = 0x2600;
enum GL_LINEAR = 0x2601;
enum GL_NEAREST_MIPMAP_NEAREST = 0x2700;
enum GL_LINEAR_MIPMAP_NEAREST = 0x2701;
enum GL_NEAREST_MIPMAP_LINEAR = 0x2702;
enum GL_LINEAR_MIPMAP_LINEAR = 0x2703;
enum GL_TEXTURE_MAG_FILTER = 0x2800;
enum GL_TEXTURE_MIN_FILTER = 0x2801;
enum GL_TEXTURE_WRAP_S = 0x2802;
enum GL_TEXTURE_WRAP_T = 0x2803;
enum GL_REPEAT = 0x2901;
enum GL_COLOR_LOGIC_OP = 0x0BF2;
enum GL_POLYGON_OFFSET_UNITS = 0x2A00;
enum GL_POLYGON_OFFSET_POINT = 0x2A01;
enum GL_POLYGON_OFFSET_LINE = 0x2A02;
enum GL_POLYGON_OFFSET_FILL = 0x8037;
enum GL_POLYGON_OFFSET_FACTOR = 0x8038;
enum GL_TEXTURE_BINDING_1D = 0x8068;
enum GL_TEXTURE_BINDING_2D = 0x8069;
enum GL_TEXTURE_INTERNAL_FORMAT = 0x1003;
enum GL_TEXTURE_RED_SIZE = 0x805C;
enum GL_TEXTURE_GREEN_SIZE = 0x805D;
enum GL_TEXTURE_BLUE_SIZE = 0x805E;
enum GL_TEXTURE_ALPHA_SIZE = 0x805F;
enum GL_DOUBLE = 0x140A;
enum GL_PROXY_TEXTURE_1D = 0x8063;
enum GL_PROXY_TEXTURE_2D = 0x8064;
enum GL_R3_G3_B2 = 0x2A10;
enum GL_RGB4 = 0x804F;
enum GL_RGB5 = 0x8050;
enum GL_RGB8 = 0x8051;
enum GL_RGB10 = 0x8052;
enum GL_RGB12 = 0x8053;
enum GL_RGB16 = 0x8054;
enum GL_RGBA2 = 0x8055;
enum GL_RGBA4 = 0x8056;
enum GL_RGB5_A1 = 0x8057;
enum GL_RGBA8 = 0x8058;
enum GL_RGB10_A2 = 0x8059;
enum GL_RGBA12 = 0x805A;
enum GL_RGBA16 = 0x805B;
enum GL_UNSIGNED_BYTE_3_3_2 = 0x8032;
enum GL_UNSIGNED_SHORT_4_4_4_4 = 0x8033;
enum GL_UNSIGNED_SHORT_5_5_5_1 = 0x8034;
enum GL_UNSIGNED_INT_8_8_8_8 = 0x8035;
enum GL_UNSIGNED_INT_10_10_10_2 = 0x8036;
enum GL_TEXTURE_BINDING_3D = 0x806A;
enum GL_PACK_SKIP_IMAGES = 0x806B;
enum GL_PACK_IMAGE_HEIGHT = 0x806C;
enum GL_UNPACK_SKIP_IMAGES = 0x806D;
enum GL_UNPACK_IMAGE_HEIGHT = 0x806E;
enum GL_TEXTURE_3D = 0x806F;
enum GL_PROXY_TEXTURE_3D = 0x8070;
enum GL_TEXTURE_DEPTH = 0x8071;
enum GL_TEXTURE_WRAP_R = 0x8072;
enum GL_MAX_3D_TEXTURE_SIZE = 0x8073;
enum GL_UNSIGNED_BYTE_2_3_3_REV = 0x8362;
enum GL_UNSIGNED_SHORT_5_6_5 = 0x8363;
enum GL_UNSIGNED_SHORT_5_6_5_REV = 0x8364;
enum GL_UNSIGNED_SHORT_4_4_4_4_REV = 0x8365;
enum GL_UNSIGNED_SHORT_1_5_5_5_REV = 0x8366;
enum GL_UNSIGNED_INT_8_8_8_8_REV = 0x8367;
enum GL_UNSIGNED_INT_2_10_10_10_REV = 0x8368;
enum GL_BGR = 0x80E0;
enum GL_BGRA = 0x80E1;
enum GL_MAX_ELEMENTS_VERTICES = 0x80E8;
enum GL_MAX_ELEMENTS_INDICES = 0x80E9;
enum GL_CLAMP_TO_EDGE = 0x812F;
enum GL_TEXTURE_MIN_LOD = 0x813A;
enum GL_TEXTURE_MAX_LOD = 0x813B;
enum GL_TEXTURE_BASE_LEVEL = 0x813C;
enum GL_TEXTURE_MAX_LEVEL = 0x813D;
enum GL_SMOOTH_POINT_SIZE_RANGE = 0x0B12;
enum GL_SMOOTH_POINT_SIZE_GRANULARITY = 0x0B13;
enum GL_SMOOTH_LINE_WIDTH_RANGE = 0x0B22;
enum GL_SMOOTH_LINE_WIDTH_GRANULARITY = 0x0B23;
enum GL_ALIASED_LINE_WIDTH_RANGE = 0x846E;
enum GL_TEXTURE0 = 0x84C0;
enum GL_TEXTURE1 = 0x84C1;
enum GL_TEXTURE2 = 0x84C2;
enum GL_TEXTURE3 = 0x84C3;
enum GL_TEXTURE4 = 0x84C4;
enum GL_TEXTURE5 = 0x84C5;
enum GL_TEXTURE6 = 0x84C6;
enum GL_TEXTURE7 = 0x84C7;
enum GL_TEXTURE8 = 0x84C8;
enum GL_TEXTURE9 = 0x84C9;
enum GL_TEXTURE10 = 0x84CA;
enum GL_TEXTURE11 = 0x84CB;
enum GL_TEXTURE12 = 0x84CC;
enum GL_TEXTURE13 = 0x84CD;
enum GL_TEXTURE14 = 0x84CE;
enum GL_TEXTURE15 = 0x84CF;
enum GL_TEXTURE16 = 0x84D0;
enum GL_TEXTURE17 = 0x84D1;
enum GL_TEXTURE18 = 0x84D2;
enum GL_TEXTURE19 = 0x84D3;
enum GL_TEXTURE20 = 0x84D4;
enum GL_TEXTURE21 = 0x84D5;
enum GL_TEXTURE22 = 0x84D6;
enum GL_TEXTURE23 = 0x84D7;
enum GL_TEXTURE24 = 0x84D8;
enum GL_TEXTURE25 = 0x84D9;
enum GL_TEXTURE26 = 0x84DA;
enum GL_TEXTURE27 = 0x84DB;
enum GL_TEXTURE28 = 0x84DC;
enum GL_TEXTURE29 = 0x84DD;
enum GL_TEXTURE30 = 0x84DE;
enum GL_TEXTURE31 = 0x84DF;
enum GL_ACTIVE_TEXTURE = 0x84E0;
enum GL_MULTISAMPLE = 0x809D;
enum GL_SAMPLE_ALPHA_TO_COVERAGE = 0x809E;
enum GL_SAMPLE_ALPHA_TO_ONE = 0x809F;
enum GL_SAMPLE_COVERAGE = 0x80A0;
enum GL_SAMPLE_BUFFERS = 0x80A8;
enum GL_SAMPLES = 0x80A9;
enum GL_SAMPLE_COVERAGE_VALUE = 0x80AA;
enum GL_SAMPLE_COVERAGE_INVERT = 0x80AB;
enum GL_TEXTURE_CUBE_MAP = 0x8513;
enum GL_TEXTURE_BINDING_CUBE_MAP = 0x8514;
enum GL_TEXTURE_CUBE_MAP_POSITIVE_X = 0x8515;
enum GL_TEXTURE_CUBE_MAP_NEGATIVE_X = 0x8516;
enum GL_TEXTURE_CUBE_MAP_POSITIVE_Y = 0x8517;
enum GL_TEXTURE_CUBE_MAP_NEGATIVE_Y = 0x8518;
enum GL_TEXTURE_CUBE_MAP_POSITIVE_Z = 0x8519;
enum GL_TEXTURE_CUBE_MAP_NEGATIVE_Z = 0x851A;
enum GL_PROXY_TEXTURE_CUBE_MAP = 0x851B;
enum GL_MAX_CUBE_MAP_TEXTURE_SIZE = 0x851C;
enum GL_COMPRESSED_RGB = 0x84ED;
enum GL_COMPRESSED_RGBA = 0x84EE;
enum GL_TEXTURE_COMPRESSION_HINT = 0x84EF;
enum GL_TEXTURE_COMPRESSED_IMAGE_SIZE = 0x86A0;
enum GL_TEXTURE_COMPRESSED = 0x86A1;
enum GL_NUM_COMPRESSED_TEXTURE_FORMATS = 0x86A2;
enum GL_COMPRESSED_TEXTURE_FORMATS = 0x86A3;
enum GL_CLAMP_TO_BORDER = 0x812D;
enum GL_BLEND_DST_RGB = 0x80C8;
enum GL_BLEND_SRC_RGB = 0x80C9;
enum GL_BLEND_DST_ALPHA = 0x80CA;
enum GL_BLEND_SRC_ALPHA = 0x80CB;
enum GL_POINT_FADE_THRESHOLD_SIZE = 0x8128;
enum GL_DEPTH_COMPONENT16 = 0x81A5;
enum GL_DEPTH_COMPONENT24 = 0x81A6;
enum GL_DEPTH_COMPONENT32 = 0x81A7;
enum GL_MIRRORED_REPEAT = 0x8370;
enum GL_MAX_TEXTURE_LOD_BIAS = 0x84FD;
enum GL_TEXTURE_LOD_BIAS = 0x8501;
enum GL_INCR_WRAP = 0x8507;
enum GL_DECR_WRAP = 0x8508;
enum GL_TEXTURE_DEPTH_SIZE = 0x884A;
enum GL_TEXTURE_COMPARE_MODE = 0x884C;
enum GL_TEXTURE_COMPARE_FUNC = 0x884D;
enum GL_BLEND_COLOR = 0x8005;
enum GL_BLEND_EQUATION = 0x8009;
enum GL_CONSTANT_COLOR = 0x8001;
enum GL_ONE_MINUS_CONSTANT_COLOR = 0x8002;
enum GL_CONSTANT_ALPHA = 0x8003;
enum GL_ONE_MINUS_CONSTANT_ALPHA = 0x8004;
enum GL_FUNC_ADD = 0x8006;
enum GL_FUNC_REVERSE_SUBTRACT = 0x800B;
enum GL_FUNC_SUBTRACT = 0x800A;
enum GL_MIN = 0x8007;
enum GL_MAX = 0x8008;
enum GL_BUFFER_SIZE = 0x8764;
enum GL_BUFFER_USAGE = 0x8765;
enum GL_QUERY_COUNTER_BITS = 0x8864;
enum GL_CURRENT_QUERY = 0x8865;
enum GL_QUERY_RESULT = 0x8866;
enum GL_QUERY_RESULT_AVAILABLE = 0x8867;
enum GL_ARRAY_BUFFER = 0x8892;
enum GL_ELEMENT_ARRAY_BUFFER = 0x8893;
enum GL_ARRAY_BUFFER_BINDING = 0x8894;
enum GL_ELEMENT_ARRAY_BUFFER_BINDING = 0x8895;
enum GL_VERTEX_ATTRIB_ARRAY_BUFFER_BINDING = 0x889F;
enum GL_READ_ONLY = 0x88B8;
enum GL_WRITE_ONLY = 0x88B9;
enum GL_READ_WRITE = 0x88BA;
enum GL_BUFFER_ACCESS = 0x88BB;
enum GL_BUFFER_MAPPED = 0x88BC;
enum GL_BUFFER_MAP_POINTER = 0x88BD;
enum GL_STREAM_DRAW = 0x88E0;
enum GL_STREAM_READ = 0x88E1;
enum GL_STREAM_COPY = 0x88E2;
enum GL_STATIC_DRAW = 0x88E4;
enum GL_STATIC_READ = 0x88E5;
enum GL_STATIC_COPY = 0x88E6;
enum GL_DYNAMIC_DRAW = 0x88E8;
enum GL_DYNAMIC_READ = 0x88E9;
enum GL_DYNAMIC_COPY = 0x88EA;
enum GL_SAMPLES_PASSED = 0x8914;
enum GL_SRC1_ALPHA = 0x8589;
enum GL_BLEND_EQUATION_RGB = 0x8009;
enum GL_VERTEX_ATTRIB_ARRAY_ENABLED = 0x8622;
enum GL_VERTEX_ATTRIB_ARRAY_SIZE = 0x8623;
enum GL_VERTEX_ATTRIB_ARRAY_STRIDE = 0x8624;
enum GL_VERTEX_ATTRIB_ARRAY_TYPE = 0x8625;
enum GL_CURRENT_VERTEX_ATTRIB = 0x8626;
enum GL_VERTEX_PROGRAM_POINT_SIZE = 0x8642;
enum GL_VERTEX_ATTRIB_ARRAY_POINTER = 0x8645;
enum GL_STENCIL_BACK_FUNC = 0x8800;
enum GL_STENCIL_BACK_FAIL = 0x8801;
enum GL_STENCIL_BACK_PASS_DEPTH_FAIL = 0x8802;
enum GL_STENCIL_BACK_PASS_DEPTH_PASS = 0x8803;
enum GL_MAX_DRAW_BUFFERS = 0x8824;
enum GL_DRAW_BUFFER0 = 0x8825;
enum GL_DRAW_BUFFER1 = 0x8826;
enum GL_DRAW_BUFFER2 = 0x8827;
enum GL_DRAW_BUFFER3 = 0x8828;
enum GL_DRAW_BUFFER4 = 0x8829;
enum GL_DRAW_BUFFER5 = 0x882A;
enum GL_DRAW_BUFFER6 = 0x882B;
enum GL_DRAW_BUFFER7 = 0x882C;
enum GL_DRAW_BUFFER8 = 0x882D;
enum GL_DRAW_BUFFER9 = 0x882E;
enum GL_DRAW_BUFFER10 = 0x882F;
enum GL_DRAW_BUFFER11 = 0x8830;
enum GL_DRAW_BUFFER12 = 0x8831;
enum GL_DRAW_BUFFER13 = 0x8832;
enum GL_DRAW_BUFFER14 = 0x8833;
enum GL_DRAW_BUFFER15 = 0x8834;
enum GL_BLEND_EQUATION_ALPHA = 0x883D;
enum GL_MAX_VERTEX_ATTRIBS = 0x8869;
enum GL_VERTEX_ATTRIB_ARRAY_NORMALIZED = 0x886A;
enum GL_MAX_TEXTURE_IMAGE_UNITS = 0x8872;
enum GL_FRAGMENT_SHADER = 0x8B30;
enum GL_VERTEX_SHADER = 0x8B31;
enum GL_MAX_FRAGMENT_UNIFORM_COMPONENTS = 0x8B49;
enum GL_MAX_VERTEX_UNIFORM_COMPONENTS = 0x8B4A;
enum GL_MAX_VARYING_FLOATS = 0x8B4B;
enum GL_MAX_VERTEX_TEXTURE_IMAGE_UNITS = 0x8B4C;
enum GL_MAX_COMBINED_TEXTURE_IMAGE_UNITS = 0x8B4D;
enum GL_SHADER_TYPE = 0x8B4F;
enum GL_FLOAT_VEC2 = 0x8B50;
enum GL_FLOAT_VEC3 = 0x8B51;
enum GL_FLOAT_VEC4 = 0x8B52;
enum GL_INT_VEC2 = 0x8B53;
enum GL_INT_VEC3 = 0x8B54;
enum GL_INT_VEC4 = 0x8B55;
enum GL_BOOL = 0x8B56;
enum GL_BOOL_VEC2 = 0x8B57;
enum GL_BOOL_VEC3 = 0x8B58;
enum GL_BOOL_VEC4 = 0x8B59;
enum GL_FLOAT_MAT2 = 0x8B5A;
enum GL_FLOAT_MAT3 = 0x8B5B;
enum GL_FLOAT_MAT4 = 0x8B5C;
enum GL_SAMPLER_1D = 0x8B5D;
enum GL_SAMPLER_2D = 0x8B5E;
enum GL_SAMPLER_3D = 0x8B5F;
enum GL_SAMPLER_CUBE = 0x8B60;
enum GL_SAMPLER_1D_SHADOW = 0x8B61;
enum GL_SAMPLER_2D_SHADOW = 0x8B62;
enum GL_DELETE_STATUS = 0x8B80;
enum GL_COMPILE_STATUS = 0x8B81;
enum GL_LINK_STATUS = 0x8B82;
enum GL_VALIDATE_STATUS = 0x8B83;
enum GL_INFO_LOG_LENGTH = 0x8B84;
enum GL_ATTACHED_SHADERS = 0x8B85;
enum GL_ACTIVE_UNIFORMS = 0x8B86;
enum GL_ACTIVE_UNIFORM_MAX_LENGTH = 0x8B87;
enum GL_SHADER_SOURCE_LENGTH = 0x8B88;
enum GL_ACTIVE_ATTRIBUTES = 0x8B89;
enum GL_ACTIVE_ATTRIBUTE_MAX_LENGTH = 0x8B8A;
enum GL_FRAGMENT_SHADER_DERIVATIVE_HINT = 0x8B8B;
enum GL_SHADING_LANGUAGE_VERSION = 0x8B8C;
enum GL_CURRENT_PROGRAM = 0x8B8D;
enum GL_POINT_SPRITE_COORD_ORIGIN = 0x8CA0;
enum GL_LOWER_LEFT = 0x8CA1;
enum GL_UPPER_LEFT = 0x8CA2;
enum GL_STENCIL_BACK_REF = 0x8CA3;
enum GL_STENCIL_BACK_VALUE_MASK = 0x8CA4;
enum GL_STENCIL_BACK_WRITEMASK = 0x8CA5;
enum GL_PIXEL_PACK_BUFFER = 0x88EB;
enum GL_PIXEL_UNPACK_BUFFER = 0x88EC;
enum GL_PIXEL_PACK_BUFFER_BINDING = 0x88ED;
enum GL_PIXEL_UNPACK_BUFFER_BINDING = 0x88EF;
enum GL_FLOAT_MAT2x3 = 0x8B65;
enum GL_FLOAT_MAT2x4 = 0x8B66;
enum GL_FLOAT_MAT3x2 = 0x8B67;
enum GL_FLOAT_MAT3x4 = 0x8B68;
enum GL_FLOAT_MAT4x2 = 0x8B69;
enum GL_FLOAT_MAT4x3 = 0x8B6A;
enum GL_SRGB = 0x8C40;
enum GL_SRGB8 = 0x8C41;
enum GL_SRGB_ALPHA = 0x8C42;
enum GL_SRGB8_ALPHA8 = 0x8C43;
enum GL_COMPRESSED_SRGB = 0x8C48;
enum GL_COMPRESSED_SRGB_ALPHA = 0x8C49;
enum GL_COMPARE_REF_TO_TEXTURE = 0x884E;
enum GL_CLIP_DISTANCE0 = 0x3000;
enum GL_CLIP_DISTANCE1 = 0x3001;
enum GL_CLIP_DISTANCE2 = 0x3002;
enum GL_CLIP_DISTANCE3 = 0x3003;
enum GL_CLIP_DISTANCE4 = 0x3004;
enum GL_CLIP_DISTANCE5 = 0x3005;
enum GL_CLIP_DISTANCE6 = 0x3006;
enum GL_CLIP_DISTANCE7 = 0x3007;
enum GL_MAX_CLIP_DISTANCES = 0x0D32;
enum GL_MAJOR_VERSION = 0x821B;
enum GL_MINOR_VERSION = 0x821C;
enum GL_NUM_EXTENSIONS = 0x821D;
enum GL_CONTEXT_FLAGS = 0x821E;
enum GL_COMPRESSED_RED = 0x8225;
enum GL_COMPRESSED_RG = 0x8226;
enum GL_CONTEXT_FLAG_FORWARD_COMPATIBLE_BIT = 0x00000001;
enum GL_RGBA32F = 0x8814;
enum GL_RGB32F = 0x8815;
enum GL_RGBA16F = 0x881A;
enum GL_RGB16F = 0x881B;
enum GL_VERTEX_ATTRIB_ARRAY_INTEGER = 0x88FD;
enum GL_MAX_ARRAY_TEXTURE_LAYERS = 0x88FF;
enum GL_MIN_PROGRAM_TEXEL_OFFSET = 0x8904;
enum GL_MAX_PROGRAM_TEXEL_OFFSET = 0x8905;
enum GL_CLAMP_READ_COLOR = 0x891C;
enum GL_FIXED_ONLY = 0x891D;
enum GL_MAX_VARYING_COMPONENTS = 0x8B4B;
enum GL_TEXTURE_1D_ARRAY = 0x8C18;
enum GL_PROXY_TEXTURE_1D_ARRAY = 0x8C19;
enum GL_TEXTURE_2D_ARRAY = 0x8C1A;
enum GL_PROXY_TEXTURE_2D_ARRAY = 0x8C1B;
enum GL_TEXTURE_BINDING_1D_ARRAY = 0x8C1C;
enum GL_TEXTURE_BINDING_2D_ARRAY = 0x8C1D;
enum GL_R11F_G11F_B10F = 0x8C3A;
enum GL_UNSIGNED_INT_10F_11F_11F_REV = 0x8C3B;
enum GL_RGB9_E5 = 0x8C3D;
enum GL_UNSIGNED_INT_5_9_9_9_REV = 0x8C3E;
enum GL_TEXTURE_SHARED_SIZE = 0x8C3F;
enum GL_TRANSFORM_FEEDBACK_VARYING_MAX_LENGTH = 0x8C76;
enum GL_TRANSFORM_FEEDBACK_BUFFER_MODE = 0x8C7F;
enum GL_MAX_TRANSFORM_FEEDBACK_SEPARATE_COMPONENTS = 0x8C80;
enum GL_TRANSFORM_FEEDBACK_VARYINGS = 0x8C83;
enum GL_TRANSFORM_FEEDBACK_BUFFER_START = 0x8C84;
enum GL_TRANSFORM_FEEDBACK_BUFFER_SIZE = 0x8C85;
enum GL_PRIMITIVES_GENERATED = 0x8C87;
enum GL_TRANSFORM_FEEDBACK_PRIMITIVES_WRITTEN = 0x8C88;
enum GL_RASTERIZER_DISCARD = 0x8C89;
enum GL_MAX_TRANSFORM_FEEDBACK_INTERLEAVED_COMPONENTS = 0x8C8A;
enum GL_MAX_TRANSFORM_FEEDBACK_SEPARATE_ATTRIBS = 0x8C8B;
enum GL_INTERLEAVED_ATTRIBS = 0x8C8C;
enum GL_SEPARATE_ATTRIBS = 0x8C8D;
enum GL_TRANSFORM_FEEDBACK_BUFFER = 0x8C8E;
enum GL_TRANSFORM_FEEDBACK_BUFFER_BINDING = 0x8C8F;
enum GL_RGBA32UI = 0x8D70;
enum GL_RGB32UI = 0x8D71;
enum GL_RGBA16UI = 0x8D76;
enum GL_RGB16UI = 0x8D77;
enum GL_RGBA8UI = 0x8D7C;
enum GL_RGB8UI = 0x8D7D;
enum GL_RGBA32I = 0x8D82;
enum GL_RGB32I = 0x8D83;
enum GL_RGBA16I = 0x8D88;
enum GL_RGB16I = 0x8D89;
enum GL_RGBA8I = 0x8D8E;
enum GL_RGB8I = 0x8D8F;
enum GL_RED_INTEGER = 0x8D94;
enum GL_GREEN_INTEGER = 0x8D95;
enum GL_BLUE_INTEGER = 0x8D96;
enum GL_RGB_INTEGER = 0x8D98;
enum GL_RGBA_INTEGER = 0x8D99;
enum GL_BGR_INTEGER = 0x8D9A;
enum GL_BGRA_INTEGER = 0x8D9B;
enum GL_SAMPLER_1D_ARRAY = 0x8DC0;
enum GL_SAMPLER_2D_ARRAY = 0x8DC1;
enum GL_SAMPLER_1D_ARRAY_SHADOW = 0x8DC3;
enum GL_SAMPLER_2D_ARRAY_SHADOW = 0x8DC4;
enum GL_SAMPLER_CUBE_SHADOW = 0x8DC5;
enum GL_UNSIGNED_INT_VEC2 = 0x8DC6;
enum GL_UNSIGNED_INT_VEC3 = 0x8DC7;
enum GL_UNSIGNED_INT_VEC4 = 0x8DC8;
enum GL_INT_SAMPLER_1D = 0x8DC9;
enum GL_INT_SAMPLER_2D = 0x8DCA;
enum GL_INT_SAMPLER_3D = 0x8DCB;
enum GL_INT_SAMPLER_CUBE = 0x8DCC;
enum GL_INT_SAMPLER_1D_ARRAY = 0x8DCE;
enum GL_INT_SAMPLER_2D_ARRAY = 0x8DCF;
enum GL_UNSIGNED_INT_SAMPLER_1D = 0x8DD1;
enum GL_UNSIGNED_INT_SAMPLER_2D = 0x8DD2;
enum GL_UNSIGNED_INT_SAMPLER_3D = 0x8DD3;
enum GL_UNSIGNED_INT_SAMPLER_CUBE = 0x8DD4;
enum GL_UNSIGNED_INT_SAMPLER_1D_ARRAY = 0x8DD6;
enum GL_UNSIGNED_INT_SAMPLER_2D_ARRAY = 0x8DD7;
enum GL_QUERY_WAIT = 0x8E13;
enum GL_QUERY_NO_WAIT = 0x8E14;
enum GL_QUERY_BY_REGION_WAIT = 0x8E15;
enum GL_QUERY_BY_REGION_NO_WAIT = 0x8E16;
enum GL_BUFFER_ACCESS_FLAGS = 0x911F;
enum GL_BUFFER_MAP_LENGTH = 0x9120;
enum GL_BUFFER_MAP_OFFSET = 0x9121;
enum GL_DEPTH_COMPONENT32F = 0x8CAC;
enum GL_DEPTH32F_STENCIL8 = 0x8CAD;
enum GL_FLOAT_32_UNSIGNED_INT_24_8_REV = 0x8DAD;
enum GL_INVALID_FRAMEBUFFER_OPERATION = 0x0506;
enum GL_FRAMEBUFFER_ATTACHMENT_COLOR_ENCODING = 0x8210;
enum GL_FRAMEBUFFER_ATTACHMENT_COMPONENT_TYPE = 0x8211;
enum GL_FRAMEBUFFER_ATTACHMENT_RED_SIZE = 0x8212;
enum GL_FRAMEBUFFER_ATTACHMENT_GREEN_SIZE = 0x8213;
enum GL_FRAMEBUFFER_ATTACHMENT_BLUE_SIZE = 0x8214;
enum GL_FRAMEBUFFER_ATTACHMENT_ALPHA_SIZE = 0x8215;
enum GL_FRAMEBUFFER_ATTACHMENT_DEPTH_SIZE = 0x8216;
enum GL_FRAMEBUFFER_ATTACHMENT_STENCIL_SIZE = 0x8217;
enum GL_FRAMEBUFFER_DEFAULT = 0x8218;
enum GL_FRAMEBUFFER_UNDEFINED = 0x8219;
enum GL_DEPTH_STENCIL_ATTACHMENT = 0x821A;
enum GL_MAX_RENDERBUFFER_SIZE = 0x84E8;
enum GL_DEPTH_STENCIL = 0x84F9;
enum GL_UNSIGNED_INT_24_8 = 0x84FA;
enum GL_DEPTH24_STENCIL8 = 0x88F0;
enum GL_TEXTURE_STENCIL_SIZE = 0x88F1;
enum GL_TEXTURE_RED_TYPE = 0x8C10;
enum GL_TEXTURE_GREEN_TYPE = 0x8C11;
enum GL_TEXTURE_BLUE_TYPE = 0x8C12;
enum GL_TEXTURE_ALPHA_TYPE = 0x8C13;
enum GL_TEXTURE_DEPTH_TYPE = 0x8C16;
enum GL_UNSIGNED_NORMALIZED = 0x8C17;
enum GL_FRAMEBUFFER_BINDING = 0x8CA6;
enum GL_DRAW_FRAMEBUFFER_BINDING = 0x8CA6;
enum GL_RENDERBUFFER_BINDING = 0x8CA7;
enum GL_READ_FRAMEBUFFER = 0x8CA8;
enum GL_DRAW_FRAMEBUFFER = 0x8CA9;
enum GL_READ_FRAMEBUFFER_BINDING = 0x8CAA;
enum GL_RENDERBUFFER_SAMPLES = 0x8CAB;
enum GL_FRAMEBUFFER_ATTACHMENT_OBJECT_TYPE = 0x8CD0;
enum GL_FRAMEBUFFER_ATTACHMENT_OBJECT_NAME = 0x8CD1;
enum GL_FRAMEBUFFER_ATTACHMENT_TEXTURE_LEVEL = 0x8CD2;
enum GL_FRAMEBUFFER_ATTACHMENT_TEXTURE_CUBE_MAP_FACE = 0x8CD3;
enum GL_FRAMEBUFFER_ATTACHMENT_TEXTURE_LAYER = 0x8CD4;
enum GL_FRAMEBUFFER_COMPLETE = 0x8CD5;
enum GL_FRAMEBUFFER_INCOMPLETE_ATTACHMENT = 0x8CD6;
enum GL_FRAMEBUFFER_INCOMPLETE_MISSING_ATTACHMENT = 0x8CD7;
enum GL_FRAMEBUFFER_INCOMPLETE_DRAW_BUFFER = 0x8CDB;
enum GL_FRAMEBUFFER_INCOMPLETE_READ_BUFFER = 0x8CDC;
enum GL_FRAMEBUFFER_UNSUPPORTED = 0x8CDD;
enum GL_MAX_COLOR_ATTACHMENTS = 0x8CDF;
enum GL_COLOR_ATTACHMENT0 = 0x8CE0;
enum GL_COLOR_ATTACHMENT1 = 0x8CE1;
enum GL_COLOR_ATTACHMENT2 = 0x8CE2;
enum GL_COLOR_ATTACHMENT3 = 0x8CE3;
enum GL_COLOR_ATTACHMENT4 = 0x8CE4;
enum GL_COLOR_ATTACHMENT5 = 0x8CE5;
enum GL_COLOR_ATTACHMENT6 = 0x8CE6;
enum GL_COLOR_ATTACHMENT7 = 0x8CE7;
enum GL_COLOR_ATTACHMENT8 = 0x8CE8;
enum GL_COLOR_ATTACHMENT9 = 0x8CE9;
enum GL_COLOR_ATTACHMENT10 = 0x8CEA;
enum GL_COLOR_ATTACHMENT11 = 0x8CEB;
enum GL_COLOR_ATTACHMENT12 = 0x8CEC;
enum GL_COLOR_ATTACHMENT13 = 0x8CED;
enum GL_COLOR_ATTACHMENT14 = 0x8CEE;
enum GL_COLOR_ATTACHMENT15 = 0x8CEF;
enum GL_COLOR_ATTACHMENT16 = 0x8CF0;
enum GL_COLOR_ATTACHMENT17 = 0x8CF1;
enum GL_COLOR_ATTACHMENT18 = 0x8CF2;
enum GL_COLOR_ATTACHMENT19 = 0x8CF3;
enum GL_COLOR_ATTACHMENT20 = 0x8CF4;
enum GL_COLOR_ATTACHMENT21 = 0x8CF5;
enum GL_COLOR_ATTACHMENT22 = 0x8CF6;
enum GL_COLOR_ATTACHMENT23 = 0x8CF7;
enum GL_COLOR_ATTACHMENT24 = 0x8CF8;
enum GL_COLOR_ATTACHMENT25 = 0x8CF9;
enum GL_COLOR_ATTACHMENT26 = 0x8CFA;
enum GL_COLOR_ATTACHMENT27 = 0x8CFB;
enum GL_COLOR_ATTACHMENT28 = 0x8CFC;
enum GL_COLOR_ATTACHMENT29 = 0x8CFD;
enum GL_COLOR_ATTACHMENT30 = 0x8CFE;
enum GL_COLOR_ATTACHMENT31 = 0x8CFF;
enum GL_DEPTH_ATTACHMENT = 0x8D00;
enum GL_STENCIL_ATTACHMENT = 0x8D20;
enum GL_FRAMEBUFFER = 0x8D40;
enum GL_RENDERBUFFER = 0x8D41;
enum GL_RENDERBUFFER_WIDTH = 0x8D42;
enum GL_RENDERBUFFER_HEIGHT = 0x8D43;
enum GL_RENDERBUFFER_INTERNAL_FORMAT = 0x8D44;
enum GL_STENCIL_INDEX1 = 0x8D46;
enum GL_STENCIL_INDEX4 = 0x8D47;
enum GL_STENCIL_INDEX8 = 0x8D48;
enum GL_STENCIL_INDEX16 = 0x8D49;
enum GL_RENDERBUFFER_RED_SIZE = 0x8D50;
enum GL_RENDERBUFFER_GREEN_SIZE = 0x8D51;
enum GL_RENDERBUFFER_BLUE_SIZE = 0x8D52;
enum GL_RENDERBUFFER_ALPHA_SIZE = 0x8D53;
enum GL_RENDERBUFFER_DEPTH_SIZE = 0x8D54;
enum GL_RENDERBUFFER_STENCIL_SIZE = 0x8D55;
enum GL_FRAMEBUFFER_INCOMPLETE_MULTISAMPLE = 0x8D56;
enum GL_MAX_SAMPLES = 0x8D57;
enum GL_INDEX = 0x8222;
enum GL_FRAMEBUFFER_SRGB = 0x8DB9;
enum GL_HALF_FLOAT = 0x140B;
enum GL_MAP_READ_BIT = 0x0001;
enum GL_MAP_WRITE_BIT = 0x0002;
enum GL_MAP_INVALIDATE_RANGE_BIT = 0x0004;
enum GL_MAP_INVALIDATE_BUFFER_BIT = 0x0008;
enum GL_MAP_FLUSH_EXPLICIT_BIT = 0x0010;
enum GL_MAP_UNSYNCHRONIZED_BIT = 0x0020;
enum GL_COMPRESSED_RED_RGTC1 = 0x8DBB;
enum GL_COMPRESSED_SIGNED_RED_RGTC1 = 0x8DBC;
enum GL_COMPRESSED_RG_RGTC2 = 0x8DBD;
enum GL_COMPRESSED_SIGNED_RG_RGTC2 = 0x8DBE;
enum GL_RG = 0x8227;
enum GL_RG_INTEGER = 0x8228;
enum GL_R8 = 0x8229;
enum GL_R16 = 0x822A;
enum GL_RG8 = 0x822B;
enum GL_RG16 = 0x822C;
enum GL_R16F = 0x822D;
enum GL_R32F = 0x822E;
enum GL_RG16F = 0x822F;
enum GL_RG32F = 0x8230;
enum GL_R8I = 0x8231;
enum GL_R8UI = 0x8232;
enum GL_R16I = 0x8233;
enum GL_R16UI = 0x8234;
enum GL_R32I = 0x8235;
enum GL_R32UI = 0x8236;
enum GL_RG8I = 0x8237;
enum GL_RG8UI = 0x8238;
enum GL_RG16I = 0x8239;
enum GL_RG16UI = 0x823A;
enum GL_RG32I = 0x823B;
enum GL_RG32UI = 0x823C;
enum GL_VERTEX_ARRAY_BINDING = 0x85B5;
enum GL_SAMPLER_2D_RECT = 0x8B63;
enum GL_SAMPLER_2D_RECT_SHADOW = 0x8B64;
enum GL_SAMPLER_BUFFER = 0x8DC2;
enum GL_INT_SAMPLER_2D_RECT = 0x8DCD;
enum GL_INT_SAMPLER_BUFFER = 0x8DD0;
enum GL_UNSIGNED_INT_SAMPLER_2D_RECT = 0x8DD5;
enum GL_UNSIGNED_INT_SAMPLER_BUFFER = 0x8DD8;
enum GL_TEXTURE_BUFFER = 0x8C2A;
enum GL_MAX_TEXTURE_BUFFER_SIZE = 0x8C2B;
enum GL_TEXTURE_BINDING_BUFFER = 0x8C2C;
enum GL_TEXTURE_BUFFER_DATA_STORE_BINDING = 0x8C2D;
enum GL_TEXTURE_RECTANGLE = 0x84F5;
enum GL_TEXTURE_BINDING_RECTANGLE = 0x84F6;
enum GL_PROXY_TEXTURE_RECTANGLE = 0x84F7;
enum GL_MAX_RECTANGLE_TEXTURE_SIZE = 0x84F8;
enum GL_R8_SNORM = 0x8F94;
enum GL_RG8_SNORM = 0x8F95;
enum GL_RGB8_SNORM = 0x8F96;
enum GL_RGBA8_SNORM = 0x8F97;
enum GL_R16_SNORM = 0x8F98;
enum GL_RG16_SNORM = 0x8F99;
enum GL_RGB16_SNORM = 0x8F9A;
enum GL_RGBA16_SNORM = 0x8F9B;
enum GL_SIGNED_NORMALIZED = 0x8F9C;
enum GL_PRIMITIVE_RESTART = 0x8F9D;
enum GL_PRIMITIVE_RESTART_INDEX = 0x8F9E;
enum GL_COPY_READ_BUFFER = 0x8F36;
enum GL_COPY_WRITE_BUFFER = 0x8F37;
enum GL_UNIFORM_BUFFER = 0x8A11;
enum GL_UNIFORM_BUFFER_BINDING = 0x8A28;
enum GL_UNIFORM_BUFFER_START = 0x8A29;
enum GL_UNIFORM_BUFFER_SIZE = 0x8A2A;
enum GL_MAX_VERTEX_UNIFORM_BLOCKS = 0x8A2B;
enum GL_MAX_GEOMETRY_UNIFORM_BLOCKS = 0x8A2C;
enum GL_MAX_FRAGMENT_UNIFORM_BLOCKS = 0x8A2D;
enum GL_MAX_COMBINED_UNIFORM_BLOCKS = 0x8A2E;
enum GL_MAX_UNIFORM_BUFFER_BINDINGS = 0x8A2F;
enum GL_MAX_UNIFORM_BLOCK_SIZE = 0x8A30;
enum GL_MAX_COMBINED_VERTEX_UNIFORM_COMPONENTS = 0x8A31;
enum GL_MAX_COMBINED_GEOMETRY_UNIFORM_COMPONENTS = 0x8A32;
enum GL_MAX_COMBINED_FRAGMENT_UNIFORM_COMPONENTS = 0x8A33;
enum GL_UNIFORM_BUFFER_OFFSET_ALIGNMENT = 0x8A34;
enum GL_ACTIVE_UNIFORM_BLOCK_MAX_NAME_LENGTH = 0x8A35;
enum GL_ACTIVE_UNIFORM_BLOCKS = 0x8A36;
enum GL_UNIFORM_TYPE = 0x8A37;
enum GL_UNIFORM_SIZE = 0x8A38;
enum GL_UNIFORM_NAME_LENGTH = 0x8A39;
enum GL_UNIFORM_BLOCK_INDEX = 0x8A3A;
enum GL_UNIFORM_OFFSET = 0x8A3B;
enum GL_UNIFORM_ARRAY_STRIDE = 0x8A3C;
enum GL_UNIFORM_MATRIX_STRIDE = 0x8A3D;
enum GL_UNIFORM_IS_ROW_MAJOR = 0x8A3E;
enum GL_UNIFORM_BLOCK_BINDING = 0x8A3F;
enum GL_UNIFORM_BLOCK_DATA_SIZE = 0x8A40;
enum GL_UNIFORM_BLOCK_NAME_LENGTH = 0x8A41;
enum GL_UNIFORM_BLOCK_ACTIVE_UNIFORMS = 0x8A42;
enum GL_UNIFORM_BLOCK_ACTIVE_UNIFORM_INDICES = 0x8A43;
enum GL_UNIFORM_BLOCK_REFERENCED_BY_VERTEX_SHADER = 0x8A44;
enum GL_UNIFORM_BLOCK_REFERENCED_BY_GEOMETRY_SHADER = 0x8A45;
enum GL_UNIFORM_BLOCK_REFERENCED_BY_FRAGMENT_SHADER = 0x8A46;
enum GL_INVALID_INDEX = 0xFFFFFFFF;
enum GL_CONTEXT_CORE_PROFILE_BIT = 0x00000001;
enum GL_CONTEXT_COMPATIBILITY_PROFILE_BIT = 0x00000002;
enum GL_LINES_ADJACENCY = 0x000A;
enum GL_LINE_STRIP_ADJACENCY = 0x000B;
enum GL_TRIANGLES_ADJACENCY = 0x000C;
enum GL_TRIANGLE_STRIP_ADJACENCY = 0x000D;
enum GL_PROGRAM_POINT_SIZE = 0x8642;
enum GL_MAX_GEOMETRY_TEXTURE_IMAGE_UNITS = 0x8C29;
enum GL_FRAMEBUFFER_ATTACHMENT_LAYERED = 0x8DA7;
enum GL_FRAMEBUFFER_INCOMPLETE_LAYER_TARGETS = 0x8DA8;
enum GL_GEOMETRY_SHADER = 0x8DD9;
enum GL_GEOMETRY_VERTICES_OUT = 0x8916;
enum GL_GEOMETRY_INPUT_TYPE = 0x8917;
enum GL_GEOMETRY_OUTPUT_TYPE = 0x8918;
enum GL_MAX_GEOMETRY_UNIFORM_COMPONENTS = 0x8DDF;
enum GL_MAX_GEOMETRY_OUTPUT_VERTICES = 0x8DE0;
enum GL_MAX_GEOMETRY_TOTAL_OUTPUT_COMPONENTS = 0x8DE1;
enum GL_MAX_VERTEX_OUTPUT_COMPONENTS = 0x9122;
enum GL_MAX_GEOMETRY_INPUT_COMPONENTS = 0x9123;
enum GL_MAX_GEOMETRY_OUTPUT_COMPONENTS = 0x9124;
enum GL_MAX_FRAGMENT_INPUT_COMPONENTS = 0x9125;
enum GL_CONTEXT_PROFILE_MASK = 0x9126;
enum GL_DEPTH_CLAMP = 0x864F;
enum GL_QUADS_FOLLOW_PROVOKING_VERTEX_CONVENTION = 0x8E4C;
enum GL_FIRST_VERTEX_CONVENTION = 0x8E4D;
enum GL_LAST_VERTEX_CONVENTION = 0x8E4E;
enum GL_PROVOKING_VERTEX = 0x8E4F;
enum GL_TEXTURE_CUBE_MAP_SEAMLESS = 0x884F;
enum GL_MAX_SERVER_WAIT_TIMEOUT = 0x9111;
enum GL_OBJECT_TYPE = 0x9112;
enum GL_SYNC_CONDITION = 0x9113;
enum GL_SYNC_STATUS = 0x9114;
enum GL_SYNC_FLAGS = 0x9115;
enum GL_SYNC_FENCE = 0x9116;
enum GL_SYNC_GPU_COMMANDS_COMPLETE = 0x9117;
enum GL_UNSIGNALED = 0x9118;
enum GL_SIGNALED = 0x9119;
enum GL_ALREADY_SIGNALED = 0x911A;
enum GL_TIMEOUT_EXPIRED = 0x911B;
enum GL_CONDITION_SATISFIED = 0x911C;
enum GL_WAIT_FAILED = 0x911D;
enum GL_TIMEOUT_IGNORED = 0xFFFFFFFFFFFFFFFF;
enum GL_SYNC_FLUSH_COMMANDS_BIT = 0x00000001;
enum GL_SAMPLE_POSITION = 0x8E50;
enum GL_SAMPLE_MASK = 0x8E51;
enum GL_SAMPLE_MASK_VALUE = 0x8E52;
enum GL_MAX_SAMPLE_MASK_WORDS = 0x8E59;
enum GL_TEXTURE_2D_MULTISAMPLE = 0x9100;
enum GL_PROXY_TEXTURE_2D_MULTISAMPLE = 0x9101;
enum GL_TEXTURE_2D_MULTISAMPLE_ARRAY = 0x9102;
enum GL_PROXY_TEXTURE_2D_MULTISAMPLE_ARRAY = 0x9103;
enum GL_TEXTURE_BINDING_2D_MULTISAMPLE = 0x9104;
enum GL_TEXTURE_BINDING_2D_MULTISAMPLE_ARRAY = 0x9105;
enum GL_TEXTURE_SAMPLES = 0x9106;
enum GL_TEXTURE_FIXED_SAMPLE_LOCATIONS = 0x9107;
enum GL_SAMPLER_2D_MULTISAMPLE = 0x9108;
enum GL_INT_SAMPLER_2D_MULTISAMPLE = 0x9109;
enum GL_UNSIGNED_INT_SAMPLER_2D_MULTISAMPLE = 0x910A;
enum GL_SAMPLER_2D_MULTISAMPLE_ARRAY = 0x910B;
enum GL_INT_SAMPLER_2D_MULTISAMPLE_ARRAY = 0x910C;
enum GL_UNSIGNED_INT_SAMPLER_2D_MULTISAMPLE_ARRAY = 0x910D;
enum GL_MAX_COLOR_TEXTURE_SAMPLES = 0x910E;
enum GL_MAX_DEPTH_TEXTURE_SAMPLES = 0x910F;
enum GL_MAX_INTEGER_SAMPLES = 0x9110;
enum GL_VERTEX_ATTRIB_ARRAY_DIVISOR = 0x88FE;
enum GL_SRC1_COLOR = 0x88F9;
enum GL_ONE_MINUS_SRC1_COLOR = 0x88FA;
enum GL_ONE_MINUS_SRC1_ALPHA = 0x88FB;
enum GL_MAX_DUAL_SOURCE_DRAW_BUFFERS = 0x88FC;
enum GL_ANY_SAMPLES_PASSED = 0x8C2F;
enum GL_SAMPLER_BINDING = 0x8919;
enum GL_RGB10_A2UI = 0x906F;
enum GL_TEXTURE_SWIZZLE_R = 0x8E42;
enum GL_TEXTURE_SWIZZLE_G = 0x8E43;
enum GL_TEXTURE_SWIZZLE_B = 0x8E44;
enum GL_TEXTURE_SWIZZLE_A = 0x8E45;
enum GL_TEXTURE_SWIZZLE_RGBA = 0x8E46;
enum GL_TIME_ELAPSED = 0x88BF;
enum GL_TIMESTAMP = 0x8E28;
enum GL_INT_2_10_10_10_REV = 0x8D9F;
enum GL_SAMPLE_SHADING = 0x8C36;
enum GL_MIN_SAMPLE_SHADING_VALUE = 0x8C37;
enum GL_MIN_PROGRAM_TEXTURE_GATHER_OFFSET = 0x8E5E;
enum GL_MAX_PROGRAM_TEXTURE_GATHER_OFFSET = 0x8E5F;
enum GL_TEXTURE_CUBE_MAP_ARRAY = 0x9009;
enum GL_TEXTURE_BINDING_CUBE_MAP_ARRAY = 0x900A;
enum GL_PROXY_TEXTURE_CUBE_MAP_ARRAY = 0x900B;
enum GL_SAMPLER_CUBE_MAP_ARRAY = 0x900C;
enum GL_SAMPLER_CUBE_MAP_ARRAY_SHADOW = 0x900D;
enum GL_INT_SAMPLER_CUBE_MAP_ARRAY = 0x900E;
enum GL_UNSIGNED_INT_SAMPLER_CUBE_MAP_ARRAY = 0x900F;
enum GL_DRAW_INDIRECT_BUFFER = 0x8F3F;
enum GL_DRAW_INDIRECT_BUFFER_BINDING = 0x8F43;
enum GL_GEOMETRY_SHADER_INVOCATIONS = 0x887F;
enum GL_MAX_GEOMETRY_SHADER_INVOCATIONS = 0x8E5A;
enum GL_MIN_FRAGMENT_INTERPOLATION_OFFSET = 0x8E5B;
enum GL_MAX_FRAGMENT_INTERPOLATION_OFFSET = 0x8E5C;
enum GL_FRAGMENT_INTERPOLATION_OFFSET_BITS = 0x8E5D;
enum GL_MAX_VERTEX_STREAMS = 0x8E71;
enum GL_DOUBLE_VEC2 = 0x8FFC;
enum GL_DOUBLE_VEC3 = 0x8FFD;
enum GL_DOUBLE_VEC4 = 0x8FFE;
enum GL_DOUBLE_MAT2 = 0x8F46;
enum GL_DOUBLE_MAT3 = 0x8F47;
enum GL_DOUBLE_MAT4 = 0x8F48;
enum GL_DOUBLE_MAT2x3 = 0x8F49;
enum GL_DOUBLE_MAT2x4 = 0x8F4A;
enum GL_DOUBLE_MAT3x2 = 0x8F4B;
enum GL_DOUBLE_MAT3x4 = 0x8F4C;
enum GL_DOUBLE_MAT4x2 = 0x8F4D;
enum GL_DOUBLE_MAT4x3 = 0x8F4E;
enum GL_ACTIVE_SUBROUTINES = 0x8DE5;
enum GL_ACTIVE_SUBROUTINE_UNIFORMS = 0x8DE6;
enum GL_ACTIVE_SUBROUTINE_UNIFORM_LOCATIONS = 0x8E47;
enum GL_ACTIVE_SUBROUTINE_MAX_LENGTH = 0x8E48;
enum GL_ACTIVE_SUBROUTINE_UNIFORM_MAX_LENGTH = 0x8E49;
enum GL_MAX_SUBROUTINES = 0x8DE7;
enum GL_MAX_SUBROUTINE_UNIFORM_LOCATIONS = 0x8DE8;
enum GL_NUM_COMPATIBLE_SUBROUTINES = 0x8E4A;
enum GL_COMPATIBLE_SUBROUTINES = 0x8E4B;
enum GL_PATCHES = 0x000E;
enum GL_PATCH_VERTICES = 0x8E72;
enum GL_PATCH_DEFAULT_INNER_LEVEL = 0x8E73;
enum GL_PATCH_DEFAULT_OUTER_LEVEL = 0x8E74;
enum GL_TESS_CONTROL_OUTPUT_VERTICES = 0x8E75;
enum GL_TESS_GEN_MODE = 0x8E76;
enum GL_TESS_GEN_SPACING = 0x8E77;
enum GL_TESS_GEN_VERTEX_ORDER = 0x8E78;
enum GL_TESS_GEN_POINT_MODE = 0x8E79;
enum GL_ISOLINES = 0x8E7A;
enum GL_FRACTIONAL_ODD = 0x8E7B;
enum GL_FRACTIONAL_EVEN = 0x8E7C;
enum GL_MAX_PATCH_VERTICES = 0x8E7D;
enum GL_MAX_TESS_GEN_LEVEL = 0x8E7E;
enum GL_MAX_TESS_CONTROL_UNIFORM_COMPONENTS = 0x8E7F;
enum GL_MAX_TESS_EVALUATION_UNIFORM_COMPONENTS = 0x8E80;
enum GL_MAX_TESS_CONTROL_TEXTURE_IMAGE_UNITS = 0x8E81;
enum GL_MAX_TESS_EVALUATION_TEXTURE_IMAGE_UNITS = 0x8E82;
enum GL_MAX_TESS_CONTROL_OUTPUT_COMPONENTS = 0x8E83;
enum GL_MAX_TESS_PATCH_COMPONENTS = 0x8E84;
enum GL_MAX_TESS_CONTROL_TOTAL_OUTPUT_COMPONENTS = 0x8E85;
enum GL_MAX_TESS_EVALUATION_OUTPUT_COMPONENTS = 0x8E86;
enum GL_MAX_TESS_CONTROL_UNIFORM_BLOCKS = 0x8E89;
enum GL_MAX_TESS_EVALUATION_UNIFORM_BLOCKS = 0x8E8A;
enum GL_MAX_TESS_CONTROL_INPUT_COMPONENTS = 0x886C;
enum GL_MAX_TESS_EVALUATION_INPUT_COMPONENTS = 0x886D;
enum GL_MAX_COMBINED_TESS_CONTROL_UNIFORM_COMPONENTS = 0x8E1E;
enum GL_MAX_COMBINED_TESS_EVALUATION_UNIFORM_COMPONENTS = 0x8E1F;
enum GL_UNIFORM_BLOCK_REFERENCED_BY_TESS_CONTROL_SHADER = 0x84F0;
enum GL_UNIFORM_BLOCK_REFERENCED_BY_TESS_EVALUATION_SHADER = 0x84F1;
enum GL_TESS_EVALUATION_SHADER = 0x8E87;
enum GL_TESS_CONTROL_SHADER = 0x8E88;
enum GL_TRANSFORM_FEEDBACK = 0x8E22;
enum GL_TRANSFORM_FEEDBACK_BUFFER_PAUSED = 0x8E23;
enum GL_TRANSFORM_FEEDBACK_BUFFER_ACTIVE = 0x8E24;
enum GL_TRANSFORM_FEEDBACK_BINDING = 0x8E25;
enum GL_MAX_TRANSFORM_FEEDBACK_BUFFERS = 0x8E70;
enum GL_FIXED = 0x140C;
enum GL_IMPLEMENTATION_COLOR_READ_TYPE = 0x8B9A;
enum GL_IMPLEMENTATION_COLOR_READ_FORMAT = 0x8B9B;
enum GL_LOW_FLOAT = 0x8DF0;
enum GL_MEDIUM_FLOAT = 0x8DF1;
enum GL_HIGH_FLOAT = 0x8DF2;
enum GL_LOW_INT = 0x8DF3;
enum GL_MEDIUM_INT = 0x8DF4;
enum GL_HIGH_INT = 0x8DF5;
enum GL_SHADER_COMPILER = 0x8DFA;
enum GL_SHADER_BINARY_FORMATS = 0x8DF8;
enum GL_NUM_SHADER_BINARY_FORMATS = 0x8DF9;
enum GL_MAX_VERTEX_UNIFORM_VECTORS = 0x8DFB;
enum GL_MAX_VARYING_VECTORS = 0x8DFC;
enum GL_MAX_FRAGMENT_UNIFORM_VECTORS = 0x8DFD;
enum GL_RGB565 = 0x8D62;
enum GL_PROGRAM_BINARY_RETRIEVABLE_HINT = 0x8257;
enum GL_PROGRAM_BINARY_LENGTH = 0x8741;
enum GL_NUM_PROGRAM_BINARY_FORMATS = 0x87FE;
enum GL_PROGRAM_BINARY_FORMATS = 0x87FF;
enum GL_VERTEX_SHADER_BIT = 0x00000001;
enum GL_FRAGMENT_SHADER_BIT = 0x00000002;
enum GL_GEOMETRY_SHADER_BIT = 0x00000004;
enum GL_TESS_CONTROL_SHADER_BIT = 0x00000008;
enum GL_TESS_EVALUATION_SHADER_BIT = 0x00000010;
enum GL_ALL_SHADER_BITS = 0xFFFFFFFF;
enum GL_PROGRAM_SEPARABLE = 0x8258;
enum GL_ACTIVE_PROGRAM = 0x8259;
enum GL_PROGRAM_PIPELINE_BINDING = 0x825A;
enum GL_MAX_VIEWPORTS = 0x825B;
enum GL_VIEWPORT_SUBPIXEL_BITS = 0x825C;
enum GL_VIEWPORT_BOUNDS_RANGE = 0x825D;
enum GL_LAYER_PROVOKING_VERTEX = 0x825E;
enum GL_VIEWPORT_INDEX_PROVOKING_VERTEX = 0x825F;
enum GL_UNDEFINED_VERTEX = 0x8260;
enum GL_COPY_READ_BUFFER_BINDING = 0x8F36;
enum GL_COPY_WRITE_BUFFER_BINDING = 0x8F37;
enum GL_TRANSFORM_FEEDBACK_ACTIVE = 0x8E24;
enum GL_TRANSFORM_FEEDBACK_PAUSED = 0x8E23;
enum GL_UNPACK_COMPRESSED_BLOCK_WIDTH = 0x9127;
enum GL_UNPACK_COMPRESSED_BLOCK_HEIGHT = 0x9128;
enum GL_UNPACK_COMPRESSED_BLOCK_DEPTH = 0x9129;
enum GL_UNPACK_COMPRESSED_BLOCK_SIZE = 0x912A;
enum GL_PACK_COMPRESSED_BLOCK_WIDTH = 0x912B;
enum GL_PACK_COMPRESSED_BLOCK_HEIGHT = 0x912C;
enum GL_PACK_COMPRESSED_BLOCK_DEPTH = 0x912D;
enum GL_PACK_COMPRESSED_BLOCK_SIZE = 0x912E;
enum GL_NUM_SAMPLE_COUNTS = 0x9380;
enum GL_MIN_MAP_BUFFER_ALIGNMENT = 0x90BC;
enum GL_ATOMIC_COUNTER_BUFFER = 0x92C0;
enum GL_ATOMIC_COUNTER_BUFFER_BINDING = 0x92C1;
enum GL_ATOMIC_COUNTER_BUFFER_START = 0x92C2;
enum GL_ATOMIC_COUNTER_BUFFER_SIZE = 0x92C3;
enum GL_ATOMIC_COUNTER_BUFFER_DATA_SIZE = 0x92C4;
enum GL_ATOMIC_COUNTER_BUFFER_ACTIVE_ATOMIC_COUNTERS = 0x92C5;
enum GL_ATOMIC_COUNTER_BUFFER_ACTIVE_ATOMIC_COUNTER_INDICES = 0x92C6;
enum GL_ATOMIC_COUNTER_BUFFER_REFERENCED_BY_VERTEX_SHADER = 0x92C7;
enum GL_ATOMIC_COUNTER_BUFFER_REFERENCED_BY_TESS_CONTROL_SHADER = 0x92C8;
enum GL_ATOMIC_COUNTER_BUFFER_REFERENCED_BY_TESS_EVALUATION_SHADER = 0x92C9;
enum GL_ATOMIC_COUNTER_BUFFER_REFERENCED_BY_GEOMETRY_SHADER = 0x92CA;
enum GL_ATOMIC_COUNTER_BUFFER_REFERENCED_BY_FRAGMENT_SHADER = 0x92CB;
enum GL_MAX_VERTEX_ATOMIC_COUNTER_BUFFERS = 0x92CC;
enum GL_MAX_TESS_CONTROL_ATOMIC_COUNTER_BUFFERS = 0x92CD;
enum GL_MAX_TESS_EVALUATION_ATOMIC_COUNTER_BUFFERS = 0x92CE;
enum GL_MAX_GEOMETRY_ATOMIC_COUNTER_BUFFERS = 0x92CF;
enum GL_MAX_FRAGMENT_ATOMIC_COUNTER_BUFFERS = 0x92D0;
enum GL_MAX_COMBINED_ATOMIC_COUNTER_BUFFERS = 0x92D1;
enum GL_MAX_VERTEX_ATOMIC_COUNTERS = 0x92D2;
enum GL_MAX_TESS_CONTROL_ATOMIC_COUNTERS = 0x92D3;
enum GL_MAX_TESS_EVALUATION_ATOMIC_COUNTERS = 0x92D4;
enum GL_MAX_GEOMETRY_ATOMIC_COUNTERS = 0x92D5;
enum GL_MAX_FRAGMENT_ATOMIC_COUNTERS = 0x92D6;
enum GL_MAX_COMBINED_ATOMIC_COUNTERS = 0x92D7;
enum GL_MAX_ATOMIC_COUNTER_BUFFER_SIZE = 0x92D8;
enum GL_MAX_ATOMIC_COUNTER_BUFFER_BINDINGS = 0x92DC;
enum GL_ACTIVE_ATOMIC_COUNTER_BUFFERS = 0x92D9;
enum GL_UNIFORM_ATOMIC_COUNTER_BUFFER_INDEX = 0x92DA;
enum GL_UNSIGNED_INT_ATOMIC_COUNTER = 0x92DB;
enum GL_VERTEX_ATTRIB_ARRAY_BARRIER_BIT = 0x00000001;
enum GL_ELEMENT_ARRAY_BARRIER_BIT = 0x00000002;
enum GL_UNIFORM_BARRIER_BIT = 0x00000004;
enum GL_TEXTURE_FETCH_BARRIER_BIT = 0x00000008;
enum GL_SHADER_IMAGE_ACCESS_BARRIER_BIT = 0x00000020;
enum GL_COMMAND_BARRIER_BIT = 0x00000040;
enum GL_PIXEL_BUFFER_BARRIER_BIT = 0x00000080;
enum GL_TEXTURE_UPDATE_BARRIER_BIT = 0x00000100;
enum GL_BUFFER_UPDATE_BARRIER_BIT = 0x00000200;
enum GL_FRAMEBUFFER_BARRIER_BIT = 0x00000400;
enum GL_TRANSFORM_FEEDBACK_BARRIER_BIT = 0x00000800;
enum GL_ATOMIC_COUNTER_BARRIER_BIT = 0x00001000;
enum GL_ALL_BARRIER_BITS = 0xFFFFFFFF;
enum GL_MAX_IMAGE_UNITS = 0x8F38;
enum GL_MAX_COMBINED_IMAGE_UNITS_AND_FRAGMENT_OUTPUTS = 0x8F39;
enum GL_IMAGE_BINDING_NAME = 0x8F3A;
enum GL_IMAGE_BINDING_LEVEL = 0x8F3B;
enum GL_IMAGE_BINDING_LAYERED = 0x8F3C;
enum GL_IMAGE_BINDING_LAYER = 0x8F3D;
enum GL_IMAGE_BINDING_ACCESS = 0x8F3E;
enum GL_IMAGE_1D = 0x904C;
enum GL_IMAGE_2D = 0x904D;
enum GL_IMAGE_3D = 0x904E;
enum GL_IMAGE_2D_RECT = 0x904F;
enum GL_IMAGE_CUBE = 0x9050;
enum GL_IMAGE_BUFFER = 0x9051;
enum GL_IMAGE_1D_ARRAY = 0x9052;
enum GL_IMAGE_2D_ARRAY = 0x9053;
enum GL_IMAGE_CUBE_MAP_ARRAY = 0x9054;
enum GL_IMAGE_2D_MULTISAMPLE = 0x9055;
enum GL_IMAGE_2D_MULTISAMPLE_ARRAY = 0x9056;
enum GL_INT_IMAGE_1D = 0x9057;
enum GL_INT_IMAGE_2D = 0x9058;
enum GL_INT_IMAGE_3D = 0x9059;
enum GL_INT_IMAGE_2D_RECT = 0x905A;
enum GL_INT_IMAGE_CUBE = 0x905B;
enum GL_INT_IMAGE_BUFFER = 0x905C;
enum GL_INT_IMAGE_1D_ARRAY = 0x905D;
enum GL_INT_IMAGE_2D_ARRAY = 0x905E;
enum GL_INT_IMAGE_CUBE_MAP_ARRAY = 0x905F;
enum GL_INT_IMAGE_2D_MULTISAMPLE = 0x9060;
enum GL_INT_IMAGE_2D_MULTISAMPLE_ARRAY = 0x9061;
enum GL_UNSIGNED_INT_IMAGE_1D = 0x9062;
enum GL_UNSIGNED_INT_IMAGE_2D = 0x9063;
enum GL_UNSIGNED_INT_IMAGE_3D = 0x9064;
enum GL_UNSIGNED_INT_IMAGE_2D_RECT = 0x9065;
enum GL_UNSIGNED_INT_IMAGE_CUBE = 0x9066;
enum GL_UNSIGNED_INT_IMAGE_BUFFER = 0x9067;
enum GL_UNSIGNED_INT_IMAGE_1D_ARRAY = 0x9068;
enum GL_UNSIGNED_INT_IMAGE_2D_ARRAY = 0x9069;
enum GL_UNSIGNED_INT_IMAGE_CUBE_MAP_ARRAY = 0x906A;
enum GL_UNSIGNED_INT_IMAGE_2D_MULTISAMPLE = 0x906B;
enum GL_UNSIGNED_INT_IMAGE_2D_MULTISAMPLE_ARRAY = 0x906C;
enum GL_MAX_IMAGE_SAMPLES = 0x906D;
enum GL_IMAGE_BINDING_FORMAT = 0x906E;
enum GL_IMAGE_FORMAT_COMPATIBILITY_TYPE = 0x90C7;
enum GL_IMAGE_FORMAT_COMPATIBILITY_BY_SIZE = 0x90C8;
enum GL_IMAGE_FORMAT_COMPATIBILITY_BY_CLASS = 0x90C9;
enum GL_MAX_VERTEX_IMAGE_UNIFORMS = 0x90CA;
enum GL_MAX_TESS_CONTROL_IMAGE_UNIFORMS = 0x90CB;
enum GL_MAX_TESS_EVALUATION_IMAGE_UNIFORMS = 0x90CC;
enum GL_MAX_GEOMETRY_IMAGE_UNIFORMS = 0x90CD;
enum GL_MAX_FRAGMENT_IMAGE_UNIFORMS = 0x90CE;
enum GL_MAX_COMBINED_IMAGE_UNIFORMS = 0x90CF;
enum GL_COMPRESSED_RGBA_BPTC_UNORM = 0x8E8C;
enum GL_COMPRESSED_SRGB_ALPHA_BPTC_UNORM = 0x8E8D;
enum GL_COMPRESSED_RGB_BPTC_SIGNED_FLOAT = 0x8E8E;
enum GL_COMPRESSED_RGB_BPTC_UNSIGNED_FLOAT = 0x8E8F;
enum GL_TEXTURE_IMMUTABLE_FORMAT = 0x912F;
enum GL_NUM_SHADING_LANGUAGE_VERSIONS = 0x82E9;
enum GL_VERTEX_ATTRIB_ARRAY_LONG = 0x874E;
enum GL_COMPRESSED_RGB8_ETC2 = 0x9274;
enum GL_COMPRESSED_SRGB8_ETC2 = 0x9275;
enum GL_COMPRESSED_RGB8_PUNCHTHROUGH_ALPHA1_ETC2 = 0x9276;
enum GL_COMPRESSED_SRGB8_PUNCHTHROUGH_ALPHA1_ETC2 = 0x9277;
enum GL_COMPRESSED_RGBA8_ETC2_EAC = 0x9278;
enum GL_COMPRESSED_SRGB8_ALPHA8_ETC2_EAC = 0x9279;
enum GL_COMPRESSED_R11_EAC = 0x9270;
enum GL_COMPRESSED_SIGNED_R11_EAC = 0x9271;
enum GL_COMPRESSED_RG11_EAC = 0x9272;
enum GL_COMPRESSED_SIGNED_RG11_EAC = 0x9273;
enum GL_PRIMITIVE_RESTART_FIXED_INDEX = 0x8D69;
enum GL_ANY_SAMPLES_PASSED_CONSERVATIVE = 0x8D6A;
enum GL_MAX_ELEMENT_INDEX = 0x8D6B;
enum GL_COMPUTE_SHADER = 0x91B9;
enum GL_MAX_COMPUTE_UNIFORM_BLOCKS = 0x91BB;
enum GL_MAX_COMPUTE_TEXTURE_IMAGE_UNITS = 0x91BC;
enum GL_MAX_COMPUTE_IMAGE_UNIFORMS = 0x91BD;
enum GL_MAX_COMPUTE_SHARED_MEMORY_SIZE = 0x8262;
enum GL_MAX_COMPUTE_UNIFORM_COMPONENTS = 0x8263;
enum GL_MAX_COMPUTE_ATOMIC_COUNTER_BUFFERS = 0x8264;
enum GL_MAX_COMPUTE_ATOMIC_COUNTERS = 0x8265;
enum GL_MAX_COMBINED_COMPUTE_UNIFORM_COMPONENTS = 0x8266;
enum GL_MAX_COMPUTE_WORK_GROUP_INVOCATIONS = 0x90EB;
enum GL_MAX_COMPUTE_WORK_GROUP_COUNT = 0x91BE;
enum GL_MAX_COMPUTE_WORK_GROUP_SIZE = 0x91BF;
enum GL_COMPUTE_WORK_GROUP_SIZE = 0x8267;
enum GL_UNIFORM_BLOCK_REFERENCED_BY_COMPUTE_SHADER = 0x90EC;
enum GL_ATOMIC_COUNTER_BUFFER_REFERENCED_BY_COMPUTE_SHADER = 0x90ED;
enum GL_DISPATCH_INDIRECT_BUFFER = 0x90EE;
enum GL_DISPATCH_INDIRECT_BUFFER_BINDING = 0x90EF;
enum GL_COMPUTE_SHADER_BIT = 0x00000020;
enum GL_DEBUG_OUTPUT_SYNCHRONOUS = 0x8242;
enum GL_DEBUG_NEXT_LOGGED_MESSAGE_LENGTH = 0x8243;
enum GL_DEBUG_CALLBACK_FUNCTION = 0x8244;
enum GL_DEBUG_CALLBACK_USER_PARAM = 0x8245;
enum GL_DEBUG_SOURCE_API = 0x8246;
enum GL_DEBUG_SOURCE_WINDOW_SYSTEM = 0x8247;
enum GL_DEBUG_SOURCE_SHADER_COMPILER = 0x8248;
enum GL_DEBUG_SOURCE_THIRD_PARTY = 0x8249;
enum GL_DEBUG_SOURCE_APPLICATION = 0x824A;
enum GL_DEBUG_SOURCE_OTHER = 0x824B;
enum GL_DEBUG_TYPE_ERROR = 0x824C;
enum GL_DEBUG_TYPE_DEPRECATED_BEHAVIOR = 0x824D;
enum GL_DEBUG_TYPE_UNDEFINED_BEHAVIOR = 0x824E;
enum GL_DEBUG_TYPE_PORTABILITY = 0x824F;
enum GL_DEBUG_TYPE_PERFORMANCE = 0x8250;
enum GL_DEBUG_TYPE_OTHER = 0x8251;
enum GL_MAX_DEBUG_MESSAGE_LENGTH = 0x9143;
enum GL_MAX_DEBUG_LOGGED_MESSAGES = 0x9144;
enum GL_DEBUG_LOGGED_MESSAGES = 0x9145;
enum GL_DEBUG_SEVERITY_HIGH = 0x9146;
enum GL_DEBUG_SEVERITY_MEDIUM = 0x9147;
enum GL_DEBUG_SEVERITY_LOW = 0x9148;
enum GL_DEBUG_TYPE_MARKER = 0x8268;
enum GL_DEBUG_TYPE_PUSH_GROUP = 0x8269;
enum GL_DEBUG_TYPE_POP_GROUP = 0x826A;
enum GL_DEBUG_SEVERITY_NOTIFICATION = 0x826B;
enum GL_MAX_DEBUG_GROUP_STACK_DEPTH = 0x826C;
enum GL_DEBUG_GROUP_STACK_DEPTH = 0x826D;
enum GL_BUFFER = 0x82E0;
enum GL_SHADER = 0x82E1;
enum GL_PROGRAM = 0x82E2;
enum GL_QUERY = 0x82E3;
enum GL_PROGRAM_PIPELINE = 0x82E4;
enum GL_SAMPLER = 0x82E6;
enum GL_MAX_LABEL_LENGTH = 0x82E8;
enum GL_DEBUG_OUTPUT = 0x92E0;
enum GL_CONTEXT_FLAG_DEBUG_BIT = 0x00000002;
enum GL_MAX_UNIFORM_LOCATIONS = 0x826E;
enum GL_FRAMEBUFFER_DEFAULT_WIDTH = 0x9310;
enum GL_FRAMEBUFFER_DEFAULT_HEIGHT = 0x9311;
enum GL_FRAMEBUFFER_DEFAULT_LAYERS = 0x9312;
enum GL_FRAMEBUFFER_DEFAULT_SAMPLES = 0x9313;
enum GL_FRAMEBUFFER_DEFAULT_FIXED_SAMPLE_LOCATIONS = 0x9314;
enum GL_MAX_FRAMEBUFFER_WIDTH = 0x9315;
enum GL_MAX_FRAMEBUFFER_HEIGHT = 0x9316;
enum GL_MAX_FRAMEBUFFER_LAYERS = 0x9317;
enum GL_MAX_FRAMEBUFFER_SAMPLES = 0x9318;
enum GL_INTERNALFORMAT_SUPPORTED = 0x826F;
enum GL_INTERNALFORMAT_PREFERRED = 0x8270;
enum GL_INTERNALFORMAT_RED_SIZE = 0x8271;
enum GL_INTERNALFORMAT_GREEN_SIZE = 0x8272;
enum GL_INTERNALFORMAT_BLUE_SIZE = 0x8273;
enum GL_INTERNALFORMAT_ALPHA_SIZE = 0x8274;
enum GL_INTERNALFORMAT_DEPTH_SIZE = 0x8275;
enum GL_INTERNALFORMAT_STENCIL_SIZE = 0x8276;
enum GL_INTERNALFORMAT_SHARED_SIZE = 0x8277;
enum GL_INTERNALFORMAT_RED_TYPE = 0x8278;
enum GL_INTERNALFORMAT_GREEN_TYPE = 0x8279;
enum GL_INTERNALFORMAT_BLUE_TYPE = 0x827A;
enum GL_INTERNALFORMAT_ALPHA_TYPE = 0x827B;
enum GL_INTERNALFORMAT_DEPTH_TYPE = 0x827C;
enum GL_INTERNALFORMAT_STENCIL_TYPE = 0x827D;
enum GL_MAX_WIDTH = 0x827E;
enum GL_MAX_HEIGHT = 0x827F;
enum GL_MAX_DEPTH = 0x8280;
enum GL_MAX_LAYERS = 0x8281;
enum GL_MAX_COMBINED_DIMENSIONS = 0x8282;
enum GL_COLOR_COMPONENTS = 0x8283;
enum GL_DEPTH_COMPONENTS = 0x8284;
enum GL_STENCIL_COMPONENTS = 0x8285;
enum GL_COLOR_RENDERABLE = 0x8286;
enum GL_DEPTH_RENDERABLE = 0x8287;
enum GL_STENCIL_RENDERABLE = 0x8288;
enum GL_FRAMEBUFFER_RENDERABLE = 0x8289;
enum GL_FRAMEBUFFER_RENDERABLE_LAYERED = 0x828A;
enum GL_FRAMEBUFFER_BLEND = 0x828B;
enum GL_READ_PIXELS = 0x828C;
enum GL_READ_PIXELS_FORMAT = 0x828D;
enum GL_READ_PIXELS_TYPE = 0x828E;
enum GL_TEXTURE_IMAGE_FORMAT = 0x828F;
enum GL_TEXTURE_IMAGE_TYPE = 0x8290;
enum GL_GET_TEXTURE_IMAGE_FORMAT = 0x8291;
enum GL_GET_TEXTURE_IMAGE_TYPE = 0x8292;
enum GL_MIPMAP = 0x8293;
enum GL_MANUAL_GENERATE_MIPMAP = 0x8294;
enum GL_AUTO_GENERATE_MIPMAP = 0x8295;
enum GL_COLOR_ENCODING = 0x8296;
enum GL_SRGB_READ = 0x8297;
enum GL_SRGB_WRITE = 0x8298;
enum GL_FILTER = 0x829A;
enum GL_VERTEX_TEXTURE = 0x829B;
enum GL_TESS_CONTROL_TEXTURE = 0x829C;
enum GL_TESS_EVALUATION_TEXTURE = 0x829D;
enum GL_GEOMETRY_TEXTURE = 0x829E;
enum GL_FRAGMENT_TEXTURE = 0x829F;
enum GL_COMPUTE_TEXTURE = 0x82A0;
enum GL_TEXTURE_SHADOW = 0x82A1;
enum GL_TEXTURE_GATHER = 0x82A2;
enum GL_TEXTURE_GATHER_SHADOW = 0x82A3;
enum GL_SHADER_IMAGE_LOAD = 0x82A4;
enum GL_SHADER_IMAGE_STORE = 0x82A5;
enum GL_SHADER_IMAGE_ATOMIC = 0x82A6;
enum GL_IMAGE_TEXEL_SIZE = 0x82A7;
enum GL_IMAGE_COMPATIBILITY_CLASS = 0x82A8;
enum GL_IMAGE_PIXEL_FORMAT = 0x82A9;
enum GL_IMAGE_PIXEL_TYPE = 0x82AA;
enum GL_SIMULTANEOUS_TEXTURE_AND_DEPTH_TEST = 0x82AC;
enum GL_SIMULTANEOUS_TEXTURE_AND_STENCIL_TEST = 0x82AD;
enum GL_SIMULTANEOUS_TEXTURE_AND_DEPTH_WRITE = 0x82AE;
enum GL_SIMULTANEOUS_TEXTURE_AND_STENCIL_WRITE = 0x82AF;
enum GL_TEXTURE_COMPRESSED_BLOCK_WIDTH = 0x82B1;
enum GL_TEXTURE_COMPRESSED_BLOCK_HEIGHT = 0x82B2;
enum GL_TEXTURE_COMPRESSED_BLOCK_SIZE = 0x82B3;
enum GL_CLEAR_BUFFER = 0x82B4;
enum GL_TEXTURE_VIEW = 0x82B5;
enum GL_VIEW_COMPATIBILITY_CLASS = 0x82B6;
enum GL_FULL_SUPPORT = 0x82B7;
enum GL_CAVEAT_SUPPORT = 0x82B8;
enum GL_IMAGE_CLASS_4_X_32 = 0x82B9;
enum GL_IMAGE_CLASS_2_X_32 = 0x82BA;
enum GL_IMAGE_CLASS_1_X_32 = 0x82BB;
enum GL_IMAGE_CLASS_4_X_16 = 0x82BC;
enum GL_IMAGE_CLASS_2_X_16 = 0x82BD;
enum GL_IMAGE_CLASS_1_X_16 = 0x82BE;
enum GL_IMAGE_CLASS_4_X_8 = 0x82BF;
enum GL_IMAGE_CLASS_2_X_8 = 0x82C0;
enum GL_IMAGE_CLASS_1_X_8 = 0x82C1;
enum GL_IMAGE_CLASS_11_11_10 = 0x82C2;
enum GL_IMAGE_CLASS_10_10_10_2 = 0x82C3;
enum GL_VIEW_CLASS_128_BITS = 0x82C4;
enum GL_VIEW_CLASS_96_BITS = 0x82C5;
enum GL_VIEW_CLASS_64_BITS = 0x82C6;
enum GL_VIEW_CLASS_48_BITS = 0x82C7;
enum GL_VIEW_CLASS_32_BITS = 0x82C8;
enum GL_VIEW_CLASS_24_BITS = 0x82C9;
enum GL_VIEW_CLASS_16_BITS = 0x82CA;
enum GL_VIEW_CLASS_8_BITS = 0x82CB;
enum GL_VIEW_CLASS_S3TC_DXT1_RGB = 0x82CC;
enum GL_VIEW_CLASS_S3TC_DXT1_RGBA = 0x82CD;
enum GL_VIEW_CLASS_S3TC_DXT3_RGBA = 0x82CE;
enum GL_VIEW_CLASS_S3TC_DXT5_RGBA = 0x82CF;
enum GL_VIEW_CLASS_RGTC1_RED = 0x82D0;
enum GL_VIEW_CLASS_RGTC2_RG = 0x82D1;
enum GL_VIEW_CLASS_BPTC_UNORM = 0x82D2;
enum GL_VIEW_CLASS_BPTC_FLOAT = 0x82D3;
enum GL_UNIFORM = 0x92E1;
enum GL_UNIFORM_BLOCK = 0x92E2;
enum GL_PROGRAM_INPUT = 0x92E3;
enum GL_PROGRAM_OUTPUT = 0x92E4;
enum GL_BUFFER_VARIABLE = 0x92E5;
enum GL_SHADER_STORAGE_BLOCK = 0x92E6;
enum GL_VERTEX_SUBROUTINE = 0x92E8;
enum GL_TESS_CONTROL_SUBROUTINE = 0x92E9;
enum GL_TESS_EVALUATION_SUBROUTINE = 0x92EA;
enum GL_GEOMETRY_SUBROUTINE = 0x92EB;
enum GL_FRAGMENT_SUBROUTINE = 0x92EC;
enum GL_COMPUTE_SUBROUTINE = 0x92ED;
enum GL_VERTEX_SUBROUTINE_UNIFORM = 0x92EE;
enum GL_TESS_CONTROL_SUBROUTINE_UNIFORM = 0x92EF;
enum GL_TESS_EVALUATION_SUBROUTINE_UNIFORM = 0x92F0;
enum GL_GEOMETRY_SUBROUTINE_UNIFORM = 0x92F1;
enum GL_FRAGMENT_SUBROUTINE_UNIFORM = 0x92F2;
enum GL_COMPUTE_SUBROUTINE_UNIFORM = 0x92F3;
enum GL_TRANSFORM_FEEDBACK_VARYING = 0x92F4;
enum GL_ACTIVE_RESOURCES = 0x92F5;
enum GL_MAX_NAME_LENGTH = 0x92F6;
enum GL_MAX_NUM_ACTIVE_VARIABLES = 0x92F7;
enum GL_MAX_NUM_COMPATIBLE_SUBROUTINES = 0x92F8;
enum GL_NAME_LENGTH = 0x92F9;
enum GL_TYPE = 0x92FA;
enum GL_ARRAY_SIZE = 0x92FB;
enum GL_OFFSET = 0x92FC;
enum GL_BLOCK_INDEX = 0x92FD;
enum GL_ARRAY_STRIDE = 0x92FE;
enum GL_MATRIX_STRIDE = 0x92FF;
enum GL_IS_ROW_MAJOR = 0x9300;
enum GL_ATOMIC_COUNTER_BUFFER_INDEX = 0x9301;
enum GL_BUFFER_BINDING = 0x9302;
enum GL_BUFFER_DATA_SIZE = 0x9303;
enum GL_NUM_ACTIVE_VARIABLES = 0x9304;
enum GL_ACTIVE_VARIABLES = 0x9305;
enum GL_REFERENCED_BY_VERTEX_SHADER = 0x9306;
enum GL_REFERENCED_BY_TESS_CONTROL_SHADER = 0x9307;
enum GL_REFERENCED_BY_TESS_EVALUATION_SHADER = 0x9308;
enum GL_REFERENCED_BY_GEOMETRY_SHADER = 0x9309;
enum GL_REFERENCED_BY_FRAGMENT_SHADER = 0x930A;
enum GL_REFERENCED_BY_COMPUTE_SHADER = 0x930B;
enum GL_TOP_LEVEL_ARRAY_SIZE = 0x930C;
enum GL_TOP_LEVEL_ARRAY_STRIDE = 0x930D;
enum GL_LOCATION = 0x930E;
enum GL_LOCATION_INDEX = 0x930F;
enum GL_IS_PER_PATCH = 0x92E7;
enum GL_SHADER_STORAGE_BUFFER = 0x90D2;
enum GL_SHADER_STORAGE_BUFFER_BINDING = 0x90D3;
enum GL_SHADER_STORAGE_BUFFER_START = 0x90D4;
enum GL_SHADER_STORAGE_BUFFER_SIZE = 0x90D5;
enum GL_MAX_VERTEX_SHADER_STORAGE_BLOCKS = 0x90D6;
enum GL_MAX_GEOMETRY_SHADER_STORAGE_BLOCKS = 0x90D7;
enum GL_MAX_TESS_CONTROL_SHADER_STORAGE_BLOCKS = 0x90D8;
enum GL_MAX_TESS_EVALUATION_SHADER_STORAGE_BLOCKS = 0x90D9;
enum GL_MAX_FRAGMENT_SHADER_STORAGE_BLOCKS = 0x90DA;
enum GL_MAX_COMPUTE_SHADER_STORAGE_BLOCKS = 0x90DB;
enum GL_MAX_COMBINED_SHADER_STORAGE_BLOCKS = 0x90DC;
enum GL_MAX_SHADER_STORAGE_BUFFER_BINDINGS = 0x90DD;
enum GL_MAX_SHADER_STORAGE_BLOCK_SIZE = 0x90DE;
enum GL_SHADER_STORAGE_BUFFER_OFFSET_ALIGNMENT = 0x90DF;
enum GL_SHADER_STORAGE_BARRIER_BIT = 0x00002000;
enum GL_MAX_COMBINED_SHADER_OUTPUT_RESOURCES = 0x8F39;
enum GL_DEPTH_STENCIL_TEXTURE_MODE = 0x90EA;
enum GL_TEXTURE_BUFFER_OFFSET = 0x919D;
enum GL_TEXTURE_BUFFER_SIZE = 0x919E;
enum GL_TEXTURE_BUFFER_OFFSET_ALIGNMENT = 0x919F;
enum GL_TEXTURE_VIEW_MIN_LEVEL = 0x82DB;
enum GL_TEXTURE_VIEW_NUM_LEVELS = 0x82DC;
enum GL_TEXTURE_VIEW_MIN_LAYER = 0x82DD;
enum GL_TEXTURE_VIEW_NUM_LAYERS = 0x82DE;
enum GL_TEXTURE_IMMUTABLE_LEVELS = 0x82DF;
enum GL_VERTEX_ATTRIB_BINDING = 0x82D4;
enum GL_VERTEX_ATTRIB_RELATIVE_OFFSET = 0x82D5;
enum GL_VERTEX_BINDING_DIVISOR = 0x82D6;
enum GL_VERTEX_BINDING_OFFSET = 0x82D7;
enum GL_VERTEX_BINDING_STRIDE = 0x82D8;
enum GL_MAX_VERTEX_ATTRIB_RELATIVE_OFFSET = 0x82D9;
enum GL_MAX_VERTEX_ATTRIB_BINDINGS = 0x82DA;
enum GL_VERTEX_BINDING_BUFFER = 0x8F4F;
enum GL_DISPLAY_LIST = 0x82E7;
enum GL_MAX_VERTEX_ATTRIB_STRIDE = 0x82E5;
enum GL_PRIMITIVE_RESTART_FOR_PATCHES_SUPPORTED = 0x8221;
enum GL_TEXTURE_BUFFER_BINDING = 0x8C2A;
enum GL_MAP_PERSISTENT_BIT = 0x0040;
enum GL_MAP_COHERENT_BIT = 0x0080;
enum GL_DYNAMIC_STORAGE_BIT = 0x0100;
enum GL_CLIENT_STORAGE_BIT = 0x0200;
enum GL_CLIENT_MAPPED_BUFFER_BARRIER_BIT = 0x00004000;
enum GL_BUFFER_IMMUTABLE_STORAGE = 0x821F;
enum GL_BUFFER_STORAGE_FLAGS = 0x8220;
enum GL_CLEAR_TEXTURE = 0x9365;
enum GL_LOCATION_COMPONENT = 0x934A;
enum GL_TRANSFORM_FEEDBACK_BUFFER_INDEX = 0x934B;
enum GL_TRANSFORM_FEEDBACK_BUFFER_STRIDE = 0x934C;
enum GL_QUERY_BUFFER = 0x9192;
enum GL_QUERY_BUFFER_BARRIER_BIT = 0x00008000;
enum GL_QUERY_BUFFER_BINDING = 0x9193;
enum GL_QUERY_RESULT_NO_WAIT = 0x9194;
enum GL_MIRROR_CLAMP_TO_EDGE = 0x8743;
enum GL_CONTEXT_LOST = 0x0507;
enum GL_NEGATIVE_ONE_TO_ONE = 0x935E;
enum GL_ZERO_TO_ONE = 0x935F;
enum GL_CLIP_ORIGIN = 0x935C;
enum GL_CLIP_DEPTH_MODE = 0x935D;
enum GL_QUERY_WAIT_INVERTED = 0x8E17;
enum GL_QUERY_NO_WAIT_INVERTED = 0x8E18;
enum GL_QUERY_BY_REGION_WAIT_INVERTED = 0x8E19;
enum GL_QUERY_BY_REGION_NO_WAIT_INVERTED = 0x8E1A;
enum GL_MAX_CULL_DISTANCES = 0x82F9;
enum GL_MAX_COMBINED_CLIP_AND_CULL_DISTANCES = 0x82FA;
enum GL_TEXTURE_TARGET = 0x1006;
enum GL_QUERY_TARGET = 0x82EA;
enum GL_GUILTY_CONTEXT_RESET = 0x8253;
enum GL_INNOCENT_CONTEXT_RESET = 0x8254;
enum GL_UNKNOWN_CONTEXT_RESET = 0x8255;
enum GL_RESET_NOTIFICATION_STRATEGY = 0x8256;
enum GL_LOSE_CONTEXT_ON_RESET = 0x8252;
enum GL_NO_RESET_NOTIFICATION = 0x8261;
enum GL_CONTEXT_FLAG_ROBUST_ACCESS_BIT = 0x00000004;
enum GL_CONTEXT_RELEASE_BEHAVIOR = 0x82FB;
enum GL_CONTEXT_RELEASE_BEHAVIOR_FLUSH = 0x82FC;
enum GL_SHADER_BINARY_FORMAT_SPIR_V = 0x9551;
enum GL_SPIR_V_BINARY = 0x9552;
enum GL_PARAMETER_BUFFER = 0x80EE;
enum GL_PARAMETER_BUFFER_BINDING = 0x80EF;
enum GL_CONTEXT_FLAG_NO_ERROR_BIT = 0x00000008;
enum GL_VERTICES_SUBMITTED = 0x82EE;
enum GL_PRIMITIVES_SUBMITTED = 0x82EF;
enum GL_VERTEX_SHADER_INVOCATIONS = 0x82F0;
enum GL_TESS_CONTROL_SHADER_PATCHES = 0x82F1;
enum GL_TESS_EVALUATION_SHADER_INVOCATIONS = 0x82F2;
enum GL_GEOMETRY_SHADER_PRIMITIVES_EMITTED = 0x82F3;
enum GL_FRAGMENT_SHADER_INVOCATIONS = 0x82F4;
enum GL_COMPUTE_SHADER_INVOCATIONS = 0x82F5;
enum GL_CLIPPING_INPUT_PRIMITIVES = 0x82F6;
enum GL_CLIPPING_OUTPUT_PRIMITIVES = 0x82F7;
enum GL_POLYGON_OFFSET_CLAMP = 0x8E1B;
enum GL_SPIR_V_EXTENSIONS = 0x9553;
enum GL_NUM_SPIR_V_EXTENSIONS = 0x9554;
enum GL_TEXTURE_MAX_ANISOTROPY = 0x84FE;
enum GL_MAX_TEXTURE_MAX_ANISOTROPY = 0x84FF;
enum GL_TRANSFORM_FEEDBACK_OVERFLOW = 0x82EC;
enum GL_TRANSFORM_FEEDBACK_STREAM_OVERFLOW = 0x82ED;




/*************************************************************************
 * GLFW API tokens
 *************************************************************************/

/*! @name GLFW version macros
 *  @{ */
/*! @brief The major version number of the GLFW library.
 *
 *  This is incremented when the API is changed in non-compatible ways.
 *  @ingroup init
 */
enum GLFW_VERSION_MAJOR          = 3;
/*! @brief The minor version number of the GLFW library.
 *
 *  This is incremented when features are added to the API but it remains
 *  backward-compatible.
 *  @ingroup init
 */
enum GLFW_VERSION_MINOR          = 2;
/*! @brief The revision number of the GLFW library.
 *
 *  This is incremented when a bug fix release is made that does not contain any
 *  API changes.
 *  @ingroup init
 */
enum GLFW_VERSION_REVISION       = 1;
/*! @} */

/*! @name Boolean values
 *  @{ */
/*! @brief One.
 *
 *  One.  Seriously.  You don't _need_ to use this symbol in your code.  It's
 *  just semantic sugar for the number 1.  You can use `1` or `true` or `_True`
 *  or `GL_TRUE` or whatever you want.
 */
enum GLFW_TRUE                   = 1;
/*! @brief Zero.
 *
 *  Zero.  Seriously.  You don't _need_ to use this symbol in your code.  It's
 *  just just semantic sugar for the number 0.  You can use `0` or `false` or
 *  `_False` or `GL_FALSE` or whatever you want.
 */
enum GLFW_FALSE                  = 0;
/*! @} */

/*! @name Key and button actions
 *  @{ */
/*! @brief The key or mouse button was released.
 *
 *  The key or mouse button was released.
 *
 *  @ingroup input
 */
enum GLFW_RELEASE                = 0;
/*! @brief The key or mouse button was pressed.
 *
 *  The key or mouse button was pressed.
 *
 *  @ingroup input
 */
enum GLFW_PRESS                  = 1;
/*! @brief The key was held down until it repeated.
 *
 *  The key was held down until it repeated.
 *
 *  @ingroup input
 */
enum GLFW_REPEAT                 = 2;
/*! @} */

/*! @defgroup keys Keyboard keys
 *
 *  See [key input](@ref input_key) for how these are used.
 *
 *  These key codes are inspired by the _USB HID Usage Tables v1.12_ (p. 53-60),
 *  but re-arranged to map to 7-bit ASCII for printable keys (function keys are
 *  put in the 256+ range).
 *
 *  The naming of the key codes follow these rules:
 *   - The US keyboard layout is used
 *   - Names of printable alpha-numeric characters are used (e.g. "A", "R",
 *     "3", etc.)
 *   - For non-alphanumeric characters, Unicode:ish names are used (e.g.
 *     "COMMA", "LEFT_SQUARE_BRACKET", etc.). Note that some names do not
 *     correspond to the Unicode standard (usually for brevity)
 *   - Keys that lack a clear US mapping are named "WORLD_x"
 *   - For non-printable keys, custom names are used (e.g. "F4",
 *     "BACKSPACE", etc.)
 *
 *  @ingroup input
 *  @{
 */

/* The unknown key */
enum GLFW_KEY_UNKNOWN            = -1;

/* Printable keys */
enum GLFW_KEY_SPACE              = 32;
enum GLFW_KEY_APOSTROPHE         = 39  /* ' = */;
enum GLFW_KEY_COMMA              = 44  /* , = */;
enum GLFW_KEY_MINUS              = 45  /* - = */;
enum GLFW_KEY_PERIOD             = 46  /* . = */;
enum GLFW_KEY_SLASH              = 47  /* / = */;
enum GLFW_KEY_0                  = 48;
enum GLFW_KEY_1                  = 49;
enum GLFW_KEY_2                  = 50;
enum GLFW_KEY_3                  = 51;
enum GLFW_KEY_4                  = 52;
enum GLFW_KEY_5                  = 53;
enum GLFW_KEY_6                  = 54;
enum GLFW_KEY_7                  = 55;
enum GLFW_KEY_8                  = 56;
enum GLFW_KEY_9                  = 57;
enum GLFW_KEY_SEMICOLON          = 59  /* ; = */;
enum GLFW_KEY_EQUAL              = 61  /* = = */;
enum GLFW_KEY_A                  = 65;
enum GLFW_KEY_B                  = 66;
enum GLFW_KEY_C                  = 67;
enum GLFW_KEY_D                  = 68;
enum GLFW_KEY_E                  = 69;
enum GLFW_KEY_F                  = 70;
enum GLFW_KEY_G                  = 71;
enum GLFW_KEY_H                  = 72;
enum GLFW_KEY_I                  = 73;
enum GLFW_KEY_J                  = 74;
enum GLFW_KEY_K                  = 75;
enum GLFW_KEY_L                  = 76;
enum GLFW_KEY_M                  = 77;
enum GLFW_KEY_N                  = 78;
enum GLFW_KEY_O                  = 79;
enum GLFW_KEY_P                  = 80;
enum GLFW_KEY_Q                  = 81;
enum GLFW_KEY_R                  = 82;
enum GLFW_KEY_S                  = 83;
enum GLFW_KEY_T                  = 84;
enum GLFW_KEY_U                  = 85;
enum GLFW_KEY_V                  = 86;
enum GLFW_KEY_W                  = 87;
enum GLFW_KEY_X                  = 88;
enum GLFW_KEY_Y                  = 89;
enum GLFW_KEY_Z                  = 90;
enum GLFW_KEY_LEFT_BRACKET       = 91;  /* [ = */
enum GLFW_KEY_BACKSLASH          = 92;  /* \ = */
enum GLFW_KEY_RIGHT_BRACKET      = 93;  /* ] = */
enum GLFW_KEY_GRAVE_ACCENT       = 96;  /* ` = */
enum GLFW_KEY_WORLD_1            = 161; /* non-US #1 = */
enum GLFW_KEY_WORLD_2            = 162; /* non-US #2 = */

/* Function keys */
enum GLFW_KEY_ESCAPE             = 256;
enum GLFW_KEY_ENTER              = 257;
enum GLFW_KEY_TAB                = 258;
enum GLFW_KEY_BACKSPACE          = 259;
enum GLFW_KEY_INSERT             = 260;
enum GLFW_KEY_DELETE             = 261;
enum GLFW_KEY_RIGHT              = 262;
enum GLFW_KEY_LEFT               = 263;
enum GLFW_KEY_DOWN               = 264;
enum GLFW_KEY_UP                 = 265;
enum GLFW_KEY_PAGE_UP            = 266;
enum GLFW_KEY_PAGE_DOWN          = 267;
enum GLFW_KEY_HOME               = 268;
enum GLFW_KEY_END                = 269;
enum GLFW_KEY_CAPS_LOCK          = 280;
enum GLFW_KEY_SCROLL_LOCK        = 281;
enum GLFW_KEY_NUM_LOCK           = 282;
enum GLFW_KEY_PRINT_SCREEN       = 283;
enum GLFW_KEY_PAUSE              = 284;
enum GLFW_KEY_F1                 = 290;
enum GLFW_KEY_F2                 = 291;
enum GLFW_KEY_F3                 = 292;
enum GLFW_KEY_F4                 = 293;
enum GLFW_KEY_F5                 = 294;
enum GLFW_KEY_F6                 = 295;
enum GLFW_KEY_F7                 = 296;
enum GLFW_KEY_F8                 = 297;
enum GLFW_KEY_F9                 = 298;
enum GLFW_KEY_F10                = 299;
enum GLFW_KEY_F11                = 300;
enum GLFW_KEY_F12                = 301;
enum GLFW_KEY_F13                = 302;
enum GLFW_KEY_F14                = 303;
enum GLFW_KEY_F15                = 304;
enum GLFW_KEY_F16                = 305;
enum GLFW_KEY_F17                = 306;
enum GLFW_KEY_F18                = 307;
enum GLFW_KEY_F19                = 308;
enum GLFW_KEY_F20                = 309;
enum GLFW_KEY_F21                = 310;
enum GLFW_KEY_F22                = 311;
enum GLFW_KEY_F23                = 312;
enum GLFW_KEY_F24                = 313;
enum GLFW_KEY_F25                = 314;
enum GLFW_KEY_KP_0               = 320;
enum GLFW_KEY_KP_1               = 321;
enum GLFW_KEY_KP_2               = 322;
enum GLFW_KEY_KP_3               = 323;
enum GLFW_KEY_KP_4               = 324;
enum GLFW_KEY_KP_5               = 325;
enum GLFW_KEY_KP_6               = 326;
enum GLFW_KEY_KP_7               = 327;
enum GLFW_KEY_KP_8               = 328;
enum GLFW_KEY_KP_9               = 329;
enum GLFW_KEY_KP_DECIMAL         = 330;
enum GLFW_KEY_KP_DIVIDE          = 331;
enum GLFW_KEY_KP_MULTIPLY        = 332;
enum GLFW_KEY_KP_SUBTRACT        = 333;
enum GLFW_KEY_KP_ADD             = 334;
enum GLFW_KEY_KP_ENTER           = 335;
enum GLFW_KEY_KP_EQUAL           = 336;
enum GLFW_KEY_LEFT_SHIFT         = 340;
enum GLFW_KEY_LEFT_CONTROL       = 341;
enum GLFW_KEY_LEFT_ALT           = 342;
enum GLFW_KEY_LEFT_SUPER         = 343;
enum GLFW_KEY_RIGHT_SHIFT        = 344;
enum GLFW_KEY_RIGHT_CONTROL      = 345;
enum GLFW_KEY_RIGHT_ALT          = 346;
enum GLFW_KEY_RIGHT_SUPER        = 347;
enum GLFW_KEY_MENU               = 348;

enum GLFW_KEY_LAST               = GLFW_KEY_MENU;

/*! @} */

/*! @defgroup mods Modifier key flags
 *
 *  See [key input](@ref input_key) for how these are used.
 *
 *  @ingroup input
 *  @{ */

/*! @brief If this bit is set one or more Shift keys were held down.
 */
enum GLFW_MOD_SHIFT           = 0x0001;
/*! @brief If this bit is set one or more Control keys were held down.
 */
enum GLFW_MOD_CONTROL         = 0x0002;
/*! @brief If this bit is set one or more Alt keys were held down.
 */
enum GLFW_MOD_ALT             = 0x0004;
/*! @brief If this bit is set one or more Super keys were held down.
 */
enum GLFW_MOD_SUPER           = 0x0008;

/*! @} */

/*! @defgroup buttons Mouse buttons
 *
 *  See [mouse button input](@ref input_mouse_button) for how these are used.
 *
 *  @ingroup input
 *  @{ */
enum GLFW_MOUSE_BUTTON_1         = 0;
enum GLFW_MOUSE_BUTTON_2         = 1;
enum GLFW_MOUSE_BUTTON_3         = 2;
enum GLFW_MOUSE_BUTTON_4         = 3;
enum GLFW_MOUSE_BUTTON_5         = 4;
enum GLFW_MOUSE_BUTTON_6         = 5;
enum GLFW_MOUSE_BUTTON_7         = 6;
enum GLFW_MOUSE_BUTTON_8         = 7;
enum GLFW_MOUSE_BUTTON_LAST      = GLFW_MOUSE_BUTTON_8;
enum GLFW_MOUSE_BUTTON_LEFT      = GLFW_MOUSE_BUTTON_1;
enum GLFW_MOUSE_BUTTON_RIGHT     = GLFW_MOUSE_BUTTON_2;
enum GLFW_MOUSE_BUTTON_MIDDLE    = GLFW_MOUSE_BUTTON_3;
/*! @} */

/*! @defgroup joysticks Joysticks
 *
 *  See [joystick input](@ref joystick) for how these are used.
 *
 *  @ingroup input
 *  @{ */
enum GLFW_JOYSTICK_1             = 0;
enum GLFW_JOYSTICK_2             = 1;
enum GLFW_JOYSTICK_3             = 2;
enum GLFW_JOYSTICK_4             = 3;
enum GLFW_JOYSTICK_5             = 4;
enum GLFW_JOYSTICK_6             = 5;
enum GLFW_JOYSTICK_7             = 6;
enum GLFW_JOYSTICK_8             = 7;
enum GLFW_JOYSTICK_9             = 8;
enum GLFW_JOYSTICK_10            = 9;
enum GLFW_JOYSTICK_11            = 10;
enum GLFW_JOYSTICK_12            = 11;
enum GLFW_JOYSTICK_13            = 12;
enum GLFW_JOYSTICK_14            = 13;
enum GLFW_JOYSTICK_15            = 14;
enum GLFW_JOYSTICK_16            = 15;
enum GLFW_JOYSTICK_LAST          = GLFW_JOYSTICK_16;
/*! @} */

/*! @defgroup errors Error codes
 *
 *  See [error handling](@ref error_handling) for how these are used.
 *
 *  @ingroup init
 *  @{ */
/*! @brief GLFW has not been initialized.
 *
 *  This occurs if a GLFW function was called that must not be called unless the
 *  library is [initialized](@ref intro_init).
 *
 *  @analysis Application programmer error.  Initialize GLFW before calling any
 *  function that requires initialization.
 */
enum GLFW_NOT_INITIALIZED        = 0x00010001;
/*! @brief No context is current for this thread.
 *
 *  This occurs if a GLFW function was called that needs and operates on the
 *  current OpenGL or OpenGL ES context but no context is current on the calling
 *  thread.  One such function is @ref glfwSwapInterval.
 *
 *  @analysis Application programmer error.  Ensure a context is current before
 *  calling functions that require a current context.
 */
enum GLFW_NO_CURRENT_CONTEXT     = 0x00010002;
/*! @brief One of the arguments to the function was an invalid enum value.
 *
 *  One of the arguments to the function was an invalid enum value, for example
 *  requesting [GLFW_RED_BITS](@ref window_hints_fb) with @ref
 *  glfwGetWindowAttrib.
 *
 *  @analysis Application programmer error.  Fix the offending call.
 */
enum GLFW_INVALID_ENUM           = 0x00010003;
/*! @brief One of the arguments to the function was an invalid value.
 *
 *  One of the arguments to the function was an invalid value, for example
 *  requesting a non-existent OpenGL or OpenGL ES version like 2.7.
 *
 *  Requesting a valid but unavailable OpenGL or OpenGL ES version will instead
 *  result in a @ref GLFW_VERSION_UNAVAILABLE error.
 *
 *  @analysis Application programmer error.  Fix the offending call.
 */
enum GLFW_INVALID_VALUE          = 0x00010004;
/*! @brief A memory allocation failed.
 *
 *  A memory allocation failed.
 *
 *  @analysis A bug in GLFW or the underlying operating system.  Report the bug
 *  to our [issue tracker](https://github.com/glfw/glfw/issues).
 */
enum GLFW_OUT_OF_MEMORY          = 0x00010005;
/*! @brief GLFW could not find support for the requested API on the system.
 *
 *  GLFW could not find support for the requested API on the system.
 *
 *  @analysis The installed graphics driver does not support the requested
 *  API, or does not support it via the chosen context creation backend.
 *  Below are a few examples.
 *
 *  @par
 *  Some pre-installed Windows graphics drivers do not support OpenGL.  AMD only
 *  supports OpenGL ES via EGL, while Nvidia and Intel only support it via
 *  a WGL or GLX extension.  OS X does not provide OpenGL ES at all.  The Mesa
 *  EGL, OpenGL and OpenGL ES libraries do not interface with the Nvidia binary
 *  driver.  Older graphics drivers do not support Vulkan.
 */
enum GLFW_API_UNAVAILABLE        = 0x00010006;
/*! @brief The requested OpenGL or OpenGL ES version is not available.
 *
 *  The requested OpenGL or OpenGL ES version (including any requested context
 *  or framebuffer hints) is not available on this machine.
 *
 *  @analysis The machine does not support your requirements.  If your
 *  application is sufficiently flexible, downgrade your requirements and try
 *  again.  Otherwise, inform the user that their machine does not match your
 *  requirements.
 *
 *  @par
 *  Future invalid OpenGL and OpenGL ES versions, for example OpenGL 4.8 if 5.0
 *  comes out before the 4.x series gets that far, also fail with this error and
 *  not @ref GLFW_INVALID_VALUE, because GLFW cannot know what future versions
 *  will exist.
 */
enum GLFW_VERSION_UNAVAILABLE    = 0x00010007;
/*! @brief A platform-specific error occurred that does not match any of the
 *  more specific categories.
 *
 *  A platform-specific error occurred that does not match any of the more
 *  specific categories.
 *
 *  @analysis A bug or configuration error in GLFW, the underlying operating
 *  system or its drivers, or a lack of required resources.  Report the issue to
 *  our [issue tracker](https://github.com/glfw/glfw/issues).
 */
enum GLFW_PLATFORM_ERROR         = 0x00010008;
/*! @brief The requested format is not supported or available.
 *
 *  If emitted during window creation, the requested pixel format is not
 *  supported.
 *
 *  If emitted when querying the clipboard, the contents of the clipboard could
 *  not be converted to the requested format.
 *
 *  @analysis If emitted during window creation, one or more
 *  [hard constraints](@ref window_hints_hard) did not match any of the
 *  available pixel formats.  If your application is sufficiently flexible,
 *  downgrade your requirements and try again.  Otherwise, inform the user that
 *  their machine does not match your requirements.
 *
 *  @par
 *  If emitted when querying the clipboard, ignore the error or report it to
 *  the user, as appropriate.
 */
enum GLFW_FORMAT_UNAVAILABLE     = 0x00010009;
/*! @brief The specified window does not have an OpenGL or OpenGL ES context.
 *
 *  A window that does not have an OpenGL or OpenGL ES context was passed to
 *  a function that requires it to have one.
 *
 *  @analysis Application programmer error.  Fix the offending call.
 */
enum GLFW_NO_WINDOW_CONTEXT      = 0x0001000A;
/*! @} */

enum GLFW_FOCUSED                = 0x00020001;
enum GLFW_ICONIFIED              = 0x00020002;
enum GLFW_RESIZABLE              = 0x00020003;
enum GLFW_VISIBLE                = 0x00020004;
enum GLFW_DECORATED              = 0x00020005;
enum GLFW_AUTO_ICONIFY           = 0x00020006;
enum GLFW_FLOATING               = 0x00020007;
enum GLFW_MAXIMIZED              = 0x00020008;

enum GLFW_RED_BITS               = 0x00021001;
enum GLFW_GREEN_BITS             = 0x00021002;
enum GLFW_BLUE_BITS              = 0x00021003;
enum GLFW_ALPHA_BITS             = 0x00021004;
enum GLFW_DEPTH_BITS             = 0x00021005;
enum GLFW_STENCIL_BITS           = 0x00021006;
enum GLFW_ACCUM_RED_BITS         = 0x00021007;
enum GLFW_ACCUM_GREEN_BITS       = 0x00021008;
enum GLFW_ACCUM_BLUE_BITS        = 0x00021009;
enum GLFW_ACCUM_ALPHA_BITS       = 0x0002100A;
enum GLFW_AUX_BUFFERS            = 0x0002100B;
enum GLFW_STEREO                 = 0x0002100C;
enum GLFW_SAMPLES                = 0x0002100D;
enum GLFW_SRGB_CAPABLE           = 0x0002100E;
enum GLFW_REFRESH_RATE           = 0x0002100F;
enum GLFW_DOUBLEBUFFER           = 0x00021010;

enum GLFW_CLIENT_API             = 0x00022001;
enum GLFW_CONTEXT_VERSION_MAJOR  = 0x00022002;
enum GLFW_CONTEXT_VERSION_MINOR  = 0x00022003;
enum GLFW_CONTEXT_REVISION       = 0x00022004;
enum GLFW_CONTEXT_ROBUSTNESS     = 0x00022005;
enum GLFW_OPENGL_FORWARD_COMPAT  = 0x00022006;
enum GLFW_OPENGL_DEBUG_CONTEXT   = 0x00022007;
enum GLFW_OPENGL_PROFILE         = 0x00022008;
enum GLFW_CONTEXT_RELEASE_BEHAVIOR = 0x00022009;
enum GLFW_CONTEXT_NO_ERROR       = 0x0002200A;
enum GLFW_CONTEXT_CREATION_API   = 0x0002200B;

enum GLFW_NO_API                          = 0;
enum GLFW_OPENGL_API             = 0x00030001;
enum GLFW_OPENGL_ES_API          = 0x00030002;

enum GLFW_NO_ROBUSTNESS                   = 0;
enum GLFW_NO_RESET_NOTIFICATION  = 0x00031001;
enum GLFW_LOSE_CONTEXT_ON_RESET  = 0x00031002;

enum GLFW_OPENGL_ANY_PROFILE              = 0;
enum GLFW_OPENGL_CORE_PROFILE    = 0x00032001;
enum GLFW_OPENGL_COMPAT_PROFILE  = 0x00032002;

enum GLFW_CURSOR                 = 0x00033001;
enum GLFW_STICKY_KEYS            = 0x00033002;
enum GLFW_STICKY_MOUSE_BUTTONS   = 0x00033003;

enum GLFW_CURSOR_NORMAL          = 0x00034001;
enum GLFW_CURSOR_HIDDEN          = 0x00034002;
enum GLFW_CURSOR_DISABLED        = 0x00034003;

enum GLFW_ANY_RELEASE_BEHAVIOR            = 0;
enum GLFW_RELEASE_BEHAVIOR_FLUSH = 0x00035001;
enum GLFW_RELEASE_BEHAVIOR_NONE  = 0x00035002;

enum GLFW_NATIVE_CONTEXT_API     = 0x00036001;
enum GLFW_EGL_CONTEXT_API        = 0x00036002;

/*! @defgroup shapes Standard cursor shapes
 *
 *  See [standard cursor creation](@ref cursor_standard) for how these are used.
 *
 *  @ingroup input
 *  @{ */

/*! @brief The regular arrow cursor shape.
 *
 *  The regular arrow cursor.
 */
enum GLFW_ARROW_CURSOR           = 0x00036001;
/*! @brief The text input I-beam cursor shape.
 *
 *  The text input I-beam cursor shape.
 */
enum GLFW_IBEAM_CURSOR           = 0x00036002;
/*! @brief The crosshair shape.
 *
 *  The crosshair shape.
 */
enum GLFW_CROSSHAIR_CURSOR       = 0x00036003;
/*! @brief The hand shape.
 *
 *  The hand shape.
 */
enum GLFW_HAND_CURSOR            = 0x00036004;
/*! @brief The horizontal resize arrow shape.
 *
 *  The horizontal resize arrow shape.
 */
enum GLFW_HRESIZE_CURSOR         = 0x00036005;
/*! @brief The vertical resize arrow shape.
 *
 *  The vertical resize arrow shape.
 */
enum GLFW_VRESIZE_CURSOR         = 0x00036006;
/*! @} */

enum GLFW_CONNECTED              = 0x00040001;
enum GLFW_DISCONNECTED           = 0x00040002;

enum GLFW_DONT_CARE              = -1;
