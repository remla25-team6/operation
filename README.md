# CS4295 - Team 6 Project

## Table of Contents
* [Requirements](#requirements)
* [Starting the application](#starting-the-application)
  * [With Docker](#with-docker)
  * [With Kubernetes](#with-kubernetes)
    * [1. Provision the cluster (required for both manual and Helm deployments)](#1-provision-the-cluster-required-for-both-manual-and-helm-deployments)
      * [1a. Open the Kubernetes Dashboard (optional)](1a-to-open-the-kubernetes-dashboard-without-a-tunnel-optional)
    * [2. Choose a deployment method](#2-choose-one-of-the-following-deployment-methods)
      * [A. Manual deployment (Ansible + manifests)](#a-manual-deployment-with-ansible-and-raw-kubernetes-manifests)
      * [B. Deployment using Helm](#b-deployment-using-helm)
* [Access the Application](#access-the-application)
* [Repositories overview](#repositories)
* [Operation Repository Overview](#operation-repository-overview)

---

## Requirements
Before starting the application, ensure you have the following installed:
* Docker & Docker Compose
* Ansible
* Vagrant
* VirtualBox

## Starting the application

From the root directory:

### Using Docker:

```bash
echo your_personal_access_token | docker login ghcr.io -u your_github_username --password-stdin     # Login
docker compose up          # Start the application
docker compose down        # Stop the application
```

Access the app at: [http://127.0.0.1:8080/](http://127.0.0.1:8080/)

### Using Kubernetes
**Before getting started** you will need an SMTP server and credentials that can be used for mail-based alerts.
The easiest approach is using Google in combination with a 16-character *app-password*. Learn more about app-passwords [here](https://myaccount.google.com/apppasswords).

To be able to deploy the application the following variables need to be set (here Gmail is used as an example):

```env
# Grafana dashboard credentials
GRAFANA_ADMIN_USER=
GRAFANA_ADMIN_PASSWORD=

# Email alert related variables
SMTP_SERVER=smtp.gmail.com:587
SMTP_USERNAME=<YOUR-GMAIL>
SMTP_PASSWORD=<YOUR-APP-PASSWORD>
ALERT_RECIPIENT=
ALERT_SENDER=<YOUR-GMAIL>
```
The above variables *need* to be exported as environment variables. If you are using the startup script then it will prompt you for the above values and store them in a file called `.monitoring.env` and on subsequent deployments will read them from this file and *export them for you*.

#### Using the startup script

This approach is the fastest but it requires GNU parallel:

```bash
sudo apt-get install parallel # Linux
```

For macOS users, you can install GNU parallel using Homebrew:

```bash
brew install parallel # macOS
```

The entire application can then be deployed using the provided start script:

```bash
chmod +x deploy-app.sh
./deploy-app.sh
```

or, for macOS users (Intel only):

```bash
chmod +x deploy-app-mac.sh
./deploy-app-mac.sh
```

If `.monitoring.env` is not present the script will prompt you for the required values that need to be set and it will export them for you automatically.

Note that this automatically adds the following three entries to your `/etc/hosts` file, if they are not already present:

```
192.168.56.91 dashboard.local
192.168.56.93 grafana.local
192.168.56.94 prometheus.local
```
On each run the deployment script will prompt the user for the possibility of a cleanup. In case you are experiencing issues with the deployment script, trying this cleanup step is recommended. It is not necessary and might not provide benefit to everyone.

#### Manually
##### 1. Provision the cluster (required for both manual and Helm deployments)

```bash
vagrant up  # Start vagrant and provision
ansible-galaxy collection install -r requirements.yml # Install required Ansible collections
ansible-playbook -i ansible/inventory.cfg finalization.yml  # Run final provisioning steps
```

##### 1a. To open the Kubernetes Dashboard without a tunnel (optional):

* Add `192.168.56.91 dashboard.local` to your /etc/hosts file (Linux, macOS) or to
  `C:\Windows\System32\drivers\etc\hosts` (Windows). Changing the entries can require a flush of the DNS cache:
  * `sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder` (macOS)
  * `sudo systemd-resolve --flush-caches` (Linux/systemd)
  * `ipconfig /flushdns` (Windows)
* A token can be manually created on the control machine using: `kubectl -n kubernetes-dashboard create token admin-user`
* Visit [https://dashboard.local/](https://dashboard.local/) (https is important) and login using the token created in the previous step

##### 2. Choose one of the following deployment methods:

###### A. Manual deployment with Ansible and raw Kubernetes manifests

```bash
export $(cat .env | xargs)  # Setup environment variables (app/model images and model service URL)
ansible-playbook -u vagrant -i 192.168.56.100, deployment.yml -e "MODEL_IMAGE=$MODEL_IMAGE APP_IMAGE=$APP_IMAGE MODEL_URL=$MODEL_URL"  # Apply Kubernetes config
```

###### B. Deployment using Helm

**Option 1: With Vagrant**

```bash
vagrant ssh ctrl  # SSH into control node
cd /vagrant/sentiment-chart  # Navigate to synced Helm chart repository
helm install <release-name> .   # Install the application using the Helm chart with desired release name (Helm chart can be installed more than once into the same cluster with different names)
```

**Option 2: With Minikube**

```bash
minikube start  # Start minikube
cd sentiment-chart  # Navigate to Helm chart repository
helm install <release-name> .  # Install the application using the Helm chart with desired release name (Helm chart can be installed more than once into the same cluster with different names)
```

## Access the Application

After starting the application:

* Access at: [https://192.168.56.91/](https://192.168.56.91/)
* The app is also accessible via the Istio ingress gateway at: [https://192.168.56.92/](https://192.168.56.92/)
* Under some conditions the app may not be reachable at this IP. If the app is not reachable:

```bash
vagrant ssh ctrl  # SSH into control node
kubectl get svc -n ingress-nginx  # Check external IP that you can access the app from
```
* To stop the application:

```bash
vagrant halt
```

## Accessing Grafana Dashboard
In order to import the dashboard in Grafana and view the metrics, open Grafana at:

- https://grafana.local (or https://192.168.56.93/)

Next, login using default credentials:

- user: admin
- pass: admin

Under Dashboards, select "Inference Classifier App Dashboard"

## Repositories

Below we list the repositories in our system, along with pointers to relevant files within each repository.

### [model-service](https://github.com/remla25-team6/model-service)

* [flask_service.py](https://github.com/remla25-team6/model-service/blob/main/src/main/flask_service.py):  The flask webservice that contains all endpoint code relevant to model prediction.
* [release.yml](https://github.com/remla25-team6/model-service/blob/main/.github/workflows/release.yml): The yml workflow file that automatically releases the package and updates the version after a new tag for the Flask model-service, used for stable releases.
* [dockerfile](https://github.com/remla25-team6/model-service/blob/main/dockerfile): A dockerfile containing all steps necessary to run the webservice image in a Docker container environment.
* [prerelease.yml](https://github.com/remla25-team6/model-service/blob/main/.github/workflows/prerelease.yml): Workflow that triggers on any push to main that creates a pre-release.

### [model-training](https://github.com/remla25-team6/model-training)

* [data_loader.py](https://github.com/remla25-team6/model-training/blob/main/src/restaurant_sentiment/data_loader.py): Method that loads training data and preprocesses data using the *lib_ml* package.
* [train.py](https://github.com/remla25-team6/model-training/blob/main/src/restaurant_sentiment/train.py): Method that trains a Naive Bayes classifier for restaurant sentiment analysis.
* [prerelease.yml](https://github.com/remla25-team6/model-training/blob/main/.github/workflows/prerelease.yml): Workflow that triggers on any push to main that creates a pre-release.
* [release.yml](https://github.com/remla25-team6/model-training/blob/main/.github/workflows/release.yml): Workflow that triggers on semantic tagging that creates a stable release.

### [lib-ml](https://github.com/remla25-team6/lib-ml)

* [preprocess.py](https://github.com/remla25-team6/lib-ml/blob/main/src/lib_ml/preprocess.py): Function which cleans and preprocesses text reviews.
* [release.yml](https://github.com/remla25-team6/lib-ml/blob/main/.github/workflows/release.yml): Workflow that triggers on semantic tagging that creates a stable release.
* [pyproject.toml](https://github.com/remla25-team6/lib-ml/blob/main/pyproject.toml): Defines the build system, dependencies, and packaging for lib-ml

### [app](https://github.com/remla25-team6/app)

* [prerelease.yml](https://github.com/remla25-team6/app/blob/main/.github/workflows/prerelease.yml): Workflow that triggers on any push to main that creates a pre-release.
* [release.yml](https://github.com/remla25-team6/app/blob/main/.github/workflows/release.yml): Workflow that triggers on semantic tagging that creates a stable release.
* [ModelController](https://github.com/remla25-team6/app/blob/main/src/main/java/com/remla6/app/controller/ModelController.java): Class responsible for defining REST-endpoints
* [ModelService](https://github.com/remla25-team6/app/blob/main/src/main/java/com/remla6/app/service/ModelService.java): Class responsible for handling user request for sentiment analysis

### [operation](https://github.com/remla25-team6/operation)

* In `submissions/a1.md` you can find a summary of the features we implemented per repo for assignment 1.

### [lib-version](https://github.com/remla25-team6/lib-version)

* [VersionUtil.java](https://github.com/remla25-team6/lib-version/blob/main/src/main/java/org/remla25team6/libversion/VersionUtil.java): The class that can be asked for the library's versions.
* [Workflow](https://github.com/remla25-team6/lib-version/blob/main/.github/workflows/release.yml): The workflow that automatically releases the package and updates the version after new tag.
* [version.properties](https://github.com/remla25-team6/lib-version/blob/main/src/main/resources/version.properties): The file that stores the library version which is automatically populated by Maven through `pom.xml`.

## Operation Repository Overview

This repository contains all infrastructure, orchestration, and deployment resources for the project. Below is an overview of the main folders and their purposes:

### `docs/`
Contains documentation for deployment, continuous experimentation, and project extensions. Notable files:
- `deployment.md`: Detailed deployment information and architecture.
- `continuous-experimentation.md`: Information on a continous experiment.
- `extension.md`: Documentation on possible project extensions.
- `images/`: Diagrams and images used in documentation.

### `kubernetes/`
Contains Kubernetes manifest templates and configuration files for deploying services and infrastructure.
- `sentiment.yml.j2`: Jinja2 template for Kubernetes deployment manifests.

### `ansible/`
Holds Ansible playbooks and inventory for automating VM and cluster setup.
- `ctrl.yml`, `node.yml`, `general.yml`: Playbooks for provisioning controller and worker nodes.
- `inventory.cfg`: Ansible inventory file.
- `templates/hosts.j2`: Jinja2 template for generating hosts files.

### `finalization.yml`, `deployment.yml`
Ansible playbooks for final cluster provisioning and application deployment.

### `sentiment-chart/` (Helm Chart)
Helm chart for deploying the application stack on Kubernetes.
- `Chart.yaml`: Helm chart metadata.
- `values.yaml`: Default configuration values.
- `templates/`: Helm templates for Kubernetes resources.
- `app-custom-dashboard.json`, `experiment-dashboard.json`: Predefined Grafana dashboards.
- `.helmignore`: Patterns to ignore when packaging the chart.

### `Vagrantfile`
Defines the Vagrant-based virtual machine cluster for local Kubernetes and Ansible testing.

### `scripts/`
Utility and helper scripts for testing and automation.
- `test-experiment.py`: Script for running experiment tests.

### `shared/`
Shared files or resources used across VMs or containers.

### `keys/` and `secrets/`
- `keys/`: Public SSH keys for team members.
- `secrets/`: Example secret files for use in Docker Compose or Kubernetes.

### `deploy-app.sh`, `deploy-app-mac.sh`
Automated deployment scripts for quickly setting up the application stack on Linux and macOS (Intel) environments. These scripts handle environment variable setup, prompt for required credentials, and manage hosts file entries for local development.

### `docker-compose.yml`
Defines the multi-service Docker Compose setup for local development and testing. It specifies the services, environment variables, secrets, and volumes required to run the application stack using Docker.

## AI Disclaimer
This README was refined using ChatGPT-4o.