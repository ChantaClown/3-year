import java.io.BufferedWriter;
import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.util.Random;

public class random_txt {

    // Método para generar un archivo de texto con contenido aleatorio
    public static void generateRandomTxtFile(String directoryPath, String fileName, int lines, int lineLength) throws IOException {
        File file = new File(directoryPath, fileName);

        // Crear el archivo si no existe
        if (!file.exists()) {
            file.createNewFile();
        }

        try (BufferedWriter writer = new BufferedWriter(new FileWriter(file))) {
            Random random = new Random();
            
            // Generar el contenido aleatorio
            for (int i = 0; i < lines; i++) {
                StringBuilder sb = new StringBuilder(lineLength);
                for (int j = 0; j < lineLength; j++) {
                    // Genera un carácter aleatorio entre 'a' y 'z'
                    char randomChar = (char) ('a' + random.nextInt(26));
                    sb.append(randomChar);
                }
                writer.write(sb.toString());
                writer.newLine();
            }
        }
    }

    // Método principal para generar múltiples archivos
    public static void main(String[] args) {
        String directoryPath = "./random_texts"; // Directorio donde se generarán los archivos
        int numberOfFiles = 10; // Número de archivos a generar
        int linesPerFile = 100; // Número de líneas por archivo
        int lineLength = 80; // Longitud de cada línea

        // Crear el directorio si no existe
        File directory = new File(directoryPath);
        if (!directory.exists()) {
            directory.mkdir();
        }

        // Generar los archivos
        for (int i = 1; i <= numberOfFiles; i++) {
            String fileName = "file" + i + ".txt"; // Nombre del archivo
            try {
                generateRandomTxtFile(directoryPath, fileName, linesPerFile, lineLength);
                System.out.println("Generado: " + fileName);
            } catch (IOException e) {
                System.err.println("Error al generar el archivo " + fileName + ": " + e.getMessage());
            }
        }
    }
}
