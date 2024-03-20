WITH ultimo_mes_registro AS (
    SELECT
        MAX(data_particao) AS ultimo_mes,
        DATE_SUB(DATE_TRUNC(MAX(data_particao), MONTH), INTERVAL 1 MONTH) AS penultimo_mes
    FROM `rj-smas.protecao_social_cadunico.condicao_rua`     
    WHERE data_particao >= DATE_SUB(CURRENT_DATE(), INTERVAL 120 day)
)

SELECT 
    cond_rua.data_particao,
    COUNT(DISTINCT cond_rua.id_membro_familia) AS numero_pessoas,
    LAG(COUNT(DISTINCT cond_rua.id_membro_familia)) OVER (ORDER BY DATE_TRUNC(cond_rua.data_particao, MONTH)) AS numero_pessoas_penultimo_mes,
    COUNT(DISTINCT cond_rua.id_membro_familia) - LAG(COUNT(DISTINCT cond_rua.id_membro_familia)) OVER (ORDER BY DATE_TRUNC(cond_rua.data_particao, MONTH)) AS diferenca_absoluta,
    ROUND((COUNT(DISTINCT cond_rua.id_membro_familia) - LAG(COUNT(DISTINCT cond_rua.id_membro_familia)) OVER (ORDER BY DATE_TRUNC(cond_rua.data_particao, MONTH))) / NULLIF(LAG(COUNT(DISTINCT cond_rua.id_membro_familia)) OVER (ORDER BY DATE_TRUNC(cond_rua.data_particao, MONTH)), 0), 4) AS taxa_variacao
FROM `rj-smas.protecao_social_cadunico.condicao_rua` cond_rua
JOIN ultimo_mes_registro ON data_particao BETWEEN penultimo_mes AND ultimo_mes
INNER JOIN `rj-smas.protecao_social_cadunico.identificacao_primeira_pessoa` identificacao_primeira_pessoa
  ON identificacao_primeira_pessoa.id_familia = cond_rua.id_familia
  AND identificacao_primeira_pessoa.id_membro_familia = cond_rua.id_membro_familia
  AND identificacao_primeira_pessoa.data_particao = cond_rua.data_particao 
  AND identificacao_primeira_pessoa.estado_cadastral = "Cadastrado"
GROUP BY data_particao
ORDER BY data_particao DESC
LIMIT 1
