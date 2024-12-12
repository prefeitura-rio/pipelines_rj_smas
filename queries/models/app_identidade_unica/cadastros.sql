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
            i.trabalho_infantil,
            count(*) over (
                partition by dp.id_familia, dp.data_particao
                order by dp.data_particao desc
            ) as numeros_membros_familia
        from `rj-smas.protecao_social_cadunico.documento_pessoa` dp
        left join
            `rj-smas.protecao_social_cadunico.identificacao_primeira_pessoa` i
            on dp.id_membro_familia = i.id_membro_familia
            and dp.id_familia = i.id_familia
            and dp.data_particao = i.data_particao
    ),

    identificacao_controle as (
        select id_familia, data_particao, valor_renda_media, valor_renda_media_original
        from `rj-smas.protecao_social_cadunico.identificacao_controle`
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
            r.id_familia,
            r.id_membro_familia,
            ic.valor_renda_media as renda_media_familia,
            ic.valor_renda_media_original as renda_media_familia_original,
            r.data_particao,
            safe_cast(r.renda_outras_rendas AS int64) as renda_outras_rendas,
            safe_cast(r.renda_emprego_ultimo_mes AS int64) as renda_emprego_ultimo_mes,
            safe_cast(r.renda_aposentadoria AS int64) as renda_aposentadoria,
            safe_cast(r.renda_bruta_12_meses AS int64) as renda_bruta_12_meses,
            safe_cast(r.renda_doacao AS int64) as renda_doacao,
            safe_cast(r.renda_pensao_alimenticia AS int64) as renda_pensao_alimenticia,
            safe_cast(r.renda_seguro_desemprego AS int64) as renda_seguro_desemprego,
            safe_cast(r.nao_recebe_remuneracao AS int64) as nao_recebe_remuneracao,
            safe_cast(r.funcao_principal_trabalho AS int64) as funcao_principal_trabalho
        from `rj-smas.protecao_social_cadunico.renda` r
        left join
            identificacao_controle ic
            on r.id_familia = ic.id_familia
            and r.data_particao = ic.data_particao
    ),

    domicilio as (
        select
            f.id_familia,
            f.data_particao,
            array_agg(
                struct(
                    d.especie_domicilio,
                    d.iluminacao_domicilio as iluminacao,
                    d.quantidade_comodos_domicilio as comodos,
                    d.forma_abatecimento_agua_domicilio as forma_abastecimento_agua,
                    d.possui_agua_encanada_domicilio as possui_agua_encanada,
                    d.escoamento_sanitario_domicilio as escoamento_sanitario,
                    d.local_domicilio as local,
                    safe_cast(f.despesa_agua_esgoto AS int64) as despesa_agua_esgoto,
                    safe_cast(f.despesa_alimentacao AS int64) as despesa_alimentacao,
                    safe_cast(f.despesa_aluguel AS int64) as despesa_aluguel,
                    safe_cast(f.despesa_energia AS int64) as despesa_energia,
                    safe_cast(f.despesa_gas AS int64) as despesa_gas,
                    safe_cast(f.despesa_transporte AS int64) as despesa_transporte
                )
            ) as domicilio
        from `rj-smas.protecao_social_cadunico.familia` f
        left join
            `rj-smas.protecao_social_cadunico.domicilio` d
            on f.id_familia = d.id_familia
            and f.data_particao = d.data_particao
        group by id_familia, data_particao
    ),

    escolaridade as (
        select
            id_familia,
            id_membro_familia,
            data_particao,
            sabe_ler_escrever,
            curso_mais_elevado_frequentou,
        from `rj-smas.protecao_social_cadunico.escolaridade`
    ),

    condicao_rua as (
        select id_familia, id_membro_familia, data_particao, true as condicao_rua
        from `rj-smas.protecao_social_cadunico.condicao_rua`
    ),

    membros as (
        select
            id_familia,
            data_particao,
            array_agg(
                struct(cpf, id_membro_familia, nome, parentesco_responsavel_familia)
            ) as membros
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
            dp.trabalho_infantil,
            pd.tem_deficiencia,
            pd.tipo_deficiencia,
            r.renda_media_familia,
            r.renda_media_familia_original,
            r.renda_outras_rendas,
            r.renda_emprego_ultimo_mes,
            r.renda_aposentadoria,
            r.renda_bruta_12_meses,
            r.renda_doacao,
            r.renda_pensao_alimenticia,
            r.renda_seguro_desemprego,
            r.nao_recebe_remuneracao,
            r.funcao_principal_trabalho,
            e.sabe_ler_escrever,
            e.curso_mais_elevado_frequentou,
            cr.condicao_rua
        from documento_pessoa_tb dp
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
        left join
            escolaridade as e
            on dp.id_membro_familia = e.id_membro_familia
            and dp.id_familia = e.id_familia
            and dp.data_particao = e.data_particao
        left join
            condicao_rua as cr
            on dp.id_membro_familia = cr.id_membro_familia
            and dp.id_familia = cr.id_familia
            and dp.data_particao = cr.data_particao
        where cpf is not null

    ),

    dados as (
        select
            dp.cpf,
            dp.id_membro_familia,
            dp.id_familia,
            dp.data_particao,
            array_agg(
                struct(
                    {{ validate_cpf("cpf") }} as cpf_valido_indicador,
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
                    dp.condicao_rua,
                    dp.trabalho_infantil,
                    dp.numeros_membros_familia
                )
            ) as dados,
            array_agg(struct(dp.tem_deficiencia, dp.tipo_deficiencia)) as deficiencia,
            array_agg(
                struct(
                    dp.renda_media_familia,
                    dp.renda_media_familia_original,
                    dp.renda_outras_rendas,
                    dp.renda_emprego_ultimo_mes,
                    dp.renda_aposentadoria,
                    dp.renda_bruta_12_meses,
                    dp.renda_doacao,
                    dp.renda_pensao_alimenticia,
                    dp.renda_seguro_desemprego,
                    dp.nao_recebe_remuneracao,
                    dp.funcao_principal_trabalho
                )
            ) as renda,
            array_agg(
                struct(dp.sabe_ler_escrever, dp.curso_mais_elevado_frequentou)
            ) as escolaridade
        from documento_pessoa_tb_filter dp
        where rank = 1
        group by dp.cpf, dp.id_membro_familia, dp.id_familia, dp.data_particao
    ),

    final_data as (
        select
            dp.cpf,
            dp.id_membro_familia,
            dp.id_familia,
            dp.data_particao,
            dp.dados,
            dp.deficiencia,
            dp.escolaridade,
            dp.renda,
            d.domicilio,
            m.membros,
            safe_cast(dp.cpf as int64) as cpf_particao
        from dados dp
        left join
            membros m
            on dp.id_familia = m.id_familia
            and dp.data_particao = m.data_particao
        left join
            domicilio d
            on dp.id_familia = d.id_familia
            and dp.data_particao = d.data_particao
    )

select *
from final_data
