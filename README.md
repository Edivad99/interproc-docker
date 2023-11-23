# Interproc Docker

## About
Interprocedural static analyzer for an academic imperative language with numerical variables and procedure calls.

## Installation
```bash
git clone https://github.com/Edivad99/interproc-docker.git
cd interproc-docker
docker build -t interproc_image .
docker create -p 8080:80 --name interproc interproc_image
```

## Usage
```bash
# Start the server
docker start interproc
# Stop the server
docker stop interproc
# Delete the container
docker rm -f interproc
```

