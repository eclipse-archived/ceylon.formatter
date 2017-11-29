void testLet() {
    value normalizedPoints = {
        for (point in points)
            if (point != origin)
                let (x = point.x,
                    y = point.y,
                    dist = (x^2 + y^2) ^ 0.5)
                    Point(x / dist, y / dist)
    };
    print(let (a = 1) a);
}
