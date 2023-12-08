CREATE OR REPLACE TABLE `rj-smas.protecao_social_cadunico.endereco` AS (

WITH endereco AS (
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
    END AS bairro,
    REGEXP_REPLACE(
      REGEXP_REPLACE(
        LOWER(NORMALIZE(CASE 
          WHEN localidade IS NULL THEN ""
          WHEN SAFE_CAST(localidade AS INT64) IS NOT NULL THEN ""
          ELSE TRIM(REGEXP_REPLACE(REGEXP_REPLACE(localidade, r'\s+', ' '), r'[0-9]', ''))
        END, NFD)), r'[^a-z0-9]+', ''), 
      r'\s+', ' '
    ) AS bairro_limpo,
  FROM `rj-smas.protecao_social_cadunico.identificacao_controle` 
)

SELECT 
  REGEXP_REPLACE(address, r'\s+', ' ') AS address,
  bairro,
  bairro_limpo,
  count(address) as count,
  ROUND(COUNT(address) * 100.0 / (SELECT COUNT(*) FROM endereco), 2) AS percentage,
  ROUND(SUM(COUNT(address) * 100.0 / (SELECT COUNT(*) FROM endereco)) OVER (ORDER BY COUNT(address) DESC) , 2) AS cumulative_percentage,
FROM endereco
GROUP BY 1, 2, 3
ORDER BY 4 DESC
)
