from chalice import Chalice, Response
from botocore.exceptions import ClientError
from boto3.dynamodb.conditions import Key
import os, boto3, json, uuid

app = Chalice(app_name='test')

dynamodb = boto3.resource('dynamodb')
dynamodb_table = dynamodb.Table(os.environ['DB_TABLE'])
dynamodb_primary_key = os.environ['PRIMARY_KEY']
dynamodb_secondary_key = os.environ['SECONDARY_KEY']

allowed_origins = [
    'http://localhost:3000'
]

def get_headers(origin = 'http://localhost:3000'):
    return {
        'Access-Control-Allow-Credentials': 'true',
        'Access-Control-Allow-Origin': origin,
        'Access-Control-Allow-Methods': 'OPTIONS,GET,POST,DELETE,PUT',
        'Access-Control-Allow-Headers': 'Content-Type,X-Amz-Date,Authorization,Host,X-Api-Key,X-Amz-Security-Token,X-Amz-User-Agent',
    }


def get_return_response(origin, body = '', status_code=200):
    headers = get_headers(origin)
    try:
        body = json.dumps(body)
    except TypeError as error:
        return Response(
            body='Error: '+str(error),
            status_code=500,
            headers=headers
        )
    return Response(
        body=body,
        status_code=status_code,
        headers=headers
    )


@app.route("/test", methods=['OPTIONS'])
def handler_options():
    print('OPTIONS handler')
    headers = get_headers()
    origin = app.current_request.headers.get('origin', '')
    status_code = 200
    body = 'OK'
    if origin in allowed_origins:
        headers.update({'Access-Control-Allow-Origin': origin})
    else:
        print('OPTIONS handler: Invalid origin ', origin)
        body = 'Invalid origin'
        status_code = 500
    return Response(
        body=body,
        status_code=status_code,
        headers=headers
    )


@app.route("/test", methods=['GET'])
def handler_get():
    print('GET handler')
    origin = app.current_request.headers.get('origin', '')
    if origin not in allowed_origins:
        print('GET handler: Invalid origin', origin)
    try:
        data = dynamodb_table.scan()
    except ClientError as error:
        return get_return_response(origin, error.response['Error']['Message'], status_code=500)
    print('GET handler: Get data', data)
    return_data = data['Items']
    return get_return_response(origin, return_data)


@app.route("/test/{id}", methods=['GET'])
def handler_get_by_id(id):
    print('GET by ID handler')
    origin = app.current_request.headers.get('origin', '')
    if origin not in allowed_origins:
        print('GET by ID handler: Invalid origin', origin)
    try:
        print('GET by ID handler id:', id)
        data = dynamodb_table.query(KeyConditionExpression=Key('id').eq(id))
        print('GET by ID handler: Get data', data)
        return_data = data['Items'][0]
    except (IndexError, ClientError):
        return get_return_response(origin, 'Id not found', status_code=400)
    return get_return_response(origin, return_data)


@app.route("/test", methods=['POST'])
def handler_post():
    print('POST handler')
    origin = app.current_request.headers.get('origin', '')
    if origin not in allowed_origins:
        print('POST handler: Invalid origin', origin)
    try:
        event_body = app.current_request.json_body
    except:
        return get_return_response(origin, 'Invalid request', status_code=400)
    print('POST handler: request', event_body)
    missing_properties, payload = validate_request_payload(event_body)
    if missing_properties:
        print('POST handler: Invalid payload', event_body)
        return get_return_response(origin, 'Invalid request - missing properties: '+str(missing_properties), status_code=400)
    try:
        data = dynamodb_table.put_item(Item=payload)
        print('POST handler: db response', data)
        return_data = payload[dynamodb_primary_key]
        return get_return_response(origin, return_data)
    except ClientError as error:
        print('POST handler: Error ', error.response)
        error_message = error.response['Error']['Message']
        return get_return_response(origin, error_message, status_code=500)


def validate_request_payload(payload):
    missing_properties = []
    if payload is None or not payload:
        payload[dynamodb_primary_key] = str(uuid.uuid4())
        payload[dynamodb_secondary_key] = str(uuid.uuid4())
        # missing_properties.append(dynamodb_primary_key)
        # missing_properties.append(dynamodb_secondary_key)
        return missing_properties, payload
    if dynamodb_primary_key not in payload:
        payload[dynamodb_primary_key] = str(uuid.uuid4())
        # missing_properties.append(dynamodb_primary_key)
    if dynamodb_secondary_key not in payload:
        payload[dynamodb_secondary_key] = str(uuid.uuid4())
        # missing_properties.append(dynamodb_secondary_key)
    return missing_properties, payload
