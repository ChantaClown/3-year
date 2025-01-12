 Precision@K
- Define un umbral en la posición $K$, ignorando todos los documentos que sean menores que $K$.
- Calcula la precisión considerando solo los $K$ documentos mejor rankeados. 
- Fórmula:
  $$
  P@K = \frac{\text{Número de documentos relevantes en los primeros } K}{K}
  $$
- Ejemplo:
  - Si de los primeros 5 documentos, 3 son relevantes: $P@5 = \frac{3}{5} = 0.6$.

- Funciona de manera similar para Recall@K:
  $$
  R@K = \frac{\text{Número de documentos relevantes recuperados hasta } K}{\text{Número total de documentos relevantes}}
  $$

![[3-year/RIMW/png/precision.png]]

# Mean Average Precision (MAP)
- Considera la posición del ranking de **cada documento relevante**. 
- El **Average Precision (AP)** para una consulta es la media de las precisiones calculadas en cada posición donde aparece un documento relevante:
  $$
  AP = \frac{\sum_{k=1}^{n} (P@k \cdot \text{rel}_k)}{\text{Número total de documentos relevantes}}
  $$
  donde $\text{rel}_k$ es 1 si el documento en la posición $k$ es relevante, de lo contrario es 0.

- El **MAP** es la media de los valores de AP para múltiples consultas:
  $$
  MAP = \frac{\sum_{q=1}^{Q} AP(q)}{Q}
  $$

### Consideraciones:
1. Si un documento relevante no es recuperado, la precisión correspondiente se asume como 0.
2. MAP da igual peso a cada consulta.

![[MAP.png]]
![[MAP2.png]]
![[MAP3.png]]

# Mean Reciprocal Rank (MRR)
- Evalúa la efectividad de los resultados rankeados, considerando que el usuario busca **un único documento relevante**.
- Para cada consulta, el **reciprocal rank** es:
  $$
  RR = \frac{1}{k}
  $$
  donde $k$ es la posición del primer documento relevante.

- El MRR es el promedio de los valores de reciprocal rank para múltiples consultas:
  $$
  MRR = \frac{\sum_{q=1}^{Q} RR(q)}{Q}
  $$

### Interpretación:
- Indica el esfuerzo del usuario para encontrar el primer resultado relevante.
- Ejemplo: si el primer documento relevante está en la posición 3, $RR = \frac{1}{3}$.

# Discounted Cumulative Gain (DCG)
- Utiliza relevancia graduada ($rel_i$) para medir la ganancia acumulada considerando el ranking.
- Los documentos en posiciones más altas contribuyen más al valor total gracias a un **descuento**:
  $$
  DCG_p = rel_1 + \sum_{i=2}^p \frac{rel_i}{\log_2(i)}
  $$

### Normalized Discounted Cumulative Gain (nDCG)
- Normaliza el DCG al dividirlo por el valor máximo posible (IDCG), calculado con el ranking ideal:
  $$
  nDCG_p = \frac{DCG_p}{IDCG_p}
  $$

![[NDCG2.png]]
![[NDCG.png]]

# Test Estadísticos
- **P-Valor**: Probabilidad de obtener resultados tan extremos como los observados si la hipótesis nula fuese verdadera.
  - Si $p < \alpha$, se rechaza la hipótesis nula.
- Pruebas comunes:
  - **Sign Test**: Compara la mediana de dos distribuciones.
  - **Wilcoxon Signed Rank Test**: Evalúa si datos emparejados provienen de la misma población.
  - **Paired t-Test**: Compara la diferencia media entre dos respuestas emparejadas.

![[p-valores.png]]

# Índice Kappa
- Mide el acuerdo entre jueces:
  $$
  k = \frac{P(A) - P(E)}{1 - P(E)}
  $$
  - $P(A)$: Proporción de acuerdos observados.
  - $P(E)$: Proporción de acuerdos esperados por azar.

### Interpretación:
- $k = 1$: Acuerdo total.
- $k = 0$: Acuerdo por azar.
- $k < 0$: Menos acuerdo que el azar.

![[3-year/RIMW/png/kappa.png]]

# Pooling
- Técnica para reducir costos en anotación.
- Evalúa relevancia solo en los documentos top-$k$ recuperados por múltiples sistemas IR.
- Consideraciones:
  - No garantiza exhaustividad, pero las comparaciones relativas suelen ser estables.
