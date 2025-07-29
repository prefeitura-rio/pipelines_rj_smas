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
            cron="0 10 * * *",
            start_date=datetime(2024, 1, 1, 18, 0, 0),
            labels=[constants.SMAS_AGENT_LABEL.value],
            parameter_defaults={
                "dump_mode": "append",
            },
        )
    ]
)
