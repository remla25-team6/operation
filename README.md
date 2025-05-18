# CS4295 - Team 6 Project

## Documentation Overview

* [Starting the application](#starting-the-application)

  * [With Docker](#with-docker)
    
  * [With Kubernetes](#with-kubernetes)
    * [1. Provision the cluster (required for both manual and Helm deployments)](#1-provision-the-cluster-required-for-both-manual-and-helm-deployments)
      * [1a. Open the Kubernetes Dashboard](#1a-open-the-kubernetes-dashboard-without-a-tunnel)
      
    * [2. Choose a deployment method](#2-choose-one-of-the-following-deployment-methods)
      * [A. Manual deployment (Ansible + manifests)](#a-manual-deployment-with-ansible-and-raw-kubernetes-manifests)
      * [B. Deployment using Helm](#b-deployment-using-helm)
        
* [Access the Application](#access-the-application)
  
* [Repositories overview](#repositories)

---

## Starting the application

From the project root:

### With Docker

```bash
echo your_personal_access_token | docker login ghcr.io -u your_github_username --password-stdin  # Login
docker compose up    # Start the application
docker compose down  # Stop the application
```

Access the app at: [http://127.0.0.1:8080/](http://127.0.0.1:8080/)

### With Kubernetes

#### 1. Provision the cluster (required for both manual and Helm deployments)

```bash
vagrant up  # Start vagrant and provision
ansible-galaxy collection install -r requirements.yml  # Install required Ansible collections
ansible-playbook -u vagrant --private-key=.vagrant/machines/ctrl/virtualbox/private_key -i 192.168.56.100, finalization.yml  # Run final provisioning steps
```

##### 1a. Open the Kubernetes Dashboard without a tunnel.

1. Add `192.168.56.91 dashboard.local` to your **/etc/hosts** (Linux/macOS) or
   `C:\Windows\System32\drivers\etc\hosts` (Windows). You may need to flush the DNS cache:

   * **macOS**: `sudo dscacheutil -flushcache && sudo killall -HUP mDNSResponder`
   * **Linux (systemd)**: `sudo systemd-resolve --flush-caches`
   * **Windows**: `ipconfig /flushdns`
2. Create a token on the control machine:

   ```bash
   kubectl -n kubernetes-dashboard create token admin-user
   ```
3. Visit **[https://dashboard.local/](https://dashboard.local/)** (note **https**) and log in with the generated token.

#### 2. Choose one of the following deployment methods

##### A. Manual deployment with Ansible and raw Kubernetes manifests

```bash
export $(cat .env | xargs)  # Load environment variables (images, model URL)
ansible-playbook -u vagrant -i 192.168.56.100, deployment.yml \
  -e "MODEL_IMAGE=$MODEL_IMAGE APP_IMAGE=$APP_IMAGE MODEL_URL=$MODEL_URL"  # Apply manifests
```

##### B. Deployment using Helm

###### Option 1: With Vagrant

```bash
vagrant ssh ctrl                        # SSH into control node
cd /vagrant/sentiment-chart            # Synced Helm chart repo
helm install <release-name> .          # Install (can repeat with different names)
```

###### Option 2: With Minikube

```bash
minikube start                         # Start minikube cluster
cd sentiment-chart                     # Helm chart repo
helm install <release-name> .          # Install (can repeat with different names)
```

## Access the Application

After the application is running:

* Access at: [http://192.168.56.90:80/](http://192.168.56.90:80/)
* If the app is unreachable at that IP:

  ```bash
  vagrant ssh ctrl                  # SSH into control node
  kubectl get svc -n ingress-nginx  # Find external IP
  ```
* To stop everything:

  ```bash
  vagrant halt
  ```
  
## Repositories
Below we list the repositories in our system, along with pointers to relevant files within each repository.

### [model-service](https://github.com/remla25-team6/model-service)
- [flask_service.py](https://github.com/remla25-team6/model-service/blob/main/src/main/flask_service.py):  The flask webservice that contains all endpoint code relevant to model prediction.
- [release.yml](https://github.com/remla25-team6/model-service/blob/main/.github/workflows/release.yml): The yml workflow file that automatically releases the package and updates the version after a new tag for the Flask model-service, used for stable releases.
- [dockerfile](https://github.com/remla25-team6/model-service/blob/main/dockerfile): A dockerfile containing all steps necessary to run the webservice image in a Docker container environment.
- [prerelease.yml](https://github.com/remla25-team6/model-service/blob/main/.github/workflows/prerelease.yml): Workflow that triggers on any push to main that creates a pre-release.


### [model-training](https://github.com/remla25-team6/model-training)
- [data_loader.py](https://github.com/remla25-team6/model-training/blob/main/src/restaurant_sentiment/data_loader.py): Method that loads training data and preprocesses data using the *lib_ml* package.
- [train.py](https://github.com/remla25-team6/model-training/blob/main/src/restaurant_sentiment/train.py): Method that trains a Naive Bayes classifier for restaurant sentiment analysis.
- [prerelease.yml](https://github.com/remla25-team6/model-training/blob/main/.github/workflows/prerelease.yml): Workflow that triggers on any push to main that creates a pre-release.
- [release.yml](https://github.com/remla25-team6/model-training/blob/main/.github/workflows/release.yml): Workflow that triggers on semantic tagging that creates a stable release.

### [lib-ml](https://github.com/remla25-team6/lib-ml)
- [preprocess.py](https://github.com/remla25-team6/lib-ml/blob/main/src/lib_ml/preprocess.py): Function which cleans and preprocesses text reviews.
- [release.yml](https://github.com/remla25-team6/lib-ml/blob/main/.github/workflows/release.yml): Workflow that triggers on semantic tagging that creates a stable release.
- [pyproject.toml](https://github.com/remla25-team6/lib-ml/blob/main/pyproject.toml): Defines the build system, dependencies, and packaging for lib-ml

### [app](https://github.com/remla25-team6/app)
- [prerelease.yml](https://github.com/remla25-team6/app/blob/main/.github/workflows/prerelease.yml): Workflow that triggers on any push to main that creates a pre-release.
- [release.yml](https://github.com/remla25-team6/app/blob/main/.github/workflows/release.yml): Workflow that triggers on semantic tagging that creates a stable release.
- [ModelController](https://github.com/remla25-team6/app/blob/main/src/main/java/com/remla6/app/controller/ModelController.java): Class responsible for defining REST-endpoints
- [ModelService](https://github.com/remla25-team6/app/blob/main/src/main/java/com/remla6/app/service/ModelService.java): Class responsible for handling user request for sentiment analysis

### [operation](https://github.com/remla25-team6/operation)
- In `submissions/a1.md` you can find a summary of the features we implemented per repo for assignment 1.

### [lib-version](https://github.com/remla25-team6/lib-version)
- [VersionUtil.java](https://github.com/remla25-team6/lib-version/blob/main/src/main/java/org/remla25team6/libversion/VersionUtil.java): The class that can be asked for the library's versions.
- [Workflow](https://github.com/remla25-team6/lib-version/blob/main/.github/workflows/release.yml): The workflow that automatically releases the package and updates the version after new tag.
- [version.properties](https://github.com/remla25-team6/lib-version/blob/main/src/main/resources/version.properties): The file that stores the library version which is automatically populated by Maven through `pom.xml`.
