# CS4295 - Team 6 Project

## Starting the application
From the root directory:
- `docker compose up` to start the application.
- `docker compose down` to stop the application.
## Repositories
Below we list the repositories in our system, along with pointers to relevant files within each repository.
### [model-service](https://github.com/remla25-team6/model-service)
### [model-training](https://github.com/remla25-team6/model-training)
### [lib-ml](https://github.com/remla25-team6/lib-ml)
### [app](https://github.com/remla25-team6/app)
### [operation](https://github.com/remla25-team6/operation)
### [lib-version](https://github.com/remla25-team6/lib-version)
- [VersionUtil.java](https://github.com/remla25-team6/lib-version/blob/main/src/main/java/org/remla25team6/libversion/VersionUtil.java): The class that can be asked for the library's versions.
- [Workflow](https://github.com/remla25-team6/lib-version/blob/main/.github/workflows/release.yml): The workflow that automatically releases the package and updates the version after new tag.
- [version.properties](https://github.com/remla25-team6/lib-version/blob/main/src/main/resources/version.properties): The file that stores the library version which is automatically populated by Maven through `pom.xml`.

## Progress log
### Assignment 1:
