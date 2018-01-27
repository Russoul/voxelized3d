module util;

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