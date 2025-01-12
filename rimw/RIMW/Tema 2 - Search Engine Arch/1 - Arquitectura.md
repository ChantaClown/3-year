#RIMW 

![[se_arch.png]]
## Core Concepts
### Information need
El objetivo de un sistema IR es _satisfacer las necesidades de información del usuario_
### Query
_Representación_ de las necesidades de información de un usuario; en lenguaje natural o alguna otra forma
### Documento
Representación de la información que pueda satisfacer a un usuario. _NO tiene por que ser un .doc, .pdf, etc. puede ser una imagen, canción, web..._
### Relevancia
Relación entre el _documento_ y la _información que necesita el usuario_. Puede ser de tema, semantica, temporal...
## Componentes Clave de un SE
### Web Crawler
Programa automático que busca sistemáticamente en la web para obtener contenido, indexar y "updatear"
### Analizador de Documentos e Indexador
Maneja el contenido del _crawler_ y otorga acceso eficiente a los [[1 - Arquitectura#Core Concepts#Documento|Documentos]].
### Query Parser
Compila las querys del usuario a un _sistema de representación manejado_
### Ranking Model
Organiza los [[1 - Arquitectura#Core Concepts#Documento|Documentos]] en relevancia a la query dada
### Result Display
Presenta los resultados obtenidos a los usuarios para satisfacer sus necesidades
### Retrieval Evaluation
Otorga calidad a los resultados generados
### FeedBack de Relevancia
Propaga la _calidad del razonamiento de vuelta al sistema_ para refinamiento
### Search Query Logs
Guarda las busquedas del usuario
### User Modeling
Personalización del SE para cada usuario
