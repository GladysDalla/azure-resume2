import azure.functions as func
import logging
import json
import os
from azure.cosmos import CosmosClient, exceptions
from azure.keyvault.secrets import SecretClient
from azure.identity import ManagedIdentityCredential

app = func.FunctionApp(http_auth_level=func.AuthLevel.ANONYMOUS)

# Configure logging
logging.basicConfig(level=logging.INFO)

@app.route(route="visitor", methods=["GET", "POST", "OPTIONS"])
def visitor_counter(req: func.HttpRequest) -> func.HttpResponse:
    logging.info(f'Visitor counter function processed a {req.method} request.')
    
    # Handle CORS preflight requests
    if req.method == "OPTIONS":
        return func.HttpResponse(
            "",
            status_code=200,
            headers={
                "Access-Control-Allow-Origin": "*",
                "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
                "Access-Control-Allow-Headers": "Content-Type, Authorization",
                "Access-Control-Max-Age": "86400"
            }
        )
    
    try:
        # Get environment variables with fallbacks
        vault_url = os.environ.get('KEY_VAULT_URI')
        if not vault_url:
            logging.error("KEY_VAULT_URI environment variable not set")
            vault_url = 'https://azure-resume-kv-default.vault.azure.net/'
        
        logging.info(f'Using Key Vault URL: {vault_url}')
        
        # Get Cosmos DB connection from Key Vault using Managed Identity
        credential = ManagedIdentityCredential()
        secret_client = SecretClient(vault_url=vault_url, credential=credential)
        
        # Get Cosmos DB connection string
        try:
            cosmos_connection = secret_client.get_secret("cosmos-connection-string").value
            logging.info('Successfully retrieved Cosmos DB connection string from Key Vault')
        except Exception as e:
            logging.error(f"Failed to retrieve Cosmos DB connection string: {e}")
            raise
        
        # Initialize Cosmos client
        client = CosmosClient.from_connection_string(cosmos_connection)
        database_name = 'resumedb'
        container_name = 'visitors'
        
        try:
            database = client.get_database_client(database_name)
            container = database.get_container_client(container_name)
            logging.info(f'Connected to Cosmos DB: {database_name}/{container_name}')
        except Exception as e:
            logging.error(f"Failed to connect to Cosmos DB: {e}")
            raise
        
        # Counter document ID
        counter_id = "visitor-count"
        
        if req.method == "GET":
            logging.info('Processing GET request - retrieving current count')
            # Get current visitor count
            try:
                counter_doc = container.read_item(item=counter_id, partition_key=counter_id)
                count = counter_doc.get('count', 0)
                logging.info(f'Retrieved current count: {count}')
            except exceptions.CosmosResourceNotFoundError:
                logging.info('Counter document not found, initializing with count 0')
                count = 0
                # Create initial counter document
                counter_doc = {
                    'id': counter_id,
                    'count': count
                }
                try:
                    container.create_item(body=counter_doc)
                    logging.info('Created initial counter document')
                except Exception as e:
                    logging.error(f'Failed to create initial counter document: {e}')
                    raise
            except Exception as e:
                logging.error(f'Error reading counter document: {e}')
                raise
            
            return func.HttpResponse(
                json.dumps({'count': count}),
                status_code=200,
                mimetype="application/json",
                headers={
                    "Access-Control-Allow-Origin": "*",
                    "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
                    "Access-Control-Allow-Headers": "Content-Type, Authorization"
                }
            )
        
        elif req.method == "POST":
            logging.info('Processing POST request - incrementing count')
            # Increment visitor count
            try:
                counter_doc = container.read_item(item=counter_id, partition_key=counter_id)
                current_count = counter_doc.get('count', 0)
                new_count = current_count + 1
                counter_doc['count'] = new_count
                container.replace_item(item=counter_id, body=counter_doc)
                logging.info(f'Incremented count from {current_count} to {new_count}')
            except exceptions.CosmosResourceNotFoundError:
                logging.info('Counter document not found during POST, creating new one')
                new_count = 1
                counter_doc = {
                    'id': counter_id,
                    'count': new_count
                }
                try:
                    container.create_item(body=counter_doc)
                    logging.info('Created new counter document with count 1')
                except Exception as e:
                    logging.error(f'Failed to create counter document during POST: {e}')
                    raise
            except Exception as e:
                logging.error(f'Error updating counter document: {e}')
                raise
            
            return func.HttpResponse(
                json.dumps({'count': new_count}),
                status_code=200,
                mimetype="application/json",
                headers={
                    "Access-Control-Allow-Origin": "*",
                    "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
                    "Access-Control-Allow-Headers": "Content-Type, Authorization"
                }
            )
    
    except Exception as e:
        error_message = str(e)
        logging.error(f"Error in visitor counter: {error_message}")
        
        # Return different error codes based on the type of error
        if "authentication" in error_message.lower() or "unauthorized" in error_message.lower():
            status_code = 401
        elif "not found" in error_message.lower():
            status_code = 404
        else:
            status_code = 500
            
        return func.HttpResponse(
            json.dumps({
                'error': 'Internal server error',
                'details': error_message if os.environ.get('ENVIRONMENT') == 'development' else 'Please try again later'
            }),
            status_code=status_code,
            mimetype="application/json",
            headers={
                "Access-Control-Allow-Origin": "*",
                "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
                "Access-Control-Allow-Headers": "Content-Type, Authorization"
            }
        )

# Health check endpoint
@app.route(route="health", methods=["GET", "OPTIONS"])
def health_check(req: func.HttpRequest) -> func.HttpResponse:
    logging.info('Health check requested.')
    
    # Handle CORS preflight requests
    if req.method == "OPTIONS":
        return func.HttpResponse(
            "",
            status_code=200,
            headers={
                "Access-Control-Allow-Origin": "*",
                "Access-Control-Allow-Methods": "GET, OPTIONS",
                "Access-Control-Allow-Headers": "Content-Type, Authorization",
                "Access-Control-Max-Age": "86400"
            }
        )
    
    try:
        # Test Key Vault connection
        vault_url = os.environ.get('KEY_VAULT_URI', 'https://azure-resume-kv-default.vault.azure.net/')
        credential = ManagedIdentityCredential()
        secret_client = SecretClient(vault_url=vault_url, credential=credential)
        
        # Try to get a secret to test the connection
        try:
            secret_client.get_secret("cosmos-connection-string")
            keyvault_status = "healthy"
        except Exception as e:
            logging.warning(f"Key Vault check failed: {e}")
            keyvault_status = "unhealthy"
        
        health_data = {
            'status': 'healthy' if keyvault_status == 'healthy' else 'degraded',
            'message': 'Azure Resume API is running',
            'components': {
                'keyvault': keyvault_status,
                'function': 'healthy'
            },
            'timestamp': func.datetime.utcnow().isoformat()
        }
        
        return func.HttpResponse(
            json.dumps(health_data),
            status_code=200,
            mimetype="application/json",
            headers={
                "Access-Control-Allow-Origin": "*"
            }
        )
    except Exception as e:
        logging.error(f"Health check failed: {e}")
        return func.HttpResponse(
            json.dumps({
                'status': 'unhealthy',
                'message': 'Health check failed',
                'error': str(e)
            }),
            status_code=503,
            mimetype="application/json",
            headers={
                "Access-Control-Allow-Origin": "*"
            }
        )