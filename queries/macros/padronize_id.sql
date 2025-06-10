{% macro padronize_id(id_column) %}
    SAFE_CAST(REGEXP_REPLACE(REGEXP_REPLACE(TRIM({{ id_column }}), r'\.0$', ''), r'^0+', '') AS STRING)
{% endmacro %}