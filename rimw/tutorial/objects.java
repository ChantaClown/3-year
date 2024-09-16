public class objects {
  int x = 5;

  // Static method
  static void myStaticMethod() {
    System.out.println("Static methods can be called without creating objects");
  }

  // Public method
  public void myPublicMethod() {
    System.out.println("Public methods must be called by creating objects");
  }

  // Main method
  public static void main(String[] args) {
    myStaticMethod(); // Call the static method
    // myPublicMethod(); This would compile an error

    Object myObj = new Object(); // Create an object of Main
    //myObj.myPublicMethod(); // Call the public method on the object

    objects myObj1 = new objects();  // Object 1
    objects myObj2 = new objects();  // Object 2
    System.out.println(myObj1.x);
    System.out.println(myObj2.x);
  }
}

/*
File: Main.java
public class Main {
  public static void main(String[] args) {
      Helper helper = new Helper();
      helper.sayHello();
  }
}

class Helper {
  public void sayHello() {
      System.out.println("Hello from the Helper class!");
  }
}
*/ 

class Main {
  int x;  // Create a class attribute

  // Create a class constructor for the Main class
  public Main() {
    x = 5;  // Set the initial value for the class attribute x
  }

  public static void main(String[] args) {
    Main myObj = new Main(); // Create an object of class Main (This will call the constructor)
    System.out.println(myObj.x); // Print the value of x
  }
}

// Code from filename: Main.java
// abstract class
abstract class College {
  public String fname = "John";
  public int age = 24;
  public abstract void study(); // abstract method
}

// Subclass (inherit from Main)
class Student extends Main {
  public int graduationYear = 2018;
  public void study() { // the body of the abstract method is provided here
    System.out.println("Studying all day long");
  }
}