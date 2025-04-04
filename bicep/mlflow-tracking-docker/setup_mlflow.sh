#!/bin/bash

echo "Starting MLflow server with settings:"
echo "Backend Store: $BACKEND_URI"
echo "Artifact Root: $MLFLOW_SERVER_DEFAULT_ARTIFACT_ROOT"
echo "Host: $MLFLOW_SERVER_HOST"
echo "Port: $MLFLOW_SERVER_PORT"
echo "Workers: $MLFLOW_SERVER_WORKERS"

# Ensure storage exists
mkdir -p /mlflow
chmod -R 777 /mlflow

# If using SQLite, ensure database file exists
if [[ "$BACKEND_URI" == sqlite* ]]; then
    touch /mlflow/mlflow.db
    echo "Initialized SQLite database at /mlflow/mlflow.db"
fi

mlflow server \
    --backend-store-uri "$BACKEND_URI" \
    --default-artifact-root "$MLFLOW_SERVER_DEFAULT_ARTIFACT_ROOT" \
    --host "$MLFLOW_SERVER_HOST" \
    --port "$MLFLOW_SERVER_PORT" \
    --workers "$MLFLOW_SERVER_WORKERS"
