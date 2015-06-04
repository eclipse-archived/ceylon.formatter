interface SecondOrder<Box>
        given Box<Value> {
    shared formal Box<Float> createBox(Float float);
}
void takesCallableParamWithTypeParam(T f<T>(T t)) {}
