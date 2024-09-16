CREATE OR REPLACE TABLE `rj-smas-dev-432320.protecao_social_cadunico.pessoa_deficiencia` AS
SELECT
  id_familia,
  id_membro_familia,
  tem_deficiencia,
  deficiencia_baixa_visao,
  deficiencia_cegueira,
  deficiencia_fisica,
  deficiencia_mental,
  deficiencia_sindrome_down,
  deficiencia_surdez_leve,
  deficiencia_surdez_profunda,
  deficiencia_transtorno_mental,
FROM `rj-smas.protecao_social_cadunico.pessoa_deficiencia`
where data_particao >= "2024-07-01"
