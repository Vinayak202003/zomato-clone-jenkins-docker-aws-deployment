# React Zomato Clone – CI/CD Pipeline and AWS EC2 Deployment Using Jenkins and Docker

## 1. Project Overview

This project demonstrates the process of building, containerizing, and deploying a React-based Zomato Clone application using Jenkins, Docker, Docker Hub, and AWS EC2.

The application source code is maintained in GitHub. Jenkins retrieves the source code, builds a Docker image, and pushes the image to Docker Hub. A separate AWS EC2 instance pulls the Docker image and runs the application inside a Docker container.

Nginx is used inside the Docker container to serve the optimized production build of the React application.

### Project Objectives

- Understand Continuous Integration (CI) using Jenkins.
- Automate Docker image creation using a Jenkins pipeline.
- Store and distribute Docker images using Docker Hub.
- Deploy a containerized React application on AWS EC2.
- Understand multi-stage Docker builds.
- Understand how Nginx serves a production React application.

## 2. Technologies and Tools Used

| Technology | Purpose |
|---|---|
| React.js | Frontend application |
| Git and GitHub | Source code management |
| Jenkins | CI pipeline automation |
| Docker | Application containerization |
| Docker Hub | Docker image registry |
| AWS EC2 | Cloud deployment infrastructure |
| Ubuntu Server 24.04 LTS | Operating system |
| Node.js 20 | React application build environment |
| Nginx Alpine | Production web server |

## 3. Project Architecture

The project uses two separate EC2 instances.

**EC2 Instance 1 – Jenkins Server**
- Hosts Jenkins.
- Retrieves source code from GitHub.
- Builds the Docker image.
- Authenticates with Docker Hub.
- Pushes the Docker image to Docker Hub.

**Docker Hub**
- Stores the built Docker image.
- Makes the image available to the deployment server.

**EC2 Instance 2 – Deployment Server**
- Runs Ubuntu Server 24.04 LTS.
- Has Docker installed.
- Pulls the Docker image from Docker Hub.
- Runs the application inside a Docker container.

### Architecture Flow

GitHub Repository  
↓  
Jenkins Server (AWS EC2)  
↓  
Git Checkout  
↓  
Docker Image Build  
↓  
Docker Hub Login  
↓  
Push Docker Image  
↓  
Docker Hub Repository  
↓  
Deployment Server (AWS EC2)  
↓  
Pull Docker Image  
↓  
Run Docker Container  
↓  
Nginx serves React application  
↓  
Access application through EC2 Public IP

## 4. GitHub Repository

The project source code is hosted in GitHub.

**Repository:**  
https://github.com/Vinayak202003/ZOMATO

**Branch:** `main`

Jenkins uses this repository as the source for the pipeline.

The repository contains the React application source code, package configuration, Dockerfile, and Jenkins pipeline definition.

## 5. Application Preparation

Before creating the Docker image, the React application's dependencies and build configuration were corrected.

Some dependency compatibility issues occurred during the initial build.

### Issues encountered

- An ESLint package compatibility issue.
- An unknown `jest/globals` environment error.
- Node.js version compatibility warnings from some dependencies.

### Changes made

The following changes were applied:

- Updated `react-scripts` to version `5.0.1`.
- Removed the conflicting explicit ESLint dependency.
- Pinned `eslint-plugin-jest` to version `25.6.0`.
- Updated the Docker build environment to Node.js 20.

The React production build was tested using:

```bash
npm run build
```

The build completed successfully and generated the production files in the `build` directory.

## 6. Dockerfile Configuration

A multi-stage Docker build was used to create a production-ready Docker image.

### Dockerfile

```dockerfile
# Stage 1: Build the React application
FROM node:20-alpine AS builder

# Set working directory
WORKDIR /app

# Copy dependency files
COPY package*.json ./

# Install dependencies
RUN npm ci

# Copy application source code
COPY . .

# Build React application
RUN NODE_OPTIONS=--openssl-legacy-provider npm run build


# Stage 2: Production server
FROM nginx:alpine

# Copy production build files into Nginx
COPY --from=builder /app/build /usr/share/nginx/html

# Expose HTTP port
EXPOSE 80

# Start Nginx
CMD ["nginx", "-g", "daemon off;"]
```

*Note: This represents the Dockerfile structure used in the project. The committed Dockerfile in GitHub is the source of truth.*

### Explanation of the Dockerfile

**Stage 1 – Node.js Builder**

`FROM node:20-alpine AS builder`

Uses Node.js 20 on Alpine Linux as the build environment.

`WORKDIR /app`

Creates and selects the working directory inside the container.

`COPY package*.json ./`

Copies the dependency configuration files.

`RUN npm ci`

Installs the dependencies using the lock file.

`COPY . .`

Copies the application source code into the container.

`RUN NODE_OPTIONS=--openssl-legacy-provider npm run build`

Builds the React application and generates optimized production files.

**Stage 2 – Nginx Production Server**

`FROM nginx:alpine`

Uses the lightweight Nginx Alpine image as the final production image.

`COPY --from=builder /app/build /usr/share/nginx/html`

Copies the production build from the first stage into Nginx's default web directory.

`EXPOSE 80`

Documents the HTTP port used by the container.

`CMD ["nginx", "-g", "daemon off;"]`

Starts Nginx in the foreground so Docker can manage the running process.

### Why Multi-Stage Builds?

A multi-stage build separates the application build environment from the production environment.

The final image contains Nginx and the generated React files rather than the entire Node.js build environment.

Benefits:

- Smaller production image.
- Reduced unnecessary dependencies.
- Better separation between build and runtime environments.
- Suitable for serving static React applications.

## 7. Jenkins Configuration

Jenkins was hosted on a separate Ubuntu EC2 instance.

The Jenkins pipeline was configured to perform the following stages:

1. Git Checkout
2. Build Docker Image
3. Login to Docker Hub
4. Push Docker Image
5. Cleanup

### Docker Hub Credentials

A Jenkins credential was created to securely store Docker Hub authentication details.

Configuration:

| Field | Value |
|---|---|
| Kind | Username with password |
| Scope | Global |
| Username | `vhvinayak` |
| Password | Docker Hub Read & Write access token |
| ID | `dockerhub-credentials` |
| Description | Docker Hub credentials for Zomato pipeline |

The Jenkinsfile references the credential ID instead of storing the Docker Hub token directly in the pipeline.

Never commit access tokens or passwords to GitHub.

## 8. Jenkins Pipeline

The pipeline automates the Docker image build and push process.

### Pipeline Workflow

**Stage 1 – Git Checkout**

Jenkins retrieves the application source code from the GitHub repository.

**Stage 2 – Build Docker Image**

Docker builds the React application using the Dockerfile and creates the production image.

**Stage 3 – Login to Docker Hub**

Jenkins authenticates with Docker Hub using the stored Jenkins credentials.

**Stage 4 – Push Docker Image**

The image is pushed to the Docker Hub repository.

**Stage 5 – Cleanup**

The pipeline removes the local image after the push to reduce unnecessary storage usage on the Jenkins server, if configured in the pipeline.

### Representative Jenkinsfile

The following is an illustrative Declarative Pipeline for the workflow. Adapt the tag and cleanup commands to match the actual Jenkinsfile used in the project.

```groovy
pipeline {
    agent any

    environment {
        IMAGE_NAME = 'vhvinayak/zomato-clone:latest'
    }

    stages {

        stage('Git Checkout') {
            steps {
                git branch: 'main',
                    url: 'https://github.com/Vinayak202003/ZOMATO.git'
            }
        }

        stage('Build Docker Image') {
            steps {
                sh 'docker build -t $IMAGE_NAME .'
            }
        }

        stage('Login to Docker Hub') {
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: 'dockerhub-credentials',
                        usernameVariable: 'DOCKER_USER',
                        passwordVariable: 'DOCKER_PASSWORD'
                    )
                ]) {
                    sh '''
                        echo "$DOCKER_PASSWORD" |
                        docker login -u "$DOCKER_USER" --password-stdin
                    '''
                }
            }
        }

        stage('Push Docker Image') {
            steps {
                sh 'docker push $IMAGE_NAME'
            }
        }

        stage('Cleanup') {
            steps {
                sh 'docker image rm $IMAGE_NAME || true'
            }
        }
    }
}
```

**Important:** This is a representative pipeline, not a verified copy of the exact Jenkinsfile executed during the project. The actual pipeline may use different syntax or image tags.

### How the Pipeline Works

When the Jenkins job is triggered:

1. Jenkins connects to GitHub.
2. It downloads the latest source code from the selected branch.
3. Docker builds the image using the Dockerfile.
4. Jenkins retrieves Docker Hub credentials from its credential store.
5. Docker authenticates with Docker Hub.
6. The image is uploaded to the Docker Hub repository.
7. The pipeline performs cleanup.

## 9. Docker Hub Configuration

Docker Hub acts as the central image registry.

**Repository:** `vhvinayak/zomato-clone`

**Image tag used for the successful deployment:** `latest`

The image can be pulled using:

```bash
docker pull vhvinayak/zomato-clone:latest
```

Docker Hub provides a centralized location for storing and distributing the container image.

## 10. AWS EC2 Deployment

A separate EC2 instance was created to host the production application.

### EC2 Configuration

| Setting | Configuration |
|---|---|
| AMI | Ubuntu Server 24.04 LTS |
| Architecture | 64-bit x86 |
| Instance type | `t2.micro` or `t3.micro`, depending on availability |
| Storage | 8–10 GB |
| Web access | HTTP port 80 |
| Remote access | SSH port 22 |

The deployment instance is separate from the Jenkins server.

### Step 1 – Connect to EC2

Connect using AWS EC2 Instance Connect or SSH.

Update the package information:

```bash
sudo apt update
```

### Step 2 – Install Docker

```bash
sudo apt install docker.io -y
```

Enable and start Docker:

```bash
sudo systemctl enable --now docker
```

Check the Docker version:

```bash
docker --version
```

Check Docker service status:

```bash
sudo systemctl status docker
```

### Step 3 – Configure Docker Permissions

The Ubuntu user initially encountered a Docker socket permission issue.

To allow the `ubuntu` user to execute Docker commands without `sudo`:

```bash
sudo usermod -aG docker ubuntu
```

Log out and reconnect for the group membership change to take effect.

Verify:

```bash
docker ps
```

Alternatively, continue using `sudo docker` for Docker commands.

### Step 4 – Pull the Docker Image

Pull the image from Docker Hub:

```bash
sudo docker pull vhvinayak/zomato-clone:latest
```

Verify the downloaded image:

```bash
sudo docker images
```

Expected repository and tag:

```text
REPOSITORY               TAG
vhvinayak/zomato-clone   latest
```

### Step 5 – Run the Docker Container

Execute:

```bash
sudo docker run -d \
  -p 80:80 \
  --name zomato-app \
  vhvinayak/zomato-clone:latest
```

### Explanation

| Option | Purpose |
|---|---|
| `-d` | Runs the container in the background |
| `-p 80:80` | Maps EC2 port 80 to container port 80 |
| `--name zomato-app` | Assigns a name to the container |
| Image name | Specifies the Docker image to run |

### Step 6 – Verify Container Status

```bash
sudo docker ps
```

The container should appear with a port mapping similar to:

```text
0.0.0.0:80->80/tcp
```

This confirms that the container is running and its HTTP port is published on the EC2 instance.

### Step 7 – Configure AWS Security Group

The deployment EC2 security group must allow inbound HTTP traffic.

Configure the inbound rules:

| Type | Protocol | Port | Source |
|---|---|---|---|
| SSH | TCP | 22 | My IP |
| HTTP | TCP | 80 | 0.0.0.0/0 |

SSH should be restricted to trusted IP addresses. HTTP is publicly accessible so users can open the application.

### Step 8 – Access the Application

Copy the deployment EC2 instance's Public IPv4 address.

Open the following URL:

```text
http://YOUR-EC2-PUBLIC-IP
```

The React Zomato Clone application is served through Nginx inside the Docker container.

## 11. Understanding Nginx in This Project

Nginx was not installed directly on the Ubuntu EC2 host.

Instead, Nginx is included in the final Docker image through:

```dockerfile
FROM nginx:alpine
```

The React production build is copied into:

```text
/usr/share/nginx/html
```

Nginx serves these static files over HTTP.

The port mapping:

```bash
-p 80:80
```

connects:

- EC2 host port 80
- Docker container port 80
- Nginx HTTP service

To check the Nginx version inside the running container:

```bash
sudo docker exec zomato-app nginx -v
```

To view Nginx logs:

```bash
sudo docker logs zomato-app
```

## 12. Troubleshooting and Issues Encountered

### Issue 1 – React Build Failure

**Error:** `ERR_PACKAGE_PATH_NOT_EXPORTED`

**Cause:** Dependency compatibility issues involving the React build toolchain and ESLint packages.

**Resolution:**
- Updated `react-scripts`.
- Removed the conflicting explicit ESLint dependency.
- Corrected the Jest ESLint plugin version.
- Used Node.js 20 in the Docker build stage.

### Issue 2 – Unknown Jest Environment

**Error:** `Environment key "jest/globals" is unknown`

**Cause:** ESLint plugin compatibility.

**Resolution:**

```bash
npm install --save-dev eslint-plugin-jest@25.6.0
```

The application build subsequently completed successfully.

### Issue 3 – Docker Hub Push Authentication

**Error:**

```text
authentication required - access token has insufficient scopes
```

**Cause:** The Docker Hub access token did not have sufficient permissions.

**Resolution:**
- Generated a Docker Hub Personal Access Token.
- Selected Read & Write permissions.
- Updated the Jenkins credential.

### Issue 4 – Jenkins Credential Not Found

**Error:**

```text
Could not find credentials entry with ID 'dockerhub-credentials'
```

**Cause:** The Jenkinsfile referenced a credential ID that did not exist.

**Resolution:**
Created a new Jenkins credential with the exact ID:

```text
dockerhub-credentials
```

The pipeline subsequently authenticated successfully.

### Issue 5 – Docker Image Not Found

**Error:**

```text
docker.io/vhvinayak/zomato-clone:1: not found
```

**Cause:** The deployment command used the `1` tag, but the available image was tagged `latest`.

**Resolution:**

Used the correct image reference:

```bash
sudo docker pull vhvinayak/zomato-clone:latest
```

### Issue 6 – Docker Socket Permission Denied

**Error:**

```text
permission denied while trying to connect to the Docker API
```

**Cause:** The Ubuntu user did not have permission to access the Docker socket.

**Resolution:**

```bash
sudo usermod -aG docker ubuntu
```

After reconnecting, Docker commands could be executed without `sudo`.

## 13. Final Project Outcome

The project successfully demonstrates the following:

- Source code management through GitHub.
- Jenkins-based CI pipeline execution.
- Docker image creation through a multi-stage build.
- Docker Hub authentication using Jenkins credentials.
- Docker image push to a central registry.
- Docker image pull on a separate AWS EC2 instance.
- Containerized deployment using Docker.
- Production React application serving through Nginx.
- Public application access through the EC2 public IPv4 address.

**Final Docker Image:**

```text
vhvinayak/zomato-clone:latest
```

**Container Name:**

```text
zomato-app
```

**Application URL:**

```text
http://YOUR-EC2-PUBLIC-IP
```

## 14. Future Enhancements

The following improvements can make this project closer to a production-style CI/CD implementation.

1. **Automatic Deployment:** Configure Jenkins to connect to the deployment EC2 and deploy the newly pushed Docker image automatically.

2. **GitHub Webhooks:** Trigger the Jenkins pipeline automatically whenever new code is pushed to GitHub.

3. **Versioned Docker Images:** Use build numbers or Git commit IDs instead of relying only on the `latest` tag.

4. **Docker Compose:** Use Docker Compose if the application later requires multiple containers or supporting services.

5. **HTTPS Configuration:** Configure a domain name and SSL/TLS certificate.

6. **Monitoring:** Introduce CloudWatch monitoring and application/container health checks.

7. **Infrastructure as Code:** Use AWS CloudFormation or Terraform to automate EC2 and networking resource creation.

8. **Container Orchestration:** Explore Kubernetes or Amazon EKS for larger-scale container deployments.

## 15. Conclusion

This project provided practical experience in integrating GitHub, Jenkins, Docker, Docker Hub, AWS EC2, and Nginx into an application deployment workflow.

It demonstrated how a frontend application can be built in a controlled environment, packaged into a Docker image, stored in a container registry, and deployed to a cloud server.

The project also provided hands-on experience with Jenkins credentials, Linux administration, Docker image management, EC2 security groups, container networking, and troubleshooting deployment issues.

The next planned improvement is to extend the existing Jenkins pipeline to perform automatic deployment on the AWS EC2 instance after a successful Docker image push.
