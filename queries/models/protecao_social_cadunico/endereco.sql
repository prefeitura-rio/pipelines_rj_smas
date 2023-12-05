WITH endereco AS (
  SELECT 
    CONCAT(
      CASE 
        WHEN tipo_logradouro IS NULL THEN ""
        ELSE tipo_logradouro
      END,
      " ",
      CASE 
        WHEN titulo_logradouro IS NULL THEN ""
        ELSE titulo_logradouro
      END,
      " ",
      CASE 
        WHEN logradouro IS NULL THEN ""
        ELSE logradouro
      END,
      ", ",
      CASE 
        WHEN numero_logradouro IS NULL THEN ""
        ELSE CAST(numero_logradouro AS STRING)
      END,
      " - ",
      CASE 
        WHEN localidade IS NULL THEN ""
        ELSE localidade
      END,
      " - ",
      CASE 
        WHEN unidade_territorial IS NULL THEN ""
        ELSE unidade_territorial
      END
    ) AS address
FROM `rj-smas.protecao_social_cadunico.identificacao_controle` 
)

SELECT 
  address,
  count(address) as count,
  ROUND(COUNT(address) * 100.0 / (SELECT COUNT(*) FROM endereco), 2) AS percentage
FROM endereco
GROUP BY 1
ORDER BY 2 DESC