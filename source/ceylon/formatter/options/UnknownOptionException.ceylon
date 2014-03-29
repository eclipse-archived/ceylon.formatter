shared class UnknownOptionException(option)
        extends Exception("Unknown option ``option``!") {
    
    shared String option;
}
