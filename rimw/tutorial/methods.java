public class methods{
    static void myMethod(){
        // Code to execute
        // Static -> Belongs to Main | Void -> Returns nothing
        System.out.println("Wachu doing!");
    }

    static void myMethod2(String name){
        // Code to execute
        // Static -> Belongs to Main | Void -> Returns nothing
        System.out.println("Wachu doing " + name);
    }

    static int plusMethod(int x, int y) {
        return x + y;
    }
    // We can make the methods work with multiple datatypes
    static double plusMethod(double x, double y) {
        return x + y;
    }
    
    public static void main(String[] args){
        myMethod();
        myMethod2("Jhon Pork!");
        plusMethod(1, 2);
        plusMethod(2.4, 1.6);
    }


}