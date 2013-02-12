class ObjectTest {
    static int unique = 20;
    int id = 1;
    double verdi = 2.0;
    ObjectTest barn;

    public static void main(String[] args){
        ObjectTest o = new ObjectTest();
        o.barn = new ObjectTest();

        o.barn.id = 10;
    }
}
