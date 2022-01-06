#!/bin/bash

# note(itay): You should be running this script to run the data migrations(manual_migrations)
# You must have `jq` installed and `awscli`, run `brew install jq awscli` on MacOS
# also you should have the correct AWS_PROFILE / credentials configured with
# the required AWS permissions.

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
command -v jq >/dev/null
EC=$?

if [ $EC -gt 0 ]; then
    echo "jq not found. Please make sure you have it..."
    exit 1
fi

function read_snapshot_name() {
    ok="false"

    while [ "$ok" == "false" ]; do
        echo "Enter Snapshot Name (e.g my-snapshot-id):"
        read -e SNAPSHOT_IDENTIFIER
        [[ ${SNAPSHOT_IDENTIFIER} =~ ^[a-z][a-z0-9\-]*[a-z0-9]$ ]] && ok="true" || echo "Bad snapshot identifier!"
    done
    echo
}

function read_config() {
    echo "Please fill in the following configuration. Leave blank to use the current values."
    echo
    echo "Pulumi stack name (${STACK_NAME}):"
    read TMP_STACK_NAME
    [[ -z "${TMP_STACK_NAME}" ]] || STACK_NAME="${TMP_STACK_NAME}"

    echo "Do you wish to create backup?"
    select yn in "Yes" "No"; do
        case $yn in
            Yes ) break;;
            No ) return; break;;
        esac
    done
    echo

    read_snapshot_name
    echo
}

function create_snapshot() {
    echo "Creating snapshot for DB cluster ${DB_CLUSTER_NAME} - ${SNAPSHOT_IDENTIFIER}"

    aws rds create-db-cluster-snapshot \
        --db-cluster-snapshot-identifier ${SNAPSHOT_IDENTIFIER} \
        --db-cluster-identifier ${DB_CLUSTER_NAME} > /dev/null

    snapshot_ready="false"

    echo "waiting for snapshot..."
    while [ "$snapshot_ready" == "false" ]; do
        snapshot_status=$(aws rds describe-db-cluster-snapshots \
            --snapshot-type manual \
            --db-cluster-snapshot-identifier ${SNAPSHOT_IDENTIFIER} \
                | jq -r '.DBClusterSnapshots[0].Status')

        [[ "$snapshot_status" == "available" ]] && snapshot_ready="true" && echo "snapshot ready!"
    done
    echo
}

function run_migrations() {
    subnets=$(aws ec2 describe-subnets \
            --filters \
    	    Name=tag:type,Values=private \
            Name=vpc-id,Values=${VPC_ID} \
            | jq -r '.Subnets | map(.SubnetId) | join(",")')

    aws ecs run-task \
        --cluster ${ECS_CLUSTER_NAME} \
        --task-definition ${TASK_DEF_FAMILY} \
        --count 1 \
        --launch-type FARGATE \
        --network-configuration "awsvpcConfiguration={subnets=[${subnets}],assignPublicIp=DISABLED}" \
        --overrides "{\"containerOverrides\": [{\"name\": \"$CONTAINER_NAME\", \"command\": [\"bin/api\",\"eval\",\"Api.Release.migrate_manual\"]}]}" > /dev/null && echo "Migration has initiated!"
}

function print_config() {
    echo "Is everything set correctly?"
    echo "STACK_NAME: ${STACK_NAME}"
    echo "REGION: ${REGION}"
    echo "VPC_ID: ${VPC_ID}"
    echo "ECS_CLUSTER_NAME: ${ECS_CLUSTER_NAME}"
    echo "TASK_DEF_FAMILY: ${TASK_DEF_FAMILY}"
    [[ -z $SNAPSHOT_IDENTIFIER ]] || echo "DB_CLUSTER_NAME: ${DB_CLUSTER_NAME}"
    [[ -z $SNAPSHOT_IDENTIFIER ]] || echo "SNAPSHOT_IDENTIFIER: ${SNAPSHOT_IDENTIFIER}"
    echo
    echo "To access the database, use this endpoint: ${STACK_NAME}-db.walnut.io"

    select yn in "Yes" "No"; do
        case $yn in
            Yes ) echo && return;;
            No ) echo && read_config; break;;
        esac
    done
}

set -e

read_config
#note(itay): Extract vpc/api variables from Pulumi `api/infrastructure`
cd $DIR/../infrastructure
pulumi stack select $STACK_NAME
stack_result=$(pulumi stack output --json --show-secrets)

#note(itay): Hardcoding these values as they're less likely to change
REGION="us-west-2"
CONTAINER_NAME="apiRunMigration"

#note(itay): Extracting the following variables from the pulumi stack output
VPC_ID=$(echo $stack_result | jq -r '.vpc.id')
ECS_CLUSTER_NAME=$(echo $stack_result | jq -r '.api.apiClusterName')
TASK_DEF_FAMILY=$(echo $stack_result | jq -r '.api.apiMigrationTaskDefinitionName')
DB_CLUSTER_NAME=$(echo $stack_result | jq -r '.api.dbIdentifier')
SNAPSHOT_IDENTIFIER=""

print_config

[[ -z ${SNAPSHOT_IDENTIFIER} ]] || create_snapshot

run_migrations

