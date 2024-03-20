SELECT
  cond_rua.data_particao,
  motivo,
  COUNT(DISTINCT 
    CASE WHEN renda.resposta = 1 THEN cond_rua.id_membro_familia ELSE NULL END) AS numero_pessoas_nesse_motivo,
  COUNT(DISTINCT cond_rua.id_membro_familia) AS numero_pessoas_total,
FROM `rj-smas.protecao_social_cadunico.condicao_rua` cond_rua
INNER JOIN `rj-smas.protecao_social_cadunico.identificacao_primeira_pessoa` identificacao_primeira_pessoa
  ON identificacao_primeira_pessoa.id_familia = cond_rua.id_familia
  AND identificacao_primeira_pessoa.id_membro_familia = cond_rua.id_membro_familia
  AND identificacao_primeira_pessoa.data_particao = cond_rua.data_particao 
  AND identificacao_primeira_pessoa.estado_cadastral = "Cadastrado",
UNNEST([
  STRUCT('Álcool' AS motivo, SAFE_CAST(condicao_rua_alcool AS FLOAT64) AS resposta),
  STRUCT('Ameaça' AS motivo, SAFE_CAST(condicao_rua_ameaca AS FLOAT64) AS resposta),
  STRUCT('Desemprego' AS motivo, SAFE_CAST(condicao_rua_desemprego AS FLOAT64) AS resposta),
  STRUCT('Não respondeu' AS motivo, SAFE_CAST(condicao_rua_nao_respondeu AS FLOAT64) AS resposta),
  STRUCT('Não sabe' AS motivo, SAFE_CAST(condicao_rua_nao_sabe AS FLOAT64) AS resposta),
  STRUCT('Outro' AS motivo, SAFE_CAST(condicao_rua_outro AS FLOAT64) AS resposta),
  STRUCT('Perda moradia' AS motivo, SAFE_CAST(condicao_rua_perda_moradia AS FLOAT64) AS resposta),
  STRUCT('Preferência' AS motivo, SAFE_CAST(condicao_rua_preferencia AS FLOAT64) AS resposta),
  STRUCT('Problemas familiares' AS motivo, SAFE_CAST(condicao_rua_problemas_familiares AS FLOAT64) AS resposta),
  STRUCT('Saúde' AS motivo, SAFE_CAST(condicao_rua_saude AS FLOAT64) AS resposta),
  STRUCT('Trabalho' AS motivo, SAFE_CAST(condicao_rua_trabalho AS FLOAT64) AS resposta)
]) AS renda
GROUP BY cond_rua.data_particao, motivo
ORDER BY cond_rua.data_particao
