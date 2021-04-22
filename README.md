# aks-observability-as-code-terraform
Explanation of the high-level design:
This configuration uses a remote backend that allows both developers and Azure Pipelines to use the same Terraform state to deploy resources. 
 
Datadog-azure-integration provider is applied directly to the Kubernetes cluster. However, a datadog-agent is also applied to all nodes to gather node-specific metrics, therefore created two modules one is for aks Kubernetes, and the other one is for Kubernetes configuration. 
 
Added a sample Nginx app through Helm. Helm is also used to deploy datadog-agent to each worker node as a daemonSet, so push-model is applied.
 
For K8S SLI's, I picked several aspects to track as a metric. These are the resources managed by K8S CPU, memory, network, storage, uptime, restarts, states.
 
Below you can find these metrics:
azure.compute_virtualmachinescalesets.data_disk_bandwidth_consumed_percentage
kubernetes_state.pod.count
kubernetes_state.node.memory_allocatable
kubernetes_state.pdb.pods_healthy
kubernetes.memory.usage
kubernetes.memory.limit
kubernetes_state.container.status_report.count.terminated
kubernetes_state.container.terminated
azure.containerservice_managedclusters.node_cpu_usage_percentage
datadog.process.agent
kubernetes_state.deployment.replicas_available
datadog.cluster_agent.running
kubernetes.containers.restarts
 
 
 
To pick Good SLIs picked for K8S. I focused on the reason K8S used in the first place. It's primarily used for high availability and scalability. Among all candidate metrics, 6 of them seemed crucial to me:
1. "Average running K8S pods": shows that k8s is running.
2. "Remaining allocatable memory". This shows that k8s still has memory to operate.
 3. "Avg CPU Usage Percentage". Calculated as 13 on Idle if it's near to 90, it may say a lot about the k8s scalability.
 4. "Restarts" Restarts can be a good indicator of problems in Kubernetes. Due to the nature of Kubernetes, it's so easy to fall into an over-provisioning trap. Keeping this metric in front can say about the health even though the k8s is highly available and ok on other metrics.
 5. "Healthy pods" on 1st metric pods are running, but frequently, due to the nature of Kubernetes in case of failure, pods can continue running, but the service may not work.
 6. "Kubernetes Rest Api Response Latency" I wanted to add a latency metric so it may say a lot about the service's performance. Degraded performance can be explained with high delays, which often may start other errors due to timeouts.
 
I have some candidate SLOs in my mind to declare. i.e. 30% average CPU percentage across worker nodes can be a good start of the SLO. It's always essential to apply measure, validate, iterate and change or edit SLOs by gathering data from actual world usage. It's hard to simulate real-world use, so SLOs determined without an actual world usage is probably flawed. However, it's good to start with a line in the sand and iterate over it.
 
 
For an enterprise-level IAC repository, I would prefer to use Terragrunt next time. I didn't choose to use it because there wasn't a prod and non-prod environment in the requirements. It lets you follow DRY principles in Terraform easily. For prod, dev, test environments, one may want to copy resources, and it's so easy to follow the fallacy of copying and repeat existing resources, which further complicates the code between prod and dev environments. Although it can be applied through different branches, it becomes hard to maintain after a while. The declarative nature of Terraform supports a single source of truth code to deploy infrastructure. Different but similar environments' default directory mechanism forces you to copy resources between environments, which violates DRY principles. Modules become bigger and bigger, and maintaining them becomes harder.
 
 
I tried to keep inputs as low as possible. When inputs are increased in Terraform modules, it becomes hard to follow and use a working code. Here's what I experienced: Input descriptions are not so helpful, and in the cloud world, it's so easy to mess it up. The first example is when versions change code maintainer can change the field type too, so instead of boolean, the field can become an input file name. The second example is that descriptions are primarily like "base64 encoded version of access key". Is it the file's name, or is it the key itself, or is it the base64 encoded version of the key? So to overcome that, I followed this process. If a resource doesn't exist, create it. If the module input doesn't have to be determined by the user, ignore it for now. These can still be provided through environment variables, but they shouldn't be on the same level as mandatory ones. So a developer should be able to start directly by only applying required inputs. After a successful start, the developer should be able to customize other optional variables.
 
Example mandatory fields:
Datadog api and app keys
Azure Service Principal ID, Secret and tenant id
 
Optional good to have fields:
Terraform Backend selection and storage account fields
Cloud Region
RBAC that controls Kubernetes
 
 
 
 
Non-Automated parts: 
1.Creation of Azure Service Principal with proper rights to create this repo and retrieve its info to feed it to run this repo. 
Why didn't I automate it? : A developer should authenticate at least one time using her Azure credentials to create a service principal. This one time can directly be the service principal creation script that will trigger azure CLI browser authentication. The proper role I would automate could be too broad for the user of this repo.
2.Creation of Service Connections on Azure Pipelines. 
Why didn't I automate it? : Not all subscription types support Azure pipeline build agents, so keeping Azure's platform decisions on track with the declared code is almost impossible. It needs to be updated so often. But it can be automated easily to get the subscription, and if the subscription type is allowed to create service connections, create them.
3.Installation of Terraform
4.Installation of Azure CLI  
1. Buying service agents on Azure Pipelines. This process also can be automated, but the developer that is forking this repository may not be comfortable with the code that is spending her money, and it's dictated. It should be purchased via Azure. They should sell that for trust issues.
 
 
Tests:
This repo assumes if Terraform doesn't fail, it's successfully made what it should be made.
 
Potential Problems and How to solve them:
Situation: Terraform provider versions have been changed, and deprecated code is failing. 
Solution: Use appropriate versions below.
 
Situation: Your service principal doesn't have the right roles and permissions to take proper actions with the code here.
Solution: Add Contributor role to the subscription you're using and to your service principal
 
Situation: You forgot to declare a mandatory environment variable, or its value is wrong
Solution: Check mandatory fields on the "How to run" part below and their types.

 
Situation: Your datadog integration already exists
Solution: If a deployment fails in that case. Don't forget to remove all resources from datadog.
 
If an error occurs any time during your installation, create an issue and send me an email at ozgurozkan123@icloud.com, and I can help you.
 
 
Azure Pipeline Stages Design: I separated init+plan and apply parts so one can run separate stage accordingly.
 
 
 
This repo successfully workes with the following provider versions:
 
hashicorp/local v2.1.0
hashicorp/azurerm v2.42.0
hashicorp/helm v2.1.1
datadog/datadog v2.25.0
hashicorp/kubernetes v2.1.0
 
I didn't declare it in code, but in a prod environment, they should be set to reduce the risk of significant dependency change, which requires you to take further action on your prod code.
 
Here are the resources created after a successful launch:
![alt text](https://reminis-pip-alb.s3.amazonaws.com/schema.jpg)
 
￼
 
 
checklist and TODO
* Terragrunt Dev, Prod, Test, Staging environments
* Tests
* Documentation
* Write a Readme.md
* Correct dashboard metrics and agent metrics
* Determine SLIs for sample nginx
* Determine SLIs for sample kubernetes
* specify versions that the code work so it can continue working in the future
* Naming
* Design Document
* Modularity
* Azure Pipeline stages and artifacts 1
* Multiple terraform provider
* Terraform Subsequent Applies can't go green because of datadog azure provider problem https://github.com/DataDog/terraform-provider-datadog/issues/190
* Local and Azure Pipelines to use the same backend
 
 
 
How to run:
Install Azure CLI
1. You need an Azure Account ( Your subscription shouldn't be a free trial. a Free trial doesn't support Azure Pipelines' parallel agents ). 
2. A Github account so you can easily fork this repo and deploy it on Azure Pipelines.
 3. Create a new organization at Azure DevOps Organizations
 4. Create a project 
 Install 
https://marketplace.visualstudio.com/items?itemName=ms-devlabs.custom-terraform-tasks
and
https://marketplace.visualstudio.com/items?itemName=charleszipp.azure-pipelines-tasks-terraform
on your organization
 5. Create a pipeline
 6. Fork https://github.com/ozgurozkan123/aks-observability-as-code-terraform
 7. Select repo
 8. Give necessary permissions
 9.Select Existing Azure Pipelines YAML File
 10. On the main branch, select /azure_pipelines.yml file as path
 11. You need to add variables
 armClientSecret
  armClientId
 armSubscriptionId
 armTenantId
 datadogApiKey
 datadogAppKey
 serviceConnection
uniqueStorage
 
 
 How to get them:
    a)On terminal:
az login 
a.1)Keep your subscription id shown on terminal armSubscriptionId=YOURVALUEOF"id"
az ad sp create-for-rbac -n "CHANGEHERETOUNIQUENAME" --role contributor
     a.2) Keep the appId password and tenant for future reference and keep them safe
  Set your variables on Azure pipeline
  armTenantId=YOURVALUEOF"tenantId"
  armClientId=YOURVALUEOF"appId"
  armClientSecret=YOURVALUEOF"password"
  
b) On browser open datadog and create a new key https://app.datadoghq.com/account/settings#api
  datadogApiKey=YOURVALUEOF"Key ID" https://app.datadoghq.com/account/settings#api
datadogAppKey=YOURVALUEOF"KEY" https://app.datadoghq.com/access/application-keys
 
 Visit https://dev.azure.com/YOURORGANIZATION/YOURPROJECTNAME/_settings/adminservices or project settings new service connection
Select Azure Resource Manager
 Select Service Principal ( automatic)
Scope: Subscription
Write a Service connection name and keep it
serviceConnection=YOURSERVICECONNECTION
uniqueStorage=tfpollinatestorage
 
 Save and run
if it gives an error, change uniqueStorage to another unique name and try again. Changing your storageName changes your state.
 

