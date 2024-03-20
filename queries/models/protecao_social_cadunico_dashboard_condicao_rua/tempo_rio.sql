SELECT 
    cond_rua.data_particao,
    CASE id_tempo_municipio
        WHEN '1' THEN 'Até seis meses'
        WHEN '2' THEN 'Entre seis meses e um ano'
        WHEN '3' THEN 'Entre um e dois anos'
        WHEN '4' THEN 'Entre dois e cinco anos'
        WHEN '5' THEN 'Entre cinco e dez anos'
        WHEN '6' THEN 'Mais de dez anos'
        ELSE 'Outro'
    END AS legenda_tempo_municipio,
    COUNT(*) AS total
FROM `rj-smas.protecao_social_cadunico.condicao_rua` cond_rua
INNER JOIN `rj-smas.protecao_social_cadunico.identificacao_primeira_pessoa` identificacao_primeira_pessoa
  ON identificacao_primeira_pessoa.id_familia = cond_rua.id_familia
  AND identificacao_primeira_pessoa.id_membro_familia = cond_rua.id_membro_familia
  AND identificacao_primeira_pessoa.data_particao = cond_rua.data_particao 
  AND identificacao_primeira_pessoa.estado_cadastral = "Cadastrado"
GROUP BY data_particao, id_tempo_municipio
;
