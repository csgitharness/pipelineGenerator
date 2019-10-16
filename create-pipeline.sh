#!/bin/bash

PIPELINE=""
ENV_TYPE="Global"
WORKFLOW_NAME=""
INPUT_FILE=""
RELEASE=""
TMP_YN=""
IFS=,

fn_init_pipeline(){
 RELEASE=${INPUT_FILE%%.*}
 if [ ! -f $INPUT_FILE ]; then
    echo "File $INPUT_FILE not found"
    exit 0
 fi
 SUFFIX=`date '+%F'`
 PIPELINE=${RELEASE}-${SUFFIX}.yaml
}

### Creates the pipeline header, standard four lines ####

fn_create_pipeline () {

  if [  -f ${PIPELINE} ]; then
     echo "${PIPELINE}" exists
     exit 0
  fi
  echo "Creating new pipeline ${PIPELINE}"
  cat <<_EOF_  > ${PIPELINE}
harnessApiVersion: '1.0'
type: PIPELINE
description: Dynamic Pipeline ${PIPELINE}
pipelineStages:
_EOF_
}

### Updates the Pipeline based on the input file ###

fn_append_pipeline () {
  echo "Appending to existing pipeline ${PIPELINE}"
  cat $INPUT_FILE | xargs -L 1 | fn_process_input
}

### Process the new environment variable, overrides what was previously set as input ###
fn_process_env() {
 ENV_TYPE=$1
}

### Appends the Approval stage
fn_process_approval() {
  sed -e "s/TMP_TYPE/$1/" \
      -e "s/TMP_ENV/${ENV_TYPE}/" \
     approval.wf
}

### Appends the batch workflow 

fn_process_batch() {
  for app in $*; do
  sed -e "s/TMP_SVC_NAME/$app/" \
      -e "s/TMP_ENV/${ENV_TYPE}/" \
      -e "s/TMP_TYPE/batch/" \
      -e "s/TMP_YN/${TMP_YN}" \
     batch.wf
  done
}

### Appends the Config workflow 

fn_process_config() {
  for app in $*; do
  sed -e "s/TMP_SVC_NAME/$app/" \
      -e "s/TMP_ENV/${ENV_TYPE}/" \
      -e "s/TMP_TYPE/config/" \
      -e "s/WORKFLOW_NAME/${WORKFLOW_NAME}"
      -e "s/TMP_YN/${TMP_YN}" \
     config.wf
  done
}

### Appends the Web workflow

fn_process_web() {
  for app in $*; do
  sed -e "s/TMP_SVC_NAME/$app/" \
      -e "s/TMP_ENV/${ENV_TYPE}/" \
      -e "s/TMP_TYPE/web/" \
     web.wf
  done
}

#### Currently, not being used ####
# Note: can be a optimization later 

fn_process_workflow() {
  for app in $*; do
  sed -e "s/TMP_SVC_NAME/$app/" \
      -e "s/TMP_ENV/${ENV_TYPE}/" \
     occ-workflow.wf
  done
}

## This function process the input file and appends it to the pipeline file to build the Pipeline YAML
## Core function of the script
## 106, Dynamically generates the function name and then generates the file, removes the need for a switch statement
## Note: if additional input is provided which is not covered by the key words we have chosen, adding function process_NEWKEYWORD, will be body of func

fn_process_input(){
  while read input; do
    occ_type=`echo $input | sed "s/:.*//"`
    occ_apps=`echo $input | sed "s/^.*: //"`
    eval fn_process_${occ_type} $occ_apps  >> ${PIPELINE}
  done
}

########## MAIN #########

if [ $# -lt 1 ]; then
   echo "Usage: create-pipeline.sh <release>.pl"
   exit 0
fi

INPUT_FILE=$1

fn_init_pipeline 
fn_create_pipeline 
fn_append_pipeline
