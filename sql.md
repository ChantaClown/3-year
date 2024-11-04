Aquí tienes un resumen de las operaciones básicas de SQL y una explicación sobre la función `COALESCE`:

### Operaciones Básicas en SQL

1. **SELECT**: Se usa para seleccionar y recuperar datos de una o varias tablas en una base de datos.
   ```sql
   SELECT columna1, columna2 FROM tabla;
   ```
   - Permite especificar qué columnas deseas ver en los resultados.
   
2. **FROM**: Especifica de qué tabla (o tablas) se obtendrán los datos.
   ```sql
   SELECT columna1 FROM tabla;
   ```

3. **WHERE**: Filtra los registros que cumplen con una condición específica.
   ```sql
   SELECT columna1 FROM tabla WHERE condicion;
   ```

4. **ORDER BY**: Ordena el conjunto de resultados según una o varias columnas, en orden ascendente (ASC) o descendente (DESC).
   ```sql
   SELECT columna1 FROM tabla ORDER BY columna1 ASC;
   ```

5. **GROUP BY**: Agrupa las filas que tienen valores idénticos en columnas especificadas, generalmente para realizar funciones de agregación (como `SUM`, `COUNT`, etc.).
   ```sql
   SELECT columna1, SUM(columna2) FROM tabla GROUP BY columna1;
   ```

6. **HAVING**: Similar a `WHERE`, pero se usa para filtrar grupos de registros tras aplicar `GROUP BY`.
   ```sql
   SELECT columna1, COUNT(*) FROM tabla GROUP BY columna1 HAVING COUNT(*) > 1;
   ```

7. **JOIN**: Combina filas de dos o más tablas basadas en una relación entre ellas.
   ```sql
   SELECT tabla1.columna1, tabla2.columna2 
   FROM tabla1 
   JOIN tabla2 ON tabla1.id = tabla2.id;
   ```

8. **LIMIT**: Restringe la cantidad de filas que se muestran en el resultado.
   ```sql
   SELECT columna1 FROM tabla LIMIT 10;
   ```

### Función `COALESCE`

La función `COALESCE` se utiliza para devolver el primer valor no nulo de una lista de expresiones. Es muy útil cuando trabajas con datos que pueden tener valores nulos, y deseas definir un valor predeterminado.

Por ejemplo:
```sql
SELECT COALESCE(columna1, columna2, 'valor por defecto') AS resultado FROM tabla;
```

En este ejemplo, si `columna1` es `NULL`, devolverá el valor de `columna2`. Si ambas son `NULL`, devolverá `'valor por defecto'`. 

Esta función es útil cuando necesitas asegurarte de que un campo tenga siempre un valor válido, incluso si en la base de datos existen valores nulos.
