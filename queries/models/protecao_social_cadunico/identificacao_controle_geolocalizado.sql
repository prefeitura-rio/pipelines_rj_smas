
WITH endereco_geo AS (
  SELECT
    t1.address,
    t2.endereco,
    t1.geometry,
    t2.bairro,
  FROM `rj-smas.protecao_social_cadunico.endereco_geolocalizado` t1
  LEFT JOIN `rj-smas.protecao_social_cadunico.endereco` t2
    ON t1.address = t2.address
),

id_controle AS (
  SELECT
    *,
    REGEXP_REPLACE(
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
      ), r'\s+', ' '
    ) AS endereco_controle,
  FROM `rj-smas.protecao_social_cadunico.identificacao_controle`
  WHERE data_particao >= '2023-11-01'
)

SELECT
   t2.* EXCEPT(endereco_controle),
   t1.* EXCEPT(endereco)
FROM endereco_geo t1
LEFT JOIN id_controle t2
  ON t1.endereco = t2.endereco_controle