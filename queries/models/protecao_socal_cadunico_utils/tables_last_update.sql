SELECT
  creation_time as last_update,
  table_schema as dataset_id,
  table_name as table_id
FROM `rj-smas.protecao_social_cadunico.INFORMATION_SCHEMA.TABLES`
ORDER BY 1