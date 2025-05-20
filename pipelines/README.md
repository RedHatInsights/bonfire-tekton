# Integration Test Pipelines

Follow the instructions [here](https://github.com/RedHatInsights/bonfire-tekton?tab=readme-ov-file#add-the-integration-test-scenario-to-your-application) for getting setup with one of the following integration test pipelines and then configure it to use one of the pipelines on this page.  

- [Basic](#basic)
- [Basic with no IQE](#basic-with-no-iqe)
- [Frontend Testing Pipeline](#frontend-testing-pipeline) 

## Basic

### Description

TODO: Write description


## Basic with no IQE

### Description

TODO: Write description


## Frontend Testing Pipeline

### Description

The frontend testing pipeline (fe_testing.yaml) allows app teams to create a custom task at the `.tekton` directory of an application's repository. [Here](https://github.com/RedHatInsights/insights-chrome/tree/master/.tekton/run-tests-tasks.yml) is an example of this custom task.

### Instructions

1. Follow the instructions here for setting up an integration test pipeline but use the following configuration for the FE testing pipeline: 

```
---
apiVersion: appstudio.redhat.com/v1beta1
kind: IntegrationTestScenario
metadata:
  labels:
    test.appstudio.openshift.io/optional: "true"
  name: <app name>-bonfire-tekton
  namespace: <workspace name> 
spec:
  application: <app name> 
  resolverRef:
    params:
      - name: url
        value: https://github.com/RedHatInsights/bonfire-tekton.git
      - name: revision
        value: main
      - name: pathInRepo
        value: pipelines/fe_testing.yaml
    resolver: git
  params:
    - name: PROJECT_URL
      value: <github project url> 
    - name: APP_NAME
      value: <app name> 
    - name: COMPONENTS
      value: <app name> 
    - name: BONFIRE_COMPONENT_NAME
      value: <app name> 
    - name: COMPONENT_NAME
      value: ""
    - name: DEPLOY_FRONTENDS
      value: "true"
```

2. Create the test task in your Github project within the `.tekton` directory:

```
apiVersion: tekton.dev/v1beta1
kind: Task
metadata:
  name: run-tests
spec:
  params:
    - name: EPHEMERAL_ENV_PROVIDER_SECRET
      type: string
      default: ephemeral-env-provider
      description: "Secret for connecting to ephemeral env provider cluster"
    - name: EPHEMERAL_ENV_URL
      type: string
      description: "Url for accessing the UI deployed in the ephemeral environment"
    - name: EPHEMERAL_ENV_PASSWORD
      type: string
      description: "Password for login to your ephemeral environment UI"
    - name: EPHEMERAL_ENV_USERNAME
      type: string
      description: "Username for login to your ephemeral environment UI"
  steps:
    - name: run-tests
      image: "quay.io/redhat-user-workloads/rh-platform-experien-tenant/cypress-e2e-image/cypress-e2e-image:af9f17cb332f8e4a7f2e629bccbeeb1451490566"
      env:
        - name: EE_HOSTNAME
          value: $(params.EPHEMERAL_ENV_URL)
        - name: EE_USERNAME
          value: $(params.EPHEMERAL_ENV_USERNAME)
        - name: EE_PASSWORD
          value: $(params.EPHEMERAL_ENV_PASSWORD)
      script: |
        #!/bin/bash
        set -ex
        
        echo "<-- write your tests here -->"
```
