# deploy-devops
## Environment  
* 4 Ubuntu20.04 LTS VM  
  * VM1(iiidevops1, 140.92.4.3): GitLab ce-12.10.6 Server  
  * VM2(iiidevops2, 140.92.4.4): Rancher Server, NFS Server  
  * VM3(iiidevops3, 140.92.4.5): Kubernetes node(control plane + etcd + worker node)  
  * VM4(iiidevops4, 140.92.4.6): Kubernetes node(control plane + etcd + worker node)  

## Install docker
> * Install docker (All VMs)  
> <code>sudo bin/ubuntu20lts_install_docker.sh </code>  

## Deploy Gitlab on VM1  
> <code> sudo gitlab/create_gitlab.sh </code>  

## Setting gitlab  
> * set gitlab new password  
> ![alt text](https://github.com/iii-org/deploy-devops/blob/master/png/set-gitlab-new-password.png?raw=true)  

> * Generate root personal access tokens  
>   * User/Administrator/User seetings, gernerate root perionsal accesss token  
> ![alt text](https://github.com/iii-org/deploy-devops/blob/master/png/root-settings.png?raw=true)  
> ![alt text](https://github.com/iii-org/deploy-devops/blob/master/png/generate-root-persional-access-token.png?raw=true)
> * Admin/Settings/Network/Outbound reuests，enable allonw request to the local netowrk  service
> ![alt text](https://github.com/iii-org/deploy-devops/blob/master/png/allow-request-to-the-local-netowrk.png?raw=true)  

# install rancher on VM2 
> <code> ./bin/ubuntu20lts_install_rancher.sh  </code>  
> * set admin password
> ![alt text](https://github.com/iii-org/deploy-devops/blob/master/png/set-racnher-admin-password.png?raw=true)  
> * set rancher server url  

# Create a Kubernetes by rancher
> ## Add cluster
> * add cluster/ From existing nodes(Custom)  
>   * Cluster name:  Then
>   * Kubernetes Version: Then newest kubernetes version  
>   * Network provider: Calico  
>   * CNI Plugin MTU Override: 1440  
> ![alt text](https://github.com/iii-org/deploy-devops/blob/master/png/rancher-add-cluster.png?raw=true)  
>   * Node Options: Chose etcd, Control plane, worker
>   * Copy command to run on VM3, VM4  
> ![alt text](https://github.com/iii-org/deploy-devops/blob/master/png/rancher-cluster-node-option.png?raw=true)  

# Get Kubeconfig Files
> Put on kubeconfig to ~/.kube/config  

# Gitlab and Rancher pipline hook  
> ## Rancher  
>  Choose Global/ Cluster(iiidevops-k8s)/ Project(Default)  
> ![alt text](https://github.com/iii-org/deploy-devops/blob/master/png/rancher-choose-cluster-project.png?raw=true)  
> Choose Tools/Pipline, select Gitlab  
> ![alt text](https://github.com/iii-org/deploy-devops/blob/master/png/rancher-setting-hook.png?raw=true)  
> Get the "Redirect URI"  
> ## Gitlab  
> Use root account/ settings/ Applications
> ![alt text](https://github.com/iii-org/deploy-devops/blob/master/png/gitlab-root-setting.png?raw=true)  
> ![alt text](https://github.com/iii-org/deploy-devops/blob/master/png/gitlab-usersetting-application.png?raw=true)  
> Setting Applications  
> insert name, redirect url and chose all optional, and save application.
> ![alt text](https://github.com/iii-org/deploy-devops/blob/master/png/gitlab-setting-application.png?raw=true)  
> ![alt text](https://github.com/iii-org/deploy-devops/blob/master/png/gitlab-application-info.png?raw=true)  
> Take the "Application ID" and "Secret", go to rancher.  
> ![alt text](https://github.com/iii-org/deploy-devops/blob/master/png/rancher-setting-applicationsecret.png?raw=true)  
> Authorize  
> ![alt text](https://github.com/iii-org/deploy-devops/blob/master/png/gitlab-authorize.png?raw=true)  

# Prepare storage (Use NFS below)
> ## VM2 (NFS Server)  
> * Install NFS service  
> <code> sudo apt install nfs-kernel-server -y </code>  
> * Edit /etc/exports, add  
> <code>/iiidevopsNFS *(no_root_squash,rw,sync,no_subtree_check) </code>  

> * Create folder /iiidevopsNFS for NFS service  
> <code> sudo mkdir /iiidevopsNFS </code>  
> <code> sudo chmod 777 /iiidevopsNFS </code>  
> * Restart NFS service  
> <code> sudo systemctl restart nfs-kernel-server </code>  
> * Check NFS service  
> <code> sudo showmount -e localhost  </code>  
> * Create redmine-postgresql folder for redmine-postgresql  
> <code> sudo mkdir /iiidevopsNFS/redmine-postgresql </code>  
> <code> sudo chmod 777 /iiidevopsNFS/redmine-postgresql </code>  
> * Create devopsdb folder for System DB  
> <code> sudo mkdir /iiidevopsNFS/devopsdb </code>  
> <code> sudo chmod 777 /iiidevopsNFS/devopsdb </code>  

> ## VM3, VM4 (NFS Client, Kubernetes worker node)  
> * Install on VM2  
> <code>sudo apt install nfs-common </code>  
> * Check NFS Service  
> <code> showmount -e {NFS server IP} </code>

# Install kubectl  
> https://kubernetes.io/docs/tasks/tools/install-kubectl/  

# Deploy Redmine  
> * deploy redmine postgresql  
> <code> kubectl apply -f redmine/redmine-postgresql/ </code>  
> * deploy redmine  
> <code> kubectl apply -f redmine/redmine/ </code>  
> * redmine url  
> http://140.92.4.5:32748/

# Set Redmine
> * login by admin/ admin, and reset administrator password
> ![alt text](https://github.com/iii-org/deploy-devops/blob/master/png/reset-redmine-admin-password.png?raw=true)  
> * Enable REST API
>   * Administratoe/ Settings/ API/ Enable REST web service
> ![alt text](https://github.com/iii-org/deploy-devops/blob/master/png/enable-redmine-rest.png?raw=true)  
> * wiki set markdown  
>   * Administrator/ Setting/ Gereral/ Text formatting  
> ![alt text](https://github.com/iii-org/deploy-devops/blob/master/png/redmine-set-testformat-markdown.png?raw=true)  
> * Create issue status  
>   *  Administratoe/ Issues statuses  
> ![alt text](https://github.com/iii-org/deploy-devops/blob/master/png/redmine-set-issue-status.png?raw=true)  
> * Create Trackers  
>   *  Administratoe/ Trackers  
> ![alt text](https://github.com/iii-org/deploy-devops/blob/master/png/redmine-set-trackers.png?raw=true)  
> * Create roles
>   * Administrator/ Roles and permissions
> ![alt text](https://github.com/iii-org/deploy-devops/blob/master/png/redmine-create-roles.png?raw=true)  
> * Create priority
>   * Administrator/ Enumerations/ Issue priorities
> ![alt text](https://github.com/iii-org/deploy-devops/blob/master/png/redmine-create-priority.png?raw=true)  
