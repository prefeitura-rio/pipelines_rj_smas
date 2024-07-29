# if this query return some column, them need to put this columns in google sheets
# https://docs.google.com/spreadsheets/d/1VgtSVom_s4QsJoOws6caPZxGfwYrpjpoSjbOrqhRbM8/edit?gid=542906575#gid=542906575

WITH layout_unique_columns AS (
SELECT
    column as coluna_layout,
    max(descricao) as descricao
FROM `rj-smas.protecao_social_cadunico_staging.layout`
GROUP BY 1
),

sheets_unique_columns AS (
SELECT
    column as coluna_sheets
FROM `rj-smas.protecao_social_cadunico_staging.layout_dicionario_colunas`

)

SELECT
    t2.coluna_sheets,
    t1.coluna_layout,
    t1.descricao
FROM layout_unique_columns t1
FULL OUTER JOIN sheets_unique_columns t2
ON t1.coluna_layout = t2.coluna_sheets
WHERE coluna_sheets IS NULL
ORDER BY coluna_layout