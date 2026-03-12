#!/usr/bin/env bash
set -euo pipefail

if ! command -v aws >/dev/null 2>&1; then
  echo "ERROR: AWS CLI not found (aws). Install AWS CLI v2 and run 'aws configure' first." >&2
  exit 1
fi

STACK_NETWORK="udagram-network"
STACK_APP="udagram-app"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IAC_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
ROOT_DIR="$(cd "${IAC_DIR}/.." && pwd)"
APP_DIR="${ROOT_DIR}/app"

NETWORK_TEMPLATE="${IAC_DIR}/network.yml"
NETWORK_PARAMS="${IAC_DIR}/network-parameters.json"
APP_TEMPLATE="${IAC_DIR}/udagram.yml"
APP_PARAMS="${IAC_DIR}/udagram-parameters.json"

stack_exists() {
  aws cloudformation describe-stacks --stack-name "$1" >/dev/null 2>&1
}

deploy_stack() {
  local stack_name="$1"
  local template_path="$2"
  local params_path="$3"
  local capabilities="${4:-}"

  if stack_exists "$stack_name"; then
    echo "Updating stack: ${stack_name}"
    local err_file
    err_file="$(mktemp)"
    if aws cloudformation update-stack \
      --stack-name "${stack_name}" \
      --template-body "file://${template_path}" \
      --parameters "file://${params_path}" \
      ${capabilities:+--capabilities "${capabilities}"} \
      2>"${err_file}"; then
      aws cloudformation wait stack-update-complete --stack-name "${stack_name}"
    else
      if grep -q "No updates are to be performed" "${err_file}"; then
        echo "No updates for stack: ${stack_name}"
      else
        cat "${err_file}" >&2
        rm -f "${err_file}"
        return 1
      fi
    fi
    rm -f "${err_file}"
  else
    echo "Creating stack: ${stack_name}"
    aws cloudformation create-stack \
      --stack-name "${stack_name}" \
      --template-body "file://${template_path}" \
      --parameters "file://${params_path}" \
      ${capabilities:+--capabilities "${capabilities}"}
    aws cloudformation wait stack-create-complete --stack-name "${stack_name}"
  fi
}

deploy_stack "${STACK_NETWORK}" "${NETWORK_TEMPLATE}" "${NETWORK_PARAMS}"
deploy_stack "${STACK_APP}" "${APP_TEMPLATE}" "${APP_PARAMS}" "CAPABILITY_NAMED_IAM"

BUCKET_NAME="$(
  aws cloudformation describe-stacks \
    --stack-name "${STACK_APP}" \
    --query "Stacks[0].Outputs[?OutputKey=='StaticBucketName'].OutputValue | [0]" \
    --output text
)"

echo "Uploading static site content to s3://${BUCKET_NAME}"
aws s3 sync "${APP_DIR}" "s3://${BUCKET_NAME}"

WEB_APP_URL="$(
  aws cloudformation describe-stacks \
    --stack-name "${STACK_APP}" \
    --query "Stacks[0].Outputs[?OutputKey=='WebAppURL'].OutputValue | [0]" \
    --output text
)"

echo "Done."
echo "WebAppURL: ${WEB_APP_URL}"
