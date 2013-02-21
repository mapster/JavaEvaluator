class ObjectTest {
    static int unique = 20;
    int id = 1;
    double verdi = 2.0;
    ObjectTest barn;

    ObjectTest(int idt){
        id = idt;
    }

    public static void main(String[] args){
        ObjectTest o = new ObjectTest(2);
        o.barn = new ObjectTest(1);

        o.barn.id = 10;
    }
}
