# -*- coding: utf-8 -*-
from dataclasses import dataclass


@dataclass
class Agendamento:
    """
    Modelo de dados para representar um agendamento da Datametrica.
    """
    id: int
    id_capacidade: int
    nome_completo: str
    primeiro_nome: str
    cpf: str
    telefone: str
    tipo: str
    data_hora: str
    nome: str  # nome da unidade
    endereco: str  # endereco da unidade
    bairro: str  # bairro da unidade