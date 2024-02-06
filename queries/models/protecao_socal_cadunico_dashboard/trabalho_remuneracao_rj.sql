WITH trabalho_remuneracao_tb AS (
  SELECT
    f.data_particao,
    CASE
      WHEN DATE_DIFF(CURRENT_DATE, data_nascimento, YEAR)  BETWEEN 0 AND 6 THEN '0-6'
      WHEN DATE_DIFF(CURRENT_DATE, data_nascimento, YEAR)  BETWEEN 7 AND 9 THEN '7-9'
      WHEN DATE_DIFF(CURRENT_DATE, data_nascimento, YEAR)  BETWEEN 10 AND 14 THEN '10-14'
      WHEN DATE_DIFF(CURRENT_DATE, data_nascimento, YEAR)  BETWEEN 15 AND 17 THEN '15-17'
      WHEN DATE_DIFF(CURRENT_DATE, data_nascimento, YEAR)  BETWEEN 18 AND 29 THEN '18-29'
      WHEN DATE_DIFF(CURRENT_DATE, data_nascimento, YEAR)  BETWEEN 30 AND 59 THEN '30-59'
      ELSE '60+'
    END AS faixa_etaria,
    CASE
        WHEN valor_renda_media > 22000 THEN 'Classe A'
        WHEN valor_renda_media BETWEEN 7100 AND 22000 THEN 'Classe B'
        WHEN valor_renda_media BETWEEN 2900 AND 7100 THEN 'Classe C'
        ELSE 'Classes D/E'
    END AS faixa_renda,
    funcao_principal_trabalho,
    COUNTIF(tr.id_trabalho_semana_passada='1') AS trabalho_semana_passada,
    COUNTIF(tr.id_afastado_semana_passada='1') AS afastado_semana_passada,
    ROUND(AVG(meses_trabalhados_nos_ultimos_12),2) AS media_meses_trabalhados_nos_ultimos_12,
    ROUND(AVG(remuneracao),2) AS media_remuneracao,
    COUNTIF(tr.nao_recebe_doacao != '0' AND tr.nao_recebe_doacao IS NOT NULL) AS recebe_doacao,
    COUNTIF(tr.nao_recebe_aposentadoria != '0' AND tr.nao_recebe_aposentadoria IS NOT NULL) AS recebe_aposentadoria,
    COUNTIF(tr.nao_recebe_seguro_desemprego != '0' AND tr.nao_recebe_seguro_desemprego IS NOT NULL) AS recebe_seguro_desemprego,
    COUNTIF(tr.nao_recebe_pensao_alimenticia != '0' AND tr.nao_recebe_pensao_alimenticia IS NOT NULL) AS recebe_pensao_alimenticia,
    COUNTIF(tr.nao_recebe_outras_fontes != '0' AND tr.nao_recebe_outras_fontes IS NOT NULL) AS recebe_outras_fontes,
    COUNTIF(ic.trabalho_infantil = '1') AS trabalho_infantil,
    COUNT(*) AS numero_membros
FROM `rj-smas.protecao_social_cadunico.trabalho_remuneracao` tr
LEFT JOIN `rj-smas.protecao_social_cadunico.identificacao_primeira_pessoa` pp
  ON pp.id_membro_familia = tr.id_membro_familia
    AND pp.data_particao = tr.data_particao
LEFT JOIN `rj-smas.protecao_social_cadunico.identificacao_controle` ic
  ON ic.id_familia = tr.id_familia
    AND ic.data_particao = tr.data_particao
LEFT JOIN `rj-smas.protecao_social_cadunico.familia` f
  ON f.id_familia = tr.id_familia
    AND f.data_particao = tr.data_particao
GROUP BY data_particao, faixa_renda, faixa_etaria, funcao_principal_trabalho
ORDER BY data_particao, faixa_renda, faixa_etaria, funcao_principal_trabalho
),

total_data_cras_cres AS (
  SELECT
      data_particao,
      COUNT(*) AS total_membros_cras,
      SUM(COUNT(DISTINCT id_membro_familia)) OVER(PARTITION BY data_particao) AS total_membros,
  FROM `rj-smas.protecao_social_cadunico.trabalho_remuneracao`
  GROUP BY 1
)

SELECT
  tr.data_particao,
  tr.faixa_etaria,
  tr.faixa_renda,
  tr.funcao_principal_trabalho,
  ROUND(100 * SAFE_DIVIDE(tr.numero_membros,tdcc.total_membros), 4) AS porcentagem_membros,
  tr.numero_membros,
  tdcc.total_membros,
  tr.trabalho_semana_passada,
  ROUND(100 * SAFE_DIVIDE(tr.trabalho_semana_passada, tdcc.total_membros), 4) AS porcentagem_trabalho_semana_passada,
  tr.afastado_semana_passada,
  ROUND(100 * SAFE_DIVIDE(tr.afastado_semana_passada, tdcc.total_membros), 4) AS porcentagem_afastado_semana_passada,
  tr.media_meses_trabalhados_nos_ultimos_12,
  tr.media_remuneracao,
  tr.recebe_doacao,
  ROUND(100 * SAFE_DIVIDE(tr.recebe_doacao, tdcc.total_membros), 4) AS porcentagem_recebe_doacao,
  tr.recebe_aposentadoria,
  ROUND(100 * SAFE_DIVIDE(tr.recebe_aposentadoria, tdcc.total_membros), 4) AS porcentagem_recebe_aposentadoria,
  tr.recebe_seguro_desemprego,
  ROUND(100 * SAFE_DIVIDE(tr.recebe_seguro_desemprego, tdcc.total_membros), 4) AS porcentagem_recebe_seguro_desemprego,
  tr.recebe_pensao_alimenticia,
  ROUND(100 * SAFE_DIVIDE(tr.recebe_pensao_alimenticia, tdcc.total_membros), 4) AS porcentagem_recebe_pensao_alimenticia,
  tr.recebe_outras_fontes,
  ROUND(100 * SAFE_DIVIDE(tr.recebe_outras_fontes, tdcc.total_membros), 4) AS porcentagem_recebe_outras_fontes,
  tr.trabalho_infantil,
  ROUND(100 * SAFE_DIVIDE(tr.trabalho_infantil, tdcc.total_membros), 4) AS porcentagem_trabalho_infantil
FROM trabalho_remuneracao_tb tr
LEFT JOIN total_data_cras_cres tdcc
  ON tr.data_particao = tdcc.data_particao
ORDER BY tr.data_particao, faixa_renda, faixa_etaria, funcao_principal_trabalho
