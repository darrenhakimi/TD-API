#!/bin/bash
# https://docs.aws.amazon.com/cli/latest/reference

# Check if S3 bucket exists and create if not
function create_s3_bucket() {
  # make sure bucket name is all lowercase
  S3_BUCKET_NAME=$(echo "$1" | tr '[:upper:]' '[:lower:]')
  if aws s3api head-bucket --bucket ${S3_BUCKET_NAME} 2>&1 | grep -q 'Not Found';
  then
    aws s3api create-bucket \
      --bucket ${S3_BUCKET_NAME} \
      --region us-east-1
  fi
}

function update_lambda_to_point_to_s3() {
    LAMBDA_NAME=${1}
    S3_BUCKET_NAME=${2}
    ZIP_FILE_NAME=${3}
    aws lambda update-function-code --function-name ${LAMBDA_NAME} --s3-bucket ${S3_BUCKET_NAME} --s3-key ${ZIP_FILE_NAME}.zip
}

# set equal to parent directory name
ZIP_FILE_NAME="${PWD##*/}"

# s3 bucket name is all lowercase lambda name
S3_BUCKET_NAME=$(echo "${ZIP_FILE_NAME}" | tr '[:upper:]' '[:lower:]')

rm -rf ${ZIP_FILE_NAME}.zip
zip -r ${ZIP_FILE_NAME}.zip *

create_s3_bucket ${S3_BUCKET_NAME}
aws s3 cp ${ZIP_FILE_NAME}.zip s3://${S3_BUCKET_NAME}/${ZIP_FILE_NAME}.zip

# Update Lambda to point to S3
LAMBDA_NAME=${ZIP_FILE_NAME}
aws lambda update-function-code --function-name ${LAMBDA_NAME} --s3-bucket ${S3_BUCKET_NAME} --s3-key ${ZIP_FILE_NAME}.zip

# Update additional Secrets-Manager-Refresh-TD-API Lambda to point to S3
# LAMBDA_NAME="Secrets-Manager-Refresh-TD-API"
# aws lambda update-function-code --function-name ${LAMBDA_NAME} --s3-bucket ${S3_BUCKET_NAME} --s3-key ${ZIP_FILE_NAME}.zip

update_lambda_to_point_to_s3 'Secrets-Manager-Refresh-TD-API' ${S3_BUCKET_NAME} ${ZIP_FILE_NAME}



