class ArrayTest {
    static int size = 10;
    static int tall = funk();
    static int[][] liste = new int[5][];

    static int funk(){
        int[][] liste = new int[size][2];
        int ind = 4;
        liste[ind][0] = size - 2;
        return liste[ind][0];
    }
}
