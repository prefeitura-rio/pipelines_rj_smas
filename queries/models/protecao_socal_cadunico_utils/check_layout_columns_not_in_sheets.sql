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