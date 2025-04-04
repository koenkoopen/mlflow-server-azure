FROM python:3.12

# Set the working directory to /
WORKDIR /

# Copy the directory contents into the container at /
COPY . /

# Install any needed packages specified in requirements.txt
RUN pip install --upgrade pip
RUN apt-get update && apt-get install gcc python3-dev -y
RUN pip install -r requirements.txt && chmod +x /setup_mlflow.sh

ENV MLFLOW_SERVER_HOST=0.0.0.0
ENV MLFLOW_SERVER_PORT=5001
ENV MLFLOW_SERVER_WORKERS=4

ENV BACKEND_URI=sqlite:///mydb.sqlite
RUN touch /mydb.sqlite && chmod 777 /mydb.sqlite

RUN mkdir -p /mlflow && chmod -R 777 /mlflow
RUN chmod +x /setup_mlflow.sh

ENV MLFLOW_SERVER_DEFAULT_ARTIFACT_ROOT=/mlflow/artifacts

EXPOSE 5001

# Copy the setup script into the container
COPY setup_mlflow.sh /setup_mlflow.sh

ENTRYPOINT ["bash", "/setup_mlflow.sh"]
