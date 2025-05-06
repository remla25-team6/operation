# CS4295 - Team 6 Project

## Starting the application
From the root directory:
- `echo your_personal_access_token | docker login ghcr.io -u your_github_username --password-stdin` to login
- `docker compose up` to start the application.
- Access at: http://127.0.0.1:8080/
- `docker compose down` to stop the application.

## Repositories
Below we list the repositories in our system, along with pointers to relevant files within each repository.

### [model-service](https://github.com/remla25-team6/model-service)
- [flask_service.py](https://github.com/remla25-team6/model-service/blob/main/src/main/flask_service.py):  The flask webservice that contains all endpoint code relevant to model prediction.
- [release.yml](https://github.com/remla25-team6/model-service/blob/main/.github/workflows/release.yml): The yml workflow file that automatically releases the package and updates the version after new tag for the Flask model-service.
- [dockerfile](https://github.com/remla25-team6/model-service/blob/main/dockerfile): The dockerfile containing all steps necessary to run the webservice image in a Docker container environment.

### [model-training](https://github.com/remla25-team6/model-training)
- [data_loader.py](https://github.com/remla25-team6/model-training/blob/main/src/restaurant_sentiment/data_loader.py): Method that loads training data and preprocesses data using the *lib_ml* package.
- [train.py](https://github.com/remla25-team6/model-training/blob/main/src/restaurant_sentiment/train.py): Method that trains a Naive Bayes classifier for restaurant sentiment analysis.
- [prerelease.yml](https://github.com/remla25-team6/model-training/blob/main/.github/workflows/prerelease.yml): Workflow that triggers on any push to main that creates a pre-relrease.
- [release.yml](https://github.com/remla25-team6/model-training/blob/main/.github/workflows/release.yml): Workflow that triggers on semantic tagging that creates a stable release.

### [lib-ml](https://github.com/remla25-team6/lib-ml)

### [app](https://github.com/remla25-team6/app)

### [operation](https://github.com/remla25-team6/operation)

### [lib-version](https://github.com/remla25-team6/lib-version)
- [VersionUtil.java](https://github.com/remla25-team6/lib-version/blob/main/src/main/java/org/remla25team6/libversion/VersionUtil.java): The class that can be asked for the library's versions.
- [Workflow](https://github.com/remla25-team6/lib-version/blob/main/.github/workflows/release.yml): The workflow that automatically releases the package and updates the version after new tag.
- [version.properties](https://github.com/remla25-team6/lib-version/blob/main/src/main/resources/version.properties): The file that stores the library version which is automatically populated by Maven through `pom.xml`.

## Progress log
### Assignment 1: