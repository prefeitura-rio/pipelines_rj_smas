# -*- coding: utf-8 -*-
from typing import Any, Dict, List, Optional

import pandas as pd
import requests
from prefect import task
from prefeitura_rio.pipelines_utils.logging import log
from prefeitura_rio.pipelines_utils.infisical import get_secret
from pipelines.datametrica.agendamentos.models import Agendamento


@task
def get_datametrica_credentials() -> Dict[str, str]:
    """
    Recupera as credenciais da API da Datametrica do Infisical.

    Returns:
        Dict com 'url' e 'token'
    """
    

    from pipelines.constants import constants

    log("Recuperando credenciais da Datametrica do Infisical")

    try:
        #TODO: Adjustar infisical abaixo
        url = get_secret(, "URL")
        token = get_secret(, "TOKEN")

        log("Credenciais recuperadas com sucesso")
        return {"url": url, "token": token}

    except Exception as e:
        log(f"Erro ao recuperar credenciais: {e}")
        raise


@task
def fetch_agendamentos_from_api(
    credentials: Dict[str, str], date: Optional[str] = None
) -> List[Dict[str, Any]]:
    """
    Busca os agendamentos da API da Datametrica.

    Args:
        credentials: Dict com 'url' e 'token' da API
        date: Data no formato YYYY-MM-DD. Se None, usa o dia seguinte.

    Returns:
        Lista de dicionários com os dados dos agendamentos
    """
    from pipelines.datametrica.agendamentos.utils import build_agendamentos_url

    url = build_agendamentos_url(credentials["url"], date)

    log(f"Buscando agendamentos na URL: {url}")

    headers = {
        "Authorization": f"Bearer {credentials['token']}",
        "Content-Type": "application/json",
    }

    try:
        response = requests.get(url, headers=headers, timeout=30)
        response.raise_for_status()

        agendamentos_data = response.json()
        log(f"Recuperados {len(agendamentos_data)} agendamentos")

        return agendamentos_data

    except requests.exceptions.RequestException as e:
        log(f"Erro ao buscar agendamentos: {e}")
        raise
    except Exception as e:
        log(f"Erro inesperado: {e}")
        raise


@task
def transform_agendamentos_data(agendamentos_data: List[Dict[str, Any]]) -> List[Agendamento]:
    """
    Transforma os dados brutos em objetos Agendamento tipados.
    """
    log(f"Transformando {len(agendamentos_data)} registros")

    agendamentos = []
    for data in agendamentos_data:
        try:
            agendamento = Agendamento(
                id=data["id"],
                id_capacidade=data["id_capacidade"],
                nome_completo=data["nome_completo"],
                primeiro_nome=data["primeiro_nome"],
                cpf=data["cpf"],
                telefone=data["telefone"],
                tipo=data["tipo"],
                data_hora=data["data_hora"],
                nome=data["nome"],
                endereco=data["endereco"],
                bairro=data["bairro"],
            )
            agendamentos.append(agendamento)
        except KeyError as e:
            log(f"Erro ao processar registro: campo {e} não encontrado")
            raise
        except Exception as e:
            log(f"Erro inesperado ao processar registro: {e}")
            raise

    log(f"Transformação concluída: {len(agendamentos)} registros processados")
    return agendamentos


@task
def convert_agendamentos_to_dataframe(agendamentos: List[Agendamento]) -> pd.DataFrame:
    """
    Converte a lista de agendamentos para um DataFrame pandas.

    Returns:
        DataFrame com os dados dos agendamentos
    """
    log(f"Convertendo {len(agendamentos)} agendamentos para DataFrame")

    data = []
    for agendamento in agendamentos:
        data.append(
            {
                "id": agendamento.id,
                "id_capacidade": agendamento.id_capacidade,
                "nome_completo": agendamento.nome_completo,
                "primeiro_nome": agendamento.primeiro_nome,
                "cpf": agendamento.cpf,
                "telefone": agendamento.telefone,
                "tipo": agendamento.tipo,
                "data_hora": agendamento.data_hora,
                "unidade_nome": agendamento.nome,
                "unidade_endereco": agendamento.endereco,
                "unidade_bairro": agendamento.bairro,
            }
        )

    df = pd.DataFrame(data)
    log(f"DataFrame criado com {len(df)} registros e {len(df.columns)} colunas")

    return df
