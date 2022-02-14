# Jira Software in Docker on arm64 platform
This is a minimalistic image for launching Atlassian Jira on the arm64 platform. The image is based on the [official one](https://bitbucket.org/atlassian-docker/docker-atlassian-jira/src/master/) with minor modifications.

## Motivation
The reason for creating this repository was the need to develop and test plugins for various versions of Atlassian Jira on an Apple M1 computers, as well as the lack of support for the arm64 platform in official images.

## Compatibility
The image supports Jira versions since 7.13.0, when OpenJDK support appeared. Therefore, the image is based on adoptopenjdk:8-hotspot (for versions from 8.2.0 you can use JDK 11).

Even though the image contains the MySQL driver, the sample docker-compose file uses PostgreSQL. The reason for this is that there is an official PostgreSQL image that supports arm64, but there is no such official image for MySQL.

For other compatibility issues, see [Jira supported platforms](https://confluence.atlassian.com/adminjiraserver/supported-platforms-938846830.html).

## Repo content
* **components** - Necessary files to copy inside the container. **entrypoint.py** and **/support** were taken from [Atlassian's docker-shared-components](https://bitbucket.org/atlassian-docker/docker-shared-components/src/master/). And the rest of the files were taken from the [official image](https://bitbucket.org/atlassian-docker/docker-atlassian-jira/src/master/).
* **compose** - [Docker compose](https://docs.docker.com/compose/) file.
* **build-image.sh** - Helper script for building an image, containing image parameters.
* **Dockerfile** - The dockerfile itself.

## Use
### Configuration
You can use any environment variables from the [Configuring Jira section of official image doc](https://bitbucket.org/atlassian-docker/docker-atlassian-jira/src/master/#markdown-header-configuring-jira).

### Build
1. Open **build-image.sh** and set the parameters as needed.
2. Run `./build-image.sh` and make sure the image was built without errors.

### Run
1. Create a folder where Jira data will be stored.
2. Copy **compose/docker-compose.yml** to the created folder.
3. Open **docker-compose.yml**
   1. Change **image** of **jira** service to image you have built.
   2. Review the rest of the configuration and make necessary changes.
   3. Save and close **docker-compose.yml**.
4. Run

       docker-compose run --rm db
   This command will start the container with the **db** service from docker-compose file, and after stopping it will delete it (--rm option). During the first run, the user and database will be created in accordance with the parameters specified in the **db** service **environment** key in the docker-compose file.
5. Wait for a message like "*database system is ready to accept connections*" and stop container (ctrl+c).
6. Run

       docker-compose up
   This will start **jira** and **db** sevices. Once loaded, Jira will be available on http://localhost:2990/jira/ (if you have not changed the corresponding parameters of the **jira** service).