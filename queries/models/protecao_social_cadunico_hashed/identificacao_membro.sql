CREATE OR REPLACE TABLE `rj-smas-dev-432320.protecao_social_cadunico.identificacao_membro` AS
with raw_table AS
(
  SELECT
    id_membro_familia,
    id_raca_cor,
    id_sexo,
    DATE_DIFF(CURRENT_DATE, CAST(data_nascimento AS DATE), YEAR) idade,
    data_particao
  FROM `rj-smas.protecao_social_cadunico.identificacao_membro`
  WHERE data_particao = "2024-07-01"
  AND id_estado_cadastral != "4"
)
SELECT
  * EXCEPT(idade),
  CASE
    WHEN idade < 12 THEN 'Criança'
    WHEN idade BETWEEN 12 AND 17 THEN 'Adolescente'
    WHEN idade BETWEEN 18 AND 24 THEN 'Jovem Adulto'
    WHEN idade BETWEEN 25 AND 39 THEN 'Adulto Jovem'
    WHEN idade BETWEEN 40 AND 59 THEN 'Adulto'
    ELSE 'Idoso'
  END AS idade
FROM
  raw_table;