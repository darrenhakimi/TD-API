# https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/secretsmanager.html

import boto3
import base64
from botocore.exceptions import ClientError

import requests
import json

class TD_API_Secrets_Manager:
    def __init__(self):
        self.secrets_manager_client = self.get_secrets_manager_client()
        self.secret_name = "prod/TD_API/auth"
        self.secret = self.get_secret()
        self.api_key, self.refresh_token, self.access_token = self.get_cur_credentials()

    def get_secrets_manager_client(self):
        # Create a Secrets Manager client
        session = boto3.session.Session()
        secrets_manager_client = session.client(
            service_name='secretsmanager',
            region_name="us-east-1"
        )
        return secrets_manager_client

    def get_secret(self):
        secret = self.secrets_manager_client.get_secret_value(
            SecretId=self.secret_name
        )
        return json.loads(secret['SecretString'])

    def get_cur_credentials(self):
        return self.secret['api_key'], self.secret['refresh_token'], self.secret['access_token']

    def update_secret(self):
        self.secret["refresh_token"] = self.refresh_token
        self.secret["access_token"] = self.access_token

        response = self.secrets_manager_client.update_secret(
            SecretId=self.secret_name,
            SecretString=json.dumps(self.secret)
        )
        return response

    def get_new_credentials(self):
        endpoint = 'https://api.tdameritrade.com/v1/oauth2/token'
        headers = {
            'Content-Type': 'application/x-www-form-urlencoded'
        }
        body = {
            'grant_type': 'refresh_token',
            'client_id': self.api_key,
            'refresh_token': self.refresh_token,
            'access_type': 'offline',
            'redirect_uri': 'http://localhost'
        }
        response = requests.post(endpoint, headers=headers, data=body)
        if response.status_code != 200:
            raise Exception('ERROR: TD API Failed')
        response = response.json()
        self.new_refresh_token = response['refresh_token']
        self.new_access_token = response['access_token']
        return self.update_secret()

def lambda_handler(event, context):
    td_api_secrets_manager = TD_API_Secrets_Manager()
    return td_api_secrets_manager.get_new_credentials()


