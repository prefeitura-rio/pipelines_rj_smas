WITH membro AS (
    SELECT
        t.data_particao,
        t.id_membro_familia,
        t.id_familia,
        sexo AS genero,
        raca_cor
    FROM `rj-smas.protecao_social_cadunico.identificacao_primeira_pessoa` t
    INNER JOIN `rj-smas.protecao_social_cadunico.condicao_rua` cond_rua 
        ON cond_rua.id_membro_familia = t.id_membro_familia 
        AND cond_rua.data_particao = t.data_particao 
        AND cond_rua.id_familia = t.id_familia
        AND t.estado_cadastral = "Cadastrado"
),
membro_renda AS (
    SELECT
        m.id_familia,
        m.data_particao,
        m.id_membro_familia,
        m.genero,
        m.raca_cor,
        COALESCE(r.renda_outras_rendas, 0) +
        COALESCE(r.renda_emprego_ultimo_mes, 0) +
        COALESCE(r.renda_aposentadoria, 0) +
        COALESCE(r.renda_bruta_12_meses, 0) +
        COALESCE(r.renda_doacao, 0) +
        COALESCE(r.renda_pensao_alimenticia, 0) +
        COALESCE(r.renda_seguro_desemprego, 0) AS total_renda
    FROM membro m
    LEFT JOIN `rj-smas.protecao_social_cadunico.renda` r
        ON m.id_membro_familia = r.id_membro_familia
        AND m.data_particao = r.data_particao
)

SELECT
    data_particao,
    genero,
    raca_cor,
    COUNT(*) AS numero_pessoas,
    SUM(total_renda) AS soma_total_renda
FROM membro_renda
GROUP BY data_particao, genero, raca_cor
ORDER BY data_particao, genero, raca_cor
;
