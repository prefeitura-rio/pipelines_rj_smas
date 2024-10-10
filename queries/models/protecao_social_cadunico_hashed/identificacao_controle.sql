CREATE OR REPLACE TABLE `rj-smas-dev-432320.protecao_social_cadunico.identificacao_controle` AS
SELECT
  id_familia,
  valor_renda_media,
  condicao_cadastro,
  estado_cadastro,
  data_alteracao,
  data_atualizacao,
  data_catrastro,
  data_particao,
FROM `rj-smas.protecao_social_cadunico.identificacao_controle`
where data_particao >= "2024-07-01"