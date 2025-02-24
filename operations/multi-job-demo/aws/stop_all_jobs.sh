#!/bin/bash
# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0


stop_jobs_in_namespace () {
   namespace=$1
   job_status=$(nomad job status -token=$nomad_token -address=$address -namespace=$namespace -short)
   if [ "$job_status" != "No running jobs" ]; then
     running_jobs=$(nomad job status -token=$nomad_token -address=$address -namespace=$namespace -short | sed 1,1d | cut -d ' ' -f 1)
     echo "namespace is $namespace"
     echo $running_jobs
     for job in $running_jobs; do
       echo "will stop job $job"
       nomad job stop -token=$nomad_token -address=$address -namespace=$namespace $job
     done
   fi
}

nomad_token=${bootstrap_token}
address=${address}
stop_jobs_in_namespace default
stop_jobs_in_namespace dev
stop_jobs_in_namespace qa
