# kubernetes_multicluster

## Requirements

The Kubernetes Multicluster deploys as code in a GitHub-hosted agent (runner).
If you want to create a local environment, you must use a linux based operational system and install the following requirements prior running the tool: 

* [Terraform 1.X](https://www.terraform.io/downloads)
* [Ansible](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html)
* [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
* [Kubectl](https://kubernetes.io/docs/tasks/tools/#kubectl)
* [Linkerd](https://linkerd.io/2.11/getting-started/#step-1-install-the-cli)
* [Step-cli](https://smallstep.com/docs/step-cli/installation)

### Credentias Required
The tool is able to provision the Kubernetes Multicluster infrastructure in 2 cloud providers, [Azure](https://azure.microsoft.com/) and [AWS](https://aws.amazon.com/).

For **Azure** deployment:
  1. Follow [this guide](https://docs.microsoft.com/en-us/cli/azure/authenticate-azure-cli#sign-in-with-a-service-principal) to create a service princial with admin access to your azure subscription. Make sure you save your **tenant ID**, **subscription ID**, the service principal **application ID** (app_id or client_id) and **application secret value** (app_secret or client_secret);
  2. Follow [this guide](https://www.terraform.io/language/settings/backends/azurerm) to create a Terraform state backend on an Azure storage account;
  3. Replace IDs and credentials value on Terraform [main.tf](./terraform/main.tf) file. If you are using GitHub Actions with a GitHub-hosted agent, create GitHub Secret **APP_SECRET** and save the application secret value on it.


For **AWS** deployment:
  1.  Follow [this guide](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_access-keys.html) to create an AWS access key. Make sure you save your Access Key ID and Secret Access Key;
  2. Replace IDs and credentials value on Terraform [main.tf](./terraform/main.tf) file. If you are using GitHub Actions with a GitHub-hosted agent, create GitHub Secret **AWS_ACCESS_KEY** and **AWS_SECRET_KEY**, and save the Access Key ID and Secret Access Key on it.


## Running the Tool
---------------
The tool is able to execute localy or in a GitHub-hosted agent using the workflow [create_multicluster.yml](./.github/workflows/create_multicluster.yml).

### Local Execution
----
Change directory to create all resources. Starting from the kubernetes_multicluster root diretory, execute:
    
    cd terraform

And:

    terraform init
    terraform plan
    terraform apply

After all clusters has been created, configure kubeconfig file name for all clusters:

    CONFIG_NAMES=$(cat inventory | grep clusters_name)
    CONFIG_NAMES=${CONFIG_NAMES##*=}
    CONFIG_NAMES=$(echo "$CONFIG_NAMES" | sed -r 's/"//g')
    CONFIG_NAMES=$(echo "$CONFIG_NAMES" | sed -r 's/,/.yml:\/home\/runner\/work\/kubernetes_multicluster\/kubernetes_multicluster\/terraform\//g')
    PWD=$(pwd)
    CONFIG_NAMES=$(echo "$PWD/$CONFIG_NAMES")
    export KUBECONFIG="${CONFIG_NAMES}.yml"



Execute ansible playbook [install_multicluster_playbook.yml](./terraform/ansible/install_multicluster_playbook.yml) to configure the Multicluster: 


    ansible-playbook ./ansible/install_multicluster_playbook.yml -i inventory -e "kubeconfig=$KUBECONFIG"

To deploy all your 5G applications, save its deployments file in [applications](./terraform/ansible/applications/) directory and execute ansible playbook [deploy_apps_playbook.yml](./terraform/ansible/deploy_apps_playbook.yml):

    ansible-playbook ./ansible/deploy_apps_playbook.yml -i inventory -e "kubeconfig=$KUBECONFIG"

If you want to delete all cloud resourcers and destroy the environment:

    terraform destroy

### GitHub-hosted Agent (runner)
-----

On [GitHub Actions page](https://github.com/JoltLeo/kubernetes_multicluster/actions), execute workflow [Create Multicluster](https://github.com/JoltLeo/kubernetes_multicluster/actions/workflows/create_multicluster.yml).

To deploy all your 5G applications, save its deployments file in [applications](./terraform/ansible/applications/) directory and execute workflow [Deploy Applications](https://github.com/JoltLeo/kubernetes_multicluster/actions/workflows/deploy_apps.yml) to deploy all 5G applications on all Kubernetes clusters.

If you want to delete all cloud resourcers and destroy the environment, execute workflow [Destroy Multicluster](https://github.com/JoltLeo/kubernetes_multicluster/actions/workflows/destroy_all.yml).