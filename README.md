# Insights Integration Test in Tekton for Konflux

This repository has a Tekton pipeline, and its tasks, made based on the way the tests are currently done with Clowder and Bonfire with the purpose of integrating them with Konflux.

For more information about how tests are currently handled, see this [repo](https://github.com/RedHatInsights/cicd-tools).

## How to use

### Prerequisites

* Access to Konflux. Join the wailist [here](https://console.redhat.com/preview/hac/application-pipeline) and ask for access in the [#konflux-users](https://redhat-internal.slack.com/archives/C04PZ7H0VA8) slack channel.
* Application in Konflux already created. You can follow the instructions in the Konflux [docs](https://redhat-appstudio.github.io/docs.appstudio.io/Documentation/main/getting-started/get-started/#creating-your-first-application). Access Konflux [here](https://console.redhat.com/preview/hac/application-pipeline).
> **IMPORTANT:** The name of the Konflux Component must be the same name of the `COMPONENT_NAME` parameter in the Integration Test Scenario below.
* Kustomize installed in your computer. Follow the instalations [intructions](https://kubectl.docs.kubernetes.io/installation/kustomize/).

### Add the Integration Test Scenario to your application

To add the Integration Test Scenario to Konflux, you need to follow these next steps:

1. Fork the tenants-config [repo](https://github.com/redhat-appstudio/tenants-config.git)
2. In case there is still not a directory for your tenant in the repo you just forked, you will need to create one under the directory `cluster/stone-prd-rh01/tenants/<your-workspace-name>-tenant`.
> **NOTE:** The Konflux workspace is where you are deploying your applications on Konflux. It can be found in the Konflux UI, on the top left corner of the Applications page, just next to the `WS` letters.
3. Create your Integration Test Scenario in that directory, name it `<your-konflux-application-name>-bonfire-tekton.yaml`. You will need to use the same values you are currently using in your `pr_check.sh`. Remove the lines of the ones that you want to keep the default value. Remove parameters which are not in use (remove both: name and value). Use the following template for that:
```yaml
apiVersion: appstudio.redhat.com/v1beta1
kind: IntegrationTestScenario
metadata:
  labels:
    test.appstudio.openshift.io/optional: "false" # Change to "true" if you don't need the test to be mandatory
  name: <name-of-your-konflux-application>-bonfire-tekton
  namespace: <your-workspace-name>-tenant
spec:
  application: <name-of-your-konflux-application>
  resolverRef:
    params:
    - name: url
      value: https://github.com/RedHatInsights/bonfire-tekton.git
    - name: revision
      value: main # Or whatever branch you want to test
    - name: pathInRepo
      value: pipelines/basic.yaml # This is the path to the pipeline
    resolver: git
  params:
    - name: APP_NAME
      value: # Name of app-sre "application" folder this component lives in.
    - name: COMPONENTS
      value: # Space-separated list of components to load.
    - name: COMPONENTS_W_RESOURCES
      value: # List of components to keep.
    - name: BONFIRE_COMPONENT_NAME
      value: # Name of app-sre "resourceTemplate" in deploy.yaml for this component. If it is the same as the name in Konflux, you don't need to fill this  
    - name: COMPONENT_NAME
      value: # Name of your component name in Konflux
    - name: IQE_PLUGINS
      value: # Name of the IQE plugin for this app.
    - name: IQE_MARKER_EXPRESSION
      value: # This is the value passed to pytest -m. Default is ""
    - name: IQE_FILTER_EXPRESSION
      value: # This is the value passed to pytest -k. Default is "" when no filter desired
    - name: IQE_REQUIREMENTS
      value: # "something,something_else" -- iqe requirements filter. Default is "" when no filter desired
    - name: IQE_REQUIREMENTS_PRIORITY
      value: # "something,something_else" -- iqe requirements priority filter. Default is "" when no filter desired
    - name: IQE_TEST_IMPORTANCE
      value: # "something,something_else" -- iqe test importance filter. Default is "" when no filter desired
    - name: IQE_CJI_TIMEOUT
      value: # Timeout value to pass to 'oc wait', should be slightly higher than expected test run time. Default is 30m
    - name: IQE_ENV
      value: # "something" -- value to set for ENV_FOR_DYNACONF. Default is "clowder_smoke"
    - name: IQE_SELENIUM
      value: # Whether to run IQE pod with a selenium container. Default is "false"
    - name: IQE_PARALLEL_ENABLED
      value: # Whether to run IQE in parallel mode. Default is "false"
    - name: IQE_PARALLEL_WORKER_COUNT
      value: # The number of parallel workers to use. Default is "".
    - name: IQE_RP_ARGS
      value: # Arguments to send to reportportal. Default is "".
    - name: IQE_IBUTSU_SOURCE
      value: # Ibutsu source for the current run. Default is "".

```
> **NOTE:** You can fork the pipeline from https://github.com/RedHatInsigths/bonfire-tekton in order to customize it. In case you do it, you will need to change the `url` field in the `IntegrationTestScenario`.
4. Add the following `kustomization.yaml` file in the same directory:
```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - <your-konflux-application-name>-bonfire-tekton.yaml
  - ../../../../lib/consoledot-test-pipeline
namespace: <your-workspace-name>-tenant
```
5. Run the `build-manifests.sh`. This is script is using [Kustomize](https://kustomize.io/) to generate the Integration Test Scenario and secrets you will need to run the pipeline in the cluster. Check that the `auto-generated` directory is updated with these files. 
6. Commit your directory and the `auto-generated` directory.
7. Create a PR from your fork, and ask for approval in the [#konflux-users](https://redhat-internal.slack.com/archives/C04PZ7H0VA8) Slack channel.

After the approval and merge of the PR, your integration test should be available in the "Integration tests" tab of your application in your Konflux workspace. Remember that to be able of running it, you will need to trigger a new build by making a change on your repository and creating a PR.

## Customizing the pipeline

If you need to add new tasks in between the ones already in the pipeline, remove or edit the ones already there, you will need to customize the pipeline itself. For that, the first step is to fork this repository.

After that, you can add all the tasks you want on the `tasks` directory and create a new pipeline on the `pipelines` directory. We are using Tekton, so for more information on how to create tasks or pipelines, follow their [documentation](https://tekton.dev/docs/). 

To use the pipeline, you can follow the same steps in the [How to use](./README.md#how-to-use) heading. Just make sure to change the references to the pipeline inside the `.spec.resolverRef` to yours.
