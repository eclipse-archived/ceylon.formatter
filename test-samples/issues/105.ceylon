Boolean f1() =>
    let (a = 1, b = 2)
        if (a+b == 3)
        then true
        else false;

Boolean f2()
        => let (a = 1, b = 2)
            if (a+b == 3)
            then true
            else false;

Boolean f3() => bool {
    par1 = true;
    par2 = false;
    Boolean par3()
            => true;
    Boolean par4() =>
        false;
};
