-- CREATE OR REPLACE TABLE `rj-smas-dev-432320.protecao_social_cadunico.renda` AS
SELECT 
  id_familia,
  id_membro_familia,
  funcao_principal_trabalho,
  nao_recebe_remuneracao,
  renda_aposentadoria,
  renda_bruta_12_meses,
  renda_doacao,
  renda_emprego_ultimo_mes,
  renda_outras_rendas,
  renda_pensao_alimenticia,
  renda_seguro_desemprego,
  data_particao
FROM `rj-smas.protecao_social_cadunico.renda`
where data_particao >= "2024-07-01"