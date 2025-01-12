#RIMW

El **rankeo por probabilidad** lleva a una **recuperación efectiva** según el PRP. Justificación basada en teoría de decisión:

$$
(1 - \phi(d_i, q))a_1 < \phi(d_i, q)a_2
$$

Donde:
- $(1 - \phi(d_i, q))a_1$: Pérdida esperada al recuperar un documento no relevante.
- $\phi(d_i, q)a_2$: Pérdida esperada de no recuperar un documento relevante.

**Rankear los documentos en orden descendente de $\phi(d_i, q)$ minimiza la pérdida.**
### Suposiciones Necesarias:
- Relevancia independiente entre documentos.
- Pérdidas independientes.
- Búsqueda secuencial.
## Modelos Condicionales para $P(R=1|Q,D)$

La relevancia depende de cómo una query $Q$ se relaciona con un documento $D$. Representamos esta relación como $rep(Q, D)$:

$$
P(R=1|Q,D) = g(rep(Q, D), \theta)
$$

Donde:
- $rep(Q, D)$: Características del par query-documento (ej., número de términos coincidentes, longitud del documento).
- $\theta$: Parámetros aprendidos a partir de datos de entrenamiento.

Este enfoque es similar a la **regresión logística**, donde usamos datos de relevancia conocidos para estimar $\theta$. Una vez entrenado, el modelo se aplica para rankear nuevos documentos.

![[ranking_regresion.png]]
![[ranking_features.png]]

## Modelos Generativos para $P(R=1|Q,D)$

En este enfoque, usamos la ley de Bayes para computar las probabilidades:

$$
Odd(R=1|Q,D) = \frac{P(R=1|Q,D)}{P(R=0|Q,D)}
$$

### Variantes:
- **Generación de documentos**:
  $$
  P(Q,D|R) = P(D|Q,R)P(Q|R)
  $$
- **Generación de queries**:
  $$
  P(Q,D|R) = P(Q|D,R)P(D|R)
  $$

![[generacion.png]]

## Modelo de Robertson-Sparck Jones (RSJ)

Desarrollado en 1976, es uno de los modelos probabilísticos clásicos. Define dos parámetros para cada término $A_i$:
- $p_i = P(A_i=1|Q,R=1)$: Probabilidad de que el término $A_i$ ocurra en un documento relevante.
- $u_i = P(A_i=1|Q,R=0)$: Probabilidad de que el término $A_i$ ocurra en un documento no relevante.

El modelo usa estas probabilidades para calcular pesos y rankear documentos. En ausencia de juicios de relevancia, los parámetros se estiman de manera aproximada.

![[RSJ.png]]

## Estimación de Parámetros

### Comparativa: Maximum Likelihood vs. Bayesian

- **Maximum Likelihood (ML)**:
  - "Mejor" significa que la probabilidad de los datos observados es máxima.
  - Ventaja: Enfoque directo.
  - Problema: Puede ser inexacto con muestras pequeñas.

- **Bayesian**:
  - "Mejor" significa consistente con el conocimiento previo y que explica bien los datos.
  - Ventaja: Integra información previa.
  - Problema: Requiere definir priors.

![[no_relevancia.png]]

## Modelo BM25

BM25 (Robertson et al., 1994) es una aproximación al modelo de mezcla de 2-Poisson. Es ampliamente usado debido a su simplicidad y efectividad. Características clave:

1. **Componente TF-IDF**: Los pesos de los términos aumentan de manera monótona con el TF, pero tienen un límite asintótico.
2. **Normalización por longitud del documento**: Penaliza documentos largos para evitar sesgos.
3. **Incorporación de TF en la query**: Introduce simetría entre documentos y queries.


![[bm25.png]]
![[bm25-2.png]]
### Fórmula de BM25:

![[bm25-formula.png]]
