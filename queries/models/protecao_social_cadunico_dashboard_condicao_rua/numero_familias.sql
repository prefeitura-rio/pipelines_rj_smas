-- as subqueries consideram família se há mais de um membro 
-- do id_familia cadastrado na tabela condicao_rua
with pessoas_por_familia_id_membro as (SELECT
  cond_rua.data_particao,
  cond_rua.id_familia,
  COUNT(DISTINCT cond_rua.id_membro_familia) AS numero_pessoas_familia,
FROM `rj-smas.protecao_social_cadunico.condicao_rua` cond_rua
GROUP BY 1,2
ORDER BY 1),

familias_cadastradas as 
  (select 
    data_particao,
    CASE
      WHEN numero_pessoas_familia = 1 THEN "1 pessoa"
      WHEN numero_pessoas_familia = 2 THEN "2 pessoas"
    ELSE "mais de 3 pessoas"
    END AS quantidade_pessoas_familia,
    count(distinct id_familia) as qnt_familias,
    SUM(numero_pessoas_familia) as qnt_pessoas
  from pessoas_por_familia_id_membro
  group by data_particao, quantidade_pessoas_familia)

SELECT
  cond_rua.data_particao,
  quantidade_pessoas_familia,
  MAX(qnt_familias) numero_familias_por_grupo,
  MAX(qnt_pessoas) numero_pessoas_por_grupo,
  COUNT(DISTINCT cond_rua.id_membro_familia) AS numero_pessoas,
  COUNT(DISTINCT cond_rua.id_familia) AS numero_familias,
  ROUND(SAFE_DIVIDE(COUNT(DISTINCT cond_rua.id_membro_familia), COUNT(DISTINCT cond_rua.id_familia)), 4) AS media_pessoas_por_familia,
  -- ROUND(100*SAFE_DIVIDE(MAX(qnt_familias), COUNT(DISTINCT cond_rua.id_familia)), 2) AS porcentagem_familias,
  AVG(c.valor_renda_media) valor_renda_media_per_capita,
FROM `rj-smas.protecao_social_cadunico.condicao_rua` cond_rua
LEFT JOIN familias_cadastradas fc on cond_rua.data_particao = fc.data_particao
LEFT JOIN `rj-smas.protecao_social_cadunico.identificacao_controle` c
      ON (cond_rua.id_familia = c.id_familia)
        AND (cond_rua.data_particao = c.data_particao)
INNER JOIN `rj-smas.protecao_social_cadunico.identificacao_primeira_pessoa` identificacao_primeira_pessoa
  ON identificacao_primeira_pessoa.id_familia = cond_rua.id_familia
  AND identificacao_primeira_pessoa.id_membro_familia = cond_rua.id_membro_familia
  AND identificacao_primeira_pessoa.data_particao = cond_rua.data_particao
  where 
  identificacao_primeira_pessoa.estado_cadastral = "Cadastrado"
GROUP BY 1, 2
ORDER BY 1, 2;