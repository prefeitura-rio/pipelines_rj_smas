# -*- coding: utf-8 -*-
"""
Schedules for cor
"""

from datetime import timedelta, datetime

from prefect.schedules import Schedule
from prefect.schedules.clocks import IntervalClock

from pipelines.constants import constants


cadunico_geolocate_schedule = Schedule(
    clocks=[
        IntervalClock(
            interval=timedelta(days=1),
            start_date=datetime(2021, 1, 1),
            labels=[
                constants.RJ_SMAC_AGENT_LABEL.value,
            ],
            parameter_defaults={
                "source_dataset_id": "protecao_social_cadunico",
                "source_table_id": "endereco",
                "source_table_address_column": "address",
                "destination_dataset_id": "protecao_social_cadunico",
                "destination_table_id": "endereco_geolocalizado",
                "georeference_mode": "distinct",
            },
        ),
    ],
)
