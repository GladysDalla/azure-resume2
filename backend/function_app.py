import azure.functions as func
import logging
import json
import os
from azure.cosmos import CosmosClient
from azure.keyvault.secrets import SecretClient
from azure.identity import ManagedIdentityCredential

app = func.FunctionApp(http_auth_level=func.AuthLevel.ANONYMOUS)

@app.route(route="visitor", methods=["GET", "POST"])
def visitor_counter(req: func.HttpRequest) -> func.HttpResponse:
    logging.info('Visitor counter function processed a request.')
    
    try:
        # Get Cosmos DB connection from Key Vault using Managed Identity
        credential = ManagedIdentityCredential()
        vault_url = os.environ.get('KEY_VAULT_URI', 'https://azure-resume-kv-default.vault.azure.net/')
        secret_client = SecretClient(vault_url=vault_url, credential=credential)
        
        # Get Cosmos DB connection string
        cosmos_connection = secret_client.get_secret("cosmos-connection-string").value
        
        # Initialize Cosmos client
        client = CosmosClient.from_connection_string(cosmos_connection)
        database_name = 'resumedb'
        container_name = 'visitors'
        
        database = client.get_database_client(database_name)
        container = database.get_container_client(container_name)
        
        # Counter document ID
        counter_id = "visitor-count"
        
        if req.method == "GET":
            # Get current visitor count
            try:
                counter_doc = container.read_item(item=counter_id, partition_key=counter_id)
                count = counter_doc.get('count', 0)
            except Exception as e:
                logging.info(f"Counter document not found, creating new one: {e}")
                count = 0
                # Create initial counter document
                counter_doc = {
                    'id': counter_id,
                    'count': count
                }
                container.create_item(body=counter_doc)
            
            return func.HttpResponse(
                json.dumps({'count': count}),
                status_code=200,
                mimetype="application/json",
                headers={
                    "Access-Control-Allow-Origin": "*",
                    "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
                    "Access-Control-Allow-Headers": "Content-Type"
                }
            )
        
        elif req.method == "POST":
            # Increment visitor count
            try:
                counter_doc = container.read_item(item=counter_id, partition_key=counter_id)
                new_count = counter_doc.get('count', 0) + 1
                counter_doc['count'] = new_count
                container.replace_item(item=counter_id, body=counter_doc)
            except Exception as e:
                logging.info(f"Counter document not found, creating new one: {e}")
                new_count = 1
                counter_doc = {
                    'id': counter_id,
                    'count': new_count
                }
                container.create_item(body=counter_doc)
            
            return func.HttpResponse(
                json.dumps({'count': new_count}),
                status_code=200,
                mimetype="application/json",
                headers={
                    "Access-Control-Allow-Origin": "*",
                    "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
                    "Access-Control-Allow-Headers": "Content-Type"
                }
            )
    
    except Exception as e:
        logging.error(f"Error in visitor counter: {str(e)}")
        return func.HttpResponse(
            json.dumps({'error': 'Internal server error'}),
            status_code=500,
            mimetype="application/json",
            headers={
                "Access-Control-Allow-Origin": "*",
                "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
                "Access-Control-Allow-Headers": "Content-Type"
            }
        )

# Health check endpoint
@app.route(route="health", methods=["GET"])
def health_check(req: func.HttpRequest) -> func.HttpResponse:
    logging.info('Health check requested.')
    
    return func.HttpResponse(
        json.dumps({
            'status': 'healthy',
            'message': 'Azure Resume API is running'
        }),
        status_code=200,
        mimetype="application/json",
        headers={
            "Access-Control-Allow-Origin": "*"
        }
    )