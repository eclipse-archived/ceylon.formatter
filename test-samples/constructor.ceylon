class Constructors /* no parameter list, no default constructor */ {
    "Constructs something"
    shared new cons1() {}
    /* undocumented */
    new cons2(String param)
            extends super.thing(param) {
        print(param);
    }
    new cons3()
            extends Other.thing(param) {}
    new () {} // default constructor
}
