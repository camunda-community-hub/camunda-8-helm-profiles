#! /bin/bash

clear

printf "******* Starting Backup Script for C8 ******* \n\n"

BACKUP_ID=$(date +"%Y%m%d%H%M%S")
BACKUP_COUNTER=0
timestamp=$(date +"%Y%m%d%H%M%S")


operate_snapshot_repo_create_endpoint="http://localhost:9200/_snapshot/operate_repo"

optimize_snapshot_repo_create_endpoint="http://localhost:9200/_snapshot/optimize_repo"

tasklist_snapshot_repo_create_endpoint="http://localhost:9200/_snapshot/tasklist_repo"

zeebe_snapshot_repo_create_endpoint="http://localhost:9200/_snapshot/zeebe_repo"
zeebe_pause_export_endpoint="http://localhost:9600/actuator/exporting/pause"
zeebe_resume_export_endpoint="http://localhost:9600/actuator/exporting/resume"
zeebe_backup_rocksdb_endpoint="http://localhost:9600/actuator/backup"


function lookup_trigger_snapshot_operate() {

  idx_passed=$1
  shift
  local arr=("$@")  

  local idx=0
  for i in "${!arr[@]}"
  do
    idx_name=${arr[$i]}
    if [[ $idx_name = "${idx_passed}"* ]]; then
      printf "\n Found! - $idx_name \n"    
      trigger_es_snapshot_operate $idx_name
      idx=$i
      break
    fi
    
  done

  printf "\n\n"

  return "$idx"

}


## create operate shapshot 1 - comma separated list of indices
function trigger_es_snapshot_operate() {
  
   printf "\n\n"
  
  let BACKUP_COUNTER=BACKUP_COUNTER+1
  local operate_snapshot_start_endpoint="http://localhost:9200/_snapshot/operate_repo/camunda_operate_snapshot_${BACKUP_ID}_${BACKUP_COUNTER}?wait_for_completion=true"

  curl --request PUT \
      --url "${operate_snapshot_start_endpoint}" \
      --header 'Content-Type: application/json' \
      --data '{
          "indices": "'${1}'"
      }'
}

function lookup_trigger_snapshot_optimize() {

  idx_passed=$1
  shift
  local arr=("$@")  

  local idx=0
  for i in "${!arr[@]}"
  do
    idx_name=${arr[$i]}
    if [[ $idx_name = "${idx_passed}"* ]]; then
      printf "\n Found! - $idx_name \n"    
      trigger_es_snapshot_optimize $idx_name
      idx=$i
      break
    fi
    
  done

  return "$idx"

}

## create tasklist shapshot 1 - comma separated list of indices
function trigger_es_snapshot_optimize() {

  let BACKUP_COUNTER=BACKUP_COUNTER+1
  local optimize_snapshot_start_endpoint="http://localhost:9200/_snapshot/optimize_repo/camunda_optimize_snapshot_${BACKUP_ID}_${BACKUP_COUNTER}?wait_for_completion=true"

  curl --request PUT \
      --url "${optimize_snapshot_start_endpoint}" \
      --header 'Content-Type: application/json' \
      --data '{
          "indices": "'${1}'"
      }'
}

function lookup_trigger_snapshot_tasklist() {

  idx_passed=$1
  shift
  local arr=("$@")  

  printf "Passed index - $idx_passed"

  local idx=0
  for i in "${!arr[@]}"
  do
    idx_name=${arr[$i]}
    if [[ $idx_name = "${idx_passed}"* ]]; then
      printf "\n Found! - $idx_name  \n"    
      trigger_es_snapshot_tasklist $idx_name
      idx=$i
      # break
    fi
    
  done

  return "$idx"

}

## create tasklist shapshot 1 - comma separated list of indices
function trigger_es_snapshot_tasklist() {

  printf "${1}"
  let BACKUP_COUNTER=BACKUP_COUNTER+1
  local optimize_snapshot_start_endpoint="http://localhost:9200/_snapshot/tasklist_repo/camunda_tasklist_snapshot_${BACKUP_ID}_${BACKUP_COUNTER}?wait_for_completion=true"

  curl --request PUT \
      --url "${optimize_snapshot_start_endpoint}" \
      --header 'Content-Type: application/json' \
      --data '{
          "indices": "'${1}'"
      }'
}

## create zeebe shapshot 1 - comma separated list of indices
function trigger_es_snapshot_zeebe() {

  printf "${1}"
  let BACKUP_COUNTER=BACKUP_COUNTER+1
  local zeebe_snapshot_start_endpoint="http://localhost:9200/_snapshot/zeebe_repo/camunda_zeebe_snapshot_${BACKUP_ID}_${BACKUP_COUNTER}?wait_for_completion=true"

  curl --request PUT \
      --url "${zeebe_snapshot_start_endpoint}" \
      --header 'Content-Type: application/json' \
      --data '{
          "indices": "'${1}'",
          "feature_states": ["none"]
      }'
}



printf "\n ****Getting all indices from ES**** \n"

curl --request GET \
    --url http://localhost:9200/_cat/indices \
  --header 'Accept: application/json' \
   -o es-indices.json


printf "\n\n"

#######################################################################################################################
# Optimize backup steps
#    Part 1:
# [index-prefix]-import-index
# [index-prefix]-timestamp-based-import-index
# [index-prefix]-position-based-import-index
# 
#######################################################################################################################

## Step 0 - create optimize snapshot repo

curl --request PUT \
        --url "${optimize_snapshot_repo_create_endpoint}" \
        --header 'Content-Type: application/json' \
        --data '{
        "type": "s3",
        "settings": {
          "bucket": "dk-c8"
        }
      }'


## Pass 1 - read through the list of indices, check if the name is one in Part 1 list and then trigger backup

printf "\n\n ***** Indices for Optimize ****** \n\n"

jq -r '.[] | select(.index|test("^optimize.")) | .index' es-indices.json  > optimize.txt

arr=() 
while read line; do
    arr+=("$line")
done < optimize.txt


#### Import Index
lookup_trigger_snapshot_optimize optimize-import-index "${arr[@]}"
deleted_id=$?
# printf "\n\n Deleted id - $deleted_id \n"
unset arr[$deleted_id] 

#### Timestamp Based Import Index
lookup_trigger_snapshot_optimize optimize-timestamp-based-import-index "${arr[@]}"
deleted_id=$?
# printf "\n\n Deleted id - $deleted_id\n"
unset arr[$deleted_id] 

#### Position Based Import Index
lookup_trigger_snapshot_optimize optimize-position-based-import-index "${arr[@]}"
deleted_id=$?
printf "\n\n Deleted id - $deleted_id \n"
unset arr[$deleted_id] 

## Pass 2 - all Other optimize indices
other_optimize_indices=$(IFS=,; printf '%s\n' "${arr[*]}")
printf "$other_optimize_indices"

printf '\n\n Handle all other indices back for optimize \n\n'

trigger_es_snapshot_optimize $other_optimize_indices

printf "\n\n\n\n"

#####################################################################################################################
# Operate backup steps
#####################################################################################################################

## Step 0 - create operate snapshot repo

curl --request PUT \
        --url "${operate_snapshot_repo_create_endpoint}" \
        --header 'Content-Type: application/json' \
        --data '{
        "type": "s3",
        "settings": {
          "bucket": "dk-c8"
        }
      }'


printf "\n\n***** Indices for Operate ******\n\n"

jq -r '.[] | select(.index|test("^operate.")) | .index' es-indices.json  > operate.txt

arr_operate=() 
while read line; do
    arr_operate+=("$line")
done < operate.txt

### import position

trigger_es_snapshot_operate operate-import-position-8.3.0_

trigger_es_snapshot_operate operate-list-view-8.3.0_

trigger_es_snapshot_operate operate-list-view-8.3.0_*,-operate-list-view-8.3.0_

trigger_es_snapshot_operate operate-batch-operation-1.0.0_,operate-decision-instance-8.3.0_,operate-event-8.3.0_,operate-flownode-instance-8.3.1_,operate-incident-8.3.1_,operate-message-8.5.0_,operate-operation-8.4.1_,operate-post-importer-queue-8.3.0_,operate-sequence-flow-8.3.0_,operate-user-task-8.5.0_,operate-variable-8.3.0_

trigger_es_snapshot_operate operate-batch-operation-1.0.0_*,-operate-batch-operation-1.0.0_,operate-decision-instance-8.3.0_*,-operate-decision-instance-8.3.0_,operate-event-8.3.0_*,-operate-event-8.3.0_,operate-flownode-instance-8.3.1_*,-operate-flownode-instance-8.3.1_,operate-incident-8.3.1_*,-operate-incident-8.3.1_,operate-message-8.5.0_*,-operate-message-8.5.0_,operate-operation-8.4.1_*,-operate-operation-8.4.1_,operate-post-importer-queue-8.3.0_*,-operate-post-importer-queue-8.3.0_,operate-sequence-flow-8.3.0_*,-operate-sequence-flow-8.3.0_,operate-user-task-8.5.0_*,-operate-user-task-8.5.0_,operate-variable-8.3.0_*,-operate-variable-8.3.0_

trigger_es_snapshot_operate operate-decision-8.3.0_,operate-decision-requirements-8.3.0_,operate-metric-8.3.0_,operate-migration-steps-repository-1.1.0_,operate-web-session-1.1.0_,operate-process-8.3.0_,operate-user-1.2.0_


printf "\n\n\n\n"




#####################################################################################################################
# Tasklist backup steps
#####################################################################################################################


printf "\n\n ***** Indices for Tasklist ****** \n\n"

jq -r '.[] | select(.index|test("^tasklist.")) | .index' es-indices.json  > tasklist.txt


arr_tasklist=() 
while read line; do
    arr_tasklist+=("$line")
done < tasklist.txt

## Step 0 - create tasklist snapshot repo

curl --request PUT \
        --url "${tasklist_snapshot_repo_create_endpoint}" \
        --header 'Content-Type: application/json' \
        --data '{
        "type": "s3",
        "settings": {
          "bucket": "dk-c8"
        }
      }'


#### import-position
lookup_trigger_snapshot_tasklist tasklist-import-position "${arr_tasklist[@]}"
deleted_id=$?
printf "\n\n Deleted id - $deleted_id \n"
unset arr_tasklist[$deleted_id] 


#### process-instance
lookup_trigger_snapshot_tasklist tasklist-process-instance "${arr_tasklist[@]}"
deleted_id=$?
printf "\n\n Deleted id - $deleted_id \n"
unset arr_tasklist[$deleted_id] 


#### tasklist-task
lookup_trigger_snapshot_tasklist tasklist-task "${arr_tasklist[@]}"
deleted_id=$?
printf "\n\n Deleted id - $deleted_id \n"
unset arr_tasklist[$deleted_id] 

### task: archived - TODO

#### tasklist-draft-task-variable
lookup_trigger_snapshot_tasklist tasklist-draft-task-variable "${arr_tasklist[@]}"
deleted_id=$?
# printf "\n\n Deleted id - $deleted_id \n"
unset arr_tasklist[$deleted_id] 

#### tasklist-flownode-instance
lookup_trigger_snapshot_tasklist tasklist-flownode-instance "${arr_tasklist[@]}"
deleted_id=$?
# printf "\n\n Deleted id - $deleted_id \n"
unset arr_tasklist[$deleted_id] 


#### tasklist-task-variable
lookup_trigger_snapshot_tasklist tasklist-task-variable "${arr_tasklist[@]}"
deleted_id=$?
# printf "\n\n Deleted id - $deleted_id \n"
unset arr_tasklist[$deleted_id] 


#### tasklist-draft-task-variable
lookup_trigger_snapshot_tasklist tasklist-draft-task-variable "${arr_tasklist[@]}"
deleted_id=$?
# printf "\n\n Deleted id - $deleted_id \n"
unset arr_tasklist[$deleted_id] 

#### tasklist-form
lookup_trigger_snapshot_tasklist tasklist-form "${arr_tasklist[@]}"
deleted_id=$?
printf "\n\n Deleted id - $deleted_id \n"
unset arr_tasklist[$deleted_id] 


#### tasklist-metric
lookup_trigger_snapshot_tasklist tasklist-metric "${arr_tasklist[@]}"
deleted_id=$?
printf "\n\n Deleted id - $deleted_id \n"
unset arr_tasklist[$deleted_id] 

#### tasklist-migration-steps-repository
lookup_trigger_snapshot_tasklist tasklist-migration-steps-repository "${arr_tasklist[@]}"
deleted_id=$?
printf "\n\n Deleted id - $deleted_id \n"
unset arr_tasklist[$deleted_id] 


#### tasklist-migration-steps-repository
lookup_trigger_snapshot_tasklist tasklist-migration-steps-repository "${arr_tasklist[@]}"
deleted_id=$?
printf "\n\n Deleted id - $deleted_id \n"
unset arr_tasklist[$deleted_id] 


#### tasklist-process
lookup_trigger_snapshot_tasklist tasklist-process "${arr_tasklist[@]}"
deleted_id=$?
printf "\n\n Deleted id - $deleted_id \n"
unset arr_tasklist[$deleted_id] 

#### tasklist-web-session
lookup_trigger_snapshot_tasklist tasklist-web-session "${arr_tasklist[@]}"
deleted_id=$?
printf "\n\n Deleted id - $deleted_id \n"
unset arr_tasklist[$deleted_id] 

#### tasklist-user
lookup_trigger_snapshot_tasklist tasklist-user "${arr_tasklist[@]}"
deleted_id=$?
printf "\n\n Deleted id - $deleted_id \n"
unset arr_tasklist[$deleted_id] 



################################################################################
#### Finally ZeeBe ES backup                                          ##########
################################################################################

## Step Z.1 - create zeebe snapshot repo

curl --request PUT \
        --url "${zeebe_snapshot_repo_create_endpoint}" \
        --header 'Content-Type: application/json' \
        --data '{
        "type": "s3",
        "settings": {
          "bucket": "dk-c8"
        }
      }'

### Z.1 Pause Zeebe exporter

printf "\n ** Pause Zeebe exporter. \n"

curl --request POST \
        --url "${zeebe_pause_export_endpoint}" \
        --header 'Content-Type: application/json' \
        --data '{}'


printf "\n ** Export Zeebe ES \n"

### Z.2 Trigger Zeebe ES Snapshot
trigger_es_snapshot_zeebe zeebe-record*


### Z.3 Zeebe RocksDB backup

curl --request POST \
        --url "${zeebe_backup_rocksdb_endpoint}" \
        --header 'Content-Type: application/json' \
        --data '{
            "backupId": "'${BACKUP_ID}'",
      }'


### Z.4 Resume Zeebe exporter

printf "\n ** Resume Zeebe exporter. \n"

curl --request POST \
        --url "${zeebe_resume_export_endpoint}" \
        --header 'Content-Type: application/json' \
        --data '{}'