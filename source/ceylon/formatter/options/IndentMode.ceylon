/********************************************************************************
 * Copyright (c) 2011-2017 Red Hat Inc. and/or its affiliates and others
 *
 * This program and the accompanying materials are made available under the 
 * terms of the Apache License, Version 2.0 which is available at
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * SPDX-License-Identifier: Apache-2.0 
 ********************************************************************************/
import ceylon.collection {
    HashMap,
    MutableMap
}

"A mode to indent code based on levels of indentation."
shared abstract class IndentMode()
        of Spaces | Tabs | Mixed {
    
    "The width of one indentation level."
    shared formal Integer widthOfLevel;
    
    "Get a string representing the indentation by `level` levels using this `IndentMode`."
    shared formal String indent(
        "The indentation level. Must be positive." // TODO assert positiveness?
        Integer level);
}

"A cached [[Correspondence]] of [[Integer]]s to [[Summable]] items.
 New items are constructed from known ones like this:
 
     get(11)
     = get(5) + <same> + get(1)
     = (get(2) + get(2) + get(1)) + <same> + get(1)
     = ((get(1) + get(1) + get(0)) + <same>) + <same> + get(1)
 
 Therefore, users only have to fill the [[cache]] with two initial values: The items belonging to the keys `0` and `1`."
interface Cached<Item> satisfies Correspondence<Integer,Item>
        given Item satisfies Summable<Item> {
    
    shared formal MutableMap<Integer,Item> cache;
    
    shared actual Item get(Integer key) {
        if (exists cached = cache[key]) {
            return cached;
        }
        // construct
        Integer half = key / 2;
        Item halfItem = get(half);
        Item constructed = halfItem + halfItem + get(key % 2);
        cache[key] = constructed;
        return constructed;
    }
    
    shared actual Boolean defines(Integer key) {
        return true;
    }
}

"Indent using spaces."
shared class Spaces(spacesPerLevel) extends IndentMode() {
    
    "The amount of spaces per indentation level.
     Usual values are `2`, `4` and `8`."
    shared Integer spacesPerLevel;
    
    widthOfLevel = spacesPerLevel;
    
    shared actual String string = spacesPerLevel.string + " spaces";
    
    object cache satisfies Cached<String> {
        shared actual MutableMap<Integer,String> cache = HashMap<Integer,String> {
            0->"",
            1 -> "".join
                { for (value i in 1..spacesPerLevel) " " } // todo: check speed of " ".join("", "", ...) vs "".join(" ", " ", ...)
        };
    }
    shared actual String indent(Integer level) => cache.get(level);
    
    shared actual Boolean equals(Object that) {
        if (is Spaces that) {
            return spacesPerLevel == that.spacesPerLevel;
        } else {
            return false;
        }
    }
    shared actual Integer hash => spacesPerLevel.hash;
}

"Indent using tabs."
shared class Tabs(width) extends IndentMode() {
    
    "The width of a tab.
     Usual values are `4` and `8`."
    shared Integer width;
    
    widthOfLevel = width;
    
    shared actual String string = widthOfLevel.string + "-wide tabs";
    
    object cache satisfies Cached<String> {
        shared actual MutableMap<Integer,String> cache = HashMap<Integer,String> {
            0->"",
            1->"\t"
        };
    }
    shared actual String indent(Integer level) => cache.get(level);
    
    shared actual Boolean equals(Object that) {
        if (is Tabs that) {
            return width == that.width;
        } else {
            return false;
        }
    }
    shared actual Integer hash => width.hash;
}

"Indent using tabs and spaces.
 
 `spaces` controls the width of one indentation level.
 To provide the wanted indentation, the line is filled with as many tabs as fit, and then padded with spaces.
 Typically, the width of a level is `4`, while a tab is `8` wide; this would be created with
 
     Mixed(Tabs(8), Spaces(4))
 
 or, more verbosely,
 
     Mixed {
         Tabs {
             width = 8;
         };
         Spaces {
             spacesPerLevel = 4;
         };
     };"
shared class Mixed(tabs, spaces) extends IndentMode() {
    
    shared Tabs tabs;
    
    shared Spaces spaces;
    
    widthOfLevel = spaces.widthOfLevel;
    
    shared actual String string = "mix " + tabs.string + ", " + spaces.string;
    
    MutableMap<Integer,String> cache = HashMap<Integer,String> { 0->"" };
    
    shared actual String indent(Integer level) {
        if (exists cached = cache[level]) {
            return cached;
        }
        // construct from scratch
        Integer fullWidth = level * spaces.widthOfLevel;
        String tabPart = tabs.indent(fullWidth / tabs.width);
        String spacesPart = "".join
            { for (value i in 1 .. (fullWidth % tabs.width)) " " };
        String indent = tabPart + spacesPart;
        cache[level] = indent;
        return indent;
    }
    
    shared actual Boolean equals(Object that) {
        if (is Mixed that) {
            return tabs==that.tabs && spaces==that.spaces;
        } else {
            return false;
        }
    }
    shared actual Integer hash => 31*tabs.hash + spaces.hash;
}

"The [[IndentMode]] represented by the given [[String]], or [[null]] if the string can't be parsed.
 
 The format is like this:
 
 * `n spaces`, where `n` represents an [[Integer]], for [[Spaces]]`(n)`
 * `n-wide tabs`, where `n` represents an `Integer`, for [[Tabs]]`(n)`
 * `mix n-wide tabs, m spaces`, where `m`, `n` represent `Integers`, for [[Mixed]]`(Tabs(n), Spaces(m))`"
shared IndentMode? parseIndentMode(String string) {
    try {
        if (exists mixIndex = string.inclusions("mix ").first) {
            if (exists commaIndex = string.inclusions(", ").first) {
                value first = parseIndentMode(string["mix ".size .. commaIndex-1]);
                value second = parseIndentMode(string[commaIndex+", ".size ...]);
                if (is Tabs tabs = first) {
                    if (is Spaces spaces = second) {
                        return Mixed(tabs, spaces);
                    } else {
                        throw Exception("First part of Mixed are tabs, but second part aren't spaces");
                    }
                } else if (is Spaces spaces = first) {
                    if (is Tabs tabs = second) {
                        return Mixed(tabs, spaces);
                    } else {
                        throw Exception("First part of Mixed are spaces, but second part aren't tabs");
                    }
                } else {
                    throw Exception("First part of Mixed are neither spaces nor tabs");
                }
            } else {
                throw Exception("Mixed doesn't contain a comma");
            }
        } else if (exists spaceIndex = string.inclusions(" spaces").first) {
            value nString = string[... spaceIndex-1];
            if (exists n = parseInteger(nString)) {
                return Spaces(n);
            } else {
                throw Exception("Can't read space amount '``nString``'");
            }
        } else if (exists tabsIndex = string.inclusions("-wide tabs").first) {
            value nString = string[... tabsIndex-1];
            if (exists n = parseInteger(nString)) {
                return Tabs(n);
            } else {
                throw Exception("Can't read tab width '``nString``'");
            }
        } else {
            throw Exception("I didn't recognize anything in that string!");
        }
    } catch (Exception e) {
        return null;
    }
}
