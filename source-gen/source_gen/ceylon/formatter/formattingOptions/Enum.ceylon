import java.lang { JChar=Character }

"An enumerated type without any actual code.
 
 Consider for example the `maxLineLength` option.
 Here, users should be allowed to either specify a concrete [[Integer]] value
 or specify that they want unlimited line length, which means you need one
 special value. You could use [[null]], but adding a dedicated object/type pair
 `unlimited` increases readability and decreases the chance of the user giving
 the wrong value without understanding what it means."
class Enum(classname, instances /* = {lowercasedFirstChar(classname)} */) { // TODO uncomment later
    
    shared String classname; // see ceylon/ceylon-compiler#1492
    
    shared {String+} instances;
    
    assert (exists classname_first = classname.first,
        classname_first.uppercase,
        classname.every((Character c) => JChar.isJavaIdentifierPart(c.integer)));
    
    for (String instance in instances) {
        assert (exists instance_first = instance.first,
            instance_first.lowercase,
            instance.every((Character c) => JChar.isJavaIdentifierPart(c.integer)));
    }
}

String lowercasedFirstChar(String string) {
    variable Boolean isFirst = true;
    return String(string.map((Character elem) => isFirst then elem.lowercased else elem));
}
