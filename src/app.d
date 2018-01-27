import std.stdio;
import std.conv;
import util;

import graphics;
import matrix;


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

void main() @system
{
	//runVoxelized();
	testStuff();
}

void testStuff(){
	auto i = vec!([1,0,0]);
	auto j = vec!([0,1,0]);
	auto k = i.cross(j);
	writeln(k);
	writeln(i * j);
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


	glEnable(GL_DEPTH_TEST);
	while(!glfwWindowShouldClose(win)){
		glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
		glClearColor(0.2f, 0.3f, 0.3f, 1.0f);

		glfwSwapBuffers(win);
		glfwPollEvents();

		processInput(win);

		checkForGlErrors();
	}


}
