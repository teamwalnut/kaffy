#!/bin/bash

# note(itay): This script is here as a helper to manually run migrations if needed
# You must have `jq` installed and `awscli`, run `brew install jq awscli` on MacOS
# also you should have the correct AWS_PROFILE / credentials configured with
# the required AWS permissions.
#
# Improvement:
# Currently all the required parameters are hardcoded, but can be easily extracted
# from `api/pulumi` -> `pulumi stack output api`

set -e
REGION="us-west-2"
CLUSTER="walnut-server-bf894bc"
TASK_DEF_FAMILY="walnut-api-run-migration-task-definition-6bdff661"
CONTAINER_NAME="apiRunMigration"

subnets=$(aws ec2 describe-subnets \
          --filters \
	    Name=tag:type,Values=public \
        | jq -r '.Subnets | map(.SubnetId) | join(",")')
aws ecs run-task --cluster $CLUSTER --task-definition $TASK_DEF_FAMILY --count 1 \
--launch-type FARGATE --network-configuration "awsvpcConfiguration={subnets=[${subnets}],assignPublicIp=DISABLED}" \
