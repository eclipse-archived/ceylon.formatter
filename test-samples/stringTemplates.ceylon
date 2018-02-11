void testStringTemplates() {
    print("Hello, ``process.arguments.first else "World"``!");
}

void testStringInterpolation() {
    value name = process.arguments.first else "World";
    print("Hello, \(name)!");
}
