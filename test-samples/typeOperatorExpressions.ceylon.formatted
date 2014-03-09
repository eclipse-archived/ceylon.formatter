void testTypeOperatorExpressions() {
    String|Integer v = "1";
    Boolean b1 = v is String;
    // formatter supports this even if language doesn’t :)
    Boolean b2 = v extends String;
    // funny how they have survived in the grammar for three years without language support :D
    Boolean b3 = v satisfies Summable<Integer>;
    Anything b4 = v of String|Integer;
}
