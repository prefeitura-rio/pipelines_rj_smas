{{
    config(
        schema="datametrica_staging",
        alias="agendamentos_cadunicos",
        materialized="table",
        partition_by={
            "field": "data_hora",
            "data_type": "date"
        }
    )
}}

with source_data as (
    select
        id,
        id_capacidade,
        nome_completo,
        cpf,
        telefone,
        tipo,
        data_hora,
        unidade_nome,
        unidade_endereco,
        unidade_bairro,
        -- Add metadata fields
        _current_timestamp() as processed_at
    from {{ source('brutos_data_metrica_staging', 'agendamentos_cadunicos') }}
    where data_hora is not null
)

select * from source_data