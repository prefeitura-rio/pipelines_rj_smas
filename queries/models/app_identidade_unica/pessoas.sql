{{
    config(
        materialized="table",
        cluster_by="cpf",
        partition_by={
            "field": "cpf_particao",
            "data_type": "int64",
            "range": {"start": 0, "end": 100000000000, "interval": 34722222},
        },
    )
}}

with
    documento_pessoa_tb as (
        select
            trim(dp.cpf) as cpf,
            dp.id_membro_familia,
            dp.id_familia,
            dp.data_particao,
            count(*) over (
                partition by dp.id_familia, dp.data_particao
                order by dp.data_particao desc
            ) as numeros_membros_familia
        from `rj-smas.protecao_social_cadunico.documento_pessoa` dp
    ),

    identificacao as (
        select
            id_membro_familia,
            id_familia,
            data_particao,
            nome,
            raca_cor,
            sexo,
            municipio_nascimento,
            sigla_uf_municipio_nascimento,
            estado_cadastral,
            parentesco_responsavel_familia,
            data_nascimento,
            data_ultima_atualizacao,
            data_cadastro,
            nome_mae,
            nome_pai
        from `rj-smas.protecao_social_cadunico.identificacao_primeira_pessoa`
    ),

    deficiencia as (
        select
            pd.id_membro_familia,
            pd.id_familia,
            pd.tem_deficiencia,
            case
                when pd.deficiencia_baixa_visao = '1'
                then 'baixa visão'
                when pd.deficiencia_cegueira = '1'
                then 'cegueira'
                when pd.deficiencia_fisica = '1'
                then 'física'
                when pd.deficiencia_mental = '1'
                then 'mental'
                when pd.deficiencia_sindrome_down = '1'
                then 'sindrome de down'
                when pd.deficiencia_surdez_leve = '1'
                then 'surdez leve'
                when pd.deficiencia_surdez_profunda = '1'
                then 'surdez profunda'
                when pd.deficiencia_transtorno_mental = '1'
                then 'transtorno mental'
                else null
            end as tipo_deficiencia,
            pd.data_particao
        from `rj-smas.protecao_social_cadunico.pessoa_deficiencia` pd
    ),

    renda as (
        select
            id_familia,
            id_membro_familia,
            data_particao,
            renda_outras_rendas,
            renda_emprego_ultimo_mes,
            renda_aposentadoria,
            renda_bruta_12_meses,
            renda_doacao,
            renda_pensao_alimenticia,
            renda_seguro_desemprego,
            nao_recebe_remuneracao
        from `rj-smas.protecao_social_cadunico.renda`
    ),

    membros as (
        select
            id_familia,
            data_particao,
            array_agg(struct(cpf, id_membro_familia)) as membros
        from documento_pessoa_tb
        group by id_familia, data_particao
    ),

    documento_pessoa_tb_filter as (
        select
            dp.cpf,
            dp.id_membro_familia,
            dp.id_familia,
            dp.numeros_membros_familia,
            dp.data_particao,
            row_number() over (
                partition by dp.cpf order by dp.data_particao desc
            ) as rank,
            i.nome,
            i.raca_cor,
            i.sexo,
            i.municipio_nascimento,
            i.sigla_uf_municipio_nascimento,
            i.estado_cadastral,
            i.parentesco_responsavel_familia,
            i.data_nascimento,
            i.data_ultima_atualizacao,
            i.data_cadastro,
            i.nome_mae,
            i.nome_pai,
            pd.tem_deficiencia,
            pd.tipo_deficiencia,
            r.renda_outras_rendas,
            r.renda_emprego_ultimo_mes,
            r.renda_aposentadoria,
            r.renda_bruta_12_meses,
            r.renda_doacao,
            r.renda_pensao_alimenticia,
            r.renda_seguro_desemprego,
            r.nao_recebe_remuneracao,
            {{ validate_cpf("cpf") }} as cpf_valido_indicador,
        from documento_pessoa_tb dp
        left join
            identificacao as i
            on dp.id_membro_familia = i.id_membro_familia
            and dp.id_familia = i.id_familia
            and dp.data_particao = i.data_particao
        left join
            deficiencia as pd
            on dp.id_membro_familia = pd.id_membro_familia
            and dp.id_familia = pd.id_familia
            and dp.data_particao = pd.data_particao
        left join
            renda as r
            on dp.id_membro_familia = r.id_membro_familia
            and dp.id_familia = r.id_familia
            and dp.data_particao = r.data_particao
        where cpf is not null
        order by cpf

    ),

    dados as (
        select
            dp.cpf,
            dp.id_membro_familia,
            dp.id_familia,
            dp.data_particao,
            array_agg(
                struct(
                    dp.cpf_valido_indicador,
                    dp.nome,
                    dp.raca_cor,
                    dp.sexo,
                    dp.municipio_nascimento,
                    dp.sigla_uf_municipio_nascimento,
                    dp.estado_cadastral,
                    dp.parentesco_responsavel_familia,
                    dp.data_nascimento,
                    dp.data_ultima_atualizacao,
                    dp.data_cadastro,
                    dp.nome_mae,
                    dp.nome_pai,
                    dp.numeros_membros_familia
                )
            ) as dados,
            array_agg(struct(dp.tem_deficiencia, dp.tipo_deficiencia)) as deficiencia,
            array_agg(
                struct(
                    dp.renda_outras_rendas,
                    dp.renda_emprego_ultimo_mes,
                    dp.renda_aposentadoria,
                    dp.renda_bruta_12_meses,
                    dp.renda_doacao,
                    dp.renda_pensao_alimenticia,
                    dp.renda_seguro_desemprego,
                    dp.nao_recebe_remuneracao
                )
            ) as renda
        from documento_pessoa_tb_filter dp
        where rank = 1
        group by dp.cpf, dp.id_membro_familia, dp.id_familia, dp.data_particao
    )

select
    dp.cpf,
    dp.id_membro_familia,
    dp.id_familia,
    dp.data_particao,
    dp.dados,
    m.membros,
    dp.deficiencia,
    dp.renda,
    safe_cast(dp.cpf as int64) as cpf_particao
from dados dp
left join
    membros m on dp.id_familia = m.id_familia and dp.data_particao = m.data_particao
order by id_familia
