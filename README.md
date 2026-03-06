# Flask API

A Flask-based REST API for the AWS GameDay Battle Royale application that manages unicorn data and provides database connectivity.

## Files

- `api.py` - Main Flask application with REST endpoints
- `package.sh` - Build and deployment script
- `.gitignore` - Git ignore rules

## API Endpoints

### Status Endpoints
- `GET /api/v1/apistatus` - API health check
- `GET /api/v1/dbstatus` - Database connectivity check
- `GET /api/v1/region` - Returns current AWS region

### Unicorn Management
- `GET /api/v1/unicorns` - List all unicorns (optional `?id=` parameter)
- `GET /api/v1/latest` - Get latest unicorn entry
- `POST /api/v1/unicorn` - Create/update unicorn
- `PATCH /api/v1/unicorn` - Update existing unicorn
- `GET /api/v1/unicorns/login` - Unicorn authentication

### Database Management
- `POST /api/v1/setdbpwd` - Update database password

### Utility
- `GET /api/v1/proxy` - HTTP proxy endpoint

## Dependencies

- Flask
- boto3
- pymysql
- requests

## Configuration

The API connects to:
- MySQL database via SSM Parameter Store (`CAVS_DB_ENDPOINT`)
- AWS Secrets Manager for credentials
- EC2 instance metadata for region detection

## Deployment

Run `./package.sh` to build and upload to S3:
```bash
chmod +x package.sh
./package.sh
```

## Backup of the Backup

Should you need a backup for this code, it can be downloaded here: https://ws-assets-prod-iad-r-iad-ed304a55c2ca1aee.s3.us-east-1.amazonaws.com/fd5f909a-e782-4dbb-94c0-c2e2a61191ab/flask_api.zip