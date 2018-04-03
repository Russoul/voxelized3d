module RenderingEngine;

import std.variant;
import std.stdio;
import std.typecons;

import graphics;
import matrix;
import render;
import util;

//
struct Manual{};
struct OneDraw{};
alias RenderLifetime = Algebraic!(Manual, OneDraw);
//


//
struct UI{};
struct World{};
alias RenderTransform = Algebraic!(UI, World, None);
//

struct RenderID{
    size_t id;
}

struct GenericCamera(T){
    Vector3!T pos;
    Vector3!T look;
    Vector3!T up; 
}

alias Camera = GenericCamera!float;

struct RenderDataProvider{
    Option!(void delegate()) preRenderState;
    Option!(void delegate()) postRenderState;
    Option!(bool delegate(Program, const ref WindowInfo, const ref Camera)) shaderData;
    //^^ returns false to cancel rendering
}

struct RenderInfo{
    RenderVertFrag renderer;
    RenderDataProvider provider;
}

class VoxelRenderer{
    RenderInfo[RenderID] lifetimeOneDrawRenderers;
    RenderInfo[RenderID] lifetimeManualRenderers;

    Program[string] shaders;
    private uint curId = 0; 


    this(Program[string] shaders){
        this.shaders = shaders;
    }


    void draw(const ref WindowInfo winInfo, const ref Camera camera){
        foreach(renderInfo; lifetimeOneDrawRenderers){
            auto shaderName = renderInfo.renderer.shaderName;
            Program shader = shaders[shaderName];

            shader.enable();

            if(renderInfo.provider.preRenderState.isDefined){
                renderInfo.provider.preRenderState.getValue()();
            }



            auto ok = renderInfo.provider.shaderData.match!(
                (x) => x(shader, winInfo, camera),
                () => true
            );


            if(ok){
                renderInfo.renderer.construct();
                renderInfo.renderer.draw();
                renderInfo.renderer.deconstruct();
            }

            if(renderInfo.provider.postRenderState.isDefined){
                renderInfo.provider.postRenderState.getValue()();
            }

            shader.disable();


        }

        foreach(renderInfo; lifetimeManualRenderers){
            auto shaderName = renderInfo.renderer.shaderName;
            Program shader = shaders[shaderName];

            shader.enable();

            if(renderInfo.provider.preRenderState.isDefined){
                renderInfo.provider.preRenderState.getValue()();
            }



            auto ok = renderInfo.provider.shaderData.match!(
                (x) => x(shader, winInfo, camera),
                () => true
            );


            if(ok){
                //manual construction and deconstruction
                renderInfo.renderer.draw();
                
            }

            if(renderInfo.provider.postRenderState.isDefined){
                renderInfo.provider.postRenderState.getValue()();
            }

            shader.disable();

        }
    }

    Option!RenderID push(RenderLifetime life, RenderTransform transform, RenderInfo renderer){
        
        return shaders.get(renderer.renderer.shaderName).visit!(
            delegate(Some!Program shader){

                auto providerDef = delegate bool(Program shader, const ref WindowInfo win , const ref Camera cam){
                    
                    
                    auto id = matS!([
                            [1.0f, 0.0f, 0.0f, 0.0f],
                            [0.0f, 1.0f, 0.0f, 0.0f],
                            [0.0f, 0.0f, 1.0f, 0.0f],
                            [0.0f, 0.0f, 0.0f, 1.0f]
                        ]);
                    
                    shader.setFloat4x4(
                        "P", false, id
                    );

                    shader.setFloat4x4(
                        "V", false, id
                    );


                    return true;
                };

                transform.visit!(
                    delegate(None _n){
                        renderer.provider.shaderData.visit!(
                            delegate(None _n){
                                renderer.provider.shaderData = some(providerDef);
                            },
                            delegate(Some!(bool delegate (Program, const ref WindowInfo, const ref Camera)) x){
                                auto combined = delegate bool(Program shader, const ref WindowInfo win , const ref Camera cam){
                                    providerDef(shader, win, cam);
                                    return x.get()(shader,win,cam);
                                };

                                renderer.provider.shaderData = some(combined);
                            }
                        );
                    },
                    delegate(UI _ui){
                        panic!void("unimplemented");
                    },
                    delegate(World _world){
                        panic!void("unimplemented");
                    }
                );

                auto rid = RenderID(curId);
                curId += 1;

                life.visit!(
                    delegate(Manual _life){
                        lifetimeManualRenderers[rid] = renderer;
                    },
                    delegate(OneDraw _life){
                        lifetimeOneDrawRenderers[rid] = renderer;
                    }
                );


                return some(rid);
            },
            delegate(None _n){ //shader not found
                return none!RenderID;
            }
        );
    }
}



