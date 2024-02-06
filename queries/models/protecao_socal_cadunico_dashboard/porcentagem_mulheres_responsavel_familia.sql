
# p.id_parentesco_responsavel_familia '01' = 'Pessoa Responsável pela Unidade Familiar - RF'
WITH responsavel_familiar AS (
SELECT
    p.data_particao,
    f.id_cras_creas,
    p.id_familia,
    p.id_parentesco_responsavel_familia,
    p.sexo
FROM `rj-smas.protecao_social_cadunico.identificacao_primeira_pessoa` p
LEFT JOIN `rj-smas.protecao_social_cadunico.familia` f
  ON (p.id_familia = f.id_familia)
    AND (p.data_particao = f.data_particao)
WHERE p.id_parentesco_responsavel_familia = '01'
)

SELECT
    data_particao,
    -- CASE
    --   WHEN id_cras_creas IS NULL THEN "Não Informado"
    --   ELSE id_cras_creas
    -- END AS id_cras_creas,
    ROUND((SUM(CASE WHEN id_parentesco_responsavel_familia = '01' AND sexo = 'Feminino' THEN 1 ELSE 0 END) * 100.0 / COUNT(DISTINCT CASE WHEN id_parentesco_responsavel_familia = '01' THEN id_familia END)), 2) AS porcentagem,
    SUM(CASE WHEN id_parentesco_responsavel_familia = '01' AND sexo = 'Feminino' THEN 1 ELSE 0 END) AS numero_mulheres_chefes,
    COUNT(DISTINCT CASE WHEN id_parentesco_responsavel_familia = '01' THEN id_familia END) AS total_familias
FROM responsavel_familiar
GROUP BY  1
ORDER BY  1