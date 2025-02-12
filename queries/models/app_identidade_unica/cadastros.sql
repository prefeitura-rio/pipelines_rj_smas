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
        select distinct
            trim(dp.cpf) as cpf,
            dp.id_membro_familia,
            dp.id_familia,
            dp.data_particao,
            {{ proper_br('i.nome') }} as nome,
            {{ proper_br('i.raca_cor') }} as raca_cor,
            {{ proper_br('i.sexo') }} as sexo,
            {{ proper_br('i.municipio_nascimento') }} as municipio_nascimento,
            lower(i.sigla_uf_municipio_nascimento) as sigla_uf_municipio_nascimento,
            {{ proper_br('i.estado_cadastral') }} as estado_cadastral,
            {{ proper_br('i.parentesco_responsavel_familia') }}
            as parentesco_responsavel_familia,

            i.data_nascimento,
            i.data_ultima_atualizacao,
            i.data_cadastro,
            {{ proper_br('i.nome_mae') }} as nome_mae,
            {{ proper_br('i.nome_pai') }} as nome_pai,
            i.trabalho_infantil,
        from `rj-smas.protecao_social_cadunico.documento_pessoa` dp
        left join
            `rj-smas.protecao_social_cadunico.identificacao_primeira_pessoa` i
            on dp.id_membro_familia = i.id_membro_familia
            and dp.id_familia = i.id_familia
            and dp.data_particao = i.data_particao
        where dp.cpf is not null
    ),

    identificacao_controle as (
        select
            id_familia,
            data_particao,
            valor_renda_media,
            valor_renda_media_original,

            {{ proper_br('condicao_cadastro') }} as condicao_cadastral_familia,
            {{ proper_br('estado_cadastro') }} as estado_cadastral_familia,
            data_alteracao as data_alteracao_familia,
            data_limite_catastro_atual as data_limite_cadastro_atual_familia,

            cep,
            {{ proper_br('localidade') }} as localidade,
            {{ proper_br('tipo_logradouro') }} as tipo_logradouro,
            {{ proper_br('logradouro') }} as logradouro,
            numero_logradouro,
            {{ proper_br('titulo_logradouro') }} as titulo_logradouro,
            {{ proper_br('complemento') }} as complemento,
            {{ proper_br('complemento_adicional') }} as complemento_adicional,
            {{ proper_br('unidade_territorial') }} as unidade_territorial

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
            safe_cast(
                safe_cast(ic.valor_renda_media_original as int64) / 100 as float64
            ) as renda_media_familia,
            ic.valor_renda_media_original as renda_media_familia_original,
            r.data_particao,
            safe_cast(r.renda_outras_rendas as int64) as renda_outras_rendas,
            safe_cast(r.renda_emprego_ultimo_mes as int64) as renda_emprego_ultimo_mes,
            safe_cast(r.renda_aposentadoria as int64) as renda_aposentadoria,
            safe_cast(r.renda_bruta_12_meses as int64) as renda_bruta_12_meses,
            safe_cast(r.renda_doacao as int64) as renda_doacao,
            safe_cast(r.renda_pensao_alimenticia as int64) as renda_pensao_alimenticia,
            safe_cast(r.renda_seguro_desemprego as int64) as renda_seguro_desemprego,
            safe_cast(r.nao_recebe_remuneracao as int64) as nao_recebe_remuneracao,
            safe_cast(r.funcao_principal_trabalho as int64) as funcao_principal_trabalho
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
                    safe_cast(f.despesa_agua_esgoto as int64) as despesa_agua_esgoto,
                    safe_cast(f.despesa_alimentacao as int64) as despesa_alimentacao,
                    safe_cast(f.despesa_aluguel as int64) as despesa_aluguel,
                    safe_cast(f.despesa_energia as int64) as despesa_energia,
                    safe_cast(f.despesa_gas as int64) as despesa_gas,
                    safe_cast(f.despesa_transporte as int64) as despesa_transporte
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
            {{ proper_br('curso_mais_elevado_frequentou') }}
            as curso_mais_elevado_frequentou,
        from `rj-smas.protecao_social_cadunico.escolaridade`
    ),

    condicao_rua as (
        select id_familia, id_membro_familia, data_particao, true as condicao_rua
        from `rj-smas.protecao_social_cadunico.condicao_rua`
    ),

    rank_membros as (
        select
            cpf,
            id_membro_familia,
            nome,
            parentesco_responsavel_familia,
            id_familia,
            data_particao,
            row_number() over (
                partition by cpf, id_familia order by data_particao desc
            ) as rn
        from documento_pessoa_tb
    ),

    membros as (
        select
            id_familia,
            data_particao,
            array_agg(
                struct(cpf, id_membro_familia, nome, parentesco_responsavel_familia)
            ) as membros
        from rank_membros
        where rn = 1
        group by id_familia, data_particao
    ),

    endereco as (
        select
            id_familia,
            data_particao,

            cep,
            localidade,
            tipo_logradouro,
            logradouro,
            numero_logradouro,
            titulo_logradouro,
            complemento,
            complemento_adicional,
            unidade_territorial
        from identificacao_controle
    ),

    dados_familia as (
        select
            id_familia,
            data_particao,

            condicao_cadastral_familia,
            estado_cadastral_familia,
            data_alteracao_familia,
            data_limite_cadastro_atual_familia
        from identificacao_controle
    ),

    documento_pessoa_tb_filter as (
        select
            dp.cpf,
            dp.id_membro_familia,
            dp.id_familia,
            dp.data_particao,
            count(distinct dp.cpf) over (
                partition by dp.id_familia, dp.data_particao
            ) as numeros_membros_familia,
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

            cr.condicao_rua,

            en.cep,
            en.localidade,
            en.tipo_logradouro,
            en.logradouro,
            en.numero_logradouro,
            en.titulo_logradouro,
            en.complemento,
            en.complemento_adicional,
            en.unidade_territorial,

            df.condicao_cadastral_familia,
            df.estado_cadastral_familia,
            df.data_alteracao_familia,
            df.data_limite_cadastro_atual_familia

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
        left join
            endereco as en
            on dp.id_familia = en.id_familia
            and dp.data_particao = en.data_particao
        left join
            dados_familia as df
            on dp.id_familia = df.id_familia
            and dp.data_particao = df.data_particao

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
                    lower(dp.raca_cor) as raca_cor,
                    lower(dp.sexo) as sexo,
                    dp.municipio_nascimento,
                    lower(
                        dp.sigla_uf_municipio_nascimento
                    ) as sigla_uf_municipio_nascimento,
                    dp.estado_cadastral,

                    dp.parentesco_responsavel_familia,
                    dp.data_nascimento,
                    dp.data_ultima_atualizacao,
                    dp.data_cadastro,
                    dp.nome_mae,
                    dp.nome_pai,
                    dp.condicao_rua,
                    dp.trabalho_infantil,

                    dp.condicao_cadastral_familia,
                    dp.estado_cadastral_familia,
                    dp.data_alteracao_familia,
                    dp.data_limite_cadastro_atual_familia,

                    numeros_membros_familia
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
            ) as escolaridade,

            array_agg(
                struct(
                    dp.cep,
                    dp.localidade,
                    dp.tipo_logradouro,
                    dp.logradouro,
                    dp.numero_logradouro,
                    dp.titulo_logradouro,
                    dp.complemento,
                    dp.complemento_adicional,
                    dp.unidade_territorial
                )
            ) as endereco

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
            dp.endereco,
            d.domicilio,
            array(
                select
                    struct(
                        m.cpf,
                        m.id_membro_familia,
                        m.nome,
                        m.parentesco_responsavel_familia
                    )
                from unnest(m.membros) m
                where m.cpf != dp.cpf
            ) as membros,
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
