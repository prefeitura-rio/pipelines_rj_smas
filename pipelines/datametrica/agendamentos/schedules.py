# -*- coding: utf-8 -*-
"""
Schedules for datametrica agendamentos pipeline
"""
from datetime import datetime, timedelta

from prefect.schedules import Schedule
from prefect.schedules.clocks import IntervalClock

from pipelines.constants import constants

hour_schedule = Schedule(
    clocks=[
        IntervalClock(
            interval=timedelta(minutes=60),
            start_date=datetime(2021, 1, 1, 0, 4, 0),
            labels=[constants.CRM_AGENT_LABEL.value],
            parameter_defaults={
                "dump_mode": "append",
            },
        )
    ]
)

ten_min_schedule = Schedule(
    clocks=[
        IntervalClock(
            interval=timedelta(minutes=10),
            start_date=datetime(2021, 1, 1, 0, 4, 0),
            labels=[constants.CRM_AGENT_LABEL.value],
            parameter_defaults={
                "dump_mode": "append",
            },
        )
    ]
)

daily_schedule = Schedule(
    clocks=[
        IntervalClock(
            interval=timedelta(days=1),
            start_date=datetime(2021, 1, 1, 0, 4, 0),
            labels=[constants.CRM_AGENT_LABEL.value],
            parameter_defaults={
                "dump_mode": "append",
            },
        )
    ]
)
