#RIMW 
## Introducción

El análisis básico de texto es fundamental para comprender y procesar información textual en sistemas como motores de búsqueda. Implica pasos clave como la tokenización, indexación y representación de documentos para que sean accesibles a máquinas.

---
## Crawler: Explorador Web

Un **crawler** es un programa automatizado que navega por la web con el propósito de indexar contenido. Su funcionamiento incluye:

- **Inicio:** Partiendo de una URL raíz, el crawler descarga páginas y extrae otras URLs llamadas "semillas".
- **Organización:** Clasifica los enlaces en dos grupos: los ya visitados y los pendientes.
- **Estrategias de visita:**
  - **Breadth-First Search:** Explora uniformemente desde la página inicial.
  - **Depth-First Search:** Se enfoca en ramas específicas.
  - **Focused Crawling:** Prioriza páginas según estrategias predefinidas, como relevancia temática o PageRank.

### Código Pseudocódigo Básico
```python
Def Crawler(entry_point):
    URL_list = [entry_point]
    while URL_list:
        URL = URL_list.pop()
        if isVisited(URL) or !isLegal(URL):
            continue
        HTML = URL.open()
        for anchor in HTML.listOfAnchors():
            URL_list.append(anchor)
        setVisited(URL)
        insertToIndex(HTML)
```

---

## Análisis de Páginas Web

El análisis de páginas web implica extraer contenido informativo y representarlo de manera procesable para máquinas. Técnicas comunes incluyen:

- **Parsing de HTML:**
  - Eliminar etiquetas HTML.
  - Extraer texto relevante entre `<title>` y `<p>`.
  - Uso de herramientas como Beautiful Soup (Python) o Jsoup (Java).

- **Tokenización:**
  - Dividir texto en unidades significativas (**tokens**): palabras, frases o símbolos.
  - Soluciones comunes:
    - Expresiones regulares.
    - Métodos estadísticos para decidir límites de palabras.

### Ejemplo de Tokenización
**Entrada:** `It’s not straight-forward to tokenize.`

**Salida (1):** `'It’s', 'not', 'straight-forward', 'to', 'tokenize'`

**Salida (2):** `'It', '’', 's', 'not', 'straight', '-', 'forward', 'to', 'tokenize'`

---

## Representación de Documentos

Los documentos se representan mediante estructuras que preservan la información textual. Ejemplos:

- **Bag-of-Words (BoW):**
  - Esta representación transforma un documento en un conjunto de palabras (o tokens), ignorando el orden y la estructura gramatical. Cada documento se representa como un vector de frecuencias donde cada posición corresponde a una palabra en el vocabulario.
  - Por ejemplo, los documentos `"blue houses are nice"` y `"blue blueberries taste nice"` se representarían como:

| Termino     | Documento 1 | Documento 2 |
| ----------- | ----------- | ----------- |
| blue        | 1           | 1           |
| house       | 1           | 0           |
| are         | 1           | 0           |
| nice        | 1           | 1           |
| blueberries | 0           | 1           |
| taste       | 0           | 1           |

  - **Ventajas:**
    - Simple y eficiente.
    - Permite a los algoritmos de aprendizaje automático trabajar directamente con los datos textuales.
  - **Desventajas:**
    - Ignora el orden de las palabras, lo que puede ser crucial en algunos contextos.
    - No capta relaciones semánticas entre palabras.

  - **Ejemplo práctico:**
    - Un motor de búsqueda podría utilizar BoW para indexar documentos y calcular similitudes basadas en las frecuencias de palabras compartidas.

---

## Normalización y Stemming

- **Normalización:** Convierte distintas formas de una palabra a una forma estándar.
  - Ejemplo: `U.S.A` -> `USA`.

- **Stemming:** Reduce palabras a su raíz, eliminando sufijos y prefijos.
  - Ejemplo: `running` -> `run`.

### Herramientas
- **Porter Stemmer:** Basado en patrones de vocales y consonantes.
- **Krovetz Stemmer:** Utiliza reglas morfológicas.

---

## Stopwords

Las **stopwords** son palabras no informativas que se eliminan para reducir el tamaño del vocabulario.

### Ejemplo
- Original: `This is not a good option.`
- Sin Stopwords: `good option`

**Nota:** Existe riesgo de pérdida de significado. Ejemplo: `to be or not to be` -> `null` (vacío).

---

## Zipf’s Law

La Ley de Zipf es una observación empírica que describe la distribución de frecuencia de palabras en un lenguaje natural. Establece que:

- La frecuencia de una palabra es inversamente proporcional a su rango en una lista ordenada de palabras por frecuencia.

### Fórmula:
$$\text{f}(k, s, N) = \frac{1/k^s}{\sum_{n=1}^{N} (1/n^s)}$$
Donde:
- \(k\): Rango de la palabra.
- \(s\): Parámetro del idioma.
- \(N\): Número total de palabras únicas.

### Ejemplo Práctico:
En el corpus de Brown de inglés americano:
- La palabra "the" es la más común, representando casi el 7% de todas las ocurrencias.
- La segunda palabra, "of", representa aproximadamente un 3.5%.

### Implicaciones de la Ley de Zipf:
- **Palabras frecuentes:** (e.g., "the", "a") tienen poca relevancia semántica y se suelen filtrar como stopwords.
- **Palabras raras:** Contienen información específica, pero son difíciles de modelar debido a su baja frecuencia.
- **Palabras intermedias:** Representan mejor el contenido y suelen ser clave en tareas de procesamiento de lenguaje natural.

### Aplicación:
- En motores de búsqueda, las palabras más comunes pueden eliminarse para mejorar la eficiencia.
- En análisis de texto, la ley ayuda a diseñar vocabularios controlados que capturan palabras significativas.

---

## Técnicas Avanzadas

- **N-grams:** Capturan dependencias locales y orden.
  - Ejemplo: `information retrieval` -> `information_retrieval` (2-gram).
  - **Ventajas:**
    - Captura relaciones locales entre palabras adyacentes.
  - **Desventajas:**
    - El tamaño del vocabulario crece exponencialmente con \(n\).

- **Parsing de Dependencias:** Identifica relaciones gramaticales entre palabras para comprender mejor su función en una oración.

---

## Resumen

1. Los **crawlers** recopilan y organizan datos web.
2. El análisis de texto incluye parsing, tokenización y eliminación de stopwords.
3. La representación de documentos (BoW, N-grams) permite a las máquinas trabajar con texto.
4. Conceptos como stemming y Zipf’s Law optimizan la recuperación y análisis de información textual.
