#!/bin/sh

if [ "$#" -eq 0 ]; then
   echo "Usage create-pipeline.sh [input file(s)]"
   exit 0
fi

SUFFIX=`date '+%F'`
PIPELINE="Dynamic-1-${SUFFIX}"
OUTPUT_DIR="output"

###### FUNCTIONS ######

fn_create_pipeline () {
 
  EXT=1
  MAX_PIPELINES_PER_DAY=10
  
  while [ $EXT -le $MAX_PIPELINES_PER_DAY ]; do
     PIPELINE="Dynamic-${EXT}-${SUFFIX}"
     if [ ! -f ${OUTPUT_DIR}/${PIPELINE}.yaml ]; then
       break
     fi
     ((EXT=$EXT+1))
  done
  
  echo "Creating new pipeline ${OUTPUT_DIR}/${PIPELINE}.yaml"
  cat <<_EOF_  > ${OUTPUT_DIR}/${PIPELINE}.yaml
harnessApiVersion: '1.0'
type: PIPELINE
description: Dynamic Pipeline ${SUFFIX}
pipelineStages:
_EOF_
 
}

fn_append_pipeline () {
  INPUT_FILE=$1
  echo "Appending $INPUT_FILE to existing pipeline ${OUTPUT_DIR}/${PIPELINE}.yaml"
  ENV_TYPE=${INPUT_FILE%%.*}
  APPS=`sed -e "/^#/d" -e '/=/d' $INPUT_FILE` 
  VARS=`sed -e "/^#/d" -e '/=/!d' $INPUT_FILE` 
  WF_TYPE=`sed -n -e "/^#@/s/^#@//p" $INPUT_FILE` 
  for app in $APPS; do
     sed -e "s/TMP_APP_NAME/$app/" \
         -e "s/TMP_ENV/${ENV_TYPE}/" \
          ${WF_TYPE}
     for var in $VARS; do 
        echo $var | sed "s/\(.*\)=\(.*\)/  - name: \1\n    value: '\2'/" 
     done
  done  >> ${OUTPUT_DIR}/${PIPELINE}.yaml
}

############## MAIN ################

mkdir -p $OUTPUT_DIR

fn_create_pipeline 
for ifile in $@; do
  fn_append_pipeline  $ifile
done
