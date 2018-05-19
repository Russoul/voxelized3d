module util;

import std.stdio;
import std.conv;
import std.variant;
import std.container.slist;
import std.typecons;

import bindings;

R iff(R)(bool cond, R function() ifTrue, R function() ifFalse){
    if(cond){
        return ifTrue();
    }else{
        return ifFalse();
    }
}

R ifm(R, alias A, alias B)(bool cond){
if(cond){
        return mixin(A);
    }else{
        return mixin(B);
    }
}

R panic(R)(string ex){
    throw new Exception(ex);
}

bool contains(T)(SList!(T) list, T a){
	foreach(T e ; list){
		if (e == a) return true;
	}

	return false;
}



struct None{};
struct Some(T){
    T t;

    alias t this;

    T get(){
        return t;
    }
};

alias Option(T) = Algebraic!(Some!(T), None);
Option!T some(T)(T t){
    return Option!T(Some!T(t));
}
Option!T none(T)(){
    return Option!T(None());
}

Option!T get(T,A)(T[A] assocArray, A key){
    T* res;
    res = (key in assocArray);
    if(res !is null){
        return some!T(*res);
    }else{
        return none!T;
    }
}


T getValue(T,uint size)(VariantN!(size, Some!T, None) opt){
    return opt.get!(Some!T).t;
}

bool isDefined(T, uint size)(VariantN!(size, Some!T, None) opt){
    return opt.convertsTo!(Some!T);
}

typeof(none()) match(alias some, alias none, T, uint size)(VariantN!(size, Some!T, None) opt) {
    if(opt.isDefined!(T,size)){
        return some(opt.getValue!(T,size));
    }else{
        return none();
    }
}


size_t createProgramVertFrag(string vertSrc_, string fragSrc_){

    auto vertSrc = cast(const char*) vertSrc_.dup;
    auto fragSrc = cast(const char*) fragSrc_.dup;

    auto prog = glCreateProgram();

    auto vertId = glCreateShader(GL_VERTEX_SHADER);
    auto fragId = glCreateShader(GL_FRAGMENT_SHADER);

    auto vertLen = vertSrc_.length;
    auto fragLen = fragSrc_.length;

    glShaderSource(vertId, 1, &vertSrc, &vertLen);
    glShaderSource(fragId, 1, &fragSrc, &fragLen);

    ulong status = 0;
    ulong max_len = 1024;
    ulong len = 0;
    char[] info = new char[max_len];
    glCompileShader(vertId);
    glGetShaderiv(vertId, GL_COMPILE_STATUS, &status);
    stdout.flush();
    if(status == 0){
        glGetShaderInfoLog(vertId, max_len, &len, info.ptr);
        writeln(info[len] + 0);

        auto strInfo = newString(info.ptr, len);
        writefln("Failed to compile vertex shader !\n Source:\n-------------------------\n%s\n-------------------------\nError:\n%s", vertSrc_, strInfo);
        stdout.flush();
        panic!void("");
    }

    glCompileShader(fragId);
    glGetShaderiv(fragId, GL_COMPILE_STATUS, &status);
    if(status == 0){
        glGetShaderInfoLog(fragId, max_len, &len, info.ptr);
        auto strInfo = newString(info.ptr, len);
        writefln("Failed to compile fragment shader !\n Source:\n-------------------------\n%s\n-------------------------\nError:\n%s", fragSrc_, strInfo);
        stdout.flush();
        panic!void("");
        
    }

    glAttachShader(prog, vertId);
    glAttachShader(prog, fragId);
    glLinkProgram(prog);
    glValidateProgram(prog);

    glDeleteShader(vertId);
    glDeleteShader(fragId);

    return prog;

}


//len includes null symbol
string newString(const(char *) cstr, size_t len){
    char[] str = new char[len];
    for(int i = 0; i < len; ++i){ //TODO memcpy ?
        str[i] = cstr[i];
    }

    return str.dup; //better way ?
}

char[] nullTerminate(string str){
    return (str ~ '\0').dup;
}

void println(string str){
    writeln(str);
    stdout.flush();
}
