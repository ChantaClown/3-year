#RIMW 
## Ley de Probabilidad Total

### Definición Formal
Para eventos b₁, b₂, ..., bₖ que forman una partición del espacio de eventos S, donde P(bⱼ)>0 para j=1,...,k:

```
P(a) = ∑ⱼ₌₁ᵏ P(bⱼ)P(a|bⱼ)
```

### Aplicación en Relevance Model
- Se considera la partición formada por todos los documentos de la colección
- El evento 'a' se reemplaza por la ocurrencia simultánea de eventos w, q₁, q₂,..., qₙ

## Probabilidad Condicional

### Definición Básica
```
P(a|b) = P(a,b) / P(b)
```

### Interpretación
- La probabilidad de 'a' dado que 'b' ha ocurrido
- Se calcula considerando las ocurrencias de 'a' entre las salidas de 'b'
- También se puede expresar como: P(a,b) = P(a|b)P(b)

## Sucesos Independientes

### Características
1. P(a|b) = P(a)
   - No es necesario conocer la ocurrencia de 'b' para evaluar 'a'
2. P(a,b) = P(a)P(b)
   - La probabilidad conjunta es el producto de las probabilidades individuales

## Sucesos Condicionalmente Independientes

### Definición
Para sucesos 'a' y 'b' condicionalmente independientes dado 'c':
```
P(a,b|c) = P(a|c)P(b|c)
```

### Aplicación en RM1 (Relevance Model)
- Se asume que w, q₁, ..., qₙ son condicionalmente independientes dado D
- Implica que, dentro de un documento D:
  - La ocurrencia de palabras del documento
  - Los términos de la query
  - Son todos independientes entre sí

## Notas Adicionales
- Existe una versión alternativa llamada RM2 que hace menos suposiciones
- RM2 no asume independencia condicional
- La referencia completa está en el paper original de Croft (no incluido en el libro)

