#RIMW

La __Recuperacion de la Informacion__ consiste en _obtener recursos de información_ relevantes a la información presente en una _colección de informacion_.

La _RI_ comenzo por la __Sobrecarga de Información__, es decir, la dificultad que tiene una persona de entender o resolver un problema por la presencia de _demasiada información_. 
## Como se realiza la RI

![[engine_schema.png]]

_NOTA: estas definiciones se expanden en [[1 - Arquitectura#Core Concepts|temas posteriores]]_
### Crawler e Indexer
Buscan/Recuperan la información _(Crawler)_ solicitada para despues clasificarla _(Indexer)_
### Query Parser
Procesa la "Query" del usuario para poder realizar la busqueda
### Document Analyzer
Procesa la información pedida presente en el documento, _elimina tags de html_, filtrado por "Stopwords"(Palabras que no aportan)
### Ranking Model
Organiza el listado de paginas, elementos... recuperados para mostrarselo al usuario
## Conceptos Importantes
### Representación de Querys
- _Gap léxico_: "Say VS Said"
- _Gap semantico_: Ranking Model VS Retrieval Method
### Representación de Documentos
- DataStructure espacial para acceso eficiente
- Gap léxico y semantico
### Modelo Recuperador
- Algoritmos que encuentras el __documento más relevante__ para la información dada
	- _La __relevacia__ es la relación entre la búsqueda y el tópico_
- Eficiencia VS Eficacia

![[ir_vs_db.png]]
![[ir_vs_nlp.png]]