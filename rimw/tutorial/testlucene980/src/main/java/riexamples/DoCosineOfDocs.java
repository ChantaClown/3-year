package riexamples;

import java.io.IOException;

public class DoCosineOfDocs {

	/**
	 * @param args
	 * 
	 */
	public static void main(String[] args) {

		if (args.length != 1) {
			System.out.println("Usage: java DoCosineOfDocs indexFolder");
			return;
		}
		// indexFolder is the folder where the documents are stored

		String indexFolder = args[0];

		String d1 = "uno uno";
		String d2 = "uno uno dos dos";

		double c = 0;

		// Coseno(45º) = 0.7071

		try {
			c = CosineDocumentSimilarity.getCosineSimilarity(d1, d2, indexFolder);
		} catch (IOException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}

		System.out.println("Coseno de los docs");
		System.out.println("d1 = \"" + d1 + "\"");
		System.out.println("d2 = \"" + d2 + "\"");
		System.out.println("= " + c);
		System.out.println();

	}
}