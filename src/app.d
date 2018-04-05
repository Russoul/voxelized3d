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
	
	 addTriangleLinesColor(rendererLines, Triangle!(float, 3)(
	 	Vector3!float([-0.3, 0, -1]),
	 	Vector3!float([0.3, 0, -1]),
	 	Vector3!float([0, 1, -1])

	 ), green);

	addTriangleColor(rendererTrianglesColor, Triangle!(float, 3)(
		Vector3!float([-0.5, 0, -1]),
		Vector3!float([0.5, 0, -1]),
		Vector3!float([0, 1, -1])

	), red);



    // ========================= UMDC ==============================
    auto noise = FastNoise();
    noise.SetFrequency(4.0F);
    writeln(noise.GetNoiseType());
    //noise.SetNoiseType(NoiseType.Perlin);
    writeln(noise.GetValue(0.5F,0.5F,0.5F));


    struct DenFn3{
        FastNoise noise;//TODO problem here, probably should craate a simple C wrapper to simplify things

        @nogc float opCall(Vector3!float v) const{
            return noise.GetValue(v.x, v.y, v.z);
        }
    }

    DenFn3 f = {noise};
    auto offset = zero!(float,3,1)();
    float a = 0.125F;
    size_t size = 128;
    size_t acc = 16;

    auto color = brown;

    writeln("denTest: " ~ to!string(f(offset)));
    stdout.flush();

    //umdc.extract!(DenFn3)(f, offset, a, size, acc, color, rendererTrianglesLight, rendererLines);


    // ==============================================================



	shaders["lighting"].enable();
	shaders["lighting"].setFloat3("pointLight.pos", vecS!([0.0F,8.0F,0.0F]));
	shaders["lighting"].setFloat3("pointLight.color", Vector3!float([1.0, 1.0, 1.0]));


	auto shaderDataLines =
	delegate(Program shader, const ref WindowInfo win, const ref Camera camera){
		auto aspect = cast(float)win.width / win.height;

		auto idMat = matS!([
			[1.0F, 0.0F, 0.0F, 0.0F],
			[0.0F, 1.0F, 0.0F, 0.0F],
			[0.0F, 0.0F, 1.0F, 0.0F],
			[0.0F, 0.0F, 0.0F, 1.0F]
		]);

		auto persp = perspectiveProjection(90.0F, aspect, 0.1F, 16.0F);
		auto view = viewDir(camera.pos, camera.look, camera.up);
		auto tr = translation(Vector3!float([0.5, 0,0]));


		shader.setFloat4x4("P", true, persp);
		shader.setFloat4x4("V", true, view);

		return glfwGetKey(win.handle, GLFW_KEY_TAB) != GLFW_PRESS;
	};


	auto providerLines = RenderDataProvider(none!(void delegate()), none!(void delegate()),
	 some(shaderDataLines));



	auto renderInfoLines = RenderInfo(rendererLines, providerLines);
	auto renderInfoTringlesColor = RenderInfo(rendererTrianglesColor, providerLines);

	auto idLines = voxelRenderer.push(RenderLifetime(Manual()), RenderTransform(None()), renderInfoLines);
	auto idTriColor = voxelRenderer.push(RenderLifetime(Manual()), RenderTransform(None()), renderInfoTringlesColor); 

	voxelRenderer.lifetimeManualRenderers[idLines.getValue].renderer.construct();
	voxelRenderer.lifetimeManualRenderers[idTriColor.getValue].renderer.construct();






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

		updateWindowInfo(winInfo);
		glfwSwapBuffers(win);
		glfwPollEvents();

		processInput(win, camera, frameDeltaNs); //TODO dt(StopWatch) + input processing

		checkForGlErrors();
	}


	voxelRenderer.lifetimeManualRenderers[idLines.getValue].renderer.deconstruct();
	voxelRenderer.lifetimeManualRenderers[idTriColor.getValue].renderer.deconstruct();


	glfwTerminate();

}
