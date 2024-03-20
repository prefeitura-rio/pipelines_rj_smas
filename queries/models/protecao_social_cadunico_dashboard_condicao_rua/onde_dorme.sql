WITH media_dias AS (
  SELECT
    cond_rua.data_particao,
    ROUND(AVG(CASE WHEN 
      COALESCE(dorme_rua_vezes_semana, 0) +
      COALESCE(dorme_domicilio_particular_vezes_semana, 0) +
      COALESCE(dorme_albergue_vezes_semana, 0) +
      COALESCE(dorme_outro_vezes_semana, 0) = 7 
      THEN COALESCE(dorme_rua_vezes_semana,0) ELSE dorme_rua_vezes_semana
    END), 2) dorme_rua_vezes_semana,
    ROUND(AVG(CASE WHEN 
      COALESCE(dorme_rua_vezes_semana, 0) +
      COALESCE(dorme_domicilio_particular_vezes_semana, 0) +
      COALESCE(dorme_albergue_vezes_semana, 0) +
      COALESCE(dorme_outro_vezes_semana, 0) = 7 
      THEN COALESCE(dorme_domicilio_particular_vezes_semana,0) ELSE dorme_domicilio_particular_vezes_semana
    END), 2) dorme_domicilio_particular_vezes_semana,
    ROUND(AVG(CASE WHEN 
      COALESCE(dorme_rua_vezes_semana, 0) +
      COALESCE(dorme_domicilio_particular_vezes_semana, 0) +
      COALESCE(dorme_albergue_vezes_semana, 0) +
      COALESCE(dorme_outro_vezes_semana, 0) = 7 
      THEN COALESCE(dorme_albergue_vezes_semana,0) ELSE dorme_albergue_vezes_semana
    END), 2) dorme_albergue_vezes_semana,
    ROUND(AVG(CASE WHEN 
      COALESCE(dorme_rua_vezes_semana, 0) +
      COALESCE(dorme_domicilio_particular_vezes_semana, 0) +
      COALESCE(dorme_albergue_vezes_semana, 0) +
      COALESCE(dorme_outro_vezes_semana, 0) = 7 
      THEN COALESCE(dorme_outro_vezes_semana,0) ELSE dorme_outro_vezes_semana
    END), 2) dorme_outro_vezes_semana,
  FROM `rj-smas.protecao_social_cadunico.condicao_rua` cond_rua
  INNER JOIN `rj-smas.protecao_social_cadunico.identificacao_primeira_pessoa` identificacao_primeira_pessoa
  ON identificacao_primeira_pessoa.id_familia = cond_rua.id_familia
  AND identificacao_primeira_pessoa.id_membro_familia = cond_rua.id_membro_familia
  AND identificacao_primeira_pessoa.data_particao = cond_rua.data_particao 
  AND identificacao_primeira_pessoa.estado_cadastral = "Cadastrado"
  -- WHERE cond_rua.data_particao >= "2024-02-01"
  GROUP BY 1
  ORDER BY 1),

principais_lugares AS (
  SELECT
    cond_rua.data_particao,
    dorme,
    COUNT(DISTINCT 
      CASE WHEN renda.resposta = 1 THEN cond_rua.id_membro_familia ELSE NULL END) AS numero_pessoas_nessa_condicao,
    COUNT(DISTINCT cond_rua.id_membro_familia) AS numero_pessoas_total,
  FROM `rj-smas.protecao_social_cadunico.condicao_rua` cond_rua
  INNER JOIN `rj-smas.protecao_social_cadunico.identificacao_primeira_pessoa` identificacao_primeira_pessoa
  ON identificacao_primeira_pessoa.id_familia = cond_rua.id_familia
  AND identificacao_primeira_pessoa.id_membro_familia = cond_rua.id_membro_familia
  AND identificacao_primeira_pessoa.data_particao = cond_rua.data_particao 
  AND identificacao_primeira_pessoa.estado_cadastral = "Cadastrado",
  UNNEST([
    STRUCT('Albergue' AS dorme, SAFE_CAST(dorme_albergue AS FLOAT64) AS resposta),
    STRUCT('Domicílio Particular' AS dorme, SAFE_CAST(dorme_domicilio_particular AS FLOAT64) AS resposta),
    STRUCT('Rua' AS dorme, SAFE_CAST(dorme_rua AS FLOAT64) AS resposta)
  ]) AS renda
  -- WHERE cond_rua.data_particao >= "2024-02-01"
  GROUP BY data_particao, dorme
  ORDER BY data_particao
)

SELECT
  principais_lugares.data_particao,
  principais_lugares.dorme,
  principais_lugares.numero_pessoas_nessa_condicao,
  principais_lugares.numero_pessoas_total,
  media_dias.dorme_albergue_vezes_semana,
  media_dias.dorme_domicilio_particular_vezes_semana,
  media_dias.dorme_outro_vezes_semana,
  media_dias.dorme_rua_vezes_semana
FROM principais_lugares
INNER JOIN media_dias ON principais_lugares.data_particao = media_dias.data_particao

