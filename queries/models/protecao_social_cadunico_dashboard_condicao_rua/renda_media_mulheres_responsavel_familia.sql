WITH 
  chefia_familiar AS (
    SELECT
      p.data_particao,
      p.id_familia,
      CASE
          WHEN p.sexo = 'Feminino' THEN 'Chefiada por Mulheres'
          WHEN p.sexo = 'Masculino' THEN 'Chefiada por Homens'
          ELSE 'Outras Famílias'
      END AS tipo_familia,
    FROM `rj-smas.protecao_social_cadunico.identificacao_primeira_pessoa` p
    INNER JOIN `rj-smas.protecao_social_cadunico.condicao_rua` cond_rua ON cond_rua.id_membro_familia = p.id_membro_familia AND cond_rua.data_particao = p.data_particao
    WHERE p.id_parentesco_responsavel_familia = '01' AND
      cond_rua.condicao_rua_vive_familia = '1'
    AND p.estado_cadastral = "Cadastrado"
),
renda_familias AS (
    SELECT
        p.data_particao,
        p.id_familia,
        cf.tipo_familia,
        COUNT(DISTINCT p.id_membro_familia) AS numero_pessoas,
        MAX(c.valor_renda_media) valor_renda_media, -- a renda é por família
    FROM `rj-smas.protecao_social_cadunico.identificacao_primeira_pessoa` p
    INNER JOIN chefia_familiar cf ON cf.id_familia = p.id_familia AND cf.data_particao = p.data_particao
    LEFT JOIN `rj-smas.protecao_social_cadunico.identificacao_controle` c
      ON (p.id_familia = c.id_familia)
        AND (p.data_particao = c.data_particao)
    -- LEFT JOIN `rj-smas.protecao_social_cadunico.familia` f
    --   ON (p.id_familia = f.id_familia)
    --     AND (p.data_particao = f.data_particao)
  	WHERE p.estado_cadastral = "Cadastrado"
    GROUP BY p.data_particao, p.id_familia, cf.tipo_familia
),
tabela_calculos AS (
SELECT
    data_particao,
    tipo_familia,
    ROUND(AVG(valor_renda_media), 2) AS valor_renda_media,
    ROUND(100 * SAFE_DIVIDE(COUNT(DISTINCT id_familia) , SUM(COUNT(DISTINCT id_familia)) OVER(PARTITION BY data_particao)),4) AS porcentagem,
    COUNT(DISTINCT id_familia) AS numero_familias,
    SUM(COUNT(DISTINCT id_familia)) OVER(PARTITION BY data_particao) AS total_familias,
    SUM(numero_pessoas) as numero_pessoas,
    ROUND(SUM(numero_pessoas)/COUNT(DISTINCT id_familia), 4) AS pessoas_por_familia,
FROM renda_familias
GROUP BY 1, 2
ORDER BY 1, 2)

SELECT * FROM tabela_calculos
WHERE tipo_familia IS NOT NULL
