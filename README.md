# aks-observability-as-code-terraform
Explanation of the high-level design:
This configuration uses a remote backend that allows both developers and Azure Pipeline to use the same Terraform state to deploy resources. 
<br />
 <br />
Datadog-azure-integration provider is applied directly to the Kubernetes cluster. However, a datadog-agent is also applied to all nodes to gather node-specific metrics, therefore created two modules one is for aks Kubernetes, and the other one is for Kubernetes configuration. 
<br />
 <br />
Added a sample Nginx app through Helm. Helm is also used to deploy datadog-agent to each worker node as a daemonSet, so push-model is applied.
<br />
 <br />
For K8S SLI's, I picked several aspects to track as a metric. These are the resources managed by K8S CPU, memory, network, storage, uptime, restarts, states.
<br />
 <br />
 <br />
Below you can find these metrics:<br />
azure.compute_virtualmachinescalesets.data_disk_bandwidth_consumed_percentage<br />
kubernetes_state.pod.count<br />
kubernetes_state.node.memory_allocatable<br />
kubernetes_state.pdb.pods_healthy<br />
kubernetes.memory.usage<br />
kubernetes.memory.limit<br />
kubernetes_state.container.status_report.count.terminated<br />
kubernetes_state.container.terminated<br />
azure.containerservice_managedclusters.node_cpu_usage_percentage<br />
datadog.process.agent<br />
kubernetes_state.deployment.replicas_available<br />
datadog.cluster_agent.running<br />
kubernetes.containers.restarts<br />
<br />
 <br />
 <br />
 <br />
To pick Good SLIs picked for K8S. I focused on the reason K8S used in the first place. It's primarily used for high availability and scalability. Among all candidate metrics, 6 of them seemed crucial to me:
<br />
1. "Average running K8S pods": shows that k8s is running.<br />
2. "Remaining allocatable memory". This shows that k8s still has memory to operate.<br />
3. "Avg CPU Usage Percentage". Calculated as 13 on Idle if it's near to 90, it may say a lot about the k8s scalability.<br />
4. "Restarts" Restarts can be a good indicator of problems in Kubernetes. Due to the nature of Kubernetes, it's so easy to fall into an over-provisioning trap. Keeping this metric in front can say about the health even though the k8s is highly available and ok on other metrics.<br />
5. "Healthy pods" on 1st metric pods are running, but frequently, due to the nature of Kubernetes in case of failure, pods can continue running, but the service may not work.<br />
6. "Kubernetes Rest Api Response Latency" I wanted to add a latency metric so it may say a lot about the service's performance. Degraded performance can be explained with high delays, which often may start other errors due to timeouts.<br />
 <br />
I have some candidate SLOs in my mind to declare. i.e. 30% average CPU percentage across worker nodes can be a good start of the SLO. It's always essential to apply measure, validate, iterate and change or edit SLOs by gathering data from actual world usage. It's hard to simulate real-world use, so SLOs determined without an actual world usage is probably flawed. However, it's good to start with a line in the sand and iterate over it.<br />
 <br />
 <br />
For an enterprise-level IAC repository, I would prefer to use Terragrunt next time. I didn't choose to use it because there wasn't a prod and non-prod environment in the requirements. It lets you follow DRY principles in Terraform easily. For prod, dev, test environments, one may want to copy resources, and it's so easy to follow the fallacy of copying and repeat existing resources, which further complicates the code between prod and dev environments. Although it can be applied through different branches, it becomes hard to maintain after a while. The declarative nature of Terraform supports a single source of truth code to deploy infrastructure. Different but similar environments' default directory mechanism forces you to copy resources between environments, which violates DRY principles. Modules become bigger and bigger, and maintaining them becomes harder.<br />
 <br />
 <br />
I tried to keep inputs as low as possible. When inputs are increased in Terraform modules, it becomes hard to follow and use a working code. Here's what I experienced: Input descriptions are not so helpful, and in the cloud world, it's so easy to mess it up. The first example is when versions change code maintainer can change the field type too, so instead of boolean, the field can become an input file name. The second example is that descriptions are primarily like "base64 encoded version of access key". Is it the file's name, or is it the key itself, or is it the base64 encoded version of the key? So to overcome that, I followed this process. If a resource doesn't exist, create it. If the module input doesn't have to be determined by the user, ignore it for now. These can still be provided through environment variables, but they shouldn't be on the same level as mandatory ones. So a developer should be able to start directly by only applying required inputs. After a successful start, the developer should be able to customize other optional variables.<br />
 <br />
Example mandatory fields:<br />
Datadog api and app keys<br />
Azure Service Principal ID, Secret and tenant id<br />
 <br />
Optional good to have fields:<br />
Terraform Backend selection and storage account fields<br />
Cloud Region<br />
RBAC that controls Kubernetes<br />
 <br />
 <br />
 <br />
 <br />
Non-Automated parts: <br />
1.Creation of Azure Service Principal with proper rights to create this repo and retrieve its info to feed it to run this repo. <br />
Why didn't I automate it? : A developer should authenticate at least one time using her Azure credentials to create a service principal. This one time can directly be the service principal creation script that will trigger azure CLI browser authentication. The proper role I would automate could be too broad for the user of this repo.<br />
2.Creation of Service Connections on Azure Pipelines. <br />
Why didn't I automate it? : Not all subscription types support Azure pipeline build agents, so keeping Azure's platform decisions on track with the declared code is almost impossible. It needs to be updated so often. But it can be automated easily to get the subscription, and if the subscription type is allowed to create service connections, create them.<br />
3.Installation of Terraform<br />
4.Installation of Azure CLI  <br />
5. Buying service agents on Azure Pipelines. This process also can be automated, but the developer that is forking this repository may not be comfortable with the code that is spending her money, and it's dictated. It should be purchased via Azure. They should sell that for trust issues.<br />
 <br />
 <br />
Tests:<br />
This repo assumes if Terraform doesn't fail, it's successfully made what it should be made.<br />
 <br />
Potential Problems and How to solve them:<br />
Situation: Terraform provider versions have been changed, and deprecated code is failing. <br />
Solution: Use appropriate versions below.<br />
 <br />
Situation: Your service principal doesn't have the right roles and permissions to take proper actions with the code here.<br />
Solution: Add Contributor role to the subscription you're using and to your service principal<br />
 <br />
Situation: You forgot to declare a mandatory environment variable, or its value is wrong<br />
Solution: Check mandatory fields on the "How to run" part below and their types.<br />
<br />
 <br />
Situation: Your datadog integration already exists<br />
Solution: If a deployment fails in that case. Don't forget to remove all resources from datadog.<br />
 <br />
If an error occurs any time during your installation, create an issue and send me an email at ozgurozkan123@icloud.com, and I can help you.<br />
 <br />
 <br />
Azure Pipeline Stages Design: I separated init+plan and apply parts so one can run separate stage accordingly.<br />
 <br />
 <br />
 <br />
This repo successfully workes with the following provider versions:<br />
 <br />
hashicorp/local v2.1.0<br />
hashicorp/azurerm v2.42.0<br />
hashicorp/helm v2.1.1<br />
datadog/datadog v2.25.0<br />
hashicorp/kubernetes v2.1.0<br />
 <br />
I didn't declare it in code, but in a prod environment, they should be set to reduce the risk of significant dependency change, which requires you to take further action on your prod code.<br />
 <br />
Here are the resources created after a successful launch:<br />

![Diagram](http://reminis-pip-alb.s3.amazonaws.com/schema.jpg)

<br />
 <br />
￼<br />
 <br />
 <br />
TODO<br />
* Terragrunt Dev, Prod, Test, Staging environments<br />
 <br />
 <br />
 <br />
How to run:<br />
Install Azure CLI<br />
1. You need an Azure Account ( Your subscription shouldn't be a free trial. a Free trial doesn't support Azure Pipelines' parallel agents ). <br />
2. A Github account so you can easily fork this repo and deploy it on Azure Pipelines.<br />
 3. Create a new organization at Azure DevOps Organizations<br />
 4. Create a project <br />
     Install <br />
    https://marketplace.visualstudio.com/items?itemName=ms-devlabs.custom-terraform-tasks<br />
    and<br />
    https://marketplace.visualstudio.com/items?itemName=charleszipp.azure-pipelines-tasks-terraform<br />
    on your organization<br />
 5. Create a pipeline<br />
 6. Fork https://github.com/ozgurozkan123/aks-observability-as-code-terraform<br />
 7. Select repo<br />
 8. Give necessary permissions<br />
 9.Select Existing Azure Pipelines YAML File<br />
 10. On the main branch, select /azure_pipelines.yml file as path<br />
 11. You need to add variables<br />
    armClientSecret<br />
     armClientId<br />
    armSubscriptionId<br />
    armTenantId<br />
    datadogApiKey<br />
    datadogAppKey<br />
    serviceConnection<br />
   uniqueStorage<br />
   <br />
   <br />
 How to get them:<br />
    a)On terminal:<br />
      az login <br />
a.1)Keep your subscription id shown on terminal armSubscriptionId=YOURVALUEOF"id"<br />
az ad sp create-for-rbac -n "CHANGEHERETOUNIQUENAME" --role contributor<br />
     a.2) Keep the appId password and tenant for future reference and keep them safe<br />
  Set your variables on Azure pipeline<br />
  armTenantId=YOURVALUEOF"tenantId"<br />
  armClientId=YOURVALUEOF"appId"<br />
  armClientSecret=YOURVALUEOF"password"<br />
  <br />
b) On browser open datadog and create a new key https://app.datadoghq.com/account/settings#api<br />
  datadogApiKey=YOURVALUEOF"Key ID" https://app.datadoghq.com/account/settings#api<br />
datadogAppKey=YOURVALUEOF"KEY" https://app.datadoghq.com/access/application-keys<br />
 <br />
 Visit https://dev.azure.com/YOURORGANIZATION/YOURPROJECTNAME/_settings/adminservices or project settings new service connection<br />
Select Azure Resource Manager<br />
 Select Service Principal ( automatic)<br />
Scope: Subscription<br />
Write a Service connection name and keep it<br />
serviceConnection=YOURSERVICECONNECTION<br />
uniqueStorage=tfpollinatestorage<br />
 <br />
 Save and run<br />
if it gives an error, change uniqueStorage to another unique name and try again. Changing your storageName changes your state.<br />
 <br />
 Check datadog dashboard that is created.
 <br />

Tested with a new datadog account and new Azure Account(Pay-As-You-Go subscription). (New Azure Accounts may not be allowed to directly use azure pipelines. Create a storage account on dashboard to solve this issue)
