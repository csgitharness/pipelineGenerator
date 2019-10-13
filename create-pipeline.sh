#!/bin/bash

PIPELINE=""
ENV_TYPE="Global"
INPUT_FILE=""
RELEASE=""
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

fn_process_env() {
 ENV_TYPE=$1
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

fn_process_web() {
  for app in $*; do
  sed -e "s/TMP_SVC_NAME/$app/" \
      -e "s/TMP_ENV/${ENV_TYPE}/" \
      -e "s/TMP_TYPE/web/" \
     web.wf
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

