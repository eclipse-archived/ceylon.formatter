void decLiterals() {
    value clM = `module ceylon.language`;
    value clP = `package ceylon.language`;
    value stringC = `class String`;
    value iterableI = `interface Iterable`;
    value aliasA = `alias Alias`;
    value givenG = `given Given`;
    value nullV = `value null`;
    value identityF = `function identity`;
    value newN = `new Constructor`;
    
    value currentM = `module`;
    value currentP = `package`;
    value currentC = `class`;
    value currentI = `interface`;
}

void decLiteralsWithoutBackticks() {
    value clM = module ceylon.language;
    value clP = package ceylon.language;
    value stringC = class String;
    value iterableI = interface Iterable;
    value aliasA = alias Alias;
    value givenG = given Given;
    value nullV = value null;
    value identityF = function identity;
    value newN = new Constructor;
    
    value currentM = module;
    value currentP = package;
    value currentC = class;
    value currentI = interface;
}
