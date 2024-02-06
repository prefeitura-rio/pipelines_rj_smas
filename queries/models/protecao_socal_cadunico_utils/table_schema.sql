SELECT
  table_catalog as project_id,
  table_schema as dataset_id,
  table_name as table_id,
  column_name as column,
  data_type,
  is_partitioning_column,
FROM `rj-smas.protecao_social_cadunico.INFORMATION_SCHEMA.COLUMNS`