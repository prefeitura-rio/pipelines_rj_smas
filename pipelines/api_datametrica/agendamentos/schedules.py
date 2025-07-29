# -*- coding: utf-8 -*-
"""
Schedules for datametrica agendamentos pipeline
"""
from datetime import datetime, timedelta

from prefect.schedules import Schedule
from prefect.schedules.clocks import IntervalClock

from pipelines.constants import constants

daily_schedule = Schedule(
    clocks=[
        IntervalClock(
            interval=timedelta(days=1),
            start_date=datetime(2025, 1, 1, 10, 0, 0),
            labels=[constants.SMAS_AGENT_LABEL.value],
            parameter_defaults={
                "dump_mode": "append",
            },
        )
    ]
)
