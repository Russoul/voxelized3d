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

import util;
import graphics;
import matrix;
import RenderingEngine;
import render;
import math;


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

void processInput(GlfwWindow* win){
	if(glfwGetKey(win, GLFW_KEY_ESCAPE) == GLFW_PRESS)
		glfwSetWindowShouldClose(win, true);
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

	auto shaders = loadShaders();

	auto voxelRenderer = new VoxelRenderer(shaders);

	auto winInfo = WindowInfo(defWidth, defHeight, win);
	auto camera = Camera(Vector3!float([0.0F, 0.0F, 2.0F]), vecS!([0.0F, 0.0F, -1.0F]), vecS!([0.0F, 1.0F, 0.0F]));


	auto rendererLines = new RenderVertFragDef("color", GL_LINES, () => setAttribPtrsColor());
	auto rendererTrianglesColor = new RenderVertFragDef("color", GL_TRIANGLES, () => setAttribPtrsColor());

	auto red = Vector3!(float)([1.0F, 0.0F, 0.0F]);
	
	
	// addTriangleLinesColor(rendererLines, Triangle!(float, 3)(
	// 	Vector3!float([-0.5, 0, -0]),
	// 	Vector3!float([0.5, 0, -0]),
	// 	Vector3!float([0, 1, -0])

	// ), red);

	addTriangleColor(rendererTrianglesColor, Triangle!(float, 3)(
		Vector3!float([-0.5, 0, -0]),
		Vector3!float([0.5, 0, -0]),
		Vector3!float([0, 1, -0])

	), red);




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

		shader.setFloat4x4("P", false, idMat);
		shader.setFloat4x4("V", false, idMat);

		//return glfwGetKey(win.handle, GLFW_KEY_TAB) != GLFW_PRESS;
		return true;
	};


	auto providerLines = RenderDataProvider(none!(void delegate()), none!(void delegate()),
	 some(shaderDataLines));



	auto renderInfoLines = RenderInfo(rendererLines, providerLines);
	auto renderInfoTringlesColor = RenderInfo(rendererTrianglesColor, providerLines);

	//auto idLines = voxelRenderer.push(RenderLifetime(Manual()), RenderTransform(None()), renderInfoLines); 
	auto idTriColor = voxelRenderer.push(RenderLifetime(Manual()), RenderTransform(None()), renderInfoTringlesColor); 

	//voxelRenderer.lifetimeManualRenderers[idLines.getValue].renderer.construct();
	voxelRenderer.lifetimeManualRenderers[idTriColor.getValue].renderer.construct();




	//TODO frame time (precise timer)

	glEnable(GL_DEPTH_TEST);
	while(!glfwWindowShouldClose(win)){
		glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
		glClearColor(0.2f, 0.3f, 0.3f, 1.0f);


		voxelRenderer.draw(winInfo, camera);

		updateWindowInfo(winInfo);
		glfwSwapBuffers(win);
		glfwPollEvents();

		processInput(win);

		checkForGlErrors();
	}


	//voxelRenderer.lifetimeManualRenderers[idLines.getValue].renderer.deconstruct();
	voxelRenderer.lifetimeManualRenderers[idTriColor.getValue].renderer.deconstruct();


	glfwTerminate();

}
