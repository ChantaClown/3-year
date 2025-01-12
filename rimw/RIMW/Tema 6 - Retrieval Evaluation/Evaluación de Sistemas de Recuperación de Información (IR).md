#RIMW 

## Clasificación de la Información

La información se puede clasificar en tres tipos principales:

- **Navegacional**: El usuario busca un sitio web o un recurso específico.
- **Informacional**: El usuario busca datos o conocimiento sobre un tema.
- **Transaccional**: El usuario busca realizar una transacción, como una compra o descarga.

## Satisfacción del Usuario

La **satisfacción** se define como la opinión de un usuario sobre una aplicación específica que utiliza. Esta se refleja en:

- Mayor número de clics en los resultados.
- Incremento o repetición de visitas al sistema.
- **Relevancia de los resultados** entregados.

# Experimentos de Cranfield

>[!Quote] "La relevancia de los documentos recuperados es una buena aproximación de la utilidad de un sistema para satisfacer la necesidad de información del usuario."

### Elementos Clave de la Evaluación de IR:

1. **Colección de Documentos**: El corpus sobre el cual se evalúa el sistema.
2. **Conjunto de Queries de Prueba**: Representan las necesidades de información que serán evaluadas.
3. **Set de Relevancia**: Juicios que indican si cada par query-documento es relevante o no.

### Nota Importante:
La relevancia se evalúa con respecto a la **información deseada**, no únicamente a la query. Es más importante que el sistema recupere información útil, aunque no coincida exactamente con los términos de la consulta.

# Evaluation Metrics

En un sistema Booleano, las métricas clave son:

- **Precision**: Fracción de documentos recuperados que son relevantes:
  $$
  \text{Precision} = \frac{TP}{TP + FP}
  $$
- **Recall**: Fracción de documentos relevantes que son recuperados:
  $$
  \text{Recall} = \frac{TP}{TP + FN}
  $$

### Matriz de Confusión:

|               | Relevant (R) | Non-Relevant (NR) |
| ------------- | ------------ | ----------------- |
| Retrieved     | TP           | FP                |
| Not Retrieved | FN           | TN                |

### Relación entre Precision y Recall:
- **Precision**: Tiende a disminuir a medida que aumenta el número de documentos recuperados.
- **Recall**: Tiende a aumentar continuamente al recuperar más documentos.

- **Precision**: Favorece recuperar menos documentos pero con alta relevancia.
- **Recall**: Favorece recuperar más documentos, sin importar si algunos son irrelevantes.

![[sawthooot.png]]
