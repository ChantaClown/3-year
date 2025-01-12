#RIMW 
### Cantidad de Información de un Símbolo
- **Fórmula**: I(sᵢ) = $-\log₂ pᵢ$
- **Relación inversa**: pᵢ = $2^{(-I(sᵢ))}$
- **Propiedades**:
  - Si pᵢ = 1 → I(sᵢ) = 0
  - Si pᵢ → 0 → I(sᵢ) → ∞

### Entropía (H)
- **Definición**: Promedio de la cantidad de información ponderado por probabilidades
- **Fórmula**: H(P) = -∑ᵢ₌₁ⁿ pᵢ log₂ pᵢ = ∑ᵢ₌₁ⁿ pᵢ I(sᵢ)

#### Ejemplos de Entropía:
1. P = {½, ½} (cara, cruz)
   - H(P) = -½ log₂ ½ -½ log₂ ½ = 1 bit
2. P = {0.99, 0.01}
   - H(P) = 0.08 (menor entropía)
3. P = {¼, ¼, ¼, ¼}
   - Representa mayor incertidumbre que el caso binario

# Sistemas de Codificación Detallados

## 1. Codificación de Longitud Fija (Uniforme)
### Características
- Cada símbolo usa el mismo número de bits
- Longitud: log₂ N bits (N = número de símbolos)

### Ventajas
- Simple de implementar
- Acceso directo a cualquier símbolo
- Decodificación rápida

### Desventajas
- Ineficiente para distribuciones no uniformes
- Desperdicia espacio en símbolos frecuentes

### Ejemplo
```
N = 8 símbolos
Bits necesarios = log₂ 8 = 3
Codificación:
1 → 001
2 → 010
3 → 011
etc.
```

## 2. Codificación Unaria
### Características
- Longitud del código = valor a codificar
- Ideal para distribución geométrica {½, ¼, ⅛, 1/16, ...}

### Formato
- Secuencia de n-1 unos seguida por un cero
- O viceversa: un uno precedido por n-1 ceros

### Ejemplo
```
1 → 0
2 → 10
3 → 110
4 → 1110
5 → 11110
```

### Uso Óptimo
- Cuando P(n) = 2^(-n)
- Frecuencia del primer símbolo = 50%
- Cada siguiente símbolo = mitad del anterior

## 3. Codificación Elias-γ (Gamma)

La codificación gamma de Elias se usa para codificar números enteros positivos y consiste en dos partes:

1. Parte unaria: Se codifica ⌊log₂(x)⌋ + 1 en unario (tantos 1's como valor, seguidos de un 0)
2. Parte binaria: Se codifica x - 2^⌊log₂(x)⌋ en binario usando ⌊log₂(x)⌋ bits

Ejemplo para codificar el número 9:

1. ⌊log₂(9)⌋ = 3
2. Parte unaria: 3+1 unos seguidos de 0 → 11110
3. Parte binaria: 9 - 2³ = 1 en 3 bits → 001
4. Resultado final: 11110001

### Características
- Variable-length
- Auto-delimitante (no necesita separadores)
- Ideal para números enteros pequeños

### Estructura
1. Parte unaria: ⌊log₂ x⌋ unos seguidos de un cero
2. Parte binaria: los bits menos significativos de x

### Ejemplo
```
1 → 0        (0 unos + 0 en binario)
2 → 100      (1 uno + 0 + binario de 2)
3 → 101      (1 uno + 0 + binario de 3)
4 → 11000    (2 unos + 0 + binario de 4)
5 → 11001    (2 unos + 0 + binario de 5)
```

### Distribución Ideal
- p(x) = 1/(2x²)
- Óptimo cuando la frecuencia decrece cuadráticamente

## 4. Codificación Elias-δ (Delta)

Es una mejora de la codificación gamma para números grandes. Se construye así:

1. Toma el número x
2. Calcula N = ⌊log₂(x)⌋ + 1 (longitud en bits)
3. Codifica N usando codificación gamma
4. Añade los últimos ⌊log₂(x)⌋ bits de x

Ejemplo para codificar 9:

1. 9 = 1001 en binario
2. N = ⌊log₂(9)⌋ + 1 = 4
3. 4 en gamma = 11000
4. Últimos bits de 9 = 001
5. Resultado: 11000001

### Características
- Mejora de Elias-γ para números grandes
- Más eficiente para valores > 16

### Estructura
1. Codifica ⌊log₂ x⌋ + 1 en gamma
2. Añade los bits menos significativos de x

### Ejemplo
```
1 → 0
2 → 1000
3 → 1001
4 → 1010
5 → 1011
```

### Distribución Ideal
- p(x) = 1/(2x(log x)²)
- Mejor para distribuciones con cola larga

## 5. Variable Byte Encoding
### Características
- Usa bytes completos
- Bit más significativo como flag de continuación

### Formato
- MSB = 0: último byte de la secuencia
- MSB = 1: hay más bytes por venir

### Ventajas
- Fácil de implementar
- Eficiente en CPU modernas
- Buenos ratios de compresión

### Ejemplo
```
127 → 0x7F         (01111111)
128 → 0x80 0x01    (10000000 00000001)
129 → 0x80 0x02    (10000000 00000010)
```

## Comparación de Eficiencia

| Método      | Mejor caso                | Peor caso    | Uso típico                    |
|-------------|---------------------------|--------------|-------------------------------|
| Fijo        | Distribución uniforme     | Sesgada      | Alfabetos pequeños            |
| Unario      | Geométrica               | Uniforme     | Números muy pequeños          |
| Elias-γ     | 1/x²                     | Uniforme     | Enteros positivos pequeños    |
| Elias-δ     | 1/(x(log x)²)            | Uniforme     | Enteros positivos medianos    |
| Var-Byte    | Números < 128            | Grandes gaps | Índices invertidos            |

## Sistemas de Distribución

### Term Distribution vs Document Distribution
- **Term Distribution**:
  - O(k) disk seeks para k términos
  - Software más complejo
  - Más eficiente en E/S
- **Document Distribution**:
  - O(kn) seeks para n servers
  - Más simple pero menos eficiente

### Federated Search
1. Obtención de estadísticas o query sampling
2. Selección de recursos
3. Ejecución selectiva de queries
4. Fusión de resultados

### Metasearch
- Fusión de scores o rankings de diversos motores
- Utiliza APIs de búsqueda
- Referencia importante: "Models for metasearch" (Aslam & Montague, SIGIR '01)

# Sistemas de Compresión en IR

## Fundamentos de Compresión

### Objetivos Principales
1. Reducir espacio de almacenamiento
2. Reducir tiempo de transferencia
3. Optimizar uso de caché
4. Mejorar eficiencia en búsquedas

### Tipos de Compresión

#### 1. Compresión sin Pérdida
- Preserva información exacta
- Recuperación perfecta
- Usada en índices invertidos

#### 2. Compresión con Pérdida
- Acepta cierta degradación
- Mayor ratio de compresión
- Usada en multimedia y datos aproximados

## Técnicas de Compresión para Índices Invertidos

### 1. D-Gaps (Delta Encoding)
#### Características
- Almacena diferencias entre valores consecutivos
- Efectivo para listas ordenadas
- Convierte números grandes en secuencias de números más pequeños

#### Ejemplo
```
Original: 1, 4, 8, 12, 15
D-Gaps:   1, 3, 4, 4, 3
```

### 2. Frame of Reference (FOR)
#### Características
- Almacena valor base y diferencias
- Efectivo para rangos pequeños
- Usa tamaño fijo para bloques

#### Ejemplo
```
Valores: 100, 102, 105, 109
Base: 100
Diferencias: 0, 2, 5, 9
```

### 3. Variable Byte Encoding
#### Formato
- Usa bytes completos
- MSB como indicador de continuación
- Balance entre compresión y velocidad

#### Ejemplo
```
127:  0x7F
128:  0x80 0x01
1000: 0x87 0x68
```

### 4. Simple-9 / Simple-16
#### Características
- Empaqueta múltiples enteros en 32 bits
- Usa 4 bits para selector de esquema
- Optimizado para CPU modernas

#### Esquemas Simple-9
```
28 números de 1 bit
14 números de 2 bits
9 números de 3 bits
7 números de 4 bits
5 números de 5 bits
4 números de 7 bits
3 números de 9 bits
2 números de 14 bits
1 número de 28 bits
```

## Compresión en Posting Lists

### Estructura Básica
```
PostingList = [DocID, Frecuencia, [Posiciones]]
```

### Técnicas de Optimización
1. Compresión de DocIDs
   - D-Gaps
   - Variable byte encoding
   
2. Compresión de Frecuencias
   - Códigos de longitud variable
   - Huffman adaptativo

3. Compresión de Posiciones
   - D-Gaps relativos
   - Codificación diferencial

### Ejemplo Completo
```
Original: (1, 2, [1,7]) (2, 3, [6, 17, 197]) (3, 1, [1])
D-Gaps: (1, 2, [1,6]) (1, 3, [6, 11, 180]) (1, 1, [1])
VByte: 81 82 81 86 81 83 86 8B 01 B4 81 81 81
```

## Skip Lists en Compresión

### Propósito
- Acelerar operaciones de búsqueda
- Permitir saltos en listas comprimidas
- Reducir decodificaciones innecesarias

### Estructura
```
[Header][Skip Pointers][Compressed Data]
```

### Skip Pointer Format
- Offset al siguiente bloque
- Último DocID en bloque actual
- Tamaño de bloque variable

## Estrategias de Implementación

### 1. Bloques de Tamaño Fijo
- Ventajas:
  * Fácil implementación
  * Acceso directo
- Desventajas:
  * Menos eficiente en espacio
  * No adapta a distribución de datos

### 2. Bloques de Tamaño Variable
- Ventajas:
  * Mejor ratio de compresión
  * Adaptativo a datos
- Desventajas:
  * Más complejo
  * Overhead en metadatos

### 3. Híbridos
- Combinan múltiples técnicas
- Optimizan para casos específicos
- Balance entre velocidad y compresión

## Métricas de Evaluación

### 1. Ratio de Compresión
```
RC = Tamaño_Original / Tamaño_Comprimido
```

### 2. Velocidad
- Tiempo de compresión
- Tiempo de decompresión
- Tiempo de acceso aleatorio

### 3. Uso de Memoria
- Durante compresión
- Durante decompresión
- En operación normal