WITH faixa_renda_tb AS (
    SELECT
        id_familia,
        data_particao,
        CASE
            WHEN valor_renda_media > 22000 THEN 'Classe A'
            WHEN valor_renda_media BETWEEN 7100 AND 22000 THEN 'Classe B'
            WHEN valor_renda_media BETWEEN 2900 AND 7100 THEN 'Classe C'
            ELSE 'Classes D/E'
        END AS faixa_renda
    FROM `rj-smas.protecao_social_cadunico.identificacao_controle`
),

despesas AS (
  SELECT
      fr.data_particao,
--       CASE
--         WHEN id_cras_creas IS NULL THEN "Não Informado"
--         ELSE id_cras_creas
--       END AS id_cras_creas,
      fr.faixa_renda,
      ROUND(100 * SAFE_DIVIDE(COUNT(DISTINCT fr.id_familia) , SUM(COUNT(DISTINCT fr.id_familia)) OVER(PARTITION BY fr.data_particao)),4) AS porcentagem,
      COUNT(DISTINCT fr.id_familia) AS numero_familias,
      AVG(despesa_agua_esgoto + despesa_alimentacao + despesa_aluguel + despesa_energia + despesa_gas + despesa_medicamentos + despesa_transporte) as media_despesas,
      AVG(f.despesa_agua_esgoto) AS media_despesa_agua_esgoto,
      AVG(f.despesa_alimentacao) AS media_despesa_alimentacao,
      AVG(f.despesa_aluguel) AS media_despesa_aluguel,
      AVG(f.despesa_energia) AS media_despesa_energia,
      AVG(f.despesa_gas) AS media_despesa_gas,
      AVG(f.despesa_medicamentos) AS media_despesa_medicamentos,
      AVG(f.despesa_transporte) AS media_despesa_transporte,
  FROM faixa_renda_tb fr
  JOIN `rj-smas.protecao_social_cadunico.familia` f
      ON fr.id_familia = f.id_familia
        AND fr.data_particao = f.data_particao
  GROUP BY 1, 2
  ORDER BY 1, 2
)

SELECT
  d.*,
  CASE
    WHEN d.media_despesa_agua_esgoto >= GREATEST(
            d.media_despesa_alimentacao,
            d.media_despesa_aluguel,
            d.media_despesa_energia,
            d.media_despesa_gas,
            d.media_despesa_medicamentos,
            d.media_despesa_transporte
    ) THEN 'Agua e Esgoto'
    WHEN d.media_despesa_alimentacao >= GREATEST(
            d.media_despesa_agua_esgoto,
            d.media_despesa_aluguel,
            d.media_despesa_energia,
            d.media_despesa_gas,
            d.media_despesa_medicamentos,
            d.media_despesa_transporte
    ) THEN 'Alimentacao'
    WHEN d.media_despesa_aluguel >= GREATEST(
            d.media_despesa_agua_esgoto,
            d.media_despesa_alimentacao,
            d.media_despesa_energia,
            d.media_despesa_gas,
            d.media_despesa_medicamentos,
            d.media_despesa_transporte
    ) THEN 'Aluguel'
    WHEN d.media_despesa_energia >= GREATEST(
            d.media_despesa_agua_esgoto,
            d.media_despesa_alimentacao,
            d.media_despesa_aluguel,
            d.media_despesa_gas,
            d.media_despesa_medicamentos,
            d.media_despesa_transporte
    ) THEN 'Energia'
    WHEN d.media_despesa_gas >= GREATEST(
            d.media_despesa_agua_esgoto,
            d.media_despesa_alimentacao,
            d.media_despesa_aluguel,
            d.media_despesa_energia,
            d.media_despesa_medicamentos,
            d.media_despesa_transporte
    ) THEN 'Gas'
    WHEN d.media_despesa_medicamentos >= GREATEST(
            d.media_despesa_agua_esgoto,
            d.media_despesa_alimentacao,
            d.media_despesa_aluguel,
            d.media_despesa_energia,
            d.media_despesa_gas,
            d.media_despesa_transporte
    ) THEN 'Medicamentos'
    WHEN d.media_despesa_transporte >= GREATEST(
            d.media_despesa_agua_esgoto,
            d.media_despesa_alimentacao,
            d.media_despesa_aluguel,
            d.media_despesa_energia,
            d.media_despesa_gas,
            d.media_despesa_medicamentos
    ) THEN 'Transporte'
    ELSE 'Não Informado'
  END AS principal_despesa
FROM despesas d
