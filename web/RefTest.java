public class RefTest {
	public int val;

	public RefTest(int a) {
		val = a;
	}

	public static void main(String[] args) {
		int x = 1;
		int[] y = new int[1];
		y[0] = 1;
		RefTest z = new RefTest(1);
		foo(x);
		bar(y);
		baz(z);
		assert x == 1;
		System.out.printf("%d, %d, %d\n", x, y[0], z.val);
	}

	static void foo(int a) {
		a = 5;
	}
	
	static void bar(int[] a) {
		a[0] = 5;
	}
	
	static void baz(RefTest a) {
		a.val = 5;
	}
}
