# Pipelines

This repository contains various Tekton pipelines to serve different purposes.

## Basic Pipeline With IQE

### Description

TODO: Description


## Basic Without IQE

### Description

TODO: Description


## Frontend Testing 

### Description

The purpose of the [fe_testing.yaml](github.com/RedHatInsights/bonfire-tekton/pipelines/fe-testing.yaml) pipeline is to allow frontend applications to test their code using tools such as Cypress. This pipeline references a task (test-runs-task.yaml) in each repositories `.tekton` directory. this allows users to customize how they wish to test their apps. 

### Instructions 

1. Create a `test-runs-task.yaml` file within the `.tekton` directory of the frontend repo you wish to test. 
   
2. 
