Boolean testBasicLogic   ()
 {
    value b1    = 1 == 5;
    value b2   = "a"   in { "a","b" };
    value b3 = b1   != b2;
    value b4 = b3&& 1 <= 2;
    value h = 'h';
    value t = "t"
    value b5 = b4 && h in t;
    return b4 == true;
}

void testPipelines() {
    value shout = String.uppercased >|> String.trimmed >|> print;
    "Hello, World!"
            |> String.size
            |> ((Integer i) => Integer.format(i, 16))
            |> shout;
}
