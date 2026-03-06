#!/bin/bash

# Find the Amazon S3 bucket whose name is like `applicationsourcecode`
bucket=$(aws s3 ls | grep applicationsourcecode | awk '{print $3}')

# Create build directory if it doesn't exist
mkdir -p build

# Package the Flask API into a ZIP file, ignore hidden files and build folder
zip -r build/flask_api.zip . \
  -x build/\* \
  \*.venv\* \
  \*.git\* \
  \*.gitea\* \
  \*__pycache__\* \

# Copy the ZIP file to the S3 bucket
aws s3 cp build/flask_api.zip s3://$bucket/flask_api.zip
echo "Flask API packaged and uploaded to S3 bucket $bucket"
