#RIMW 
## Introducción

Los modelos de recuperación de información son fundamentales para transformar las consultas de los usuarios en resultados ordenados por relevancia. Incluyen desde búsquedas Booleanas simples hasta modelos avanzados basados en espacios vectoriales y pesos.

---

## Modelo Booleano

El modelo booleano utiliza operadores lógicos para realizar búsquedas exactas basadas en combinaciones de términos.

### Ejemplo de consulta:
- `"obama" AND "healthcare" NOT "news"`

### Procedimiento:
1. Buscar cada término en el diccionario.
2. Recuperar las listas de publicaciones asociadas.
3. Realizar operaciones lógicas:
   - **AND:** Intersección de listas.
   - **OR:** Unión de listas.
   - **NOT:** Diferencia de listas.

#### Limitaciones:
- Consultas sobreconstriñidas pueden no devolver resultados relevantes.
- Consultas subconstriñidas pueden devolver demasiados resultados.
- No considera grados de relevancia entre documentos.

---

## Filtrado de Documentos vs. Ranking

### Filtrado:
- Clasifica documentos como relevantes o no relevantes.
- No establece prioridades entre los documentos relevantes.

### Ranking:
- Ordena documentos por grados de relevancia.
- Ventajas:
  - Permite a los usuarios detener la revisión en cualquier punto.
  - Equilibra precisión y cobertura.

---

## Procedimiento de Recuperación Moderno

1. **Identificación de candidatos:**
   - Usar un modelo booleano para encontrar documentos que cumplan las condiciones básicas.
2. **Ranking por relevancia:**
   - Ordenar los documentos candidatos usando un modelo de relevancia más avanzado.

### Principio de Ranking Probabilístico:
La probabilidad de relevancia de un documento depende de su similitud con la consulta.

---

## Modelo de Espacio Vectorial (VSM)

El modelo de espacio vectorial (VSM) representa tanto las consultas como los documentos como vectores en un espacio multidimensional. Este enfoque facilita la comparación y cálculo de similitudes entre ambos.

### Representación de Vectores

1. **Conceptos básicos:**
   - Cada dimensión en el espacio vectorial corresponde a un término o concepto único del vocabulario.
   - Un vector está compuesto por los pesos asignados a cada término.

2. **Pesos en los vectores:**
   - Indican la importancia del término en el documento o consulta.
   - Se calculan usando métricas como **TF-IDF**.

3. **Ejemplo práctico:**
   - Vocabulario: $\{\text{data}, \text{mining}, \text{machine}\}$.
   - Documento $d_1$: "data mining techniques for machine learning".
     - Vector: $[1, 1, 1]$.
   - Consulta $q$: "data machine".
     - Vector: $[1, 0, 1]$.

### Similitud entre Vectores

La similitud entre vectores se utiliza para medir la relevancia entre un documento y una consulta. En el VSM, se emplean métricas como:

1. **Distancia Euclidiana:**
   - Mide la distancia geométrica entre dos vectores.
   - Fórmula:
     $$
     \text{dist}(\vec{d}, \vec{q}) = \sqrt{\sum_{i=1}^{n} (d_i - q_i)^2}
     $$
   - Problema: Penaliza documentos más largos debido a términos adicionales.

2. **Similitud Coseno:**
   - Mide el ángulo entre dos vectores.
   - Ventaja: Normaliza la longitud de los documentos.
   - Fórmula:
     $$
     \text{sim}(\vec{d}, \vec{q}) = \frac{\vec{d} \cdot \vec{q}}{||\vec{d}|| \times ||\vec{q}||} = \frac{\sum_{i=1}^{n} d_i q_i}{\sqrt{\sum_{i=1}^{n} d_i^2} \times \sqrt{\sum_{i=1}^{n} q_i^2}}
     $$

#### Ejemplo Detallado:
- Vocabulario: $\{\text{data}, \text{mining}, \text{machine}\}$.
- Documento $d_1$: $[1, 1, 1]$.
- Consulta $q$: $[1, 0, 1]$.

1. Producto punto:
   $$
   \vec{d} \cdot \vec{q} = (1 \times 1) + (1 \times 0) + (1 \times 1) = 2
   $$

2. Magnitud de los vectores:
   $$
   ||\vec{d}|| = \sqrt{1^2 + 1^2 + 1^2} = \sqrt{3}, \quad ||\vec{q}|| = \sqrt{1^2 + 0^2 + 1^2} = \sqrt{2}
   $$

3. Similitud coseno:
   $$
   \text{sim}(\vec{d}, \vec{q}) = \frac{2}{\sqrt{3} \times \sqrt{2}} \approx 0.816
   $$

El resultado $$0.816$$ indica una alta similitud entre el documento y la consulta.

### Consideraciones Adicionales:
- **Ventajas del coseno:**
  - Invariante a la longitud de los documentos.
  - Se enfoca en términos compartidos.
- **Implementación práctica:**
  - Las métricas de similitud se calculan al recuperar listas de publicaciones desde índices invertidos.

---

## Pesos en el VSM

### TF (Frecuencia de Término):
- Mide cuántas veces aparece un término en un documento.
- **TF bruto:** $$ tf(t, d) = f(t, d) $$.
- **Normalización de TF:** Penaliza documentos largos para evitar sesgos.

### IDF (Frecuencia Inversa de Documentos):
- Mide cuán discriminativo es un término.
- Fórmula:
$$
idf(t) = \log \frac{N}{df(t)}
$$
  - $N \rightarrow$ Número total de documentos.
 - $df(t)$: Número de documentos que contienen el término $t$.
### TF-IDF:
- Combina TF e IDF para equilibrar la frecuencia en el documento con su rareza en la colección.
- Muy utilizado en recuperación de información.

---

## Ventajas del VSM

1. Intuitivo y fácil de implementar.
2. Empíricamente efectivo (buen rendimiento en evaluaciones TREC).
3. Bien estudiado y con muchas variantes disponibles.

### Limitaciones:
1. Supone independencia de términos (Bag-of-Words).
2. Requiere ajustes de parámetros.
3. Mide relevancia basada en términos individuales, sin considerar contexto global.

---
## Resumen

1. Los modelos booleanos son simples pero carecen de flexibilidad y precisión.
2. El modelo de espacio vectorial permite capturar grados de relevancia.
3. Pesos como TF-IDF mejoran significativamente la representación de documentos.
4. La similitud coseno es una métrica clave para medir relevancia en el VSM.
