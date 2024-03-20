SELECT
  cond_rua.data_particao,
  id_tempo_rua,
  CASE 
    WHEN id_tempo_rua = '1' THEN 'Até seis meses'
    WHEN id_tempo_rua = '2' THEN 'Entre seis meses e um ano'
    WHEN id_tempo_rua = '3' THEN 'Entre um e dois anos'
    WHEN id_tempo_rua = '4' THEN 'Entre dois e cinco anos'
    WHEN id_tempo_rua = '5' THEN 'Entre cinco e dez anos'
    WHEN id_tempo_rua = '6' THEN 'Mais de dez anos'
    ELSE "Não informado"
  END AS tempo_rua,
  COUNT(DISTINCT cond_rua.id_membro_familia) as numero_pessoas
FROM `rj-smas.protecao_social_cadunico.condicao_rua` cond_rua
INNER JOIN `rj-smas.protecao_social_cadunico.identificacao_primeira_pessoa` identificacao_primeira_pessoa
  ON identificacao_primeira_pessoa.id_familia = cond_rua.id_familia
  AND identificacao_primeira_pessoa.id_membro_familia = cond_rua.id_membro_familia
  AND identificacao_primeira_pessoa.data_particao = cond_rua.data_particao
  where 
  identificacao_primeira_pessoa.estado_cadastral = "Cadastrado"
GROUP BY data_particao, id_tempo_rua, tempo_rua
ORDER BY 1;

