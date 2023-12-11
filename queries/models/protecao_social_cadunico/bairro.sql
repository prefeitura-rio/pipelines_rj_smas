WITH address AS (
    SELECT
        bairro_limpo AS nome_limpo_cadunico,
        SUM(count) as count
    FROM `rj-smas.protecao_social_cadunico.endereco`
    GROUP BY  1
),

address_percentage AS (
  SELECT
    a.nome_limpo_cadunico,
    count,
    ROUND(count * 100.0 / SUM(count) OVER (), 5) AS percentage,
  FROM address a
  ORDER BY count DESC
),

bairro AS (
  SELECT
    id_bairro,
    nome,
    subprefeitura,
    geometry_wkt,
    REGEXP_REPLACE(REGEXP_REPLACE(LOWER(NORMALIZE(nome, NFD)), r'[^a-z0-9]+', ''), r'\s+', ' ') AS nome_limpo
  FROM `rj-escritorio-dev.dados_mestres.bairro`

)

SELECT
    id_bairro,
    b.nome,
    b.nome_limpo,
    a.nome_limpo_cadunico,
    a.count,
    a.percentage,
    subprefeitura,
    geometry_wkt,
    ROUND(SUM(percentage) OVER (ORDER BY count DESC), 2) AS cumulative_percentage,
FROM address_percentage a
FULL OUTER JOIN bairro b
  ON a.nome_limpo_cadunico = b.nome_limpo
ORDER BY count DESC