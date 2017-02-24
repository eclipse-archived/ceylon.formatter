shared void asserts() {
    // assert with multiple conditions
    assert (exists arg0 = process.arguments.first,
        is String arg1 = process.arguments.rest.first,
        nonempty arg2 = process.arguments.rest.rest.first?.sequence());
    "Time must be positive" // assertion message
    assert (system.milliseconds >= 0);
    "Should have exactly three (3) arguments, not ``process.arguments.size``" // interpolated assertion message
    assert (process.arguments.size == 3);
}
