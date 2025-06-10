SELECT
    data_particao,
    -- CASE
    --     WHEN id_cras_creas IS NULL THEN "Não Informado"
    --     ELSE id_cras_creas
    -- END AS id_cras_creas,
    COUNT(DISTINCT id_familia) AS numero_familias,
    SUM(CASE WHEN familia_indigena = 'Sim' THEN 1 ELSE 0 END) AS numero_familias_indigenas,
    ROUND(100 * SAFE_DIVIDE(SUM(CASE WHEN familia_indigena = 'Sim'  THEN 1 ELSE 0 END) , SUM(COUNT(DISTINCT id_familia)) OVER(PARTITION BY data_particao)), 3) AS porcentagem_familia_indigena,
    SUM(CASE WHEN familia_quilombola = 'Sim' THEN 1 ELSE 0 END) AS numero_familias_quilombolas,
    ROUND(100 *  SAFE_DIVIDE(SUM(CASE WHEN familia_quilombola = 'Sim'  THEN 1 ELSE 0 END) , SUM(COUNT(DISTINCT id_familia)) OVER(PARTITION BY data_particao)) , 3) AS porcentagem_familias_quilombolas,
    SUM(COUNT(DISTINCT id_familia)) OVER(PARTITION BY data_particao) AS total_familias,
FROM `rj-smas.protecao_social_cadunico.familia`
GROUP BY 1
ORDER BY 1