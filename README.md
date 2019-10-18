# Dynamic Pipeline Generator

## Introduction

This script was designed to Dynamically Generate Pipelines for OCC Encore2 Application and Pricing Application. By taking a specific input, this script will generate a Harness Pipeline Yaml that can be synced to the OCC's Harness account through Configuration as Code. 

The Team originally wanted a pipeline generator so they wouldn't have to manually create the pipelines form scratch. With this script, the developer needs to provide a select set of inputs and based of these inputs we generate the pipeline

## Architecture of the Generated Pipeline

The OCC team will be deploying the deploy_zip workflow first which contains workflow variables to indicate deploy_batch or deploy_config. The script allows to pass the parameters "yes" or "no". The Third component is Web. If the user specifies yes to web, the corresponding web service will be added to the pipeline.

```
[Zip1 - Zip2 - Zip3] - Aprroval - [Web1 - Web2 - Web 2]
```

## Arguments 

The user will pass in a <file-name>.pl, harness environment they want to deploy to, and a harness service infrastructure value.

Example input for the script:

```
./create-pipeline.sh pl2019.pl Tech tech1
```

The expected output:

```
Creating new pipeline pl2019-2019-10-13.yaml
Appending to existing pipeline pl2019-2019-10-13.yaml
```


## Quick Start 

```
./create-pipeline.sh pl2019.pl Tech tech1
Creating new pipeline pl2019-2019-10-13.yaml
Appending to existing pipeline pl2019-2019-10-13.yaml
```
