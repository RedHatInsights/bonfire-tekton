# Insights Integration Test in Tekton for RHTAP

This repository has a Tekton pipeline, and its tasks, made based on the way the tests are currently done with Clowder and Bonfire with the purpose of integrating them with RHTAP.

For more information about how tests are currently handled, see this [repo](https://github.com/RedHatInsights/cicd-tools).

## How to use

### Prerequisites

* Access to RHTAP. Join the wailist [here](https://console.redhat.com/preview/hac/application-pipeline) and ask for access in the [#rhtap-users](https://redhat-internal.slack.com/archives/C04PZ7H0VA8) slack channel.
* Application in RHTAP already created. You can follow the instructions in the RHTAP [docs](https://redhat-appstudio.github.io/docs.appstudio.io/Documentation/main/getting-started/get-started/#creating-your-first-application).
> **IMPORTANT:** The name of the RHTAP Component must be the same name of the `COMPONENT_NAME` parameter in the Integration Test Scenario below.
* Access to RHTAP using the CLI. Please follow these [instructions](https://docs.google.com/document/d/1hFvQDH1H6MGNqTGfcZpyl2h8OIaynP8sokZohCS0Su0/edit#heading=h.olhho0rpp8t5).

### Create Integration Test Scenario

Currently, there is no option to add parameters to an integration test from the UI. So you will need to create an IntegrationTestScenario CR in the cluster. The YAML will have this structure:

```yaml
apiVersion: appstudio.redhat.com/v1beta1
kind: IntegrationTestScenario
metadata:
  labels:
    test.appstudio.openshift.io/optional: "false" # Change to "true" if you don't need the test to be mandatory
  name: tekton-insights 
  namespace: <your-namespace>
spec:
  application: <name-of-your-rhtap-application>
  resolverRef:
    params:
    - name: url
      value: https://github.com/gbenhaim/tekton-insights.git # Temporary on gbenhaim's org. Also, you can fork it and reference yours here.
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
    - name: COMPONENT_NAME
      value: # Name of app-sre "resourceTemplate" in deploy.yaml for this component.
    - name: IQE_PLUGINS
      value: # Name of the IQE plugin for this app.
    - name: IQE_MARKER_EXPRESSION
      value: # This is the value passed to pytest -m. Default is ""
    - name: IQE_FILTER_EXPRESSION
      value: # This is the value passed to pytest -k. Default is test_plugin_accessible
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
```

> **NOTE:** You can fork the pipeline from https://github.com/gbenhaim/tekton-insights in order to customize it. In case you do it, you will need to change the `url` field in the `IntegrationTestScenario`.

### Add the Integration Test Scenario to your application

To add the Integration Test Scenario to RHTAP, you need to follow these next steps:

1. Fork the tenants-config [repo](https://github.com/redhat-appstudio/tenants-config.git)
2. In case there is still not a directory for your tenant you will need to create one under the directory `cluster/<cluster-of-your-tenant>/tenants/<your-workspace-name>-tenant`.
3. Create your Integration Test Scenario in that directory and add the following `kustomization.yaml` file:
```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - <your-test-integration-scenario-filename>.yaml
  - ../../../../lib/consoledot-test-pipeline
namespace: <your-workspace-name>-tenant
```
4. Run the `build-manifests.sh`.
5. Commit your directory and the `auto-generated` directory.
6. Create a PR and ask for approval in the [#rhtap-users](https://redhat-internal.slack.com/archives/C04PZ7H0VA8) Slack channel.

After the approval and merge of the PR, your integration test should be available in your RHTAP workspace. Remember that to be able of running it, you will need to trigger a new build by making a change on your repository and creating a PR.