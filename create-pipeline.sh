#!/bin/bash

PIPELINE=""
ENV_TYPE="Global"
INPUT_FILE=""
RELEASE=""
IFS=,
TMP_PARALLEL=false

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
  cat $INPUT_FILE | xargs -L 1 | fn_process_input1
  fn_process_approval >> ${PIPELINE}
  cat $INPUT_FILE | xargs -L 1 | fn_process_input2
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


fn_process_zip() {
  sed -e "s/TMP_SVC_NAME/$1/" \
      -e "s/TMP_ENV/${ENV_TYPE}/" \
      -e "s/TMP_TYPE/zip/" \
      -e "s/TMP_PARALLEL/${TMP_PARALLEL}/" \
      -e "s/TMP_BATCH_VALUE/${2}/" \
      -e "s/TMP_CONFIG_VALUE/${3}/" \
      zip.wf
    TMP_PARALLEL=true
}

fn_process_web() {
  for app in $*; do
    sed -e "s/TMP_SVC_NAME/$app/" \
      -e "s/TMP_ENV/${ENV_TYPE}/" \
      -e "s/TMP_PARALLEL/${TMP_PARALLEL}/" \
      -e "s/TMP_TYPE/web/" \
      web.wf
    TMP_PARALLEL=true
  done
}


fn_process_workflow() {
  for app in $*; do
  sed -e "s/TMP_SVC_NAME/$app/" \
      -e "s/TMP_ENV/${ENV_TYPE}/" \
     o9cc-workflow.wf
  done
}

fn_process_input1(){
  while read app batch config web; do
    isBatch=`fn_get_value $batch`
    isConfig=`fn_get_value $config`
   # isWeb=`fn_get_value $web`
    if [ $isBatch == yes -o $isConfig == yes ]; then
      fn_process_zip $app $isBatch $isConfig >> ${PIPELINE}
    fi
  done
}

fn_process_input2(){
  while read app batch config web; do
    isWeb=`fn_get_value $web`
    if [ $isWeb == yes ]; then
       fn_process_web $app >> ${PIPELINE}
    fi
  done
}

fn_get_value() {

   input=$1
   
   if [ $input = 'Y' ] || [ $input = 'y' ]; then
      echo yes
   fi
   if [ $input = 'N' ] || [ $input = 'n' ]; then
      echo no
   fi
   
   if [ $input = 'T' ] || [ $input = 't' ]; then
      echo true
   fi
   if [ $input = 'F' ] || [ $input = 'f' ]; then
      echo false
   fi
}

########## MAIN #########

if [ $# -lt 2 ]; then
   echo "Usage: create-pipeline.sh <release>.pl <env>"
   exit 0
fi

INPUT_FILE=$1
ENV_TYPE=$2

fn_init_pipeline 
fn_create_pipeline 
fn_append_pipeline