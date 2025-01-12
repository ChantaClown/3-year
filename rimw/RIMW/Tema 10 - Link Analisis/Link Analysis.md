#RIMW 
### Estructura Intra-documento

Los documentos web tienen múltiples componentes que contribuyen de manera diferente a su relevancia:

1. **Título**: Resumen conciso del documento
2. **Cuerpo**: Contenido principal
3. **Texto ancla**: Referencias a otros documentos
4. **Párrafos**: Subdivisiones del contenido
5. **Imágenes**: Descripción visual del documento

Para incorporar esta estructura en el modelo de recuperación, podemos asignar diferentes pesos a distintas partes del documento. En el contexto del modelo query-likelihood:

$$
p(Q|D,R) = \prod^n_{i=1}\sum^k_{j=1} s(D_j|D,R)p(w_i|D_j,R)
$$

Donde:
- $s(D_j|D,R)$ actúa como peso para la sección $D_j$
- Este peso puede estimarse mediante EM o establecerse manualmente

### Estructura Inter-documento

Los documentos no son independientes entre sí, están conectados mediante enlaces que forman una estructura de red. Esta estructura es fundamental para:
- Determinar la utilidad de los documentos
- Mejorar el ranking de resultados
- Guiar el crawling focalizado

## PageRank: Modelo de Navegación Aleatoria

PageRank modela el comportamiento de un usuario navegando aleatoriamente por la web:

![[pagerank.png]]

### Proceso de Navegación
1. Inicio en una página aleatoria
2. Seguimiento aleatorio de enlaces salientes
3. Salto aleatorio cuando no hay enlaces salientes
4. Repetición indefinida del proceso

### Fundamento Matemático: Cadenas de Markov

![[cadenas_markov.png]]

Las cadenas de Markov son procesos estocásticos con la propiedad de Markov:

$$
P(X_{n+1}|X_1,\dots,X_n) = P(X_{n+1}|X_n)
$$

### Matriz de Transición
- Es una matriz estocástica donde:
$$
\forall i \sum M_{ij} = 1
$$

![[transition_matrix.png]]

#### Construcción de la Matriz de Transición

1. Reemplazo de filas sin unos: $\frac{1}{N}$
2. Normalización por fila, dividir cada 1 en _A_ por el numero de 1's en la fila
3. Multiplicación por $1-\alpha$
4. Adición de $\frac{\alpha}{N}$ a cada elemento

### Distribución del PageRank

Para cadenas de Markov no periódicas e irreducibles, existe una única distribución estacionaria $\pi$:

$$
\lim_{t\rightarrow \inf} \frac{c(i,t)}{t}= \pi_i
$$

Donde $c(i,t)$ representa el número de visitas al estado $i$ después de $t$ pasos.

![[pagerank_computation.png]]

## Algoritmo HITS (Hyperlink-Induced Topic Search)

HITS identifica dos tipos de páginas web para una consulta general:

1. **Authorities**: Fuentes de información reconocidas
2. **Hubs**: Listas de enlaces hacia páginas autoritativas

### Cálculo de Puntuaciones
Se calculan dos puntuaciones para cada página:

1. **Authority score**:
$$
a(d) \leftarrow \sum_{v \to d} h(v)
$$

2. **Hub score**:
$$
h(d) \leftarrow \sum_{d \to v} a(v)
$$

### Construcción de la Matriz de Adyacencia

1. Recuperación de documentos que contienen la consulta
2. Expansión del conjunto:
   - Añadir páginas con enlaces hacia el conjunto
   - Añadir páginas referenciadas por el conjunto
3. Generación de la matriz de adyacencia

## Comparación de Algoritmos

### PageRank
- **Ventajas**:
  - Independiente de la consulta
  - Computación offline
- **Desventajas**:
  - No considera el contenido
  - Vulnerable a spam de enlaces

### HITS
- **Ventajas**:
  - Considera el contexto de la consulta
  - Distingue entre diferentes roles de páginas
- **Desventajas**:
  - Computación en tiempo real
  - Sensible a la calidad del conjunto inicial