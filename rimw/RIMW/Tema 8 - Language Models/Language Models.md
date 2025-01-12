#RIMW

Un **modelo de lenguaje probabilístico** especifica la distribución de probabilidad de palabras en secuencias y proporciona una cuantificación de las incertidumbres del lenguaje natural. La probabilidad de una secuencia de palabras se calcula como:

$$
p(W_1, W_2, \dots W_n) = p(w_1)p(w_2|w_1) \dots p(w_n|w_1, w_2 \dots w_{n-1})
$$

### Complejidad:
La complejidad de este cálculo es:

$$
O(V^n)
$$

donde $V$ es el tamaño del vocabulario y $n$ es el tamaño máximo de los documentos.

### Suposición de Independencia:
Si consideramos que las palabras son independientes:

$$
p(W_1, W_2, \dots W_n) = p(w_1)p(w_2) \dots p(w_n)
$$

## Otros Modelos de Lenguaje

### N-Gram
El modelo **N-Gram** utiliza solamente las últimas $n-1$ palabras para calcular la probabilidad:

$$
p(W_1, W_2, \dots W_n) = p(w_1)p(w_2|w_1)p(w_3|w_2) \dots p(w_n|w_{n-1})
$$

### Remote-Dependence LM
Explora dependencias remotas entre palabras para mejorar las predicciones.

### Structured LM
Modela estructuras gramaticales o contextos específicos en el lenguaje.

## Modelos de Lenguaje para Recuperación de Información (IR)

![[likelihood_lm.png]]

En IR, hacemos ranking de documentos basado en la probabilidad de generar una query dada (query likelihood):

$$
\log p(Q|D) = \sum_i \log p(Q_i|D)
$$

Donde $p(Q_i|D)$ es el **Document LM**. Sin embargo, el uso de estimación de máxima verosimilitud (**MLE**) presenta problemas porque cualquier palabra no vista en la colección tendrá probabilidad 0.

### Smoothing
Para solucionar este problema, utilizamos **smoothing**. Todos los métodos de smoothing intentan:

1. Reducir la probabilidad de las palabras vistas en un documento.
2. Redistribuir las cuentas extra para asignar probabilidades no nulas a palabras no vistas.

![[smoothing.png]]

## Métodos de Smoothing

### Additive Smoothing
Se añade una constante $\delta$ a cada palabra:

$$
p(w|d) = \frac{c(w,d) + 1}{|d| + |V|}
$$

Donde:
- $+ 1$: Laplace smoothing.
- $|d|$: Longitud del documento.
- $|V|$: Tamaño del vocabulario.

### Absolute Discounting
Se resta una constante $\delta$ a cada palabra:

$$
p(w|d) = \frac{\max(c(w,d) - \delta, 0) + \delta|d|_up(w|REF)}{|d|}
$$

### Jelinek-Mercer Smoothing
Mezcla uniforme con un modelo de referencia $p(w|REF)$:

$$
p(w|d) = (1 - \lambda)\frac{c(w,d)}{|d|} + \lambda p(\frac{C}{|C|})
$$

Donde:
- C, es el alfabeto actual
- $\lambda$: Factor de interpolación.
- $\frac{c(w,d)}{|d|}$: Estimación de máxima verosimilitud (MLE).

### Dirichlet Smoothing
Este método utiliza un enfoque bayesiano con un prior de Dirichlet:

$$
p(w|d) = \frac{c(w,d) + \mu \frac{c(w,C)}{|C|}}{|d| + \mu}
$$

Donde:
- $c(w,C)$: Cuenta de la palabra $w$ en la colección.
- $|C|$: Tamaño total de la colección.
- $\mu$: Parámetro de suavizado.

Este enfoque ajusta las probabilidades basado tanto en el documento como en la colección completa.
