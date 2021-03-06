# deploy-devops
## Installation environment and requriments

* Ubuntu 20.04 LTS virtual machine(VM) (The minimum resource configuration of a VM is 8 vCore, 16G RAM, 120G HD; however, for production environment, it should be 3 or more VMs with SSD driver)
* Before installation, you should decide on these configuration settings
  * IP of VM
  * Deploy mode:IP or DNS or nip.io or xip.io (nip.io and xip.io are only for test environment)
	- IP : External access IP of VM
    - DNS: Domain names of III DevOps, GitLab, Redmine, Harbor, Sonarqube.
  * GitLab root password
  * Harbor, Rancher, Redmine, Sonarqube admin password
  * III-devops first user (super user) 
    - account ('admin' and 'root' are not allowed)
    - E-Mail
    - password

* You can scale out the Kubernetes nodes (VM2, VM3, VM4, VM5...) and scale up the VM1 according to actual performance requirements.

* You should add firewall policy allow rules - From src(User) To dest(VM) TCP port 80/443/3443/30000~32767


# Step 1. Download deploy-devops and Install docker

> ```bash
> wget https://raw.githubusercontent.com/iii-org/deploy-devops/master/bin/iiidevops_install.pl;
> perl ./iiidevops_install.pl local
> ```
> * If everything is correct, you will see that all check items are OK shown below.
> 
> ```
> localadmin@iiidevops-71:~$ perl ./iiidevops_install.pl local
> :
> :
> -----Validation results-----
> Install docker 19.03.14 ..OK!
> Install kubectl v1.18 ..OK!
> Install helm v3.5 ..OK!
> ```

# Step 2. Generate configuration setting information file "env.pl"

> ```bash
> ~/deploy-devops/bin/generate_env.pl
> ````
> * After entering, please check whether the configuration setting information is correct.  You can also edit this env.pl configuration file data.
>
>   ``` vi ~/deploy-devops/env.pl```

# Step 3. Deploy NFS and Rancher

> ``` sudo ~/deploy-devops/bin/iiidevops_install_base.pl```
>
> After the deployment is complete, you should be able to see the URL information of these services as shown below.
>
> * Rancher - https://10.20.0.71:3443/

# Step 4. Set up Rancher from the web UI

> * Rancher - https://10.20.0.71:3443/
> * **Use the $rancher_admin_password entered in Step 2.(~/deploy-devops/env.pl) to set the admin password**
> ![alt text](https://github.com/iii-org/deploy-devops/blob/master/png/set-racnher-admin-password.png?raw=true)  
>   
> * set **Rancher Server URL**  

## Create a Kubernetes by Rancher
> * Add Cluster/ From existing nodes(Custom)  
>   * Cluster Name:  **iiidevops-k8s**
>   * Kubernetes Version: Then newest kubernetes version  Exp. **v.118.15-rancher1-1**
>   * Network provider: **Calico**  
>   * CNI Plugin MTU Override: **1440**  
>   ![alt text](https://github.com/iii-org/deploy-devops/blob/master/png/rancher-add-cluster.png?raw=true)  
>   * Click Next to  save the setting (It will take a while. If  you receive the error message "Failed while: Wait for Condition: InitialRolesPopulated: True", just click 'Next' again.)
>   * Node Options: Chose etcd, Control plane, worker
> ![alt text](https://github.com/iii-org/deploy-devops/blob/master/png/rancher-cluster-node-option.png?raw=true)  

## Copy the command to add-k8s.sh and build the K8s cluster
> * Copy the command to /iiidevopsNFS/deploy-config/add_k8s.sh 
>
>   ```vi /iiidevopsNFS/deploy-config/add_k8s.sh```
>
> * Execute the following command to build the K8s cluster.
>
>   ```sh /iiidevopsNFS/deploy-config/add_k8s.sh```
>
>   It should display as below.
>   ```bash
>   localadmin@iiidevops-71:~$ sh /iiidevopsNFS/deploy-config/add_k8s.sh
>   Unable to find image 'rancher/rancher-agent:v2.4.5' locally
>   v2.4.5: Pulling from rancher/rancher-agent
>   d7c3167c320d: Already exists
>   :
>   :
>   :
>   Digest: sha256:f263b6df0dccfafe5249618498287cae19673999face1a1555ac58f665974418
>   Status: Downloaded newer image for rancher/rancher-agent:v2.4.5
>   73f824ccd94f5e7b871bcd13f1a0023c6f63af0036cb9a73927f61461a75b3ae
>   ```
>
> * After executing this command, it takes about 5 to 10 minutes to build the cluster.  
> * Rancher Web UI will automatically refresh to use the new SSL certificate. You may need to login again. After the iiidevops-k8s cluster is activated, you can get the kubeconfig file.
>

## Get iiidevops-k8s Kubeconfig File
> ![alt text](https://github.com/iii-org/deploy-devops/blob/master/png/rancher-cluster-kubeconfig.png?raw=true)  
> Put on kubeconfig file to **~/.kube/config** and **/iiidevopsNFS/kube-config/config** and also keep it.
> ```bash
>  touch /iiidevopsNFS/kube-config/config
>  ln -s /iiidevopsNFS/kube-config/config ~/.kube/config
>  vi /iiidevopsNFS/kube-config/config
> ```
> After pasting the Kubeconfig File, you can use the following command to check if the configuration is working properly.
>
> > ```kubectl cluster-info```
>
> It should display as below.
>
> ```bash
> localadmin@iiidevops-71:~$ kubectl cluster-info
> Kubernetes master is running at https://10.20.0.71:3443/k8s/clusters/c-fg42q
> CoreDNS is running at https://10.20.0.71:3443/k8s/clusters/c-fg42q/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy
> 
> To further debug and diagnose cluster problems, use 'kubectl cluster-info dump'.
> ```

# Step 5. Deploy GitLab, Redmine, Harbor, Sonarqube on kubernetes cluster

> ```~/deploy-devops/bin/iiidevops_install_cpnt.pl```
>
>
> After the deployment is complete, you should be able to see the URL information of these services as shown below.
>
> * GitLab - http://10.20.0.71:32080/
> * Redmine - http://10.20.0.71:32748/
> * Harbor - http://10.20.0.71:32443/
> * Sonarqube - http://10.20.0.71:31910/

# Step 6. Set up GitLab from the web UI

> * GitLab - http://10.20.0.71:32080/
> * **Log in with the account root and password ($gitlab_root_passwd) you entered in step 2.(~/deploy-devops/env.pl)**
>

## Generate **root personal access tokens** 
> * User/Administrator/User seetings, generate the root personal access tokens and keep it.  
> ![alt text](https://github.com/iii-org/deploy-devops/blob/master/png/root-settings.png?raw=true)  
>
> * Access Tokens / Name : **root-pat** / Scopes : Check all / Create personal access token  
> ![alt text](https://github.com/iii-org/deploy-devops/blob/master/png/generate-root-persional-access-token.png?raw=true)
>
> * Keep Your New Personal Access Token 
>   ![alt text](https://github.com/iii-org/deploy-devops/blob/master/png/gitlab-rootpat.png?raw=true)  
>
> * Modify the **$gitlab_private_token** value in env.pl
>
>   ```~/deploy-devops/bin/generate_env.pl gitlab_private_token [Personal Access Token]```
>
>   It should display as below.
>   ```bash
>   localadmin@iiidevops-71:~$ ~/deploy-devops/bin/generate_env.pl gitlab_private_token 535wZnCJDTL5y22xYYzv
>   A4. Set GitLab Token OK!
> 
>   Q21. Do you want to generate env.pl based on the above information?(Y/n)
>   The original env.pl has been backed up as /home/localadmin/deploy-devops/bin/../env.pl.bak
>   -----
>   11c11
>   < $gitlab_private_token = '535wZnCJDTL5y22xYYzv'; # Get from GitLab Web
>   ---
>   > $gitlab_private_token = 'skip'; # Get from GitLab Web
>   -----
>   ```
>

## Set up Rancher pipeline and Gitlab hook
> * Choose Global/ Cluster(**iiidevops-k8s**)/ Project(Default)  
> ![alt text](https://github.com/iii-org/deploy-devops/blob/master/png/rancher-choose-cluster-project.png?raw=true)  
> * Choose Tools/Pipline, select **Gitlab**  
> ![alt text](https://github.com/iii-org/deploy-devops/blob/master/png/rancher-setting-hook.png?raw=true)  
> Get the "Redirect URI" and then open GitLab web UI
>

> Use root account/ settings/ Applications
> ![alt text](https://github.com/iii-org/deploy-devops/blob/master/png/gitlab-root-setting.png?raw=true)  
> ![alt text](https://github.com/iii-org/deploy-devops/blob/master/png/gitlab-usersetting-application.png?raw=true)  
> Setting Applications  
> insert Name : **iiidevops-k8s**, Redirect URI: [from Rancher] and chose all optional, and save application.
> ![alt text](https://github.com/iii-org/deploy-devops/blob/master/png/gitlab-setting-application.png?raw=true)  
> ![alt text](https://github.com/iii-org/deploy-devops/blob/master/png/gitlab-application-info.png?raw=true)  
> Take the "Application ID" and "Secret", go to rancher pipeline, insert application id, secret and private gitlab url. Exp. **10.20.0.71:32080** 
> ![alt text](https://github.com/iii-org/deploy-devops/blob/master/png/rancher-setting-applicationsecret.png?raw=true)  
> Authorize  
> ![alt text](https://github.com/iii-org/deploy-devops/blob/master/png/gitlab-authorize.png?raw=true)  
> Done  
> ![alt text](https://github.com/iii-org/deploy-devops/blob/master/png/rancher-hook-down.png?raw=true)  
>
> Switch back to GitLab web UI


## Enable Outbound requests from web hooks
> * Admin Area/Settings/Network/Outbound reuests, enable **allow request to the local network from web hooks and service** / Save changes
> ![alt text](https://github.com/iii-org/deploy-devops/blob/master/png/allow-request-to-the-local-netowrk.png?raw=true)  
>

# Step 7. Check Harbor Project(Option)

> * Harbor - https://10.20.0.71:32443/
> * **Log in with the account admin and password ($harbour_admin_password) you entered in step 2.(~/deploy-devops/env.pl)**
> 
> * Check Project - dockerhub (Access Level : **Public** , Type : **Proxy Cache**) was added.
> ![alt text](https://github.com/iii-org/deploy-devops/blob/master/png/harbor_dockerhub_project.png?raw=true)  
> * If the project dockerhub is not created, you can exectue the command to manually create it.   
> 
>   ```sudo ~/deploy-devops/harbor/create_harbor.pl create_dockerhub_proxy```
>

# Step 8. Deploy III DevOps

> ```~/deploy-devops/bin/iiidevops_install_core.pl```
>
> You should wait 3 to 5 minutes to complete the deployment and initial system setup. Then, you can access the URL as shown below.
>
> ```
> :
> :
> .
> 
> Add Secrets Credentials
> -----
> nexus : Create Secrets /home/localadmin/deploy-devops/devops-api/secrets/nexus-secret.json..OK!
> checkmarx : Create Secrets /home/localadmin/deploy-devops/devops-api/secrets/checkmarx-secret.json..OK!
> webinspect : Create Secrets /home/localadmin/deploy-devops/devops-api/secrets/webinspect-secret.json..OK!
> 
> Add Registry Credentials
> -----
> harbor-local : Create Registry /home/localadmin/deploy-devops/devops-api/secrets/harbor-local-registry.json..OK!
> 
> The deployment of III DevOps services has been completed. Please try to connect to the following URL.
> III DevOps URL - http://10.20.0.71:30775
>
> ```

## Go to Web UI to login 
> * III DevOps URL -  http://10.20.0.71:30775/
> ![alt text](https://github.com/iii-org/deploy-devops/blob/master/png/devops-ui.png?raw=true)  
>
> Use the **$admin_init_login** and **$admin_init_password** entered in Step 2.(~/deploy-devops/env.pl) to login to III DevOps

# Step 9. Scale-out K8s Node

> * Execute the following command on VM1 to make VM2, VM3.... join the K8s cluster.
>
>   ```~/deploy-devops/bin/add-k8s-node.pl [user@vm2_ip]```
>
>   It should display as below.
>   ```bash
>   localadmin@iiidevops-71:~$ ~/deploy-devops/bin/add-k8s-node.pl localadmin@10.20.0.72
>   :
>   :
>   :
>   -----Validation results-----
>   Docker          : OK!
>   Kubectl         : OK!
>   NFS Client      : OK!
>   Harbor Cert     : OK!
>   -----
>   NAME           STATUS   ROLES                      AGE   VERSION
>   iiidevops-71   Ready    controlplane,etcd,worker   23h   v1.18.12
>   ```
>   * After executing this command, it will take about 3 to 5 minutes for the node to join the cluster.

# Step 10. Auto update III DevOps project templates

> * III DevOps provides popular software development frameworks and database project templates - https://github.com/iiidevops-templates
> * Please get the personal token on github first (scopes : public_repo) - https://docs.github.com/en/github/authenticating-to-github/creating-a-personal-access-token
>
> * Create cron.txt on VM1 and set it to synchronize with github every 10 minutes during working hours
>
>   ```bash
>   localadmin@iiidevops-71:~$ vi cron.txt
>   ----
>   */10 7-20 * * * /home/localadmin/deploy-devops/bin/sync-prj-templ.pl my_github_id:3563cxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxf3ba4 >> /tmp/sync-prj-templ.log 2>&1
>   ----
>   localadmin@iiidevops-71:~$ crontab cron.txt
>   localadmin@iiidevops-71:~$ crontab -l
>   */10 7-20 * * * /home/localadmin/deploy-devops/bin/sync-prj-templ.pl my_github_id:3563cxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxf3ba4 >> /tmp/sync-prj-templ.log 2>&1
>   ```
> * You can see the synchronization log in /tmp/sync-prj-templ.log . It should display as below.
>
>   ```bash
>   localadmin@iiidevops-71:~$ tail /tmp/sync-prj-templ.log
>   ----
>   :
>   :
>   [18].   name:flask-postgres-todo (2021-03-11T08:18:11Z)
>           GitLab-> id:252 path:flask-postgres-todo created_at:2021-03-11T09:00:53.812Z
>   [19].   name:spring-maraidb-restapi (2021-03-11T08:13:26Z)
>           GitLab-> id:253 path:spring-maraidb-restapi created_at:2021-03-11T09:01:00.607Z
>   [20].   name:flask-webpage-with-men (2021-03-11T08:10:06Z)
>           GitLab-> id:254 path:flask-webpage-with-men created_at:2021-03-11T09:01:02.401Z
>   localadmin@iiidevops-71:~$
>   ```

