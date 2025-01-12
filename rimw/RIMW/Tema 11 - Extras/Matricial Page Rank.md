#RIMW 
## Introducción al Ejemplo Base
Consideramos un sistema con 4 páginas web (a, b, c, d) conectadas entre sí. La estructura de enlaces es:
- Página a: enlaza a b y c
- Página b: enlaza a c
- Página c: enlaza a b
- Página d: enlaza a b y c

## Matrices del Sistema

### Matriz de Adyacencia
Representa los enlaces directos entre páginas:
```
[0 1 1 0]
[0 0 1 0]
[0 1 0 0]
[0 1 1 0]
```

### Matriz de Transición de Probabilidades (MTP)
Se obtiene normalizando cada fila de la matriz de adyacencia:
```
[0   0.5 0.5 0  ]
[0   0   1   0  ]
[0   1   0   0  ]
[0   0.5 0.5 0  ]
```

## Cálculo del PageRank

### Vector Inicial
Se comienza con un vector donde todas las páginas tienen igual probabilidad:
```
[0.25 0.25 0.25 0.25]
```

### Proceso Iterativo
1. Se multiplica el vector inicial por la MTP
2. Se repite hasta que converge
3. En este caso, converge a: `[0 0.5 0.5 0]`

## Teleporting

### ¿Por qué es necesario?
- Algunos grafos web no convergen
- Permite que páginas sin enlaces entrantes tengan alguna probabilidad de ser visitadas

### Ejemplo con 10% de Teleporting
1. Se modifica la MTP original:
   - 90% de la probabilidad original
   - 10% distribuido uniformemente (0.025 por página)

### Nueva MTP con Teleporting
```
[0.025 0.475 0.475 0.025]
[0.025 0.025 0.925 0.025]
[0.025 0.925 0.025 0.025]
[0.025 0.475 0.475 0.025]
```

### Resultado Final
El PageRank converge a: `[0.025 0.475 0.475 0.025]`

## Interpretación de Resultados
- Páginas a y d: solo reciben tráfico por teleporting (0.025)
- Páginas b y c: 
  - Tienen igual importancia (0.475)
  - Son más centrales en la estructura
  - Mantienen el mismo orden relativo que sin teleporting

## Caso Especial: Páginas sin Enlaces Salientes
- Son sumideros de probabilidad
- Solución: distribuir su probabilidad uniformemente entre todas las páginas
- Implementación: convertir filas de ceros en filas de unos en la matriz de adyacencia

## Consideraciones Importantes
1. El algoritmo siempre converge con teleporting si no hay páginas sin enlaces salientes
2. La suma de probabilidades siempre debe ser 1
3. El orden relativo de importancia se mantiene con teleporting
4. Teleporting garantiza una probabilidad mínima para todas las páginas