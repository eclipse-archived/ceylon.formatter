interface SecondOrder<Box>
        given Box<Value> {
    shared formal Box<Float> createBox(Float float);
}
void takesCallableParamWithTypeParam(T f<T>(T t)) {}
value namedArgsInvocWithFunctionArgWithTypeParam = f {
    function f<T>(T t) {
        return t;
    }
};
value anonymousGenericFunction = <T>(T t) => t;
