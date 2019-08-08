module util.pair;

struct pair(A, B) {
	A first;
	B second;

	this(A a, B b) {
		first = a;
		second = b;
	}
}

struct triple(A, B, C) {
	A first;
	B second;
	C third;

	this(A a, B b, C c) {
		first = a;
		second = b;
		third = c;
	}
}
