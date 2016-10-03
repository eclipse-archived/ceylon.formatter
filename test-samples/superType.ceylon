class Super() {
    shared class Inner() {
    }
}

class Sub() extends Super() {
    class SubInner() extends super.Inner() {
    }
}

class Other() extends JavaClass.InnerClass.NestedClass.AnotherClass() {
}
