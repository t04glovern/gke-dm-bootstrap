#!/bin/sh

PROJECT_ID="$1"

# Set Project
gcloud config set project $PROJECT_ID

case "$3" in
    "create"    )
        DEPLOY_ACTION="create"
        ;;
    "delete"    )
        DEPLOY_ACTION="delete"
        ;;
    *           )
        echo "Script requires an action. E.g. create, delete"
        exit 1
        ;;
esac

case "$2" in
    "iam"           )
        PROJECT_NUM=$(gcloud projects list \
            --filter=PROJECT_ID=$PROJECT_ID \
            --format="value(PROJECT_NUMBER)")
        if [ "$DEPLOY_ACTION" = "create" ]; then
            gcloud projects add-iam-policy-binding $PROJECT_ID \
                --member serviceAccount:$PROJECT_NUM@cloudservices.gserviceaccount.com  \
                --role roles/owner
        else
            echo "Deleting $PROJECT_ID-iam"
            gcloud projects remove-iam-policy-binding $PROJECT_ID \
                --member serviceAccount:$PROJECT_NUM@cloudservices.gserviceaccount.com  \
                --role roles/owner
        fi
        ;;
    "network"       )
        if [ "$DEPLOY_ACTION" = "create" ]; then
            gcloud deployment-manager deployments create $PROJECT_ID-network \
                --config resources/network.yaml
        else
            echo "Deleting $PROJECT_ID-network"
            gcloud deployment-manager deployments delete $PROJECT_ID-network -q
        fi
        ;;
    "cloud-router"  )
        if [ "$DEPLOY_ACTION" = "create" ]; then
            gcloud deployment-manager deployments create $PROJECT_ID-cloud-router \
                --config resources/cloud_router.yaml
        else
            echo "Deleting $PROJECT_ID-cloud-router"
            gcloud deployment-manager deployments delete $PROJECT_ID-cloud-router -q
        fi
        ;;
    "gke"           )
        if [ "$DEPLOY_ACTION" = "create" ]; then
            gcloud deployment-manager deployments create $PROJECT_ID-gke \
                --config resources/gke.yaml
        else
            echo "Deleting $PROJECT_ID-gke"
            gcloud deployment-manager deployments delete $PROJECT_ID-gke -q
        fi
        ;;
    "bastion"       )
        if [ "$DEPLOY_ACTION" = "create" ]; then
            gcloud deployment-manager deployments create $PROJECT_ID-bastion \
                --config resources/bastion.yaml
        else
            echo "Deleting $PROJECT_ID-bastion"
            gcloud deployment-manager deployments delete $PROJECT_ID-bastion -q
        fi
        ;;
    *               )
        echo "Script requires a resource. E.g. network, cloud-router, gke, bastion"
        exit 1
        ;;
esac