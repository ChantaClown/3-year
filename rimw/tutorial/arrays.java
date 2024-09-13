public class arrays {
    public static void main(String[] args) {
        String[] cars = {"Volvo", "BMW", "Ford", "Mazda"};
        System.out.println(cars[0]);
        System.out.println(cars[3]);
        System.out.println(cars.length);
        
        int[] numbers = {10,20,30,40};
        System.out.println(numbers[0]);
        System.out.println(numbers[3]);   
        
        for (String i : cars) {
            System.out.println(i);
          }
        System.out.println("\n");
        for (int i = 0; i < cars.length; i++) {
            System.out.println(cars[i]);
        }
        
        // Matrix
        int[][] myNumbers = { {1, 2, 3, 4}, {5, 6, 7} };
        System.out.println(myNumbers[1][2]); // Outputs 7
        // Loop through the matrix
        int[][] myNumbers2 = { {1, 2, 3, 4}, {5, 6, 7} };
        for (int i = 0; i < myNumbers2.length; ++i) {
        for (int j = 0; j < myNumbers2[i].length; ++j) {
            System.out.println(myNumbers2[i][j]);
        }
        }
    }
}
