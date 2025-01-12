#RIMW 

## Introducción

El procesamiento de consultas e indexación son pilares fundamentales en sistemas de recuperación de información. Estos procesos convierten documentos textuales en estructuras eficientes para búsquedas rápidas, optimizando espacio y tiempo mediante técnicas avanzadas como índices invertidos y compresión de datos.

---

## Espacio y Tiempo en Indexación

Cuando representamos documentos como Bag-of-Words (BoW):

- **Complejidad de espacio:** $O(D \times V)$, donde:
  - $D$: número total de documentos.
  - $V$: tamaño del vocabulario.

  **Problema:** La Ley de Zipf nos dice que solo el 10% del vocabulario aparece en cada documento, desperdiciando un 90% del espacio.

- **Solución:** Usar una **lista enlazada** para almacenar solo las palabras observadas por documento.

---

## Índices Invertidos

Un **índice invertido** mejora la eficiencia del procesamiento de consultas al construir una tabla de consulta que mapea palabras a los documentos donde aparecen.

### Ejemplo:
- Palabras: `information`, `retrieval`
- Documentos:

| Término     | Documentos |
| ----------- | ---------- |
| information | Doc1, Doc2 |
| retrieval   | Doc1, Doc2 |
### Complejidad:
- **Tiempo:** $O(|q| \times |L|)$, donde:
  - $|q|$: número de términos en la consulta.
  - $|L|$: longitud promedio de la lista de publicaciones.

**Nota:** Por la Ley de Zipf, $|L| \ll D$.

### Componentes:
1. **Diccionario:**
   - Tamaño modesto.
   - Acceso rápido (Hash table, B-tree, Trie).
2. **Publicaciones:**
   - Tamaño grande (almacenado en disco).
   - Contiene `docID`, frecuencia y posición de término.
   - Necesita compresión.

---

## Construcción de Índices Invertidos

### Método basado en Ordenamiento
1. Parsear y contar:
   - Generar tuplas $<termID, docID, count>$.
2. Ordenar localmente por $termID$.
3. Realizar un ordenamiento global:
   - Preservar el orden por $docID$.

### Desafíos y Soluciones
- **Documentos grandes:**
  - Dividir en partes manejables.
  - Usar algoritmos distribuidos como MapReduce.

---

## Compresión de Índices

### Beneficios:
1. Ahorrar espacio en disco.
2. Incrementar la eficiencia del caché.
3. Mejorar la velocidad de transferencia disco-memoria.

### Observaciones:
- En vez de almacenar `docID` completos, almacenar las diferencias (`d-gaps`).
  - **Ejemplo:** Documentos $1, 5, 9$ → Gaps $1, 4, 4$.

### Métodos de Codificación:
1. **Elias-γ Code:**
   - Mezcla codificación unaria y binaria.
   - Ejemplo: $k = 1023$ → 19 bits (en lugar de 1024 con unaria).

2. **Delta Encoding:**
   - Codifica diferencias entre números consecutivos.
   - Mejora la compresión de palabras frecuentes.

3. **V-Byte Encoding:**
   - Alineado a bytes, como UTF-8.
   - Compatible con procesadores modernos.

---

## Procesamiento de Consultas

El procesamiento de consultas implica transformar y analizar las consultas del usuario para obtener resultados relevantes.

### Pasos:
1. Parsear la sintaxis:
   - Operadores: AND, OR, NOT.
2. Procesar términos:
   - Tokenización, normalización, stemming, eliminación de stopwords.
3. Recuperar listas de publicaciones:
   - Operar: intersección (AND), unión (OR), diferencia (NOT).

### Estrategias:
1. **Documento por Documento:**
   - Calcula puntajes completos por documento.
2. **Término por Término:**
   - Acumula puntajes procesando listas de términos una por una.

### Optimización:
- **Umbrales:**
  - Ignorar documentos con puntajes inferiores al top-\(k\).
- **MaxScore:**
  - Usa puntajes máximos estimados para saltar términos irrelevantes.

---

## Consultas Avanzadas

### Consultas de Frases:
- Ejemplo: `"computer science"`
- Necesitan coincidencias exactas de términos y posiciones.

### Corrección Ortográfica:
- Soluciones:
  - **Distancia de edición:** Mínimo número de operaciones para transformar una palabra en otra.
  - **Hashing fonético:** Términos con sonidos similares comparten valores hash (e.g., Soundex).

---

## Resumen

1. La indexación eficiente se logra mediante índices invertidos con compresión.
2. El procesamiento de consultas requiere estrategias avanzadas para optimizar tiempo y espacio.
3. Consultas avanzadas como frases o con errores ortográficos necesitan técnicas adicionales para mejorar la precisión.
