# OSINT Social Analyzer

## Objetivo

Crear una aplicación que permita organizar y analizar
información disponible públicamente en fuentes autorizadas
y generar un informe profesional con las evidencias y
fuentes utilizadas.

## Usuario objetivo

Investigadores OSINT, periodistas, analistas, investigadores
de seguridad y profesionales que necesiten organizar
información pública.

## Problema

Actualmente el investigador debe revisar múltiples fuentes
manualmente y organizar los resultados en documentos.

La aplicación busca centralizar y estructurar ese proceso.

## Flujo principal

1. El usuario crea una investigación.
2. Introduce una o más URLs públicas.
3. El sistema valida las fuentes.
4. Se recopila la información permitida.
5. Los datos se normalizan.
6. Se eliminan duplicados.
7. Se clasifican los resultados.
8. Se muestran las fuentes originales.
9. El usuario revisa los resultados.
10. El usuario genera un informe.

## Entrada

El usuario puede introducir:

- URL de sitio web
- URL de perfil público
- URL de contenido público
- Nombre de organización o proyecto

## Resultado

La aplicación debe mostrar:

- Fuente
- URL
- Fecha de consulta
- Información encontrada
- Categoría
- Evidencia asociada
- Nivel de confianza cuando corresponda

## Informe

El usuario podrá generar:

- PDF
- HTML

El informe debe contener:

- Título
- Fecha
- Objetivo
- Fuentes analizadas
- Resumen
- Hallazgos
- Evidencias
- URLs de origen
- Limitaciones del análisis

## Restricciones

La aplicación no debe:

- acceder a perfiles privados;
- evadir autenticación;
- saltar controles de acceso;
- obtener credenciales;
- realizar scraping donde esté prohibido;
- presentar inferencias como hechos;
- generar diagnósticos psicológicos;
- inferir atributos sensibles de una persona.

## Criterios de aceptación

Una investigación se considera completada cuando:

- Las fuentes fueron registradas.
- Los resultados están asociados a su fuente.
- Los datos duplicados fueron tratados.
- Los resultados pueden ser revisados.
- El informe puede generarse.
- El informe conserva las fuentes originales.