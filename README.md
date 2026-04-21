## Problema

Una coordinación académica debe asignar bloques de tiempo (2 horas por bloque) a un conjunto de clases, evitando traslapes que violen las siguientes restricciones operativas:

- Un grupo no puede cursar dos clases en el mismo bloque de tiempo.
- Un docente no puede impartir dos clases en el mismo bloque de tiempo.

## Objetivo general

Optimizar la asignación de bloques de tiempo para clases académicas mediante el modelado del problema como un grafo de conflictos y la aplicación de algoritmos de coloreo.

## Tareas para realizar

- Modelar el conjunto de clases como un grafo de conflictos a partir de restricciones por grupo y por docente (como ejemplo considere los datos de la Tabla 1).
- Construir la representación gráfica del grafo para su procesamiento.
- Aplicar un algoritmo Greedy (paso a paso), dibujando el grafo de conflictos generado considerando el conjunto de datos de la Tabla 1 con el orden: B, A, H, F, I, E, D, C, G.
- Aplicar cualquier otro algoritmo de coloreo de grafos para compararlo con el algoritmo Greedy, considere los mismos datos de la Tabla 1 y coloree el grafo resultante.
- Argumentar un resultado teórico que le permita determinar: ¿cuándo se obtiene un número mínimo de bloques de tiempo?, o ¿cómo saber que ya no se puede reducir el número de bloques de tiempo.?
- Realizar el análisis de la complejidad de los algoritmos de coloreo utilizados.
- Proponer una implementación computacional para al menos uno de los algoritmos propuestos para el caso general de resolver conflictos mediante el coloreo grafos.

***Tabla 1***.  Regla de conflicto: dos clases están en conflicto si comparten el mismo Grupo o Docente.

| Id Clase | Materia    | Grupo | Docente |
| --- | --- | --- | --- |
| A | Mate I     | G1 | T1 |
| B | Mate II    | G1 | T2 |
| C | Mate III   | G1 | T3 |
| D | Física I   | G2 | T1 |
| E | Física II  | G2 | T2 |
| F | Física III | G2 | T3 |
| G | Prog I     | G3 | T1 |
| H | Prog II    | G3 | T2 |
| I | Prog III   | G3 | T3 |

### Preguntas guía

- ¿Cómo se construye el grafo de conflictos a partir de datos de clases?
- ¿Cuál es el número mínimo de bloques requerido para un conjunto de clases dado?
- ¿Qué algoritmo de coloreo produce soluciones de mejor calidad (menos bloques) bajo el mismo tiempo de cómputo?
- ¿Cómo se valida que el horario resultante no contiene conflictos?
- ¿En una implementación computacional que estructura de datos es adecuada para representar los datos del grafo de conflictos?
- Cómo se quiere obtener un óptimo minimal sobre el número de bloques de tiempo, ¿cómo saber si ya obtuvo tal valor óptimo?
- ¿Cómo cambia la solución al introducir el conflicto sobre la disponibilidad de los docentes por bloque?

#### Por ejemplo

Disponibilidad por docente:

- T1: **NO disponible** en B1 y B4 → **permitidos** {B2, B3}
- T2: **NO disponible** en B2 y B3 → **permitidos** {B1, B4}
- T3: **NO disponible** en B1 y B3 → **permitidos** {B2, B4}

---

## Solución

### Tarea 1

Modelar el conjunto de clases como un grafo de conflictos a partir de restricciones por grupo y por docente (como ejemplo considere los datos de la Tabla 1).

#### Ejecución

Al analizar el problema, vemos que se parece mucho al **coloreo de grafos**. Eso nos sirve para entender que:

1. Es posible revisar en tiempo polinomial si una solución propuesta cumple las restricciones.

    Para cada arista `(V1, V2)` comprobar que `C(V1) != C(V2)`.

    En este problema eso significa que si dos clases están en conflicto entonces no pueden estar en el mismo bloque.
    Para verificar la solución solo tendríamos que comprobar que no viola las restricciones del problema.

    Para un grafo con `n` vértices y `m` aristas se hace:

      - Leer la asignación de colores en cada vértice: `O(n)`.
      - Recorrer cada arista y comparar los colores en sus extremos: `O(m)` (cada arista se revisa una vez).

    En total la complejidad es **`O(n + m)`**. (En un grafo no dirigido la suma de los grados es `2m`, así que recorrer aristas equivale a `O(m)` en el conteo usual.)

2. Encontrar siempre la mejor solución puede ser costoso. En la práctica suele usarse una heurística constructiva; para instancias pequeñas (o con suficiente tiempo y memoria) se pueden usar métodos exactos.

   **Algunos métodos heurísticos o constructivos**

   - DSATUR
   - RLF
   - Welsh-Powell
   - Greedy

   **Algunos métodos exactos**

   - Backtracking
   - Branch and Bound
   - Branch and Cut
   - Branch and Price

#### Demostración

Queremos probar que **3-COLORING es NP-completo**.

Para eso hacen falta dos cosas:

1. Probar que **3-COLORING pertenece a NP**.
2. Probar que **3-COLORING es NP-Hard**.

La segunda parte se demuestra con una reducción polinomial desde **3-SAT** hacia **3-COLORING**:

3-SAT <=p 3-COLORING

Es decir, dada una fórmula booleana phi en 3-CNF, construiremos un grafo G_phi tal que:

phi es satisfacible si y solo si G_phi es 3-coloreable.

Ref: `Chekuri & Pitt, 2015, p. 5`

##### 1. 3-COLORING pertenece a NP

Dado un grafo G y una propuesta de coloreo con 3 colores, se puede verificar en tiempo polinomial que el coloreo es válido:

- se revisa cada arista (u, v)
- se comprueba que u y v tengan colores distintos

Eso toma tiempo polinomial en el tamaño del grafo.

Por tanto, **3-COLORING pertenece a NP**.

##### 2. Idea general de la reducción

Partimos de una fórmula phi de 3-SAT con:

- variables x1, x2, ..., xn
- cláusulas C1, C2, ..., Cm

Vamos a construir un grafo G_phi usando exactamente 3 colores conceptuales:

- T = True
- F = False
- B = Base

La construcción debe forzar dos cosas:

1. que cada variable tome exactamente uno de los valores True o False
2. que cada cláusula tenga al menos un literal verdadero

Si logramos eso, entonces una 3-coloración válida del grafo equivale a una asignación satisfactoria de phi.

###### Gadget base: el triángulo T, F, B

Primero se crea un triángulo con tres nodos:

- T
- F
- B

Como forman un triángulo, en cualquier 3-coloración válida deben recibir tres colores distintos.

Entonces esos tres nodos fijan la paleta completa de colores del resto de la construcción.

A partir de ese momento interpretamos:

- color de T = verdadero
- color de F = falso
- color de B = base

```
      T --- F
       \   /
        \ /
         B
```

###### Gadget de variable

Para cada variable xi se crean dos nodos:

- vi  (representa xi)
- not_vi (representa no xi)

Y se conectan así:

- vi con not_vi
- vi con B
- not_vi con B

Eso forma un triángulo **(vi, not_vi, B)** con aristas **vi–not_vi**, **vi–B** y **not_vi–B**.

```
   T ----------- F
    \           /
     \         /
      \       /
       \     /
        \   /
         \ /
          B
         / \
        /   \
       /     \
    vi ------- not_vi
```

**¿Qué fuerza este gadget?**

Como **vi** y **not_vi** están conectados a **B**, ninguno de los dos puede tomar el color de **B**.

Por tanto, cada uno solo puede tomar uno de estos dos colores (los que ya tienen **T** y **F** en una 3-coloración válida del triángulo base):

- el color de **T**
- el color de **F**

Además, como **vi** y **not_vi** están conectados entre sí, no pueden tener el mismo color.

Entonces obligatoriamente:

- uno queda con el color de **T**
- el otro queda con el color de **F**

Eso codifica una asignación de verdad coherente para la variable **xi**.

**Interpretación:**

- si **vi** tiene el color de **T**, entonces **xi** = verdadero
- si **vi** tiene el color de **F**, entonces **xi** = falso

Y automáticamente su negación queda con el valor contrario.

###### Gadget de cláusula

Ahora hay que forzar que cada cláusula sea satisfecha.

Si una cláusula es:

Cj = (a or b or c)

entonces las diapositivas construyen un gadget OR con:

- tres nodos de entrada: a, b, c
- varios nodos internos
- un nodo de salida que representa a or b or c

Este gadget tiene dos propiedades esenciales:

**Propiedad 1**

Si a, b y c están coloreados como False, entonces la salida del gadget también queda forzada a False.

**Propiedad 2**

Si al menos uno de a, b o c está coloreado como True, entonces el gadget sí puede 3-colorearse haciendo que la salida quede con color True.

Estas dos propiedades son exactamente lo que necesitamos para representar una disyunción.

###### Cómo se conecta el gadget de cláusula al resto del grafo

Para cada cláusula Cj = (a or b or c):

1. se construye el gadget OR con entradas a, b y c
2. se toma el nodo de salida del gadget
3. ese nodo de salida se conecta a:
   - F
   - B

###### ¿Qué logra esto?

Como la salida está conectada a F y a B, no puede usar ni el color F ni el color B.

Por tanto, la salida queda forzada a usar el color T.

Pero el gadget OR solo permite que la salida sea T si al menos una de las entradas a, b, c es T.

Entonces queda forzado que en cada cláusula haya al menos un literal verdadero.

Eso hace que cada cláusula sea satisfecha

###### Construcción completa del grafo G_phi

El grafo G_phi se construye así:

1. Se crea el triángulo base con T, F y B.
2. Para cada variable xi, se agrega su gadget de variable.
3. Para cada cláusula Cj = (a or b or c), se agrega su gadget OR.
4. La salida de cada gadget OR se conecta con F y con B.

El tamaño del grafo resultante es polinomial en el tamaño de phi, porque:

- por cada variable se añade una cantidad constante de nodos y aristas
- por cada cláusula se añade una cantidad constante de nodos y aristas

Por tanto, la transformación se puede hacer en tiempo polinomial.

###### Correctitud de la reducción

Ahora hay que demostrar la equivalencia:

phi es satisfacible si y solo si G_phi es 3-coloreable.

**(=>) Si phi es satisfacible, entonces G_phi es 3-coloreable**

Supongamos que phi tiene una asignación satisfactoria.

- Coloreamos T, F y B con tres colores distintos.
- Para cada variable xi:
  - si xi = verdadero, damos a vi el color T y a not_vi el color F
  - si xi = falso, damos a vi el color F y a not_vi el color T

Eso colorea correctamente todos los gadgets de variable.

Ahora consideremos una cláusula Cj = (a or b or c).

Como la asignación satisface phi, en cada cláusula al menos uno de los literales a, b o c es verdadero.

Entonces, por la propiedad del gadget OR, ese gadget puede colorearse de modo que su salida tenga color T.

Como esto vale para cada cláusula, todo el grafo G_phi queda 3-coloreado legalmente.

Por tanto, G_phi es 3-coloreable.

###### (<=) Si G_phi es 3-coloreable, entonces phi es satisfacible

Supongamos ahora que G_phi admite una 3-coloración válida.

- El triángulo T-F-B usa tres colores distintos.
- En cada gadget de variable, vi y not_vi no pueden usar el color B y además deben tener colores distintos.
- Por tanto, uno queda con T y el otro con F.

Eso define una asignación booleana consistente para cada variable.

Ahora miremos cualquier cláusula Cj = (a or b or c).

La salida del gadget de cláusula está conectada a F y a B, así que no puede tomar esos colores.
Entonces su color debe ser T.

Pero por la propiedad del gadget OR, eso solo es posible si al menos una de las entradas a, b o c tiene color T.

Por tanto, en cada cláusula al menos un literal es verdadero.

Luego todas las cláusulas se satisfacen y phi es satisfacible.

###### Conclusión

Se ha construido en tiempo polinomial un grafo G_phi tal que:

phi es satisfacible si y solo si G_phi es 3-coloreable.

Por tanto:

3-SAT <=p 3-COLORING

Como 3-SAT es NP-completo, se concluye que **3-COLORING es NP-Hard**.

Además, como 3-COLORING pertenece a NP, concluimos finalmente que:

**3-COLORING es NP-completo.**

#### Reducción a coloreo de grafos

Luego de esta demostración, reducimos nuestro problema de asignación de bloques de clases a **coloreo de grafos** de la siguiente manera:

- Cada clase se representa como un nodo en el grafo.
- Se dibuja una arista de conflicto entre dos nodos si las clases comparten el **mismo grupo** o el **mismo docente**; así reflejamos que no pueden ocurrir en el **mismo bloque de tiempo**.
- Colorear el grafo con **k** colores equivale a asignar a **k** bloques de tiempo de manera que no existan conflictos, cumpliendo así todas las restricciones.

Por eso tiene sentido usar aquí los mismos algoritmos de coloreo (**heurísticos** y **exactos**) que vimos antes: si obtenemos un coloreo válido con **k** colores, ese resultado se lee directamente como un **horario sin conflictos** en **k** bloques.

#### Modelado como grafo de conflictos

El conjunto de clases de la Tabla 1 se representa como un **grafo no dirigido de conflictos**: hay arista entre dos clases si comparten **grupo** o **docente**. Para almacenarlo de forma compacta usamos **listas de adyacencia**: por cada vértice guardamos sus vecinos (en ambos sentidos, porque el grafo es no dirigido).

**Vértices:** `A, B, C, D, E, F, G, H, I` (una clase por letra).

**Listas de adyacencia** (formato `vértice → vecinos`):

```
A → B, C, D, G
B → A, C, E, H
C → A, B, F, I
D → A, E, F, G
E → B, D, F, H
F → C, D, E, I
G → A, D, H, I
H → B, E, G, I
I → C, F, G, H
```

##### ¿Por qué listas de adyacencia y no matriz de adyacencia?

En este problema el grafo de conflictos suele ser **ralo** (`m` mucho menor que `n²`). Con **listas**, localizar el contenedor del vecindario de un vértice es `O(1)` y **recorrer sus vecinos** cuesta `O(grado(v))`; al recorrer todas las aristas (por ejemplo para comprobar colores en cada extremo), el trabajo total es **`O(n + m)`**, con `m` el número de aristas.

Con una **matriz `n × n`**, encontrar vecinos de `v` mirando toda la fila cuesta **`O(n)`** aunque `v` tenga pocos vecinos; repetir eso para todos los vértices lleva a **`O(n²)`** incluso cuando el grafo es ralo. Por eso conviene la lista de adyacencia frente a la matriz en este escenario.

### Tarea 2

Construir la representación gráfica del grafo para su procesamiento.

#### Ejecución

![Grafo](assets/graph_before_coloring.png)

### Tarea 3
Aplicar un algoritmo Greedy (paso a paso), dibujando el grafo de conflictos generado considerando el conjunto de datos de la Tabla 1 con el orden: B, A, H, F, I, E, D, C, G.

#### Ejecución

El **Greedy de coloreo** recorre los nodos en ese orden; al llegar a un nodo **v**, mira solo los **vecinos que ya quedaron coloreados** en pasos anteriores, anota los colores que usan y asigna a **v** el **menor color entero no usado** entre esos vecinos (típicamente empezando en **0**). Así cada paso es local y rápido, pero el resultado **depende del orden**: puede usar más colores que el óptimo aunque exista un coloreo con menos colores.

Orden de visita solicitado:

`B, A, H, F, I, E, D, C, G`

Grafo de conflicto por listas de adyacencia:

```
A -> B, C, D, G
B -> A, C, E, H
C -> A, B, F, I
D -> A, E, F, G
E -> B, D, F, H
F -> C, D, E, I
G -> A, D, H, I
H -> B, E, G, I
I -> C, F, G, H
```

Pasos del algoritmo de coloreo:

| Nodo | Colores de vecinos | Color asignado |
| --- | --- | --- |
| B | [] | 0 |
| A | [0] | 1 |
| H | [0] | 1 |
| F | [] | 0 |
| I | [0, 1] | 2 |
| E | [0, 1] | 2 |
| D | [0, 1, 2] | 3 |
| C | [0, 1, 2] | 3 |
| G | [1, 2, 3] | 0 |

Coloración final:

```
{
  B: 0,
  A: 1,
  H: 1,
  F: 0,
  I: 2,
  E: 2,
  D: 3,
  C: 3,
  G: 0
}
```

![Grafo](assets/graph_after_greedy_coloring_custom_order.png)

### Tarea 4

Aplicar cualquier otro algoritmo de coloreo de grafos para compararlo con el algoritmo Greedy, considere los mismos datos de la Tabla 1 y coloree el grafo resultante.

#### Ejecución

Elegimos el algoritmo DSATUR porque selecciona primero los nodos con más colores distintos entre sus vecinos, lo que suele reducir la cantidad total de colores (bloques de tiempo) necesarios respecto a Greedy. Además, DSATUR facilita la incorporación de restricciones adicionales, como la disponibilidad de docentes en bloques de tiempo que se trata en la **Pregunta 7**.

##### Demostración

Queremos probar que existe un grafo `G` y un orden de visita para Greedy tal que:

`colores(Greedy) > colores(DSATUR)`.

Consideremos:

- `V = {A, B, C, D, E}`
- `E = {AB, AC, BC, BD, BE, CE, DE}`

`{A, B, C}` es un `K_3`, por lo que `chi(G) >= 3`.

Además, existe una 3-coloración válida, por ejemplo:

- `B -> 0`
- `C -> 1`
- `A -> 2`
- `E -> 2`
- `D -> 1`

Por tanto, `chi(G) = 3`.

**Greedy con orden desfavorable**

Tomemos el orden: `A, D, C, E, B`.

1. `A`: sin vecinos coloreados, asigna `0`.
2. `D`: sin vecinos coloreados, asigna `0`.
3. `C`: vecino coloreado `A(0)`, asigna `1`.
4. `E`: vecinos coloreados `C(1)` y `D(0)`, asigna `2`.
5. `B`: vecinos coloreados `A(0), C(1), D(0), E(2)`, asigna `3`.

Greedy usa `4` colores.

**DSATUR en el mismo grafo**

Usamos desempate por mayor grado y, si persiste empate, orden alfabético.

1. `B` (grado 4) -> color `0`.
2. Máxima saturación: `C, E` (1); mayor grado (3), elegimos `C` -> color `1`.
3. `E` tiene saturación 2 (`{0,1}`) -> color `2`.
4. `A` y `D` tienen saturación 2; elegimos `A` -> color `2`.
5. `D` -> color `1`.

DSATUR usa `3` colores, que coincide con `chi(G)`.

Con esto queda demostrado que existe un caso donde Greedy (con mal orden) usa más colores que DSATUR.

##### Aplicación al caso de estudio

Orden de visita solicitado:

`B, A, H, F, I, E, D, C, G`

Grafo de conflicto por listas de adyacencia:

```
A -> B, C, D, G
B -> A, C, E, H
C -> A, B, F, I
D -> A, E, F, G
E -> B, D, F, H
F -> C, D, E, I
G -> A, D, H, I
H -> B, E, G, I
I -> C, F, G, H
```

Prioridad de nodos según entrada:

| Nodo | Prioridad |
| --- | --- |
| B | 0 |
| A | 1 |
| H | 2 |
| F | 3 |
| I | 4 |
| E | 5 |
| D | 6 |
| C | 7 |
| G | 8 |

Paso a Paso del Algoritmo DSATUR

1. Paso 1:
    - Nodos sin color: A, B, C, D, E, F, G, H, I
    - Nodo seleccionado: B (mayor saturación y prioridad)
    - Colores vecinos usados: []
    - Color asignado: 0
    - Saturación actualizada para vecinos (A, C, E, H): [0]
2. Paso 2:
    - Nodos sin color: A, C, D, E, F, G, H, I
    - Nodo seleccionado: A
    - Colores vecinos usados: [0]
    - Color asignado: 1
    - Saturación actualizada para vecinos (C, D, G): [1]
3. Paso 3:
    - Nodos sin color: C, D, E, F, G, H, I
    - Nodo seleccionado: C
    - Colores vecinos usados: [0, 1]
    - Color asignado: 2
    - Saturación actualizada para vecinos (F, I): [2]
4. Paso 4:
    - Nodos sin color: D, E, F, G, H, I
    - Nodo seleccionado: H
    - Colores vecinos usados: [0]
    - Color asignado: 1
    - Saturación actualizada para vecinos (E, G, I): [1,2]
5. Paso 5:
    - Nodos sin color: D, E, F, G, I
    - Nodo seleccionado: I
    - Colores vecinos usados: [1, 2]
    - Color asignado: 0
    - Saturación actualizada para vecinos (F, G): [0,2]
6. Paso 6:
    - Nodos sin color: D, E, F, G
    - Nodo seleccionado: F
    - Colores vecinos usados: [0, 2]
    - Color asignado: 1
    - Saturación actualizada para vecinos (D, E): [1,2]
7. Paso 7:
    - Nodos sin color: D, E, G
    - Nodo seleccionado: E
    - Colores vecinos usados: [0, 1]
    - Color asignado: 2
    - Saturación actualizada para vecinos (D): [1,2]
8. Paso 8:
    - Nodos sin color: D, G
    - Nodo seleccionado: D
    - Colores vecinos usados: [1, 2]
    - Color asignado: 0
    - Saturación actualizada para vecinos (G): [0,1]
9. Paso 9:
    - Nodo sin color: G
    - Colores vecinos usados: [0, 1]
    - Color asignado: 2

Coloración final:

```
{
  B: 0,
  A: 1,
  C: 2,
  H: 1,
  I: 0,
  F: 1,
  E: 2,
  D: 0,
  G: 2
}
```

### Tarea 4

Argumentar un resultado teórico que le permita determinar: ¿cuándo se obtiene un número mínimo de bloques de tiempo?, o ¿cómo saber que ya no se puede reducir el número de bloques de tiempo.?

#### Ejecución

El mínimo número de bloques de tiempo coincide con el **número cromático** chi(G) del grafo de conflictos.

##### Resultado teórico (criterio de optimalidad)
Una asignación con k bloques es óptima si se cumplen simultáneamente:

1. **Cota inferior:** existe un clique de tamaño k, por lo que chi(G) >= k.
2. **Cota superior:** existe una coloración válida con k colores, por lo que chi(G) <= k.

Si ambas se cumplen, entonces necesariamente chi(G) = k, y por tanto **ya no se puede reducir** el número de bloques.

##### Aplicación al caso de estudio
1. Existe un clique de tamaño 3, por ejemplo {A, B, C}, porque las tres clases comparten el mismo grupo (G1). Luego chi(G) >= 3.
2. En las ejecuciones de coloreo se obtuvo una coloración válida con 3 colores (3 bloques). Luego chi(G) <= 3.
3. Por lo tanto, chi(G) = 3. El número mínimo de bloques es 3; con 2 bloques se generan conflictos.

### Tarea 5

Realizar el análisis de la complejidad de los algoritmos de coloreo utilizados.

#### Ejecución

##### Greedy

El algoritmo greedy para el coloreo de grafos funciona de la siguiente manera:
1. Se fija un orden de visita de los nodos
2. Para cada nodo, se asigna el menor color disponible que no esté usado por sus vecinos
3. Se repite hasta colorear todos los nodos

***Análisis***:

Sea `n` el número de nodos y `m` el número de aristas.

En el algoritmo Greedy:

1. Se recorre cada nodo una vez para decidir su color.
2. Para cada nodo, se revisan los colores de sus vecinos para encontrar el menor color disponible.

En total, revisar vecinos en todos los pasos equivale a sumar los grados de todos los nodos.
Esa suma es `2m`, porque cada arista contribuye al grado de dos nodos.

Por ello, el costo por revisión de vecinos es `O(m)`, y el recorrido de nodos agrega `O(n)`.

La complejidad total es:

`O(n + m)`

##### DSATUR

El algoritmo **DSATUR** (Degree of Saturation) funciona de la siguiente manera:

1. Inicialmente, todos los nodos están sin colorear.
2. En cada paso, se selecciona el nodo con **mayor saturación** (es decir, el que tiene más colores diferentes ya asignados entre sus vecinos).  
   - Si hay empate, se selecciona el nodo con **mayor grado** o según prioridad definida.
3. Se asigna al nodo el **menor color disponible** que no esté usado por sus vecinos.
4. Se repite hasta que todos los nodos estén coloreados.

#### Análisis de complejidad

Sea `n` el número de nodos y `m` el número de aristas.

En cada iteración de DSATUR se realizan dos operaciones principales:

1. Seleccionar el nodo con mayor saturación.
   En la implementación actual, esta selección revisa y ordena candidatos, lo que en el peor caso es del orden de `O(n log n)` por iteración.
2. Revisar los colores de los vecinos del nodo seleccionado para elegir el menor color disponible.
   Esta parte cuesta `O(grado del nodo)`.

Como el proceso se repite para todos los nodos:

- El costo acumulado de selección es `O(n^2 log n)`.
- El costo acumulado de revisar vecinos es `O(m)`.

Por lo tanto, la complejidad total de esta implementación es:

`O(n^2 log n + m)`

### Tarea 6

Proponer una implementación computacional para al menos uno de los algoritmos propuestos para el caso general de resolver conflictos mediante el coloreo grafos.

#### Ejecución

``` Dart
Map<T, int> call(Map<T, Set<T>> adjacency, {List<T>? visitOrder}) {
    final normalized = _normalizeUndirectedAdjacency(adjacency);
    if (normalized.isEmpty) {
      return <T, int>{};
    }

    print('visitOrder: $visitOrder');
    print('normalized: $normalized');

    final priorityByNode = _buildPriorityByNode(normalized, visitOrder);
    final colorByNode = <T, int>{};
    final uncolored = normalized.keys.toSet();
    final saturationByNode = <T, Set<int>>{
      for (final node in normalized.keys) node: <int>{},
    };

    while (uncolored.isNotEmpty) {
      final node = _pickNextNode(
        uncolored,
        normalized,
        saturationByNode,
        priorityByNode,
      );
      final usedColors = <int>{};

      for (final neighbor in normalized[node] ?? <T>{}) {
        final color = colorByNode[neighbor];
        if (color != null) {
          usedColors.add(color);
        }
      }

      var selectedColor = 0;
      while (usedColors.contains(selectedColor)) {
        selectedColor++;
      }

      colorByNode[node] = selectedColor;
      uncolored.remove(node);

      for (final neighbor in normalized[node] ?? <T>{}) {
        if (uncolored.contains(neighbor)) {
          saturationByNode[neighbor]!.add(selectedColor);
        }
      }
    }

    return colorByNode;
  }

  /// Pick the next node to color based on saturation and degree.
  T _pickNextNode(
    Set<T> uncolored,
    Map<T, Set<T>> adjacency,
    Map<T, Set<int>> saturationByNode,
    Map<T, int> priorityByNode,
  ) {
    final nodes = uncolored.toList()
      ..sort((a, b) {
        final saturationComparison = saturationByNode[b]!.length.compareTo(
          saturationByNode[a]!.length,
        );
        if (saturationComparison != 0) {
          return saturationComparison;
        }

        final degreeComparison = adjacency[b]!.length.compareTo(
          adjacency[a]!.length,
        );
        if (degreeComparison != 0) {
          return degreeComparison;
        }

        final priorityA = priorityByNode[a];
        final priorityB = priorityByNode[b];
        if (priorityA != null && priorityB != null) {
          final priorityComparison = priorityA.compareTo(priorityB);
          if (priorityComparison != 0) {
            return priorityComparison;
          }
        } else if (priorityA != null) {
          return -1;
        } else if (priorityB != null) {
          return 1;
        }

        return a.toString().compareTo(b.toString());
      });

    return nodes.first;
  }

  Map<T, int> _buildPriorityByNode(
    Map<T, Set<T>> adjacency,
    List<T>? visitOrder,
  ) {
    if (visitOrder == null) {
      return <T, int>{};
    }

    final priorityByNode = <T, int>{};
    for (var i = 0; i < visitOrder.length; i++) {
      final node = visitOrder[i];
      if (!adjacency.containsKey(node)) {
        continue;
      }
      priorityByNode.putIfAbsent(node, () => i);
    }

    return priorityByNode;
  }

  /// Normalize undirected adjacency graph to ensure all nodes are connected.
  Map<T, Set<T>> _normalizeUndirectedAdjacency(Map<T, Set<T>> adjacency) {
    final normalized = <T, Set<T>>{};

    for (final entry in adjacency.entries) {
      normalized.putIfAbsent(entry.key, () => <T>{});
      for (final neighbor in entry.value) {
        if (neighbor == entry.key) {
          continue;
        }
        normalized.putIfAbsent(neighbor, () => <T>{});
        normalized[entry.key]!.add(neighbor);
        normalized[neighbor]!.add(entry.key);
      }
    }

    return normalized;
  }
```


## Solución a preguntas guía:

### Pregunta 1
¿Cómo se construye el grafo de conflictos a partir de datos de clases?

#### Ejecución
La pregunta queda resuelta y demostrada en la solución de la **Tarea 1**.

### Pregunta 2
¿Cuál es el número mínimo de bloques requerido para un conjunto de clases dado?

#### Ejecución
La respuesta se encuentra en la **Tarea 5**, donde se explica el número cromático `x(G)` como mínimo de bloques de tiempo.

Para el caso de la Tabla 1, el mínimo es **3 bloques**.

### Pregunta 3
¿Qué algoritmo de coloreo produce soluciones de mejor calidad (menos bloques) bajo el mismo tiempo de cómputo?

#### Ejecución
Con los datos usados en este documento, **DSATUR** obtiene una solución de mejor calidad: **3 bloques**, frente a **4 bloques** de **Greedy**.

Sin embargo, esta mejora no se logra con el mismo costo computacional. En esta implementación:

- **Greedy:** `O(n + m)`
- **DSATUR:** `O(n^2 log n + m)`

En este caso **DSATUR** da mejor calidad, pero con mayor tiempo de cómputo; en general no garantiza siempre menos colores que Greedy.

### Pregunta 4
¿Cómo se valida que el horario resultante no contiene conflictos?

#### Ejecución
Un horario es válido si para toda arista `(u, v)` del grafo se cumple que `color(u) != color(v)`.

Esto significa que dos clases en conflicto (mismo grupo o mismo docente) nunca quedan asignadas al mismo bloque.

### Pregunta 5
¿En una implementación computacional qué estructura de datos es adecuada para representar los datos del grafo de conflictos?

#### Ejecución
La estructura adecuada y usada en esta implementación es una **lista de adyacencia**:

`Map<T, Set<T>> adjacency`

Permite:

- consultar vecinos de cada nodo de forma eficiente,
- recorrer aristas para validar conflictos,
- aplicar algoritmos como Greedy y DSATUR de manera directa.

### Pregunta 6
Cómo se quiere obtener un óptimo minimal sobre el número de bloques de tiempo, ¿cómo saber si ya obtuvo tal valor óptimo?

#### Ejecución
La respuesta conceptual se encuentra en la **Tarea 5** (criterios con número cromático y clique máximo).

En práctica, se confirma el óptimo cuando:

1. Se obtiene una coloración válida con `k` bloques.
2. Se demuestra que no existe coloración válida con `k - 1` bloques.
3. Además, se puede usar un límite inferior como el tamaño del clique máximo para reforzar la prueba.

### Pregunta 7


## Referencias

1. Chekuri, C., & Pitt, L. (2015, April 23). NP-completeness of 3-color and SAT [Diapositivas de clase]. CS 374: Algorithms & Models of Computation, University of Illinois Urbana-Champaign. <https://courses.grainger.illinois.edu/cs498374/sp2015/slides/24-3color-Cook-Levin.pdf>
