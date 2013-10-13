import ceylon.collection { HashMap, MutableMap }

"A mode to indent code based on levels of indentation."
shared abstract class IndentMode()
		of Spaces|Tabs|Mixed {
	
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
interface Cached<Item> satisfies Correspondence<Integer, Item>
		given Item satisfies Summable<Item> {
	
	shared formal MutableMap<Integer, Item> cache;
	
	shared actual Item get(Integer key) {
		if (exists cached = cache[key]) {
			return cached;
		}
		// construct
		Integer half = key / 2;
		Item halfItem = get(half);
		Item constructed = halfItem + halfItem
				+ get(key%2);
		cache.put(key, constructed);
		return constructed;
	}
}

"Indent using spaces."
shared class Spaces(spacesPerLevel) extends IndentMode() {
	
	"The amount of spaces per indentation level.
	 Usual values are `2`, `4` and `8`."
	shared Integer spacesPerLevel;
	
	widthOfLevel = spacesPerLevel;
	
	object cache satisfies Cached<String> {
		shared actual MutableMap<Integer,String> cache = HashMap<Integer, String> {
			0 -> "",
			1 -> "".join
			{ for (value i in 1..spacesPerLevel) " " } // todo: check speed of " ".join("", "", ...) vs "".join(" ", " ", ...)
		};		
	}
	shared actual String indent(Integer level) => cache.get(level);
}

"Indent using tabs."
shared class Tabs(width) extends IndentMode() {
	
	"The width of a tab.
	 Usual values are `4` and `8`."
	shared Integer width;
	
	widthOfLevel = width;
	
	object cache satisfies Cached<String> {
		shared actual MutableMap<Integer,String> cache = HashMap<Integer, String> {
			0 -> "",
			1 -> "\t"
		};
	}
	shared actual String indent(Integer level) => cache.get(level);
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
	
	MutableMap<Integer, String> cache = HashMap<Integer, String> { 0 -> "" };
	
	shared actual String indent(Integer level) {
		if (exists cached = cache[level]) {
			return cached;
		}
		// construct from scratch
		Integer fullWidth = level * spaces.widthOfLevel;
		String tabPart = tabs.indent(fullWidth / tabs.width);
		String spacesPart = "".join
		{ for (value i in 1..(fullWidth % tabs.width)) " " };
		String indent = tabPart + spacesPart;
		cache.put(level, indent);
		return indent;
	}
}