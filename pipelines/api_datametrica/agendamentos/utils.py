# -*- coding: utf-8 -*-
from datetime import datetime, timedelta
from typing import Optional


def build_agendamentos_url(base_url: str, date: Optional[str] = None) -> str:
    """
    Constrói a URL para buscar agendamentos da API da Datametrica.

    Args:
        base_url: URL base da API (vem do Infisical)
        date: Data no formato YYYY-MM-DD. Se None, usa o dia seguinte.

    Returns:
        URL completa para a API
    """
    if date is None:
        # Data de amanhã no formato YYYY-MM-DD
        date = (datetime.now() + timedelta(days=1)).strftime("%Y-%m-%d")

    # Remove trailing slash se existir
    base_url = base_url.rstrip("/")
    return f"{base_url}/api/agendamentos/{date}"
