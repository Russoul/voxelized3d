import std.stdio;
import std.conv;
import std.variant;
import std.typecons;
import std.file;
import std.algorithm;
import std.array;
import std.file;
import std.path;
import std.container.slist;
import std.datetime.stopwatch;
import std.math;

import util;
import graphics;
import matrix;
import RenderingEngine;
import render;
import math;
import umdc;



extern(C) void errorCallback(int code, const char* error) {
	writeln("GL error: " ~ to!string(error));
	
}

extern (C) void framebufSzCb(GlfwWindow* win, size_t w, size_t h){
	glViewport(0,0,w,h);
}

void checkForGlErrors(){
	auto err = glGetError();



	while(err != GL_NO_ERROR){
		stderr.writefln("GL error: %d", err);
	}
}


Vector2!double lastCursorPos = vecS!([0.0,0.0]);
void processInput(GlfwWindow* win, ref Camera camera, ulong frameDeltaNs){
	if(glfwGetKey(win, GLFW_KEY_ESCAPE) == GLFW_PRESS)
		glfwSetWindowShouldClose(win, true);

    double deltaSec = frameDeltaNs / 1000000000.0; //nano is 10^(-9)


    double unitPerSecond = 2.5F;

    float gain = unitPerSecond * cast(float)deltaSec;

    if(glfwGetMouseButton(win, GLFW_MOUSE_BUTTON_2) == GLFW_PRESS){
        gain *= 0.01F;
    }


    auto right = camera.look.cross(camera.up);

    if(glfwGetKey(win, GLFW_KEY_W) == GLFW_PRESS){
        camera.pos = camera.pos + camera.look * gain;
    }

    if(glfwGetKey(win, GLFW_KEY_S) == GLFW_PRESS){
        camera.pos = camera.pos - camera.look * gain;
    }


    if(glfwGetKey(win, GLFW_KEY_A) == GLFW_PRESS){
        camera.pos = camera.pos - right * gain;
    }

    if(glfwGetKey(win, GLFW_KEY_D) == GLFW_PRESS){
        camera.pos = camera.pos + right * gain;
    }

    if(glfwGetKey(win, GLFW_KEY_SPACE) == GLFW_PRESS){
        camera.pos = camera.pos + camera.up * gain;
    }

    if(glfwGetKey(win, GLFW_KEY_LEFT_SHIFT) == GLFW_PRESS){
        camera.pos = camera.pos - camera.up * gain;
    }

    auto cursorPos = vecS!([0.0, 0.0]);

    glfwGetCursorPos(win, cursorPos.array.ptr, cursorPos.array.ptr + 1);

    auto cursorDelta = cursorPos - lastCursorPos;

    auto angularVelocity = cast(float)PI / 3.0;

    // ==============
    auto yaw = cursorDelta.x * angularVelocity * deltaSec;

    auto rotYaw = rotation(camera.up, -yaw);

    auto newLook = mult(rotYaw, Vector4!float([camera.look.x, camera.look.y, camera.look.z, 1.0F])).xyz.normalize();

    camera.look = newLook;

    right = camera.look.cross(camera.up); //update `right`

    // ===============


    auto pitch = cursorDelta.y * angularVelocity * deltaSec;

    auto rotPitch = rotation(right, -pitch);

    newLook = mult(rotPitch, Vector4!float([camera.look.x, camera.look.y, camera.look.z, 1.0F])).xyz.normalize();

    camera.look = newLook;

    camera.up = right.cross(newLook);

    //`right` does not need to be updated

    // ================


    float roll = 0.0F;

    if(glfwGetKey(win, GLFW_KEY_Q) == GLFW_PRESS){
        roll += angularVelocity * deltaSec;
    }

    if(glfwGetKey(win, GLFW_KEY_E) == GLFW_PRESS){
        roll -= angularVelocity * deltaSec;
    }

    auto rotRoll = rotation(camera.look, -roll);

    auto newUp = mult(rotRoll, Vector4!float([camera.up.x, camera.up.y, camera.up.z, 1.0F])).xyz.normalize();

    camera.up = newUp;

    right = camera.look.cross(camera.up); //update `right`


    //TODO make camera movement smoother

    lastCursorPos = cursorPos;

}


void updateWindowInfo(ref WindowInfo win){
	size_t w;
	size_t h;

	glfwGetWindowSize(win.handle, &w, &h);

	win.width = w;
	win.height = h;
}

void main() @system
{
    println("Running Voxelized3D...");
    //specialTable();
	runVoxelized();
}




Program[string] loadShaders(){
	auto dir = "./assets/shaders/";
	SList!(string) uniqueNames;
	std.file.dirEntries(dir, SpanMode.shallow)
        .filter!(a => a.isFile)
        .map!(a => stripExtension(a.name))
	    .each!(delegate (a){
				if ( !uniqueNames.contains(a) ) 
					uniqueNames.insertFront(a); 
		}
		
			
	);

	Program[string] shaders;

	foreach(string shaderName; uniqueNames){
		string vertSrc = cast(string) read(shaderName ~ ".vert");
		string fragSrc = cast(string) read(shaderName ~ ".frag");
		string base = baseName(shaderName);

		auto prog = createProgramVertFrag(vertSrc, fragSrc);

		shaders[base] = Program(prog);
		
	}


	return shaders;

}

void runVoxelized(){

	size_t defWidth = 800;
	size_t defHeight = 600;

	glfwSetErrorCallback(&errorCallback);
	glfwInit();
	glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 3);
	glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 3);

	auto win = glfwCreateWindow(defWidth, defHeight, "voxelized3d", null, null);

	if(win == null){
		glfwTerminate();
		panic!void("Failed to initialize GLFW window !");
	}

	glfwMakeContextCurrent(win);
	int ret = gladLoadGLLoader( cast(GLADloadproc)  &glfwGetProcAddress);
	if(ret == 0){
		glfwTerminate();
		panic!void("Failed to load GLAD");
	}

	writefln("Using GL version %s", to!string(glGetString(GL_VERSION)));

	glfwSetFramebufferSizeCallback(win, &framebufSzCb);
	glfwSetInputMode(win, GLFW_STICKY_KEYS, 1);
	glfwSetInputMode(win, GLFW_CURSOR, GLFW_CURSOR_DISABLED);

	glViewport(0,0,defWidth,defHeight);

	auto shaders = loadShaders();

	auto voxelRenderer = new VoxelRenderer(shaders);

	auto winInfo = WindowInfo(defWidth, defHeight, win);
	auto camera = Camera(Vector3!float([0.0F, 0.0F, 0.0F]), vecS!([0.0F, 0.0F, -1.0F]), vecS!([0.0F, 1.0F, 0.0F]));


	auto rendererLines = new RenderVertFragDef("color", GL_LINES, () => setAttribPtrsColor());
	auto rendererTrianglesColor = new RenderVertFragDef("color", GL_TRIANGLES, () => setAttribPtrsColor());
    auto rendererTrianglesLight = new RenderVertFragDef("lighting", GL_TRIANGLES, () => setAttribPtrsNormal());


	auto red = Vector3!(float)([1.0F, 0.0F, 0.0F]);
	auto green = Vector3!(float)([0.0F, 1.0F, 0.0F]);
	auto blue = Vector3!(float)([0.0F, 0.0F, 1.0F]);
	auto black = zero!(float,3,1);
	auto white = red + green + blue;
	auto brown = Vector3!float([139.0F/256.0F,69.0F/255.0F,19.0F/255.0F]);

    addLine3Color(rendererLines, Line!(float,3)(black, red), red);
    addLine3Color(rendererLines, Line!(float,3)(black, green), green);
    addLine3Color(rendererLines, Line!(float,3)(black, blue), blue);


    // ========================= UMDC ==============================
    auto noise = allocFastNoise();
    setFrequency(noise, 1.0);

    setNoiseType(noise, FastNoise.NoiseType.Simplex);


    float octaveNoise(void* noise, size_t octaves, float persistence, float x, float y, float z){
        float total = 0.0F;
        float frequency = 1.0F;
        float amplitude = 1.0F;
        float maxValue = 0.0;

        float k = pow(2.0, octaves - 1);

        foreach(i; 0..octaves){
            total += getValue(noise, x * frequency / k, y * frequency / k, z * frequency / k);
            maxValue += amplitude;
            amplitude *= persistence;
            frequency *= 2.0;
        }

        return total / maxValue;
    }

    struct DenUnion(alias Den1, alias Den2){
        Den1 f1;
        Den2 f2;

        @nogc float opCall(Vector3!float v){
            auto d1 = f1(v);
            auto d2 = f2(v);

            return min(d1, d2);
        }
    }

    struct DenIntersection(alias Den1, alias Den2){
        Den1 f1;
        Den2 f2;

        @nogc float opCall(Vector3!float v){
            auto d1 = f1(v);
            auto d2 = f2(v);

            return max(d1, d2);
        }
    }

    struct DenDifference(alias Den1, alias Den2){
        Den1 f1;
        Den2 f2;

        @nogc float opCall(Vector3!float v){
            auto d1 = f1(v);
            auto d2 = f2(v);

            return max(d1, -d2);
        }
    }

    struct DenFn3{
        void* noise;//TODO problem here, probably should craate a simple C wrapper to simplify things

        Cube!float cube;

        this(void* noise, Cube!float cube){
            this.cube = cube;
            this.noise = noise;
            import std.datetime;
            auto currentTime = Clock.currTime();
            import core.stdc.time;
            time_t unixTime = core.stdc.time.time(null);
            setSeed(noise, cast(int) unixTime);
        }

        @nogc float opCall(Vector3!float v){

            auto den = (octaveNoise(noise, 8, 0.82F, v.x/1.0F, 0, v.z/1.0F) + 1)/2 * cube.extent * 2  * 0.7F;
            //writeln(den);
            return (v.y - (cube.center.y - cube.extent)) - den;
        }
    }

    struct DenSphere{
        Sphere!float sph;

        @nogc float opCall(Vector3!float v){
            return (sph.center - v).dot(sph.center - v) - sph.rad * sph.rad;
        }
    }

    struct DenZPos{
        float z;

        @nogc float opCall(Vector3!float v){
            return z - v.z;
        }
    }

    struct DenZNeg{
        float z;

        @nogc float opCall(Vector3!float v){
            return v.z - z;
        }
    }

    struct DenYPos{
        float y;

        @nogc float opCall(Vector3!float v){
            return y - v.y;
        }
    }

    struct DenYNeg{
        float y;

        @nogc float opCall(Vector3!float v){
            return v.y - y;
        }
    }

    struct DenXPos{
        float x;

        @nogc float opCall(Vector3!float v){
            return x - v.x;
        }
    }

    struct DenXNeg{
        float x;

        @nogc float opCall(Vector3!float v){
            return v.x - x;
        }
    }


    struct DenHalfSpace{
        Plane!float plane;

        @nogc float opCall(Vector3!float v){
            return -dot(plane.normal,v - plane.point);
        }
    }





    struct DenOBB{

        alias I1 = DenIntersection!(DenHalfSpace,DenHalfSpace);
        alias I2 = DenIntersection!(DenHalfSpace,DenHalfSpace);
        alias I3 = DenIntersection!(DenHalfSpace,DenHalfSpace);
        alias I4 = DenIntersection!(I1, I2);
        DenIntersection!(I4, I3) i;

        this(OBB!float obb){
            auto look = cross(obb.up,obb.right);
            DenHalfSpace zp = {{obb.center - look * obb.extent.z, look}};
            DenHalfSpace zn = {{obb.center + look * obb.extent.z, -look}};

            DenHalfSpace yp = {{obb.center - obb.up * obb.extent.y, obb.up}};
            DenHalfSpace yn = {{obb.center + obb.up * obb.extent.y, -obb.up}};

            DenHalfSpace xp = {{obb.center - obb.right * obb.extent.x, obb.right}};
            DenHalfSpace xn = {{obb.center + obb.right * obb.extent.x, -obb.right}};

            DenIntersection!(DenHalfSpace,DenHalfSpace) i1 = {zp,zn};
            DenIntersection!(DenHalfSpace,DenHalfSpace) i2 = {yp,yn};
            DenIntersection!(DenHalfSpace,DenHalfSpace) i3 = {xp,xn};

            DenIntersection!(typeof(i1), typeof(i2)) i4 = {i1,i2};
            DenIntersection!(typeof(i4), typeof(i3)) i = {i4,i3};

            this.i = i;
        }

        @nogc float opCall(Vector3!float v){
            return i(v);
        }
    }

    struct DenCube{

        alias I1 = DenIntersection!(DenZPos,DenZNeg);
        alias I2 = DenIntersection!(DenYPos,DenYNeg);
        alias I3 = DenIntersection!(DenXPos,DenXNeg);
        alias I4 = DenIntersection!(I1, I2);
        DenIntersection!(I4, I3) i;

        this(Cube!float cube){
            DenZPos zp = {cube.center.z - cube.extent};
            DenZNeg zn = {cube.center.z + cube.extent};

            DenYPos yp = {cube.center.y - cube.extent};
            DenYNeg yn = {cube.center.y + cube.extent};

            DenXPos xp = {cube.center.x - cube.extent};
            DenXNeg xn = {cube.center.x + cube.extent};

            DenIntersection!(DenZPos,DenZNeg) i1 = {zp,zn};
            DenIntersection!(DenYPos,DenYNeg) i2 = {yp,yn};
            DenIntersection!(DenXPos,DenXNeg) i3 = {xp,xn};

            DenIntersection!(typeof(i1), typeof(i2)) i4 = {i1,i2};
            DenIntersection!(typeof(i4), typeof(i3)) i = {i4,i3};

            this.i = i;
        }

        @nogc float opCall(Vector3!float v){
            return i(v);
        }
    }

    struct DenSphereDisplacement{
        Sphere!float sph;

        @nogc float opCall(Vector3!float v){
            float disp = (getValue(noise, v.x/20,v.y/20,v.z/20)+2)/4;
            return (sph.center - v).dot(sph.center - v) - sph.rad * sph.rad * disp;
        }
    }






    auto offset = vec3!float(-2.0, -2.0, -2.0);
    writeln(offset);
    float a = 0.125F/2.0F;
    const size_t size = 128;
    size_t acc = 16;


    Cube!float bounds = Cube!float(offset + vec3!float(size/2 * a, size/2 * a, size/2 * a), size * a / 2);


    DenFn3 f = DenFn3(noise, bounds);

    auto color = brown;


    DenSphereDisplacement sph = {Sphere!float(vec3!float(0,0,0), 2)};

    auto cube = DenCube(Cube!float(vec3!float(1.0,1.0,1.0), 0.5));
    auto sizee = 0.8F;

    auto dirs = matS!([
        [1.0F, 1.0F],
        [-0.5F,1.0F],
        [-0.2F,1.0F]
    ]);

    auto resDirs = dirs;

    gramSchmidt(dirs, resDirs);

    auto obb = DenOBB(OBB!float(vec3!float(2.0,2.0,2.0), resDirs.column(0), resDirs.column(1), vec3!float(sizee,sizee,sizee)));
    DenUnion!(typeof(f), typeof(obb)) r = {f, obb};
    DenUnion!(typeof(r), DenOBB) q = {r, obb};


    alias colorizer = delegate(Vector3!float v){
        auto rel = v - offset;
        auto a = bounds.extent * 2;

        if(rel.y < a / 4){
            return Vector3!float([64.0F/255.0F, 164.0F/255.0F, 223/255.0F]);
        }
        else if(rel.y < a/2){
            return Vector3!float([37.6F/255.0F, 50.2F/255.0F, 22/255.0F]);
        }
        else if(rel.y < 3*a/4){
            return Vector3!float([139.0F/255.0F, 141.0F/255.0F, 122/255.0F]);
        }
        else{
            return Vector3!float([212.0F/255.0F, 240.0F/255.0F, 1.0F]);
        }
    };

    //umdc.extract!(typeof(q))(q, offset, a, size, acc, colorizer, rendererTrianglesLight, rendererLines);
    import hermite.uniform;

    StopWatch watch;

    auto storage = UniformVoxelStorage!float(size);

    //auto storageC = UniformVoxelStorageC(cast(uint)storage.cellCount, storage.grid, storage.edgeInfo);

    watch.start();
    sampleGPU(cast(float3)offset, a, cast(uint)acc, &storage);//TODO malloc calls inside !
    watch.stop();
    size_t ms;
    watch.peek().split!"msecs"(ms);
    printf("GPU sampling took %d ms\n", ms);

    umdc.extract(storage, offset, a, acc, colorizer, rendererTrianglesLight, rendererLines);


    /*
    watch.start();
    umdc.sample!(typeof(q))(q, offset, a, acc, storage);
    umdc.extract(storage, offset, a, acc, colorizer, rendererTrianglesLight, rendererLines);
    watch.stop();
    size_t ms;
    watch.peek().split!"msecs"(ms);
    printf("Whole process took %d ms", ms);
    stdout.flush();*/


    freeFastNoise(noise);

    // ==============================================================



	shaders["lighting"].enable();
	shaders["lighting"].setFloat3("pointLight.pos", vecS!([4.0F,4.0F,4.0F]));
	shaders["lighting"].setFloat3("pointLight.color", Vector3!float([25.0, 25.0, 25.0])/10.0F);


	auto shaderDataLines =
	delegate(Program shader, const ref WindowInfo win, const ref Camera camera){
		auto aspect = cast(float)win.width / win.height;

		auto idMat = matS!([
			[1.0F, 0.0F, 0.0F, 0.0F],
			[0.0F, 1.0F, 0.0F, 0.0F],
			[0.0F, 0.0F, 1.0F, 0.0F],
			[0.0F, 0.0F, 0.0F, 1.0F]
		]);

		auto persp = perspectiveProjection(90.0F, aspect, 0.01F, 16.0F);
		auto view = viewDir(camera.pos, camera.look, camera.up);
		auto tr = translation(Vector3!float([0.5, 0,0]));


		shader.setFloat4x4("P", true, persp);
		shader.setFloat4x4("V", true, view);

		return glfwGetKey(win.handle, GLFW_KEY_TAB) != GLFW_PRESS;
	};

	auto shaderData =
    	delegate(Program shader, const ref WindowInfo win, const ref Camera camera){
    		auto aspect = cast(float)win.width / win.height;

    		auto idMat = matS!([
    			[1.0F, 0.0F, 0.0F, 0.0F],
    			[0.0F, 1.0F, 0.0F, 0.0F],
    			[0.0F, 0.0F, 1.0F, 0.0F],
    			[0.0F, 0.0F, 0.0F, 1.0F]
    		]);

    		auto persp = perspectiveProjection(90.0F, aspect, 0.01F, 16.0F);
    		auto view = viewDir(camera.pos, camera.look, camera.up);
    		auto tr = translation(Vector3!float([0.5, 0,0]));


    		shader.setFloat4x4("P", true, persp);
    		shader.setFloat4x4("V", true, view);

    		return true;
    	};


	auto providerLines = RenderDataProvider(none!(void delegate()), none!(void delegate()),
	 some(shaderDataLines));


    auto provider = RenderDataProvider(none!(void delegate()), none!(void delegate()), some(shaderData));


	auto renderInfoLines = RenderInfo(rendererLines, providerLines);
	auto renderInfoTringlesColor = RenderInfo(rendererTrianglesColor, provider);
	auto renderInfoTrianglesLight = RenderInfo(rendererTrianglesLight, provider);

	auto idLines = voxelRenderer.push(RenderLifetime(Manual()), RenderTransform(None()), renderInfoLines);
	auto idTriColor = voxelRenderer.push(RenderLifetime(Manual()), RenderTransform(None()), renderInfoTringlesColor);
	auto idTriLight = voxelRenderer.push(RenderLifetime(Manual()), RenderTransform(None()), renderInfoTrianglesLight);

	voxelRenderer.lifetimeManualRenderers[idLines.getValue].renderer.construct();
	voxelRenderer.lifetimeManualRenderers[idTriColor.getValue].renderer.construct();
    voxelRenderer.lifetimeManualRenderers[idTriLight.getValue].renderer.construct();





	StopWatch sw;
	sw.start();
    enum n = 100;


	glEnable(GL_DEPTH_TEST);
	while(!glfwWindowShouldClose(win)){
		glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
		glClearColor(0.2f, 0.3f, 0.3f, 1.0f);

        sw.stop();

        ulong frameDeltaNs; //frame delta time TODO render it
        sw.peek().split!"nsecs"(frameDeltaNs);

		voxelRenderer.draw(winInfo, camera);
		sw.reset();
		sw.start();


		//debug bounds
		if(glfwGetKey(win, GLFW_KEY_Z) == GLFW_PRESS){
		    auto bmin = bounds.center - vec3!float(bounds.extent,bounds.extent,bounds.extent);
            auto dp = camera.pos - bmin;
            auto x = cast(size_t)(dp.x / a) % size;
            auto y = cast(size_t)(dp.y / a) % size;
            auto z = cast(size_t)(dp.z / a) % size;

            writeln("x="~to!string(x)~",y="~to!string(y)~",z="~to!string(z));
            stdout.flush();
		}

		//===

		updateWindowInfo(winInfo);
		glfwSwapBuffers(win);
		glfwPollEvents();

		processInput(win, camera, frameDeltaNs); //TODO dt(StopWatch) + input processing

		checkForGlErrors();
	}


	voxelRenderer.lifetimeManualRenderers[idLines.getValue].renderer.deconstruct();
	voxelRenderer.lifetimeManualRenderers[idTriColor.getValue].renderer.deconstruct();
    voxelRenderer.lifetimeManualRenderers[idTriLight.getValue].renderer.deconstruct();

	glfwTerminate();

}
