public class ReturnTest {
    public static void main(String[] args){
        int x = 0;
        f(x);
        x = g(x);
        int y = x;
    }

    static void f(int a){
        a = a + 2;
    }

    static int g(int a){
        return a +3;
    }
}

