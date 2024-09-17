-- CREATE OR REPLACE TABLE `rj-smas-dev-432320.protecao_social_cadunico.domicilio` AS
SELECT 
  id_familia,
  forma_abatecimento_agua_domicilio,
  possui_agua_encanada_domicilio,
  possui_banheiro_domicilio,
  calcamento_domicilio,
  destino_lixo_domicilio,
  escoamento_sanitario_domicilio,
  especie_domicilio,
  iluminacao_domicilio,
  local_domicilio,
  material_domicilio,
  material_piso_domicilio,
  quantidade_comodos_domicilio,
  quantidade_comodos_dormitorio,
  data_particao,
FROM `rj-smas.protecao_social_cadunico.domicilio`
where data_particao >= "2024-07-01"