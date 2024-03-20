WITH first_last_date AS (
  SELECT
    cond_rua.id_membro_familia,
    MIN(cond_rua.data_particao) first_homelessness_date,
    MAX(cond_rua.data_particao) last_homelessness_date,
  FROM
    `rj-smas.protecao_social_cadunico.condicao_rua` cond_rua
  INNER JOIN `rj-smas.protecao_social_cadunico.identificacao_primeira_pessoa` identificacao_primeira_pessoa
  ON identificacao_primeira_pessoa.id_familia = cond_rua.id_familia
  AND identificacao_primeira_pessoa.id_membro_familia = cond_rua.id_membro_familia
  AND identificacao_primeira_pessoa.data_particao = cond_rua.data_particao 
  AND identificacao_primeira_pessoa.estado_cadastral = "Cadastrado"
  GROUP BY cond_rua.id_membro_familia
),

max_date AS (
  SELECT MAX(data_particao) last_update
  FROM `rj-smas.protecao_social_cadunico.condicao_rua`
)

SELECT
  id_membro_familia,
  first_homelessness_date,
  last_homelessness_date,
  DATE_DIFF(last_update, first_homelessness_date, month) duration_homelessness,
  DATE_DIFF(last_update, last_homelessness_date, month) duration_homelessness_ended,
  CASE WHEN DATE_TRUNC(last_update, MONTH) = DATE_TRUNC(first_homelessness_date, MONTH) THEN 1 ELSE 0 END new_homelessness,
  CASE WHEN DATE_DIFF(last_update, last_homelessness_date, month) BETWEEN 6 AND 12 THEN 1 ELSE 0 END ended_homelessness_last_year,
FROM first_last_date
CROSS JOIN max_date
ORDER BY 
    id_membro_familia
