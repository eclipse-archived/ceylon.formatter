class TestTypeConstraints<T1,T2,T3>()
given T1 of String
satisfies Identifiable
given T2 of String|Integer
abstracts String {}
