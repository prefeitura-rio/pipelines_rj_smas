# -*- coding: utf-8 -*-
"""
CADUNICO: INGEST RAW FLOW.
"""

from copy import deepcopy

from prefect.run_configs import KubernetesRun
from prefect.storage import GCS
from prefeitura_rio.pipelines_templates.geolocate import utils_geolocate_flow
from prefeitura_rio.pipelines_utils.prefect import set_default_parameters
from prefeitura_rio.pipelines_utils.state_handlers import handler_inject_bd_credentials

from pipelines.cadunico.geolocate.schedules import cadunico_geolocate_schedule
from pipelines.constants import constants

cadunico_geolocate_flow = deepcopy(utils_geolocate_flow)
cadunico_geolocate_flow.state_handlers = [handler_inject_bd_credentials]
cadunico_geolocate_flow.name = "GEOLOCATE: cadunico - Geolocalização de endereços do Cadunico"
cadunico_geolocate_flow.storage = GCS(constants.GCS_FLOWS_BUCKET.value)

cadunico_geolocate_flow.run_config = KubernetesRun(
    image=constants.DOCKER_IMAGE.value,
    labels=[
        constants.RJ_SMAS_AGENT_LABEL.value,
    ],
)

cadunico_geolocate_default_parameters = {
    "source_dataset_id": "protecao_social_cadunico",
    "source_table_id": "endereco",
    "source_table_address_column": "address",
    "destination_dataset_id": "protecao_social_cadunico",
    "destination_table_id": "endereco_geolocalizado",
    "georeference_mode": "distinct",
}
cadunico_geolocate_flow = set_default_parameters(
    cadunico_geolocate_flow, default_parameters=cadunico_geolocate_default_parameters
)

cadunico_geolocate_flow.schedule = cadunico_geolocate_schedule
