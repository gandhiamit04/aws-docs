#!/bin/bash

accesskey=$1
secretkey=$2
sourceregion=$3
sourceregionsnapshotid=$4
destinationregion=$5

AWS_ACCESS_KEY_ID=$accesskey AWS_SECRET_ACCESS_KEY=$secretkey AWS_DEFAULT_REGION=$sourceregion aws ec2 --output json copy-snapshot --source-region=$sourceregion --source-snapshot-id=$sourceregionsnapshotid --destination=$destinationregion
