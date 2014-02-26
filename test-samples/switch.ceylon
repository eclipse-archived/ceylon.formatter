void testSwitch() {
    String|Character? first = process.arguments.first;
    switch (first)
    case ("Hi") {
        print("Hello");
    }
    case (is Character) {
        print(first);
    }
    case (is Null) {
        print("null");
    }
    else {
        print(first);
    }
}
