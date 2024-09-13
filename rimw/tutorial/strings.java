public class strings {
    public static void main(String[] args){
        String txt = "abcdeFGHIJKL location MNOPQRSTUVWXYZ";
        System.out.println("The length of the txt string is: " + txt.length());
        System.out.println(txt.toUpperCase());   
        System.out.println(txt.toLowerCase());   
        System.out.println(txt.indexOf("location")); // Index starts at 0
        // Concats
        String firstName = "John ";
        String lastName = "Doe";
        System.out.println(firstName.concat(lastName));
        // Avoids problems with quotes in strings
        String inside = "We are the so-called \"Vikings\" from the north.";
        String apos = "It\'s alright.";
        String double_bar = "The character \\ is called backslash.";
        System.out.println(inside);
        System.out.println(apos);
        System.out.println(double_bar);
    
    }
}
