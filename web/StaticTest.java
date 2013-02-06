class StaticTest {
    static int[][] liste = new int[10][2];
    static String s = "hei";
    static String s2 = s + "sann";
    static int tall0 = 3-1;
    static int mult = 3*tall0;
    static int div = 6/2;
    static int tall2 = 4 + 3 + 2 + 1;
    static int tall3 = funksjon(fem());
    static int tall4 = funksjon3(fem(), funksjon2(fem()), 3);
    static double d1 = 2.0 * tall0;

    static int farray(String[] liste){
        return 1;
    }

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
}

