void testTry() {
    try {
        print("Hi!");
    }
}

void testTryCatch() {
    try {
        print("Hi!");
    } catch (Exception e) {
        print("Oops.");
    }
}

void testTryCatchFinally() {
    try {
        print("Hi!");
    } catch (Exception e) {
        print("oops.");
    } finally {
        print("Phew!");
    }
}
