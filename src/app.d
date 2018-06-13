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
import bindings;
import matrix;
import RenderingEngine;
import render;
import math;
import umdc;

import amdc;

import hermite;

import std.typecons;



extern(C) void errorCallback(int code, const char* error) {
	writeln("GL error: " ~ to!string(error));
	
}

extern (C) void framebufSzCb(GlfwWindow* win, size_t w, size_t h){
	glViewport(0,0,w,h);
}

extern (C) void keyCallback(GlfwWindow* win,int key,int scancode,int action,int mods){
    
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

    if(glfwGetKey(win, GLFW_KEY_LEFT_ALT) == GLFW_PRESS){
        glfwSetInputMode(win, GLFW_CURSOR, GLFW_CURSOR_DISABLED);
    }else{
        glfwSetInputMode(win, GLFW_CURSOR, GLFW_CURSOR_NORMAL);
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

    // import std.container.slist;
    // auto list = SList!uint();
    // writeln(list);
    // list.insertFront(1);
    // writeln(list);

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
    glfwSetKeyCallback(win, &keyCallback);
	glfwSetInputMode(win, GLFW_STICKY_KEYS, 1);
	//glfwSetInputMode(win, GLFW_CURSOR, GLFW_CURSOR_DISABLED);

	glViewport(0,0,defWidth,defHeight);

	auto shaders = loadShaders();

	auto voxelRenderer = new VoxelRenderer(shaders);

	auto winInfo = WindowInfo(defWidth, defHeight, win);
	auto camera = Camera(Vector3!float([0.0F, 0.0F, 0.0F]), vecS!([0.0F, 0.0F, -1.0F]), vecS!([0.0F, 1.0F, 0.0F]));


	auto rendererLines = new RenderVertFragDef("color", GL_LINES, () => setAttribPtrsColor());
	auto rendererTrianglesColor = new RenderVertFragDef("color", GL_TRIANGLES, () => setAttribPtrsColor());
    auto rendererTrianglesLight = new RenderVertFragDef("lighting", GL_TRIANGLES, () => setAttribPtrsNormal());
    auto rendererScreenGuiTextureColor = new RenderVertFragDef("texture_color", GL_TRIANGLES, () => setAttribPtrsTextureColor());

    auto rendererLinesDebugOneDraw = new RenderVertFragDef("color", GL_LINES, () => setAttribPtrsColor()); 


	auto red = Vector3!(float)([1.0F, 0.0F, 0.0F]);
	auto green = Vector3!(float)([0.0F, 1.0F, 0.0F]);
	auto blue = Vector3!(float)([0.0F, 0.0F, 1.0F]);
	auto black = zero!(float,3,1);
	auto white = red + green + blue;
	auto brown = Vector3!float([139.0F/256.0F,69.0F/255.0F,19.0F/255.0F]);
    auto yellow = red + green;

    addLine3Color(rendererLines, Line!(float,3)(black, red), red);
    addLine3Color(rendererLines, Line!(float,3)(black, green), green);
    addLine3Color(rendererLines, Line!(float,3)(black, blue), blue);


    // ========================= UMDC & ADC ==============================
    auto noise = allocFastNoise();
    setFrequency(noise, 1.0);

    setNoiseType(noise, FastNoise.NoiseType.Simplex);



    alias FP = float;

    import density;


    auto offset = vec3!FP(-2.0, -2.0, -2.0);
    FP a = 0.125F/2.0F;
    const size_t size = 128;
    size_t acc = 16;


    Cube!FP bounds = Cube!FP(offset + vec3!FP(size/2 * a, size/2 * a, size/2 * a), size * a / 2);


    auto f = DenFn3!FP(noise, bounds);

    auto color = brown;


    DenSphereDisplacement!FP sph = {Sphere!FP(vec3!FP(0,0,0), 2)};

    auto cube = DenCube!FP(Cube!FP(vec3!FP(1.0,1.0,1.0), 0.5));
    FP sizee = 0.8;

    auto dirs = Matrix!(FP,3,2)([
        1.0, 1.0,
        -0.5,1.0,
        -0.2,1.0
    ]);

    auto resDirs = dirs;

    gramSchmidt(dirs, resDirs);

    auto obb = DenOBB!FP(OBB!FP(vec3!FP(2.0,2.0,2.0), resDirs.column(0), resDirs.column(1), vec3!FP(sizee,sizee,sizee)));
    DenUnion!(FP,typeof(f), typeof(obb)) r = {f, obb};
    DenUnion!(FP,typeof(r), DenOBB!FP) q = {r, obb};


    alias colorizer = delegate(Vector3!FP v){
        auto rel = v - offset;
        auto a = bounds.extent * 2;

        if(rel.y < a / 4){
            return Vector3!FP([64.0F/255.0F, 164.0F/255.0F, 223/255.0F]);
        }
        else if(rel.y < a/2){
            return Vector3!FP([37.6F/255.0F, 50.2F/255.0F, 22/255.0F]);
        }
        else if(rel.y < 3*a/4){
            return Vector3!FP([139.0F/255.0F, 141.0F/255.0F, 122/255.0F]);
        }
        else{
            return Vector3!FP([212.0F/255.0F, 240.0F/255.0F, 1.0F]);
        }
    };

    //umdc.extract!(typeof(q))(q, offset, a, size, acc, colorizer, rendererTrianglesLight, rendererLines);

    

    StopWatch watch;
    size_t ms;

    
    // setConstantMem();
    // watch.start();
    // sampleGPU(cast(float3)offset, a, cast(uint)acc, &storage);//TODO malloc calls inside !
    // watch.stop();
    // size_t ms;
    // watch.peek().split!"msecs"(ms);
    // printf("GPU sampling took %d ms\n", ms);
    // watch.start();
    // umdc.extract(storage, offset, a, colorizer, rendererTrianglesLight, rendererLines);
    // watch.stop();
    // watch.peek().split!"msecs"(ms);
    // printf("Whole process took %d ms", ms);
    // stdout.flush();


    
    // watch.start();
    // auto ustorage = UniformVoxelStorage!float(size);
    // umdc.sample!(typeof(q))(q, offset, a, acc, ustorage);
    // umdc.extract(ustorage, offset, a, colorizer, rendererTrianglesLight, rendererLines);
    // watch.stop();
    // watch.peek().split!"msecs"(ms);
    // watch.reset();
    // printf("Whole process of uniform gen took %d ms\n", ms);
    // stdout.flush();


    watch.start();
    VoxelRenderData!FP voxelRenderData;
    auto tree = sample!(FP, typeof(q), false)(q, offset, a, size, acc, 1e-5, voxelRenderData);
    watch.stop();
    watch.peek().split!"msecs"(ms);
    watch.reset();
    printf("Tree generation and collapsing homo leaves took %d\n", ms);

    auto fhet = (Node!FP* node, Cube!FP bounds){
        auto boundsf = Cube!float( bounds.center.mapf( x => cast(float) x), cast(float) bounds.extent );
        if(nodeType(node) == NODE_TYPE_HETEROGENEOUS){
            addCubeBounds(rendererLines, boundsf, red);
            addCubeBounds(rendererLines, Cube!float( asHetero!FP(node).qef.minimizer.mapf(x => cast(float)x ) + asHetero!FP(node).qef.massPoint.mapf(x => cast(float) x), cast(float)bounds.extent / 32 ), yellow);
        
            foreach(i;0..8){
                auto sign = asHetero!FP(node).getSign(cast(ubyte)i);
                
                auto center = bounds.center;
                auto rel = cornerPointsOrigin[i] * bounds.extent;
                auto point = center + rel;

                Vector3!float color;
                if(sign == 1){
                    color = black;
                }else{
                    color = white;
                }

                addCubeBounds(rendererLines, Cube!float(point.mapf(x => cast(float)x), boundsf.extent / 32), color);
            }
        
        }else{
            addCubeBounds(rendererLines, boundsf, green);
        }
    };
    foreachLeaf!(FP, fhet)(tree, bounds);

    
    watch.start();
    auto astorage = AdaptiveVoxelStorage!FP(size, tree);
    extract!FP(astorage, voxelRenderData);
    auto voxelRendererColorNormal = new RenderVertFragDef("lighting", GL_TRIANGLES, () => setAttribPtrsNormal());
    voxelRenderData.updateColorNormalRenderer(voxelRendererColorNormal);
    watch.stop();
    watch.peek().split!"msecs"(ms);
    printf("Extraction took %d ms\n", ms);
    stdout.flush();

    freeFastNoise(noise);

    // ==============================================================



    // ===================== load crosshair =======================

    int imgWidth, imgHeight, imgCh;
    ubyte* dotImg = stbi_load("assets/textures/gui/dot.png", &imgWidth, &imgHeight, &imgCh, 0);
    writeln("loaded dot.png, width = " ~ to!string(imgWidth) ~ ", height = " ~ to!string(imgHeight) ~ ", channels = " ~ to!string(imgCh));
    uint dotTex;
    glGenTextures(1, &dotTex);
    glBindTexture(GL_TEXTURE_2D, dotTex);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, imgWidth, imgHeight, 0, GL_RGBA, GL_UNSIGNED_BYTE, cast(void*) dotImg);
    glGenerateMipmap(GL_TEXTURE_2D);
    stbi_image_free(dotImg);

    // =====================================

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

    auto shaderScreenGui =
    	delegate(Program shader, const ref WindowInfo win, const ref Camera camera){

            glBindTexture(GL_TEXTURE_2D, dotTex);
            glUniform1i(glGetUniformLocation(shader.id, "textureID"), 0);

    		auto aspect = cast(float)win.width / win.height;

    		auto idMat = matS!([
    			[1.0F, 0.0F, 0.0F, 0.0F],
    			[0.0F, 1.0F, 0.0F, 0.0F],
    			[0.0F, 0.0F, 1.0F, 0.0F],
    			[0.0F, 0.0F, 0.0F, 1.0F]
    		]);

    		auto ortho = orthographicProjection(0, win.width, win.height, 0, -1, 1);


    		shader.setFloat4x4("P", false, ortho); //TODO
    		shader.setFloat4x4("V", true, idMat);

    		return true;
    	};

	auto providerLines = RenderDataProvider(none!(void delegate()), none!(void delegate()),
	 some(shaderDataLines));


    auto provider = RenderDataProvider(none!(void delegate()), none!(void delegate()), some(shaderData));

    auto providerScreenGui = RenderDataProvider(none!(void delegate()), none!(void delegate()), some(shaderScreenGui));


	auto renderInfoLines = RenderInfo(rendererLines, providerLines);
	auto renderInfoTringlesColor = RenderInfo(rendererTrianglesColor, provider);
	auto renderInfoTrianglesLight = RenderInfo(rendererTrianglesLight, provider);
    auto renderInfoVoxels = RenderInfo(voxelRendererColorNormal, provider);
    auto renderInfoScreenGui = RenderInfo(rendererScreenGuiTextureColor, providerScreenGui);

    auto renderInfoLinesDebugOneDraw = RenderInfo(rendererLinesDebugOneDraw, providerLines);

	auto idLines = voxelRenderer.push(RenderLifetime(Manual()), RenderTransform(None()), renderInfoLines);
	auto idTriColor = voxelRenderer.push(RenderLifetime(Manual()), RenderTransform(None()), renderInfoTringlesColor);
	auto idTriLight = voxelRenderer.push(RenderLifetime(Manual()), RenderTransform(None()), renderInfoTrianglesLight);
    auto idVoxels = voxelRenderer.push(RenderLifetime(Manual()), RenderTransform(None()), renderInfoVoxels);

	voxelRenderer.lifetimeManualRenderers[idLines.getValue].renderer.construct();
	voxelRenderer.lifetimeManualRenderers[idTriColor.getValue].renderer.construct();
    voxelRenderer.lifetimeManualRenderers[idTriLight.getValue].renderer.construct();
    voxelRenderer.lifetimeManualRenderers[idVoxels.getValue].renderer.construct();



	StopWatch sw;
	sw.start();


    //glEnable(GL_CULL_FACE);
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
		    auto bmin = bounds.center.mapf(x => cast(float) x) - vec3!float(cast(float)bounds.extent,cast(float)bounds.extent,cast(float)bounds.extent);
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
        update(winInfo, camera, bounds, astorage, voxelRenderData,voxelRendererColorNormal, frameDeltaNs, renderInfoScreenGui, renderInfoLinesDebugOneDraw, voxelRenderer);

		checkForGlErrors();
	}


	voxelRenderer.lifetimeManualRenderers[idLines.getValue].renderer.deconstruct();
	voxelRenderer.lifetimeManualRenderers[idTriColor.getValue].renderer.deconstruct();
    voxelRenderer.lifetimeManualRenderers[idTriLight.getValue].renderer.deconstruct();
    voxelRenderer.lifetimeManualRenderers[idVoxels.getValue].renderer.deconstruct();

    glDeleteTextures(1, &dotTex);

	glfwTerminate();

}



Tuple!(HeterogeneousNode!T*,Cube!T) rayTraceFirstHetero(T)(Node!T* tree, Cube!T bounds, ref Line!(T,3) ray, ref T t){

    if(checkLine3CubeIntersection(ray, bounds, t)){

        if(tree.__node_type__ == NODE_TYPE_HETEROGENEOUS){
            return tuple(asHetero!T(tree), bounds);
        }else if(tree.__node_type__ == NODE_TYPE_HOMOGENEOUS){
            return tuple( cast(HeterogeneousNode!T*) null, bounds);
        }

        Cube!T[8] chBounds;
        genCubeChildrenBounds!T(bounds, chBounds);

        T tMin = 2.0; //2.0 is not possible case (0 < t < 1)
        Tuple!(HeterogeneousNode!T* ,Cube!T) nMin;
        size_t iMin;
        
        foreach(i;0..8){
            T tCur;
            auto nCur = rayTraceFirstHetero!T(asInterior!T(tree).children[i], chBounds[i], ray, tCur);
            if(nCur[0]){
                if(tCur < tMin){
                    tMin = tCur;
                    nMin = nCur;
                    iMin = i;
                }
            }
        }

        if(tMin > 1.0){
            return tuple(cast(HeterogeneousNode!T*) null, bounds);
        }else{
            return nMin;
        }

    }else{
        return tuple(cast(HeterogeneousNode!T*) null, bounds);
    }
}


Cube!float lastCube;

void update(const ref WindowInfo win, ref Camera cam, Cube!float bounds, ref AdaptiveVoxelStorage!float chunk, ref VoxelRenderData!float vrd, ref RenderVertFragDef chunkRenderer, ulong frameDeltaNs,
  ref RenderInfo renderInfoScreenGui, ref RenderInfo renderInfoLinesDebugOneDraw, VoxelRenderer vr){

    // === update crosshair ====

    auto crosshairWidth = win.height / 128;
    auto crosshairCenter = vec3!float(win.width/2, win.height/2, 0);
    Vector3!float[4] vertices;
    foreach(i;0..4){
        vertices[i] = crosshairCenter + vec3!float(crosshairWidth,0,0) * rectangle3VerticesNDC[i].x + vec3!float(0,crosshairWidth,0) * rectangle3VerticesNDC[i].y; 
    }
    Vector2!float[4] texCoords = [vec2!float(0,0), vec2!float(1,0), vec2!float(1,1), vec2!float(0,1)];

    (cast(RenderVertFragDef) renderInfoScreenGui.renderer).reset(); //clear the pools
    (cast(RenderVertFragDef) renderInfoLinesDebugOneDraw.renderer).reset(); //clear the pools

    addRectangleTexColor( cast(RenderVertFragDef) renderInfoScreenGui.renderer, vertices, texCoords, vec3!float(0.8, 0.8, 0.8));
    vr.push(RenderLifetime(OneDraw()), RenderTransform(None()), renderInfoScreenGui);

    addCubeBounds(cast(RenderVertFragDef) renderInfoLinesDebugOneDraw.renderer, lastCube, vec3!float(0, 0, 0));
    vr.push(RenderLifetime(OneDraw()), RenderTransform(None()), renderInfoLinesDebugOneDraw);


    // =========================  

    if(glfwGetKey(win.handle, GLFW_KEY_R) == GLFW_PRESS){
        float rayLen = 32.0F;

        auto ray = Line!(float, 3)(cam.pos, cam.pos + cam.look * rayLen);

        auto tree = chunk.root;

        float t;
        auto traced = rayTraceFirstHetero(tree, bounds, ray, t);

        if(traced[0] != null){
            lastCube = traced[1].scale(0.8);
            writeln("found intersection");

            vrd.removeVertex(traced[0].index);
            vrd.updateColorNormalRenderer(chunkRenderer);
            chunkRenderer.deconstruct();
            chunkRenderer.construct();

        }else{
            writeln("intersection not found");
        }
    }

    if(glfwGetKey(win.handle, GLFW_KEY_F) == GLFW_PRESS){
        float rayLen = 32.0F;

        auto ray = Line!(float, 3)(cam.pos, cam.pos + cam.look * rayLen);

        Cube!float cube = Cube!float(vec3!float(0,0,0), 0.5F);

        float t;
        auto traced = checkLine3CubeIntersection(ray, cube, t);

        writeln(to!string(t) ~ to!string(traced));
    }
}
