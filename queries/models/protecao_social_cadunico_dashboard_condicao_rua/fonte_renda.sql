SELECT
  cond_rua.data_particao,
  fonte_renda,
  COUNT(DISTINCT 
    CASE WHEN renda.resposta = 1 THEN cond_rua.id_membro_familia ELSE NULL END) AS numero_pessoas_nesse_trabalho,
  COUNT(DISTINCT cond_rua.id_membro_familia) AS numero_pessoas_total,
  ROUND(100*COUNT(DISTINCT CASE
    WHEN ganha_dinheiro_carregador = '1' OR
         ganha_dinheiro_catador = '1' OR
         ganha_dinheiro_construcao_civil = '1' OR
         ganha_dinheiro_flanelinha = '1' OR
         ganha_dinheiro_outro = '1' OR
         ganha_dinheiro_pedinte = '1' OR
         ganha_dinheiro_sevicos_gerais = '1' OR
         ganha_dinheiro_vendas = '1'
  THEN cond_rua.id_membro_familia ELSE NULL END)/COUNT(DISTINCT cond_rua.id_membro_familia), 2) AS porcentagem_com_atividade_remunerada
FROM `rj-smas.protecao_social_cadunico.condicao_rua` cond_rua
INNER JOIN `rj-smas.protecao_social_cadunico.identificacao_primeira_pessoa` identificacao_primeira_pessoa
  ON identificacao_primeira_pessoa.id_familia = cond_rua.id_familia
  AND identificacao_primeira_pessoa.id_membro_familia = cond_rua.id_membro_familia
  AND identificacao_primeira_pessoa.data_particao = cond_rua.data_particao 
  AND identificacao_primeira_pessoa.estado_cadastral = "Cadastrado",
UNNEST([
  STRUCT('Carregador' AS fonte_renda, SAFE_CAST(ganha_dinheiro_carregador AS FLOAT64) AS resposta),
  STRUCT('Catador' AS fonte_renda, SAFE_CAST(ganha_dinheiro_catador AS FLOAT64) AS resposta),
  STRUCT('Construção civil' AS fonte_renda, SAFE_CAST(ganha_dinheiro_construcao_civil AS FLOAT64) AS resposta),
  STRUCT('Flanelinha' AS fonte_renda, SAFE_CAST(ganha_dinheiro_flanelinha AS FLOAT64) AS resposta),
  STRUCT('Não respondeu' AS fonte_renda, SAFE_CAST(ganha_dinheiro_nao_respondeu AS FLOAT64) AS resposta),
  STRUCT('Outro' AS fonte_renda, SAFE_CAST(ganha_dinheiro_outro AS FLOAT64) AS resposta),
  STRUCT('Pedinte' AS fonte_renda, SAFE_CAST(ganha_dinheiro_pedinte AS FLOAT64) AS resposta),
  STRUCT('Serviços gerais' AS fonte_renda, SAFE_CAST(ganha_dinheiro_sevicos_gerais AS FLOAT64) AS resposta),
  STRUCT('Pedinte' AS fonte_renda, SAFE_CAST(ganha_dinheiro_pedinte AS FLOAT64) AS resposta),
  STRUCT('Vendas' AS fonte_renda, SAFE_CAST(ganha_dinheiro_vendas AS FLOAT64) AS resposta)
]) AS renda
GROUP BY cond_rua.data_particao, fonte_renda
ORDER BY cond_rua.data_particao;
