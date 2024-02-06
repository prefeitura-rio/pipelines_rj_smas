WITH escolaridade AS (
    SELECT
    id_membro_familia,
    data_particao,
      COALESCE(
        ano_serie_frequenta,
        ultimo_ano_serie_frequentou
      ) AS escolaridade_fundamental,

      COALESCE(
        curso_frequenta,
        curso_mais_elevado_frequentou
    ) AS escolaridade
  FROM `rj-smas.protecao_social_cadunico.escolaridade`

),

membro AS (
    SELECT
    data_particao,
    id_membro_familia,
    id_familia,
    sexo AS genero,
    raca_cor AS raca,
    CASE
      WHEN DATE_DIFF(CURRENT_DATE, data_nascimento, YEAR)  BETWEEN 0 AND 6 THEN '0-6'
      WHEN DATE_DIFF(CURRENT_DATE, data_nascimento, YEAR)  BETWEEN 7 AND 9 THEN '7-9'
      WHEN DATE_DIFF(CURRENT_DATE, data_nascimento, YEAR)  BETWEEN 10 AND 14 THEN '10-14'
      WHEN DATE_DIFF(CURRENT_DATE, data_nascimento, YEAR)  BETWEEN 15 AND 17 THEN '15-17'
      WHEN DATE_DIFF(CURRENT_DATE, data_nascimento, YEAR)  BETWEEN 18 AND 29 THEN '18-29'
      WHEN DATE_DIFF(CURRENT_DATE, data_nascimento, YEAR)  BETWEEN 30 AND 59 THEN '30-59'
      ELSE '60+'
    END AS faixa_etaria,
  FROM `rj-smas.protecao_social_cadunico.identificacao_primeira_pessoa`
),

membro_escolaridade AS (
  SELECT
    m.id_familia,
    m.data_particao,
    -- CASE
    --   WHEN f.id_cras_creas IS NULL THEN "Não Informado"
    --   ELSE f.id_cras_creas
    -- END AS id_cras_creas,
    m.id_membro_familia,
    m.genero,
    m.raca,
    m.faixa_etaria,
    e.escolaridade_fundamental,
    e.escolaridade
  FROM membro m
  LEFT JOIN escolaridade e
    ON (m.id_membro_familia = e.id_membro_familia)
      AND (m.data_particao = e.data_particao)
  LEFT JOIN `rj-smas.protecao_social_cadunico.familia` f
  ON (m.id_familia = f.id_familia)
      AND (m.data_particao = f.data_particao)
)


SELECT
  data_particao,
  faixa_etaria,
  genero,
  raca,
  escolaridade,
  COUNT(*) AS numero_pessoas,
  SUM(COUNT(DISTINCT id_membro_familia)) OVER(PARTITION BY data_particao) AS total_membros,
FROM membro_escolaridade
GROUP BY 1, 2, 3, 4, 5
ORDER BY 1, 2, 3, 4, 5