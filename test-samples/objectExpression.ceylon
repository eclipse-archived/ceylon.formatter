Anything objectExpression = object extends Object() satisfies Identifiable {
    shared String member = "member";
    print(object {
            string = "Init";
        });
};
