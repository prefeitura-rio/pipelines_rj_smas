CREATE OR REPLACE TABLE `rj-smas-dev-432320.protecao_social_cadunico.escolaridade` AS
SELECT
  id_familia,
  id_membro_familia,
  ano_serie_frequenta,
  ultimo_ano_serie_frequentou,
  id_inep_escola,
  id_concluiu_curso_frequentado,
  curso_frequenta,
  curso_mais_elevado_frequentou,
  id_sabe_ler_escrever,
  escola_nao_tem_inep,
  frequenta_escola,
FROM `rj-smas.protecao_social_cadunico.escolaridade`
where data_particao >= "2024-07-01"
