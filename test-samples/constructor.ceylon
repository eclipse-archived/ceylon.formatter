class Constructors /* no parameter list, no default constructor */
        extends SuperClass /* no argument list */ {
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
    
    "A value constructor."
    shared new valueCons1 {}
    /* undocumented */
    new valueCons2 {
        shared actual String string => "valueCons2";
    }
}
