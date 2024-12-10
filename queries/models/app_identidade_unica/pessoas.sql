with
    documento_pessoa_tb as (
        select
            trim(cpf) as cpf,
            id_membro_familia,
            id_familia,
            data_particao,
            row_number() over (partition by cpf order by data_particao desc) as rank,
            {{ validate_cpf("cpf") }} as cpf_valido_indicador,
        from `rj-smas.protecao_social_cadunico.documento_pessoa`
        where cpf is not null
        order by cpf, rank
        limit 100
    )

select
    cpf,
    cpf_valido_indicador,
    id_membro_familia,
    id_familia,

    array_agg(struct(data_particao, rank)) as datas

from documento_pessoa_tb
where rank <= 2
group by cpf, cpf_valido_indicador, id_membro_familia, id_familia