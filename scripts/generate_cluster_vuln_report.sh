#!/bin/bash

set -eu

CLUSTER_NAME=$1
FILENAME=$(date -I)

echo "Getting all vulnerabilities for ${CLUSTER_NAME}..."
kubectl get vulnerabilityreports.aquasecurity.github.io -A -o json > ${CLUSTER_NAME}_vuln.json

echo "Getting namespace annotations to enrich vulnerability report..."
jq -r '.items | map(.metadata.namespace) | unique | .[]' ${CLUSTER_NAME}_vuln.json | xargs -n 1 | xargs -I % bash -c 'kubectl get ns % -ojson > %.json'

cp ${CLUSTER_NAME}_vuln.json updated.json

echo "Looping over vulnerabilities and enriching with relevant namespace details..."
jq -c '.items | .[]' ${CLUSTER_NAME}_vuln.json | while read i; do
  OBJ_UID=$(echo $i | jq -r '.metadata.uid')
  NS=$(echo $i | jq -r '.metadata.namespace')

  SOURCE_CODE=$(jq -r '.metadata.annotations."cloud-platform.justice.gov.uk/source-code"' "$NS.json")
  OWNER=$(jq -r '.metadata.annotations."cloud-platform.justice.gov.uk/owner"' "$NS.json")
  TEAM_NAME=$(jq -r '.metadata.annotations."cloud-platform.justice.gov.uk/team-name"' "$NS.json")

  # add the new values to the object
  jq --arg SOURCE_CODE "$SOURCE_CODE" --arg OBJ_UID "$OBJ_UID" '{items: [.items | .[] | select(.metadata.uid | contains($OBJ_UID)).metadata += {"cloud-platform.justice.gov.uk/source-code": $SOURCE_CODE }]}' updated.json > updated_source_code.json

  jq --arg OWNER "$OWNER" --arg OBJ_UID "$OBJ_UID" '{items: [.items | .[] | select(.metadata.uid | contains($OBJ_UID)).metadata += {"cloud-platform.justice.gov.uk/owner": $OWNER }]}' updated_source_code.json > updated_owner.json

  jq --arg TEAM_NAME "$TEAM_NAME" --arg OBJ_UID "$OBJ_UID" '{items: [.items | .[] | select(.metadata.uid | contains($OBJ_UID)).metadata += {"cloud-platform.justice.gov.uk/team-name": $TEAM_NAME }]}' updated_owner.json > updated_team_name.json

  cp updated_team_name.json updated.json
done
echo "Vulnerabilitiy data enriched."

cp updated.json "${FILENAME}.json"

echo "Pushing report to s3..."
aws s3 cp "${FILENAME}.json" s3://cloud-platform-vulnerability-reports/$CLUSTER_NAME/

exit 0

