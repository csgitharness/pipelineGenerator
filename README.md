# Dynamic Pipeline Generator

## Introduction

This script was designed to Dynamically Generate Pipelines for OCC Encore2 Application and Pricing Application. By taking a specific input, this script will generate a Harness Pipeline Yaml that can be synced to the OCC's Harness account through Configuration as Code. 

The Team originally wanted a pipeline generator so they wouldn't have to manually create the pipelines form scratch. With this script, the developer needs to provide a select set of inputs and based of these inputs we generate the pipeline

---

## Architecture of the Generated Pipeline

The OCC team will be deploying the deploy_zip workflow first which contains workflow variables to indicate deploy_batch or deploy_config. The script allows to pass the parameters "yes" or "no". The Third component is Web. If the user specifies yes to web, the corresponding web service will be added to the pipeline.

```
[Zip1 - Zip2 - Zip3] - Approval - [Web1 - Web2 - Web3]
```

---

## How to Use

1. The user will need to provide a sample input file in the format below:

The Format is based on this table: 

| Service | Batch | Config | Web |
|------------|-------|--------|-----|
| agreements | Y | N | Y |
| arch | Y | N | N |
| drive | Y | N | N |


#### Sample Input File

```
agreements,Y,N,Y
arch,Y,N,N
drive,Y,N,N
```


2. The user will pass in a <file-name>.pl, harness environment they want to deploy to, and a harness service infrastructure value.


Example input for the script:

```
./create-pipeline.sh pl2019.pl tech tech1
```

The expected output:

```
Creating new pipeline pl2019-2019-10-13.yaml
Appending to existing pipeline pl2019-2019-10-13.yaml
```

- In the above example, the first argument, *tech* represents the environment a developer wishes to deploy into. 
- The second argument, *tech1* represents the service infrastructure mapping where the developer wishes to deploy. 

```
pl2019-2019-10-13.yaml
```

The filename generated from the pipeline takes the file name, and appends the date it was created. This was done in order to prevent conflicting names from being created. In the example above, the filename is *pl2019* and the script appends the date created, in this case *2019-10-13*. 

**Sample Pipeline YAML**

```
harnessApiVersion: '1.0'
type: PIPELINE
description: Dynamic Pipeline pl2019-2019-10-17.yaml
pipelineStages:
- type: ENV_STATE
  disable: false
  name: agreements-tech-zip
  parallel: false
  stageName: 'STAGE 1'
  workflowName: deploy-zip-prod0
  workflowVariables:
  - name: deploy_batch
    value: yes
  - name: deploy-config
    value: no
  - entityType: ENVIRONMENT
    name: Environment
    value: tech
  - entityType: SERVICE
    name: Service
    value: agreements
  - entityType: INFRASTRUCTURE_MAPPING
    name: ServiceInfra_SSH
    value: agreements-tech1
- type: ENV_STATE
  disable: false
  name: arch-tech-zip
  parallel: true
  stageName: 'STAGE 1'
  workflowName: deploy-zip-prod0
  workflowVariables:
  - name: deploy_batch
    value: yes
  - name: deploy-config
    value: no
  - entityType: ENVIRONMENT
    name: Environment
    value: tech
  - entityType: SERVICE
    name: Service
    value: arch
  - entityType: INFRASTRUCTURE_MAPPING
    name: ServiceInfra_SSH
    value: arch-tech1
- type: ENV_STATE
  disable: false
  name: drive-tech-zip
  parallel: true
  stageName: 'STAGE 1'
  workflowName: deploy-zip-prod0
  workflowVariables:
  - name: deploy_batch
    value: yes
  - name: deploy-config
    value: no
  - entityType: ENVIRONMENT
    name: Environment
    value: tech
  - entityType: SERVICE
    name: Service
    value: drive
  - entityType: INFRASTRUCTURE_MAPPING
    name: ServiceInfra_SSH
    value: drive-tech1
- type: APPROVAL
  disable: false
  name: 'Approval'
  parallel: false
  properties:
    userGroups:
    - sF962ZRwSQO0YQKj6K8yWA
    timeoutMillis: 259200000
    approvalStateType: USER_GROUP
    stageName: 'Stage 2'
- type: ENV_STATE
  disable: false
  name: agreements-tech-web
  parallel: false
  stageName: 'WEB'
  workflowName: deploy-web-prod
  workflowVariables:
  - entityType: ENVIRONMENT
    name: Environment
    value: tech
  - entityType: SERVICE
    name: Service
    value: agreements-web
  - entityType: INFRASTRUCTURE_MAPPING
    name: ServiceInfra_SSH
    value: agreements-web

```

3. Please add the script to Harness Application Git Repository. Under the Pipeline Folder in the Application of choice.

```
.
├── Setup
|   |- Applications
|      |- Default.yaml
|      |- Index.yaml 
|      |- Application1
|         |- Environments
|         |- Pipeline
|         |   |- <Place Pipeline in this folder> pl2019-2019-10-13.yaml
|         |- Services
|         |- Workflows
|          
|      |- Application2
|      |- Application3            
└── README.md
```

4. Ensure that the Bi-Directional sync has been setup between Harness and the Git Repository where the application is being hosted. 

5. Once, sync is established, check the Harness UI to see if the Pipeline has been populated 

**Note: If the Pipeline doesn't upload, please check the error icon, the red alarm, and view the error**

---

## Common Issues

1. The existing infrastructure doesn't exist in Harness

```
 The Service Infrastructure mapping must exist within Harness and has to be spelled correctly. Everything is case sensative when syncing with Harness
``` 

2. The environment doesn't exist in Harness

```
Please make sure the environment is already configured within Harness. Most times its a spelling or case error. The pipeline doesn't generate a new environment and attach it to the application. This must be done within Harness or through configuration as code and must exist before the pipeline is generated and synced. 
```

3. No Workflow with the chosen name exists

```
Please make sure the workflow is named properly and exists in Harness first. 
```

---
## Deep Dive 

### web.wf

The web.wf file is the templated out Harness workflow YAML for a web service related workflow. We use this template and append the desired values when specific which web service is being deployed. We also pass the environment and service infrastructure into the file as well. 

```
- type: ENV_STATE
  disable: false
  name: TMP_SVC_NAME-TMP_ENV-TMP_TYPE
  parallel: TMP_PARALLEL
  stageName: 'WEB'
  workflowName: deploy-web-prod
  workflowVariables:
  - entityType: ENVIRONMENT
    name: Environment
    value: TMP_ENV
  - entityType: SERVICE
    name: Service
    value: TMP_SVC_NAME-web
  - entityType: INFRASTRUCTURE_MAPPING
    name: ServiceInfra_SSH
    value: TMP_SVC_NAME-web
```


### zip.wf 

The zip.wf is a templated out Harness workflow YAML that is appended to a Pipeline.yaml file, similar to the web.wf. The zip.wf file recieves the passed Deploy Batch Value, the Deploy Config Value, the environment, and the service infrastructure value. These values are appended to the file and are compiled together to create a pipeline yaml that Harness can sync and display. 

```
- type: ENV_STATE
  disable: false
  name: TMP_SVC_NAME-TMP_ENV-TMP_TYPE
  parallel: TMP_PARALLEL
  stageName: 'STAGE 1'
  workflowName: deploy-zip-prod0
  workflowVariables:
  - name: deploy_batch
    value: TMP_BATCH_VALUE
  - name: deploy-config
    value: TMP_CONFIG_VALUE
  - entityType: ENVIRONMENT
    name: Environment
    value: TMP_ENV
  - entityType: SERVICE
    name: Service
    value: TMP_SVC_NAME
  - entityType: INFRASTRUCTURE_MAPPING
    name: ServiceInfra_SSH
    value: TMP_SVC_NAME-INFRA_TYPE
```

### approval.wf 

The Approval Workflow is a templated Workflow step from a Harness Pipeline.yaml. The approval step is currently utilized after the zip files are deployed, the user will need to approve before deploying the web files. 

```
- type: APPROVAL
  disable: false
  name: 'Approval'
  parallel: false
  properties:
    userGroups:
    - sF962ZRwSQO0YQKj6K8yWA
    timeoutMillis: 259200000
    approvalStateType: USER_GROUP
    stageName: 'Stage 2'
```

---

## Quick Start 

```
./create-pipeline.sh pl2019.pl tech tech1
Creating new pipeline pl2019-2019-10-13.yaml
Appending to existing pipeline pl2019-2019-10-13.yaml
```

---