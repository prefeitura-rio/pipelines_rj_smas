# -*- coding: utf-8 -*-
from prefect import Parameter, case
from prefect.executors import LocalDaskExecutor
from prefect.run_configs import KubernetesRun
from prefect.storage import GCS
from prefeitura_rio.pipelines_utils.custom import Flow

# pylint: disable=E0611, E0401
from prefeitura_rio.pipelines_utils.state_handlers import (
    handler_initialize_sentry,
    handler_inject_bd_credentials,
)
from prefeitura_rio.pipelines_utils.tasks import (
    create_table_and_upload_to_gcs,
    task_run_dbt_model_task,
)

from pipelines.api_datametrica.agendamentos.schedules import (  # pylint: disable=E0611, E0401
    daily_schedule,
)
from pipelines.api_datametrica.agendamentos.tasks import (  # pylint: disable=E0611, E0401
    convert_agendamentos_to_dataframe,
    fetch_agendamentos_from_api,
    get_datametrica_credentials,
    transform_agendamentos_data,
)
from pipelines.constants import constants  # pylint: disable=E0611, E0401
from pipelines.utils.tasks import create_date_partitions

with Flow(
    name="rj-smas: Datametrica - Extração de agendamentos",
    state_handlers=[
        handler_initialize_sentry,
        handler_inject_bd_credentials,
    ],
    parallelism=10,
    skip_if_running=False,
) as datametrica_agendamentos_flow:
    #########################
    #  Define parameters    #
    #########################

    dataset_id = Parameter("dataset_id", default="brutos_data_metrica_staging", required=False)
    table_id = Parameter("table_id", default="agendamentos_cadunicos", required=False)
    dump_mode = Parameter("dump_mode", default="append", required=False)
    materialize_after_dump = Parameter("materialize_after_dump", default=True, required=False)
    date_param = Parameter("date", default=None, required=False)

    #########################
    #  Start flow           #
    #########################

    credentials = get_datametrica_credentials()

    raw_data = fetch_agendamentos_from_api(credentials=credentials, date=date_param)

    processed_data = transform_agendamentos_data(raw_data)

    df = convert_agendamentos_to_dataframe(processed_data)

    partitions_path = create_date_partitions(
        dataframe=df,
        partition_column="data_hora",
        file_format="csv",
        root_folder="./data_agendamentos/",
    )

    # Upload to GCS and BigQuery
    create_table = create_table_and_upload_to_gcs(
        data_path=partitions_path,
        dataset_id=dataset_id,
        table_id=table_id,
        dump_mode=dump_mode,
        biglake_table=False,
    )

    with case(materialize_after_dump, True):
        run_dbt = task_run_dbt_model_task(
            dataset_id=dataset_id,
            table_id=table_id,
        )
        run_dbt.set_upstream(create_table)

# Storage and run configs
datametrica_agendamentos_flow.state_handlers = [handler_inject_bd_credentials]
datametrica_agendamentos_flow.storage = GCS(constants.GCS_FLOWS_BUCKET.value)
datametrica_agendamentos_flow.run_config = KubernetesRun(
    image=constants.DOCKER_IMAGE.value, labels=[constants.SMAS_AGENT_LABEL.value]
)
datametrica_agendamentos_flow.schedule = daily_schedule
datametrica_agendamentos_flow.executor = LocalDaskExecutor(num_workers=1)
