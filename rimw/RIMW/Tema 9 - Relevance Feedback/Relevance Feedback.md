#RIMW 
## Introducción

El Relevance Feedback (RF) es una técnica que permite refinar iterativamente los resultados de búsqueda basándose en la retroalimentación del usuario sobre la relevancia de los documentos recuperados.

## Mejorando el Recall en Búsqueda

El recall es una medida crucial en RI que indica la proporción de documentos relevantes que el sistema es capaz de recuperar. Existen dos aproximaciones principales para mejorar el recall:

### 1. Análisis Local
- **Relevance Feedback**: Análisis bajo demanda para una consulta específica del usuario
- Se basa en la interacción directa con el usuario
- Adapta los resultados según las necesidades específicas de cada búsqueda

### 2. Análisis Global
- Utiliza un análisis previo de toda la colección
- Genera recursos como tesauros para expansión de consultas
- No depende de la interacción del usuario en tiempo real

## Relevance Feedback en el Modelo de Espacio Vectorial (VSM)

### El Concepto de Centroide

En el contexto del VSM, el centroide representa el centro de masa de un conjunto de documentos en el espacio vectorial. Matemáticamente se define como:

$$\bar{\mu}(D) = \frac{1}{|D|} \sum_{d \in D} \bar{v}(d)$$

Donde:
- $D$ es el conjunto de documentos
- $|D|$ es el número total de documentos
- $\bar{v}(d)$ es el vector que representa al documento d

### Algoritmo de Rocchio

El algoritmo de Rocchio es una implementación práctica del RF en el VSM. Su objetivo es encontrar un vector de consulta óptimo que maximice la diferencia entre documentos relevantes y no relevantes:

$$\vec{q}_{opt} = \arg \max_{\vec{q}} \left[ \text{sim}(\vec{q}, \mu(D_r)) - \text{sim}(\vec{q}, \mu(D_{nr})) \right]$$

En la práctica, se utiliza la fórmula modificada de Rocchio:

$$\vec{q}_m = \alpha\vec{q}_0 + \beta\frac{1}{|D_r|}\sum_{d_j \in D_r}\vec{d}_j - \gamma\frac{1}{|D_{nr}|}\sum_{d_j \in D_{nr}}\vec{d}_j$$

Donde:
- $\vec{q}_m$ es el vector de consulta modificado
- $\vec{q}_0$ es el vector de consulta original
- $\alpha$, $\beta$, y $\gamma$ son parámetros de peso
- $D_r$ y $D_{nr}$ son los conjuntos de documentos relevantes y no relevantes

#### Visualización del Algoritmo de Rocchio

![[roochio.png]]
![[roochio2.png]]
## Pseudo Relevance Feedback (PRF)

El PRF es una variante automatizada del RF que elimina la necesidad de intervención del usuario. El proceso consiste en:

1. Realizar una búsqueda inicial con la consulta del usuario
2. Asumir que los primeros k documentos son relevantes
3. Aplicar RF (típicamente Rocchio) usando estos documentos
4. Generar una nueva consulta expandida

Ventajas:
- No requiere interacción del usuario
- Mejora significativamente los resultados en promedio

Desventajas:
- Puede producir deriva de la consulta (query drift)
- El rendimiento puede variar significativamente según la consulta

## Relevance Feedback en Modelos de Lenguaje (LM)

Los modelos de lenguaje abordan el RF desde una perspectiva probabilística. El concepto clave es el Modelo de Relevancia (RM), que representa la distribución de probabilidad sobre términos que caracteriza la necesidad de información.

### Visualización del Modelo

![[RFLM.png]]

### Estimación del Modelo de Relevancia

La probabilidad de un término w dado el modelo de relevancia R se estima como:

$$P(w|R) \approx \frac{P(w,q_1\dots q_n)}{P(q_1 \dots q_n)}$$

Donde:
- $q_1\dots q_n$ son los términos de la consulta
- La probabilidad conjunta se calcula como:

$$P(w, q_1 \dots q_n) = \sum_{D \in C} P(D) P(w|D) \prod_{i=1}^n P(q_i|D)$$

### Algoritmo de Pseudo-Feedback

![[pseudo-algoriut.png]]

## Query Expansion

La expansión de consultas es una técnica complementaria al RF que busca mejorar el recall mediante la adición de términos relacionados. Existen dos aproximaciones principales:

### 1. Tesauros Manuales
- Mantenidos por expertos
- Alta precisión pero costosos de mantener
- Útiles en dominios específicos

![[therasus-example.png]]

### 2. Tesauros Automáticos
- Generados mediante análisis estadístico
- Basados en co-ocurrencia de términos
- Más flexibles pero pueden introducir ruido

![[auto-therasus.png]]

### Métodos de Generación Automática

Los tesauros automáticos se generan principalmente mediante:

1. **Co-ocurrencia de términos**:
   - Dos términos son similares si aparecen en contextos similares
   - Más robusto pero menos preciso

2. **Relaciones gramaticales**:
   - Términos similares comparten patrones sintácticos
   - Más preciso pero requiere análisis lingüístico