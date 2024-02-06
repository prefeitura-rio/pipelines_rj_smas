WITH renda_familias AS (
    SELECT
        p.data_particao,
        p.id_familia,
        c.valor_renda_media,
        CASE
            WHEN p.sexo = 'Feminino'  THEN 'Chefiada por Mulheres'
            ELSE 'Outras Famílias'
        END AS tipo_familia
    FROM `rj-smas.protecao_social_cadunico.identificacao_primeira_pessoa` p
    LEFT JOIN `rj-smas.protecao_social_cadunico.identificacao_controle` c
      ON (p.id_familia = c.id_familia)
        AND (p.data_particao = c.data_particao)
    LEFT JOIN `rj-smas.protecao_social_cadunico.familia` f
      ON (p.id_familia = f.id_familia)
        AND (p.data_particao = f.data_particao)
    WHERE p.id_parentesco_responsavel_familia = '01'
)
SELECT
    data_particao,
    tipo_familia,
    AVG(valor_renda_media) AS valor_renda_media,
    ROUND(100 * SAFE_DIVIDE(COUNT(DISTINCT id_familia) , SUM(COUNT(DISTINCT id_familia)) OVER(PARTITION BY data_particao)),4) AS porcentagem,
    COUNT(DISTINCT id_familia) AS numero_familias,
    SUM(COUNT(DISTINCT id_familia)) OVER(PARTITION BY data_particao) AS total_familias,
FROM renda_familias
GROUP BY 1, 2
ORDER BY 1, 2