SELECT
  data_particao,
  ROUND(100 * SAFE_DIVIDE(COUNT(DISTINCT id_familia) , SUM(COUNT(DISTINCT id_familia)) OVER(PARTITION BY data_particao)),4) AS porcentagem,
  COUNT(DISTINCT id_familia) AS numero_familias,
  AVG(pessoas_domicilio) AS media_pessoas_por_familia
FROM `rj-smas.protecao_social_cadunico.familia`
GROUP BY 1
ORDER BY 1