  SELECT
    SAFE_CAST(address AS STRING) AS address,
    SAFE_CAST(latitude AS FLOAT64) AS latitude,
    SAFE_CAST(longitude AS FLOAT64) AS longitude,
    ST_GEOGPOINT(
      SAFE_CAST(longitude AS FLOAT64),
      SAFE_CAST(longitude AS FLOAT64)
    ) AS geometry
  FROM `rj-smas.protecao_social_cadunico_staging.endereco_geolocalizado`
