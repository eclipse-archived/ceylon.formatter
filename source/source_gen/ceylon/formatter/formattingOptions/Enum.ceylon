/********************************************************************************
 * Copyright (c) 2011-2017 Red Hat Inc. and/or its affiliates and others
 *
 * This program and the accompanying materials are made available under the 
 * terms of the Apache License, Version 2.0 which is available at
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * SPDX-License-Identifier: Apache-2.0 
 ********************************************************************************/
import java.lang {
    JChar=Character
}

"An enumerated type without any actual code.
 
 Consider for example the `maxLineLength` option.
 Here, users should be allowed to either specify a concrete [[Integer]] value
 or specify that they want unlimited line length, which means you need one
 special value. You could use [[null]], but adding a dedicated object/type pair
 `unlimited` increases readability and decreases the chance of the user giving
 the wrong value without understanding what it means."
class Enum(classname, instances = { lowercasedFirstChar(classname) }, generate = true) {
    
    shared String classname; // see ceylon/ceylon-compiler#1492
    
    shared {String+} instances;
    
    "If you set this to [[false]], the enum class won’t be generated.
     In this case, the only use of the enum is to simplify the parser,
     which will still directly check all cases instead of delegating to a `parseX` function."
    shared Boolean generate;
    
    "[[classname]] must be a valid class name!"
    assert (exists classname_first = classname.first,
        classname_first.uppercase,
        classname.every((Character c) => JChar.isJavaIdentifierPart(c.integer)));
    
    for (String instance in instances) {
        "[[instances]] must each be a valid object name!"
        assert (exists instance_first = instance.first,
            instance_first.lowercase,
            instance.every((Character c) => JChar.isJavaIdentifierPart(c.integer)));
    }
}

String lowercasedFirstChar(String string) {
    variable Boolean isFirst = true;
    return String(string.map((Character elem) => isFirst then elem.lowercased else elem));
}
