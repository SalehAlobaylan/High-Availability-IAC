#!/usr/bin/env bash
set -euo pipefail

if ! command -v aws >/dev/null 2>&1; then
  echo "ERROR: AWS CLI not found (aws). Install AWS CLI v2 and run 'aws configure' first." >&2
  exit 1
fi

STACK_NETWORK="udagram-network"
STACK_APP="udagram-app"

stack_exists() {
  aws cloudformation describe-stacks --stack-name "$1" >/dev/null 2>&1
}

if stack_exists "${STACK_APP}"; then
  BUCKET_NAME="$(
    aws cloudformation describe-stacks \
      --stack-name "${STACK_APP}" \
      --query "Stacks[0].Outputs[?OutputKey=='StaticBucketName'].OutputValue | [0]" \
      --output text
  )"

  if [[ -n "${BUCKET_NAME}" && "${BUCKET_NAME}" != "None" ]]; then
    echo "Emptying S3 bucket: s3://${BUCKET_NAME}"
    aws s3 rm "s3://${BUCKET_NAME}" --recursive || true
  fi

  echo "Deleting stack: ${STACK_APP}"
  aws cloudformation delete-stack --stack-name "${STACK_APP}"
  aws cloudformation wait stack-delete-complete --stack-name "${STACK_APP}"
else
  echo "Stack not found (skipping): ${STACK_APP}"
fi

if stack_exists "${STACK_NETWORK}"; then
  echo "Deleting stack: ${STACK_NETWORK}"
  aws cloudformation delete-stack --stack-name "${STACK_NETWORK}"
  aws cloudformation wait stack-delete-complete --stack-name "${STACK_NETWORK}"
else
  echo "Stack not found (skipping): ${STACK_NETWORK}"
fi

echo "Done."
