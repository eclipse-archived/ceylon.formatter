shared class ParseOptionException(option, val)
        extends Exception("Can’t parse value '``val``' for option '``option``'!") {
    
    shared String option;
    shared String val;
}
