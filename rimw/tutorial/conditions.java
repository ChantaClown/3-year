public class conditions {
    public static void main(String[] args){
        int age = 20;
        if (age >= 18){
            System.out.println("You can enter!");
        }
        else{
            System.out.println("You are a minor!");
        }

        // variable = (condition) ? expressionTrue :  expressionFalse;
        int time = 20;
        String result = (time < 18) ? "Good day." : "Good evening.";
        System.out.println(result);

        int day = 4;
        switch (day) {
            case 1:
                System.out.println("Monday");
                break;
            case 2:
                System.out.println("Tuesday");
                break;
            case 3:
                System.out.println("Wednesday");
                break;
            case 4:
                System.out.println("Thursday");
                break;
            case 5:
                System.out.println("Friday");
                break;
            case 6:
                System.out.println("Saturday");
                break;
            case 7:
                System.out.println("Sunday");
                break;}

            // Do-While -> Executes at least once
            // While -> it can be executed 0 times
            int i = 0;
            do {
                System.out.println(i);
                i++;
            }
            while (i < 5);
            /*
             * for (statement 1; statement 2; statement 3) {
             *  // code block to be executed
             *  }
             *  Statement 1 is executed (one time) before the execution of the code block.
             *
             *  Statement 2 defines the condition for executing the code block.
             *
             *  Statement 3 is executed (every time) after the code block has been executed.
             * 
             * There is also a "for-each" loop, which is used exclusively to 
             * loop through elements in an array (or other data sets):
             * for (type variableName : arrayName){
             * }
             */
              
    }    
}
