SELECT
  cond_rua.data_particao,
  CASE
      WHEN cond_rua.id_carteira_assinada = '1'  THEN 'Sim'
      WHEN cond_rua.id_carteira_assinada = '2'  THEN 'Não'
      ELSE 'Não sabe'
  END AS tipo_familia, 
  COUNT(DISTINCT cond_rua.id_membro_familia) as numero_pessoas,
  ROUND(100 * SAFE_DIVIDE(COUNT(DISTINCT cond_rua.id_membro_familia) , SUM(COUNT(DISTINCT cond_rua.id_membro_familia)) OVER(PARTITION BY cond_rua.data_particao)),2) AS porcentagem,
FROM `rj-smas.protecao_social_cadunico.condicao_rua` cond_rua 
INNER JOIN `rj-smas.protecao_social_cadunico.identificacao_primeira_pessoa` identificacao_primeira_pessoa
  ON identificacao_primeira_pessoa.id_familia = cond_rua.id_familia
  AND identificacao_primeira_pessoa.id_membro_familia = cond_rua.id_membro_familia
  AND identificacao_primeira_pessoa.data_particao = cond_rua.data_particao
WHERE identificacao_primeira_pessoa.estado_cadastral = "Cadastrado"
GROUP BY cond_rua.data_particao, tipo_familia
ORDER BY cond_rua.data_particao, tipo_familia