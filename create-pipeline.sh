#!/bin/sh

if [ "$#" -eq 0 ]; then
   echo "Usage create-pipeline.sh [input file(s)]"
   exit 0
fi

SUFFIX=`date '+%F'`
PIPELINE="Dynamic-1-${SUFFIX}"

###### FUNCTIONS ######

fn_create_pipeline () {
  INPUT_FILE=$1
  EXT=1
  while [ $EXT -le 10 ]; do
     PIPELINE="Dynamic-${EXT}-${SUFFIX}"
     if [ ! -f ${PIPELINE}.yaml ]; then
       break
     fi
     ((EXT=$EXT+1))
  done
  echo "Creating new pipeline ${PIPELINE}.yaml"
  if [ ! -f ${PIPELINE}.yaml ]; then
     cat <<_EOF_  > ${PIPELINE}.yaml
harnessApiVersion: '1.0'
type: PIPELINE
description: Dynamic Pipeline ${SUFFIX}
pipelineStages:
_EOF_
  fi
}

fn_append_pipeline () {
  INPUT_FILE=$1
  echo "Appending $INPUT_FILE to existing pipeline ${PIPELINE}.yaml"
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
  done  >> ${PIPELINE}.yaml
}

############## MAIN ################

fn_create_pipeline 
for ifile in $@; do
  fn_append_pipeline  $ifile
done
