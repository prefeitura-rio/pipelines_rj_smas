# -*- coding: utf-8 -*-
# pylint: disable=invalid-name
# flake8: noqa: E501
from typing import Any, Dict, List, Optional

import pandas as pd
import requests
from prefect import task  # pylint: disable=E0611, E0401
from prefeitura_rio.pipelines_utils.infisical import (
    get_secret,  # pylint: disable=E0611, E0401
)
from prefeitura_rio.pipelines_utils.logging import log  # pylint: disable=E0611, E0401

from pipelines.constants import constants  # pylint: disable=E0611, E0401


@task
def get_datametrica_credentials() -> Dict[str, str]:
    """
    Recupera as credenciais da API da Datametrica do Infisical.

    Returns:
        Dict com 'url' e 'token'
    """

    log("Recuperando credenciais da Datametrica do Infisical")

    try:
        dm_path = constants.DATAMETRICA_PATH.value
        url = constants.DATAMETRICA_URL.value
        token = constants.DATAMETRICA_TOKEN.value

        url = get_secret(url, path=dm_path)
        log(f"URL: {url}")
        url = url[url]
        token = get_secret(token, path=dm_path)[token]

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
    # Build URL inline to avoid import issues
    base_url = credentials["url"].rstrip("/")
    if date is None:
        from datetime import datetime, timedelta

        date = (datetime.now() + timedelta(days=1)).strftime("%Y-%m-%d")
    url = f"{base_url}/api/agendamentos/{date}"

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
def transform_agendamentos_data(agendamentos_data: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
    """
    Transforma e valida os dados brutos dos agendamentos.
    """
    log(f"Transformando {len(agendamentos_data)} registros")

    agendamentos = []
    for data in agendamentos_data:
        try:
            agendamento = {
                "id": data["id"],
                "id_capacidade": data["id_capacidade"],
                "nome_completo": data["nome_completo"],
                "primeiro_nome": data["primeiro_nome"],
                "cpf": data["cpf"],
                "telefone": data["telefone"],
                "tipo": data["tipo"],
                "data_hora": data["data_hora"],
                "unidade_nome": data["nome"],
                "unidade_endereco": data["endereco"],
                "unidade_bairro": data["bairro"],
            }
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
def convert_agendamentos_to_dataframe(agendamentos: List[Dict[str, Any]]) -> pd.DataFrame:
    """
    Converte a lista de agendamentos para um DataFrame pandas.

    Returns:
        DataFrame com os dados dos agendamentos
    """
    log(f"Convertendo {len(agendamentos)} agendamentos para DataFrame")

    df = pd.DataFrame(agendamentos)
    log(f"DataFrame criado com {len(df)} registros e {len(df.columns)} colunas")

    return df
