class Mains {
    public static void main(String args){
        int x = 5;
        x = 10;
        x = 21;
        x = Mains.funksjon("hei");
        if(x == 21){
            x = 22;
            int y = 10;
            y = 5;
        }
    }


    static int funksjon(String s){
        if(s == "hei")
            return 1;
        
        return 0;
    }

}
