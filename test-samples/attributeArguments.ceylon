class ClassWithAttributeArguments(string) {
    shared actual variable String string;
}

void testAttributeArguments() {
    value withExpression = ClassWithAttributeArguments {
        string => "hi";
    };
    value withBlock = ClassWithAttributeArguments {
        String string {
            return "hi";
        }
    };
}
