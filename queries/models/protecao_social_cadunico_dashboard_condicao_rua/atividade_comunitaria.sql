WITH data_temp  AS (
  SELECT 
    cond_rua.data_particao, 
    atividade_comunitaria_associacao,
    atividade_comunitaria_cooperativa,
    atividade_comunitaria_escola,
    atividade_comunitaria_nao_respondeu,
    atividade_comunitaria_nao_sabe,
    atibidade_comunitaria_movimento_social
  FROM `rj-smas.protecao_social_cadunico.condicao_rua` cond_rua
  INNER JOIN `rj-smas.protecao_social_cadunico.identificacao_primeira_pessoa` identificacao_primeira_pessoa
    ON identificacao_primeira_pessoa.id_familia = cond_rua.id_familia
    AND identificacao_primeira_pessoa.id_membro_familia = cond_rua.id_membro_familia
    AND identificacao_primeira_pessoa.data_particao = cond_rua.data_particao 
    AND identificacao_primeira_pessoa.estado_cadastral = "Cadastrado"
)

SELECT data_particao, 
       'Total Associação' AS categoria, 
       SUM(SAFE_CAST(atividade_comunitaria_associacao AS INT64)) AS total 
FROM data_temp
GROUP BY data_particao

UNION ALL

SELECT data_particao, 
       'Total Cooperativa' AS categoria, 
       SUM(SAFE_CAST(atividade_comunitaria_cooperativa AS INT64)) AS total 
FROM data_temp
GROUP BY data_particao

UNION ALL

SELECT data_particao, 
       'Total Escola' AS categoria, 
       SUM(SAFE_CAST(atividade_comunitaria_escola AS INT64)) AS total 
FROM data_temp
GROUP BY data_particao

UNION ALL

SELECT data_particao, 
       'Total Movimento Social' AS categoria, 
       SUM(SAFE_CAST(atibidade_comunitaria_movimento_social AS INT64)) AS total 
FROM data_temp
GROUP BY data_particao

UNION ALL

SELECT data_particao, 
       'Total Não Respondeu' AS categoria, 
       SUM(SAFE_CAST(atividade_comunitaria_nao_respondeu AS INT64)) AS total 
FROM data_temp
GROUP BY data_particao

UNION ALL

SELECT data_particao, 
       'Total Não Sabe' AS categoria, 
       SUM(SAFE_CAST(atividade_comunitaria_nao_sabe AS INT64)) AS total 
FROM data_temp
GROUP BY data_particao
