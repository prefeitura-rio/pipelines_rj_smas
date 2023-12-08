# -*- coding: utf-8 -*-
"""
CADUNICO: INGEST RAW FLOW.
"""

from prefect import Parameter, case
from prefect.run_configs import KubernetesRun
from prefect.storage import GCS
from prefect.tasks.prefect import create_flow_run, wait_for_flow_run
from prefect.utilities.edges import unmapped
from prefeitura_rio.core import settings
from prefeitura_rio.pipelines_utils.custom import Flow
from prefeitura_rio.pipelines_utils.prefect import (
    task_get_current_flow_run_labels,
    task_get_flow_group_id,
)
from prefeitura_rio.pipelines_utils.state_handlers import handler_inject_bd_credentials

from pipelines.cadunico.ingest_raw.tasks import (
    append_data_to_storage,
    create_table_if_not_exists,
    get_dbt_models_to_materialize_task,
    get_existing_partitions,
    get_files_to_ingest,
    get_project_id_task,
    ingest_file,
    need_to_ingest,
)
from pipelines.constants import constants

with Flow(
    name="CadUnico: Ingestão de dados brutos", state_handlers=[handler_inject_bd_credentials]
) as cadunico__ingest_raw__flow:
    # Parameters
    dataset_id = Parameter("dataset_id", default="protecao_social_cadunico")
    table_id = Parameter("table_id", default="registro_familia")
    dump_mode = Parameter("dump_mode", default="append")
    biglake_table = Parameter("biglake_table", default=True)
    ingested_files_output = Parameter("ingested_files_output", default="/tmp/ingested_files/")
    prefix_raw_area = Parameter(
        "prefix_raw_area", default="raw/protecao_social_cadunico/registro_familia"
    )
    prefix_staging_area = Parameter(
        "prefix_staging_area", default="staging/protecao_social_cadunico/registro_familia"
    )

    materialize_after_dump = Parameter("materialize_after_dump", default=True, required=False)
    layout_dataset_id = Parameter("layout_dataset_id", default="protecao_social_cadunico")
    layout_table_id = Parameter("layout_table_id", default="layout")
    layout_output_path = Parameter("layout_output_path", default="/tmp/cadunico/layout_parsed/")
    force_create_models = Parameter("force_create_models", default=False, required=False)
    force_materialize_harmonized_dbt_models = Parameter(
        "force_materialize_harmonized_dbt_models", default=False, required=False
    )
    # Tasks
    project_id = get_project_id_task()
    materialization_flow_id = task_get_flow_group_id(flow_name=settings.FLOW_NAME_EXECUTE_DBT_MODEL)
    materialization_labels = task_get_current_flow_run_labels()

    existing_partitions = get_existing_partitions(
        prefix=prefix_staging_area, bucket_name=project_id
    )
    existing_partitions.set_upstream(project_id)

    files_to_ingest = get_files_to_ingest(
        prefix=prefix_raw_area, partitions=existing_partitions, bucket_name=project_id
    )
    files_to_ingest.set_upstream(existing_partitions)

    need_to_ingest_bool = need_to_ingest(files_to_ingest=files_to_ingest)
    need_to_ingest_bool.set_upstream(files_to_ingest)

    with case(need_to_ingest_bool, True):
        ingested_files = ingest_file.map(
            blob=files_to_ingest, output_directory=unmapped(ingested_files_output)
        )
        ingested_files.set_upstream(need_to_ingest_bool)

        create_table = create_table_if_not_exists(
            dataset_id=dataset_id,
            table_id=table_id,
            biglake_table=biglake_table,
        )
        create_table.set_upstream(ingested_files)

        append_data_to_gcs = append_data_to_storage(
            data_path=ingested_files_output,
            dataset_id=dataset_id,
            table_id=table_id,
            dump_mode=dump_mode,
            biglake_table=biglake_table,
        )

        append_data_to_gcs.set_upstream(create_table)

        with case(materialize_after_dump, True):
            # PROD TABLES
            dump_prod_tables_to_materialize_parameters = get_dbt_models_to_materialize_task(
                dataset_id=dataset_id,
                table_id=table_id,
                project_id=project_id,
                layout_dataset_id=layout_dataset_id,
                layout_table_id=layout_table_id,
                layout_output_path=layout_output_path,
                force_create_models=force_create_models,
            )
            dump_prod_tables_to_materialize_parameters.set_upstream(append_data_to_gcs)

            dum_prod_materialization_flow_runs = create_flow_run.map(
                flow_id=unmapped(materialization_flow_id),
                parameters=dump_prod_tables_to_materialize_parameters,
                labels=unmapped(materialization_labels),
            )

            dump_prod_wait_for_flow_run = wait_for_flow_run.map(
                flow_run_id=dum_prod_materialization_flow_runs,
                stream_states=unmapped(True),
                stream_logs=unmapped(True),
                raise_final_state=unmapped(True),
            )
    # materialize only prod dbt models
    with case(force_materialize_harmonized_dbt_models, True):
        # PROD TABLES
        only_prod_tables_to_materialize_parameters = get_dbt_models_to_materialize_task(
            dataset_id=dataset_id,
            table_id=table_id,
            project_id=project_id,
            layout_dataset_id=layout_dataset_id,
            layout_table_id=layout_table_id,
            layout_output_path=layout_output_path,
            force_create_models=force_create_models,
        )
        only_prod_tables_to_materialize_parameters.set_upstream(need_to_ingest_bool)

        only_prod_materialization_flow_runs = create_flow_run.map(
            flow_id=unmapped(materialization_flow_id),
            parameters=only_prod_tables_to_materialize_parameters,
            labels=unmapped(materialization_labels),
        )

        only_prod_wait_for_flow_run = wait_for_flow_run.map(
            flow_run_id=only_prod_materialization_flow_runs,
            stream_states=unmapped(True),
            stream_logs=unmapped(True),
            raise_final_state=unmapped(True),
        )


# Storage and run configs
cadunico__ingest_raw__flow.storage = GCS(constants.GCS_FLOWS_BUCKET.value)
cadunico__ingest_raw__flow.run_config = KubernetesRun(image=constants.DOCKER_IMAGE.value)
