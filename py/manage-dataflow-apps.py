import yaml
import oci
import os
import sys
from typing import Any, Dict

def load_yaml(file_path: str) -> Dict[str, Any]:
    try:
        with open(file_path, 'r') as stream:
            return yaml.safe_load(stream)
    except Exception as e:
        print(f"Error loading YAML file: {file_path}")
        print(e)
        raise

def get_existing_applications(client, compartment_id: str) -> Dict[str, Any]:
    try:
        applications = client.list_applications(compartment_id).data
        return {app.display_name: app.id for app in applications}
    except oci.exceptions.ServiceError as e:
        print(f"Error: Failed to retrieve applications for compartment '{compartment_id}'.")
        print(e)
        raise

def create_or_update_application(client, compartment_id, dataflow_app, overwrite):
    try:
        existing_apps = get_existing_applications(client, compartment_id)
        display_name = dataflow_app['display_name']
        
        if display_name in existing_apps:
            app_id = existing_apps[display_name]
            if overwrite:
                modified_config = dataflow_app.copy()
                # Remove 'type' key from modified_config if it exists
                if 'type' in modified_config:
                    modified_config.pop('type')
                print(f"Updating existing application: {display_name}")
                client.update_application(
                    oci.data_flow.models.UpdateApplicationDetails(
                        **modified_config
                    ),
                    application_id=app_id
                )
            else:
                print(f"Application with display name '{display_name}' already exists. Skipping creation.")
        else:
            print(f"Creating new application: {display_name}")
            create_application_response = client.create_application(
                create_application_details=oci.data_flow.models.CreateApplicationDetails(
                    compartment_id=compartment_id,
                    **dataflow_app
                )
            )
            print(create_application_response.data)
    except oci.exceptions.ServiceError as e:
        print(f"Error: Failed to create or update application '{dataflow_app['display_name']}'.")
        print(e)
        raise
    except KeyError as e:
        print(f"Error: Missing required configuration key '{e.args[0]}' in configuration.")
        raise
    except Exception as e:
        print(f"Unexpected error: {str(e)}")
        raise

def main(config_file: str):
    try:
        config_data = load_yaml(config_file)
    except Exception as e:
        print(f"Error loading configuration file '{config_file}': {e}")
        return
    
    environment_data = config_data.get('environments_list')[0]
    environment = environment_data.get('name')
    compartment_id = environment_data.get('compartment_id')

    dataflow_app = config_data['dataflow_app'][0]['details']  # Adjusted path to access 'details'

    overwrite = os.getenv('OVERWRITE_EXISTING', 'no').lower() == 'yes'
    oci_config = oci.config.from_file(os.getenv('OCI_CONFIG_FILE', '~/.oci/config'))
    data_flow_client = oci.data_flow.DataFlowClient(oci_config)
    
    create_or_update_application(data_flow_client, compartment_id, dataflow_app, overwrite)

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python manage_dataflow_apps.py <config_file>")
        sys.exit(1)
    
    config_file = sys.argv[1]
    main(config_file)