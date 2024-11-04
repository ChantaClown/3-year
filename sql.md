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


¡Claro! Vamos a ver en qué consiste el operador `ALL` y las uniones `LEFT JOIN` y `RIGHT JOIN` en SQL.

### `ALL` en SQL

El operador `ALL` se utiliza en SQL en combinaciones con operadores de comparación (`=`, `>`, `<`, `>=`, etc.) para realizar comparaciones con todos los valores de un subconjunto o resultado de una subconsulta. Básicamente, `ALL` verifica que una condición se cumpla en **todos** los valores devueltos por la subconsulta.

#### Ejemplos de uso de `ALL`

1. **Mayor que todos los valores**:

   ```sql
   SELECT empno, sal
   FROM emp
   WHERE sal > ALL (SELECT sal FROM emp WHERE dept = 10);
   ```
   
   Esta consulta selecciona los empleados cuyo salario es mayor que **todos** los salarios en el departamento 10. Solo se seleccionarán aquellos empleados que tienen un salario superior al salario máximo del departamento 10.

2. **Igual a todos los valores** (poco común):

   ```sql
   SELECT empno, sal
   FROM emp
   WHERE sal = ALL (SELECT sal FROM emp WHERE dept = 20);
   ```

   Aquí se seleccionan los empleados cuyo salario es igual a todos los salarios en el departamento 20. Solo funcionará si todos los empleados del departamento 20 tienen exactamente el mismo salario.

### `LEFT JOIN` y `RIGHT JOIN`

Los **`JOIN`** en SQL permiten combinar filas de dos tablas basándose en una condición común entre ellas. `LEFT JOIN` y `RIGHT JOIN` son dos tipos de uniones externas que permiten incluir todas las filas de una tabla, aunque no tengan correspondencia en la otra tabla.

#### `LEFT JOIN`

- Un **`LEFT JOIN`** (o unión externa izquierda) devuelve **todas las filas de la tabla izquierda** y, cuando no hay coincidencia en la tabla derecha, devuelve `NULL` en las columnas de la tabla derecha.
- Es útil para encontrar registros en la tabla izquierda que no tienen correspondencia en la tabla derecha.

   ```sql
   SELECT e.empno, e.name, d.dept_name
   FROM employee e
   LEFT JOIN department d ON e.dept = d.dept_id;
   ```

   En esta consulta:
   - Se obtienen todos los empleados (`employee`).
   - Si un empleado no está asignado a ningún departamento (es decir, no hay coincidencia en `department`), las columnas de `department` para ese empleado mostrarán `NULL`.

#### `RIGHT JOIN`

- Un **`RIGHT JOIN`** (o unión externa derecha) funciona de manera similar a `LEFT JOIN`, pero en sentido contrario: **devuelve todas las filas de la tabla derecha** y, si no hay coincidencias en la tabla izquierda, devuelve `NULL` en las columnas de la tabla izquierda.
- Es útil para encontrar registros en la tabla derecha que no tienen correspondencia en la tabla izquierda.

   ```sql
   SELECT e.empno, e.name, d.dept_name
   FROM employee e
   RIGHT JOIN department d ON e.dept = d.dept_id;
   ```

   En esta consulta:
   - Se obtienen todos los departamentos (`department`).
   - Si un departamento no tiene empleados asignados, las columnas de `employee` correspondientes mostrarán `NULL`.

### Diferencia entre `LEFT JOIN` y `RIGHT JOIN`

- **`LEFT JOIN`** garantiza que se incluyan todas las filas de la **tabla de la izquierda** (la que está antes de `JOIN`), independientemente de si hay una coincidencia en la tabla derecha.
- **`RIGHT JOIN`** asegura que se incluyan todas las filas de la **tabla de la derecha** (la que está después de `JOIN`), independientemente de si hay coincidencia en la tabla izquierda.

Ambos tipos de uniones son útiles en diferentes contextos, dependiendo de qué tabla es más importante para el análisis o la visualización de resultados.
