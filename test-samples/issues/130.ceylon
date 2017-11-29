shared void issue130() {
    if (true) { print(1); }
    else { print(2); }
    
    switch (b = true)
    case (true) { print(1); }
    else if (true) { print(2); }
    else { print(3); }
    
    switch (b2 = true)
    case (true) {
        if (true) { print(1); }
        else { print(2); }
    }
    else {
        if (true) { print(3); }
        else { print(4); }
    }
}
