WITH pessoa_deficiencia_tb AS (
    SELECT
    p.data_particao,
    p.id_familia,
    p.tem_deficiencia
    FROM `rj-smas.protecao_social_cadunico.pessoa_deficiencia` p
    LEFT JOIN `rj-smas.protecao_social_cadunico.familia` f
    ON (p.id_familia = f.id_familia)
    AND (p.data_particao = f.data_particao)
)

SELECT
    data_particao,
    ROUND(100 * SUM(CASE WHEN tem_deficiencia = 'Sim' THEN 1 ELSE 0 END) / SUM(COUNT(DISTINCT id_familia)) OVER(PARTITION BY data_particao), 4) AS porcentagem,
    SUM(CASE WHEN tem_deficiencia = 'Sim' THEN 1 ELSE 0 END) AS total_pessoas_deficiencia,
    SUM(COUNT(DISTINCT id_familia)) OVER(PARTITION BY data_particao) AS total_familias
FROM pessoa_deficiencia_tb
GROUP BY  1
ORDER BY  1
