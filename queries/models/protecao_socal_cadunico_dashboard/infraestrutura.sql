WITH tb AS (
  SELECT
    f.id_familia,
    f.data_particao,
    CASE
      WHEN f.id_cras_creas IS NULL THEN "Não Informado"
      ELSE f.id_cras_creas
    END AS id_cras_creas,
    d.destino_lixo_domicilio,
    d.escoamento_sanitario_domicilio,
    d.iluminacao_domicilio,
    d.local_domicilio,
    d.calcamento_domicilio,
    d.material_piso_domicilio,
    d.material_domicilio,
  FROM `rj-smas.protecao_social_cadunico.domicilio` as d
  JOIN `rj-smas.protecao_social_cadunico.familia` as f
    ON  d.id_familia = f.id_familia
      AND d.data_particao = f.data_particao
),

banheiro AS (
  SELECT
    data_particao,
    'possui banheiro' AS tipo,
    escoamento_sanitario_domicilio AS grupo,
    ROUND(100 * COUNT(DISTINCT id_familia) / SUM(COUNT(DISTINCT id_familia)) OVER(PARTITION BY data_particao), 2) AS porcentagem,
    COUNT(DISTINCT id_familia) numero_familias,
    SUM(COUNT(DISTINCT id_familia)) OVER(PARTITION BY data_particao) AS total_familias,
  FROM tb
  GROUP BY 1, 2, 3
  ORDER BY 1, 2, 3
),

lixo AS (
  SELECT
    data_particao,
    'destino lixo' AS tipo,
    destino_lixo_domicilio AS grupo,
    ROUND(100 * COUNT(DISTINCT id_familia) / SUM(COUNT(DISTINCT id_familia)) OVER(PARTITION BY data_particao), 2) AS porcentagem,
    COUNT(DISTINCT id_familia) numero_familias,
    SUM(COUNT(DISTINCT id_familia)) OVER(PARTITION BY data_particao) AS total_familias,
  FROM tb
  GROUP BY 1, 2, 3
  ORDER BY 1, 2, 3
),

iluminacao AS (
  SELECT
    data_particao,
    'iluminacao' AS tipo,
    iluminacao_domicilio AS grupo,
    ROUND(100 * COUNT(DISTINCT id_familia) / SUM(COUNT(DISTINCT id_familia)) OVER(PARTITION BY data_particao), 2) AS porcentagem,
    COUNT(DISTINCT id_familia) numero_familias,
    SUM(COUNT(DISTINCT id_familia)) OVER(PARTITION BY data_particao) AS total_familias,
  FROM tb
  GROUP BY 1, 2, 3
  ORDER BY 1, 2, 3
),

local_domicilio AS (
  SELECT
    data_particao,
    'local domicilio' AS tipo,
    local_domicilio AS grupo,
    ROUND(100 * COUNT(DISTINCT id_familia) / SUM(COUNT(DISTINCT id_familia)) OVER(PARTITION BY data_particao), 2) AS porcentagem,
    COUNT(DISTINCT id_familia) numero_familias,
    SUM(COUNT(DISTINCT id_familia)) OVER(PARTITION BY data_particao) AS total_familias,
  FROM tb
  GROUP BY 1, 2, 3
  ORDER BY 1, 2, 3
),

pavimentacao AS (
  SELECT
    data_particao,
    'pavimentacao' AS tipo,
    calcamento_domicilio AS grupo,
    ROUND(100 * COUNT(DISTINCT id_familia) / SUM(COUNT(DISTINCT id_familia)) OVER(PARTITION BY data_particao), 2) AS porcentagem,
    COUNT(DISTINCT id_familia) numero_familias,
    SUM(COUNT(DISTINCT id_familia)) OVER(PARTITION BY data_particao) AS total_familias,
  FROM tb
  GROUP BY 1, 2, 3
  ORDER BY 1, 2, 3
),

material_piso AS (
  SELECT
    data_particao,
    'material piso' AS tipo,
    material_piso_domicilio AS grupo,
    ROUND(100 * COUNT(DISTINCT id_familia) / SUM(COUNT(DISTINCT id_familia)) OVER(PARTITION BY data_particao), 2) AS porcentagem,
    COUNT(DISTINCT id_familia) numero_familias,
    SUM(COUNT(DISTINCT id_familia)) OVER(PARTITION BY data_particao) AS total_familias,
  FROM tb
  GROUP BY 1, 2, 3
  ORDER BY 1, 2, 3
),

revestimento_parede AS (
  SELECT
    data_particao,
    'revestimento parede' AS tipo,
    material_domicilio AS grupo,
    ROUND(100 * COUNT(DISTINCT id_familia) / SUM(COUNT(DISTINCT id_familia)) OVER(PARTITION BY data_particao), 2) AS porcentagem,
    COUNT(DISTINCT id_familia) numero_familias,
    SUM(COUNT(DISTINCT id_familia)) OVER(PARTITION BY data_particao) AS total_familias,
  FROM tb
  GROUP BY 1, 2, 3
  ORDER BY 1, 2, 3
)

SELECT * FROM banheiro
UNION ALL
SELECT * FROM lixo
UNION ALL
SELECT * FROM iluminacao
UNION ALL
SELECT * FROM local_domicilio
UNION ALL
SELECT * FROM pavimentacao
UNION ALL
SELECT * FROM material_piso
UNION ALL
SELECT * FROM revestimento_parede
