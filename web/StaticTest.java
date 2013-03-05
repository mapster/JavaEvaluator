class StaticTest {
    static int tall = 8;
    static int tall0 = 3-1;
    static int mult = 3*tall0;
    static int div = 6/2;
    static int tall2 = 4 + 3 + 2 + 1;
    static int tall3 = funksjon(fem());
    static int tall4 = funksjon3(fem(), funksjon2(fem()), 3);
    static double d1 = 2.0 * tall0;

    static int funksjon(int tall){
        tall0 = tall;
        return funksjon2(9);
    }

    static int funksjon2(int tall){
        tall2 = 1;
        if(true)
            return tall;
        else
            return 1;
    }

    static int fem(){
        return 5;
    }

    static int funksjon3(int tall, int tall2, int tall3){
        return tall2;
    }

    public static void main(String[] args){
 /*       System.out.println(mult);
        System.out.println(tall2);
        System.out.println(tall0);
        System.out.println(div);
        System.out.println(tall);
        System.out.println(tall3);
        System.out.println(d1);
        System.out.println(tall4);
*/
    }


}

