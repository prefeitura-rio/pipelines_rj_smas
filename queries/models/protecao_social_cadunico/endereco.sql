WITH endereco_tb AS (
  SELECT
    CONCAT(
      CASE
        WHEN tipo_logradouro IS NULL THEN ""
        WHEN SAFE_CAST(tipo_logradouro AS INT64) IS NOT NULL THEN ""
        ELSE TRIM(REGEXP_REPLACE(REGEXP_REPLACE(tipo_logradouro, r'\s+', ' '), r'[0-9]', ''))

      END,
      " ",
      CASE
        WHEN titulo_logradouro IS NULL THEN ""
        WHEN SAFE_CAST(titulo_logradouro AS INT64) IS NOT NULL THEN ""
        ELSE TRIM(REGEXP_REPLACE(REGEXP_REPLACE(titulo_logradouro, r'\s+', ' '), r'[0-9]', ''))
      END,
      " ",
      CASE
        WHEN logradouro IS NULL THEN ""
        ELSE TRIM(REGEXP_REPLACE(logradouro, r'\s+', ' '))
      END,
      " ",
      CASE
        WHEN numero_logradouro IS NULL THEN "S/N"
        ELSE CAST(numero_logradouro AS STRING)
      END,
      ", RIO DE JANEIRO, RJ, BRASIL"
    ) AS address,
    CASE
      WHEN localidade IS NULL THEN ""
      WHEN SAFE_CAST(localidade AS INT64) IS NOT NULL THEN ""
      ELSE TRIM(REGEXP_REPLACE(REGEXP_REPLACE(localidade, r'\s+', ' '), r'[0-9]', ''))
    END AS bairro_cadunico,
    REGEXP_REPLACE(
      REGEXP_REPLACE(
        LOWER(NORMALIZE(CASE
          WHEN localidade IS NULL THEN ""
          WHEN SAFE_CAST(localidade AS INT64) IS NOT NULL THEN ""
          ELSE TRIM(REGEXP_REPLACE(REGEXP_REPLACE(localidade, r'\s+', ' '), r'[0-9]', ''))
        END, NFD)), r'[^a-z0-9]+', ''),
      r'\s+', ' '
    ) AS bairro_limpo_cadunico,
  FROM `rj-smas.protecao_social_cadunico.identificacao_controle`
),

address_tb AS (
    SELECT
      REGEXP_REPLACE(address, r'\s+', ' ') AS address,
      bairro_cadunico,
      bairro_limpo_cadunico,
      count(address) as count,
      ROUND(COUNT(address) * 100.0 / (SELECT COUNT(*) FROM endereco_tb), 2) AS percentage,
      ROUND(SUM(COUNT(address) * 100.0 / (SELECT COUNT(*) FROM endereco_tb)) OVER (ORDER BY COUNT(address) DESC) , 2) AS cumulative_percentage,
  FROM endereco_tb
  GROUP BY 1, 2, 3
  ORDER BY 4 DESC
),

address_prep_tb AS (
    SELECT
        address,
        SPLIT(address, ',') AS address_array,
        bairro_cadunico,
        bairro_limpo_cadunico,
        count,
        percentage,
        cumulative_percentage,
    FROM address_tb
),

bairro AS (
  SELECT
    id_bairro,
    bairro_limpo,
    bairro,
    subprefeitura,
  FROM `rj-smas.protecao_social_cadunico.bairro`
)

SELECT
  REGEXP_REPLACE(
    CONCAT(
      address_array[OFFSET(0)],
      ', ',
      CASE
        WHEN b.bairro IS NULL THEN ""
        ELSE UPPER(b.bairro)
      END,
      ', ',
      ARRAY_TO_STRING(ARRAY(SELECT x FROM UNNEST(address_array) x WITH OFFSET o WHERE o > 0), ', ')
    ), r',\s*,',","
  ) AS address,
  b.id_bairro,
  b.bairro AS bairro,
  b.bairro_limpo,
  a.bairro_cadunico,
  a.bairro_limpo_cadunico,
  b.subprefeitura,
  a.count,
  a.percentage,
  a.cumulative_percentage,
FROM address_prep_tb a
LEFT JOIN bairro b
  ON a.bairro_limpo_cadunico = b.bairro_limpo
ORDER BY count DESC
