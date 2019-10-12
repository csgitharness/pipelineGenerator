#!/bin/bash

PIPELINE=""
ENV_TYPE="Global"
INPUT_FILE=""
RELEASE=""
IFS=,

fn_process_args(){
 if [ $# -lt 2 ]; then
   echo "Usage: create-pipeline.sh <release> <env>.txt"
   exit 0
 fi
 RELEASE=$1
 INPUT_FILE=$2
 
 if [ ! -f $INPUT_FILE ]; then
    echo "File $INPUT_FILE not found"
    exit 0
 fi

 fn_get_pipeline 
}

fn_get_pipeline(){
   ENV_TYPE=${INPUT_FILE%%.*}
   SUFFIX=`date '+%F'`
   PIPELINE=${RELEASE}-${ENV_TYPE}-${SUFFIX}.yaml
}


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

fn_append_pipeline () {
  echo "Appending to existing pipeline ${PIPELINE}"
  cat $INPUT_FILE | xargs -L 1 | fn_process_input
}


fn_process_approval() {
  sed -e "s/TMP_TYPE/$1/" \
      -e "s/TMP_ENV/${ENV_TYPE}/" \
     approval.wf
}

fn_process_batch() {
  for app in $*; do
  sed -e "s/TMP_SVC_NAME/$app/" \
      -e "s/TMP_ENV/${ENV_TYPE}/" \
      -e "s/TMP_TYPE/batch/" \
     batch.wf
  done
}

fn_process_config() {
  for app in $*; do
  sed -e "s/TMP_SVC_NAME/$app/" \
      -e "s/TMP_ENV/${ENV_TYPE}/" \
      -e "s/TMP_TYPE/config/" \
     config.wf
  done
}

fn_process_webapp() {
  for app in $*; do
  sed -e "s/TMP_SVC_NAME/$app/" \
      -e "s/TMP_ENV/${ENV_TYPE}/" \
      -e "s/TMP_TYPE/webapp/" \
     webapp.wf
  done
}


fn_process_workflow() {
  for app in $*; do
  sed -e "s/TMP_SVC_NAME/$app/" \
      -e "s/TMP_ENV/${ENV_TYPE}/" \
     occ-workflow.wf
  done
}

fn_process_input(){
  approval=""
  while read input; do
    occ_type=`echo $input | sed "s/:.*//"`
    occ_apps=`echo $input | sed "s/^.*: //"`
    if [ "$approval" != "" ]; then
      fn_process_approval $occ_type  >> ${PIPELINE}
    fi
    eval fn_process_${occ_type} $occ_apps  >> ${PIPELINE}
    approval=$occ_type
  done
}

######### MAIN ###########


fn_process_args $*
fn_create_pipeline 
fn_append_pipeline

