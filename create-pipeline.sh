#!/bin/bash

PIPELINE=""
ENV_TYPE="Global"
INPUT_FILE=""
RELEASE=""
IFS=,
TMP_PARALLEL=false
INFRA_TYPE=""
WEB_WORKFLOW=""
ZIP_WORKFLOW=""

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

  if [ -f ${PIPELINE} ]; then
     echo "${PIPELINE}" exists
     exit 0
  fi
  echo "Validating input $INPUT_FILE"
  cat $INPUT_FILE | xargs -L 1 | fn_validate_input
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
  # Append zip workflows
  TMP_PARALLEL=false
  cat $INPUT_FILE | xargs -L 1 | fn_process_input1
  # Add approval
  cat $INPUT_FILE | xargs -L 1 | fn_process_input2
  # Append web workflows
  TMP_PARALLEL=false
  cat $INPUT_FILE | xargs -L 1 | fn_process_input3
}



fn_process_approval() {
  sed -e "s/TMP_TYPE/web/" \
      -e "s/TMP_ENV/${ENV_TYPE}/" \
     approval.wf
}

# Output zip workflow

fn_process_zip() {
  sed -e "s/TMP_SVC_NAME/$1/" \
      -e "s/TMP_ENV/${ENV_TYPE}/" \
      -e "s/TMP_TYPE/zip/" \
      -e "s/TMP_PARALLEL/${TMP_PARALLEL}/" \
      -e "s/TMP_WORKFLOW_NAME_ZIP/${ZIP_WORKFLOW}/" \
      -e "s/TMP_BATCH_VALUE/${2}/" \
      -e "s/TMP_CONFIG_VALUE/${3}/" \
      -e "s/INFRA_TYPE/${INFRA_TYPE}/" \
      zip.wf
   
}

# Output web workflow

fn_process_web() {

    sed -e "s/TMP_SVC_NAME/$1/" \
      -e "s/TMP_ENV/${ENV_TYPE}/" \
      -e "s/TMP_PARALLEL/${TMP_PARALLEL}/" \
      -e "s/TMP_TYPE/web/" \
      -e "s/TMP_WORKFLOW_NAME_WEB/${WEB_WORKFLOW}/" \
      -e "s/INFRA_TYPE/${INFRA_TYPE}/" \
      web.wf  

}

fn_validate_input(){
   while IFS= read -r line
   do
     echo "Validating $line"
     echo "TBD..."
   done
}

# First pass to handle zip workflows

fn_process_input1(){
  while read app batch config web; do
    isBatch=`fn_get_value $batch`
    isConfig=`fn_get_value $config`
    if [ $isBatch == yes -o $isConfig == yes ]; then
      fn_process_zip $app $isBatch $isConfig >> ${PIPELINE}
      TMP_PARALLEL=true
    fi
  done
}

# Second pass to add approval only for web workflows

fn_process_input2(){
  while read app batch config web; do
    isWeb=`fn_get_value $web`
    if [ $isWeb == yes ]; then
       fn_process_approval >> ${PIPELINE}
       break
    fi
  done
}

# Third pass to add approval only for web workflows
fn_process_input3(){
  while read app batch config web; do
    isWeb=`fn_get_value $web`
    if [ $isWeb == yes ]; then
       fn_process_web $app >> ${PIPELINE}
       TMP_PARALLEL=true
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

if [ $# -lt 5 ]; then
   echo "Usage: create-pipeline.sh <release>.pl <env> <infra> <zip> <web>"
   exit 0
fi

INPUT_FILE=$1
ENV_TYPE=$2
INFRA_TYPE=$3
ZIP_WORKFLOW=$4
WEB_WORKFLOW=$5

fn_init_pipeline 
fn_create_pipeline 
fn_append_pipeline

