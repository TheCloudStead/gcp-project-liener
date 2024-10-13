#!/bin/bash

PROJECTS_FILE="projects.txt"

while IFS= read -r project; do
    echo "Processing project: $project"

    lien_ids=$(gcloud alpha resource-manager liens list --project="$project" --format=json | jq -r '.[].name | split("/") | .[1]')

    for lien_id in $lien_ids; do
        echo "Deleting lien: $lien_id for project: $project"
        gcloud alpha resource-manager liens delete "$lien_id"
    done

done < "$PROJECTS_FILE"