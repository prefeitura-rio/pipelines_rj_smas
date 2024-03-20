WITH pessoa_deficiencia_tb AS (
    SELECT
    p.data_particao,
    p.id_familia,
    p.tem_deficiencia
    FROM `rj-smas.protecao_social_cadunico.pessoa_deficiencia` p
    INNER JOIN `rj-smas.protecao_social_cadunico.condicao_rua` cond_rua ON cond_rua.id_membro_familia = p.id_membro_familia AND cond_rua.data_particao = p.data_particao
    INNER JOIN `rj-smas.protecao_social_cadunico.identificacao_primeira_pessoa` identificacao_primeira_pessoa
  ON identificacao_primeira_pessoa.id_familia = cond_rua.id_familia
  AND identificacao_primeira_pessoa.id_membro_familia = cond_rua.id_membro_familia
  AND identificacao_primeira_pessoa.data_particao = cond_rua.data_particao
  where 
  identificacao_primeira_pessoa.estado_cadastral = "Cadastrado"
    -- LEFT JOIN `rj-smas.protecao_social_cadunico.familia` f
    -- ON (p.id_familia = f.id_familia)
    -- AND (p.data_particao = f.data_particao
)

SELECT
    data_particao,
    ROUND(100 * SUM(CASE WHEN tem_deficiencia = 'Sim' THEN 1 ELSE 0 END) / SUM(COUNT(DISTINCT id_familia)) OVER(PARTITION BY data_particao), 4) AS porcentagem,
    SUM(CASE WHEN tem_deficiencia = 'Sim' THEN 1 ELSE 0 END) AS total_pessoas_deficiencia,
    SUM(COUNT(DISTINCT id_familia)) OVER(PARTITION BY data_particao) AS total_familias
FROM pessoa_deficiencia_tb def
GROUP BY  1
ORDER BY  1;
