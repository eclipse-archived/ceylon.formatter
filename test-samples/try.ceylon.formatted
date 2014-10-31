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

void testTryWithResources() {
    try (s = String("Hi!")) {
        print(s);
    }
}

void testTryWithMultipleResources() {
    try (s = String("Hi!"), i = 3) {
        print(s);
        print(i);
    }
}
