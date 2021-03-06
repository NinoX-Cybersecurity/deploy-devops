#!/usr/bin/perl
# Install iiidevops core script
#
use FindBin qw($Bin);
use MIME::Base64;
my $p_config = "$Bin/../env.pl";
if (!-e $p_config) {
	print("The configuration file [$p_config] does not exist!\n");
	exit;
}
require($p_config);

$prgname = substr($0, rindex($0,"/")+1);
$logfile = "$Bin/$prgname.log";
require("$Bin/../lib/common_lib.pl");
log_print("\n----------------------------------------\n");
log_print(`TZ='Asia/Taipei' date`);


# Check kubernetes status.
$cmd = "kubectl get pod | grep redmine | tail -1";
log_print("Check kubernetes status..\n");
$cmd_msg = `$cmd`;
log_print("-----\n$cmd_msg\n-----\n\n");
#$cmd_msg =~  s/\e\[[\d;]*[a-zA-Z]//g; # Remove ANSI color
if (index($cmd_msg, 'Running')<0) {
	log_print("The Kubernetes cluster is not working properly!\n");
	exit;
}

# Create Namespace on kubernetes cluster
$cmd = "kubectl apply -f $Bin/../kubernetes/namespaces/account.yaml";
log_print("Create Namespace on kubernetes cluster..\n");
$cmd_msg = `$cmd`;
log_print("-----\n$cmd_msg\n-----\n\n");
if (index($cmd_msg, 'namespace/account created')<0 && index($cmd_msg, 'namespace/account unchanged')<0) {
	log_print("Failed to create namespace on kubernetes cluster!\n");
	exit;
}
log_print("Create namespace on kubernetes cluster OK!\n");


# Check if Gitlab/Rancher/Harbor/Redmine services are running well
# Check GitLab service is working
$gitlab_domain_name = get_domain_name('gitlab');
$cmd = "curl -q -I http://$gitlab_domain_name/users/sign_in";
$chk_key = '200 OK';
$cmd_msg = `$cmd 2>&1`;
#HTTP/1.1 200 OK
if (index($cmd_msg, $chk_key)<0) {
	log_print("GitLab is not working!\n");
	log_print("-----\n$cmd_msg-----\n");
	exit;	
}
# Check token-key 
#curl --silent --location --request GET 'http://10.50.1.53/api/v4/users' \
#--header 'PRIVATE-TOKEN: 7ZWkyr8PYwLyCvncKHwP'
# OK -> ,"username":
# Error -> {"message":"
$cmd = "curl --silent --location --request GET 'http://$gitlab_domain_name/api/v4/users' --header 'PRIVATE-TOKEN: $gitlab_private_token'";
$chk_key = ',"username":';
$cmd_msg = `$cmd 2>&1`;
if (index($cmd_msg, $chk_key)<0) {
	log_print("GitLab private-token is not working!\n");
	log_print("-----\n$cmd_msg-----\n");
	exit;	
}
log_print("GitLab is working well!\n");

# Check Rancher service is working
$cmd = "nc -z -v $rancher_ip 3443";
$chk_key = 'succeeded!';
$cmd_msg = `$cmd 2>&1`;
# Connection to 10.20.0.71 3443 port [tcp/*] succeeded!
if (index($cmd_msg, $chk_key)<0) {
	log_print("Rancher is not working!\n");
	log_print("-----\n$cmd_msg-----\n");
	exit;	
}
log_print("Rancher is working well!\n");

# Check Harbor service is working
$harbor_domain_name = get_domain_name('harbor');
$cmd = "curl -k --location --request POST 'https://$harbor_domain_name/api/v2.0/registries'";
$chk_key = 'UNAUTHORIZED';
$cmd_msg = `$cmd 2>&1`;
#{"errors":[{"code":"UNAUTHORIZED","message":"UnAuthorized"}]}
if (index($cmd_msg, $chk_key)<0) {
	log_print("Harbor is not working!\n");
	log_print("-----\n$cmd_msg-----\n");
	exit;	
}
log_print("Harbor is working well!\n");

# Check Redmine service is working
$redmine_domain_name = get_domain_name('redmine');
$cmd = "curl -q -I http://$redmine_domain_name";
$chk_key = '200 OK';
$cmd_msg = `$cmd 2>&1`;
# HTTP/1.1 200 OK
if (index($cmd_msg, $chk_key)<0) {
	log_print("Redmine is not working!\n");
	log_print("-----\n$cmd_msg-----\n");
	exit;	
}
log_print("Redmine is working well!\n");

# Check Sonarqube service is working
$sonarqube_domain_name = get_domain_name('sonarqube');
$cmd = "curl -q -I http://$sonarqube_domain_name";
$chk_key = 'Content-Type: text/html;charset=utf-8';
$cmd_msg = `$cmd 2>&1`;
# Content-Type: text/html;charset=utf-8
if (index($cmd_msg, $chk_key)<0) {
	log_print("Sonarqube is not working!\n");
	log_print("-----\n$cmd_msg-----\n");
	exit;	
}
log_print("Sonarqube is working well!\n");

# Deploy DevOps DB (Postgresql) on kubernetes cluster
$yaml_path = "$Bin/../devops-db/";
$yaml_file = $yaml_path.'devopsdb-deployment.yaml';
$tmpl_file = $yaml_file.'.tmpl';
if (!-e $tmpl_file) {
	log_print("The template file [$tmpl_file] does not exist!\n");
	exit;
}
$template = `cat $tmpl_file`;
$template =~ s/{{db_passwd}}/$db_passwd/g;
$template =~ s/{{nfs_ip}}/$nfs_ip/g;
$template =~ s/{{nfs_dir}}/$nfs_dir/g;
#log_print("-----\n$template\n-----\n\n");
open(FH, '>', $yaml_file) or die $!;
print FH $template;
close(FH);
$cmd = "kubectl apply -f $yaml_path";
log_print("Deploy devops-db..\n");
$cmd_msg = `$cmd`;
#log_print("-----\n$cmd_msg\n-----\n\n");

# Check the database is ready!
$isChk=1;
while($isChk) {
	print('.');
	$cmd_msg = `nc -z -v $db_ip 31403 2>&1`;
	# Connection to 192.168.11.205 31403 port [tcp/*] succeeded!
	$isChk = index($cmd_msg, 'succeeded!')<0?1:0;
	sleep($isChk);
}
print("OK!\n");

# iiidevops_ver
$iiidevops_ver = ($iiidevops_ver eq '')?'1':$iiidevops_ver;

# Deploy DevOps API (Python Flask) on kubernetes cluster
$yaml_path = "$Bin/../devops-api/";
$yaml_file = $yaml_path.'devopsapi-deployment.yaml';
$tmpl_file = $yaml_file.'.tmpl';
if (!-e $tmpl_file) {
	log_print("The template file [$tmpl_file] does not exist!\n");
	exit;
}
$template = `cat $tmpl_file`;
$template =~ s/{{iiidevops_ver}}/$iiidevops_ver/g;
$template =~ s/{{db_passwd}}/$db_passwd/g;
$template =~ s/{{db_ip}}/$db_ip/g;
$template =~ s/{{jwt_secret_key}}/$jwt_secret_key/g;
$template =~ s/{{redmine_domain_name}}/$redmine_domain_name/g;
$template =~ s/{{redmine_admin_passwd}}/$redmine_admin_passwd/g;
$template =~ s/{{redmine_api_key}}/$redmine_api_key/g;
$template =~ s/{{gitlab_url}}/$gitlab_domain_name/g;
$template =~ s/{{gitlab_root_passwd}}/$gitlab_root_passwd/g;
$template =~ s/{{gitlab_private_token}}/$gitlab_private_token/g;
$template =~ s/{{rancher_ip}}/$rancher_ip/g;
$template =~ s/{{rancher_admin_password}}/$rancher_admin_password/g;
$template =~ s/{{harbor_ip}}/$harbor_ip/g;
$template =~ s/{{harbor_domain_name}}/$harbor_domain_name/g;
$template =~ s/{{harbor_admin_password}}/$harbor_admin_password/g;
$template =~ s/{{k8sctl_domain_name}}/$k8sctl_domain_name/g;
$template =~ s/{{ingress_domain_name}}/$ingress_domain_name/g;
$template =~ s/{{checkmarx_origin}}/$checkmarx_origin/g;
$template =~ s/{{checkmarx_username}}/$checkmarx_username/g;
$template =~ s/{{checkmarx_password}}/$checkmarx_password/g;
$template =~ s/{{checkmarx_secret}}/$checkmarx_secret/g;
$template =~ s/{{webinspect_base_url}}/$webinspect_base_url/g;
$template =~ s/{{sonarqube_domain_name}}/$sonarqube_domain_name/g;
$template =~ s/{{sonarqube_admin_token}}/$sonarqube_admin_token/g;
$template =~ s/{{admin_init_login}}/$admin_init_login/g;
$template =~ s/{{admin_init_email}}/$admin_init_email/g;
$template =~ s/{{admin_init_password}}/$admin_init_password/g;
$template =~ s/{{nfs_ip}}/$nfs_ip/g;
$template =~ s/{{nfs_dir}}/$nfs_dir/g;
#log_print("-----\n$template\n-----\n\n");
open(FH, '>', $yaml_file) or die $!;
print FH $template;
close(FH);
$cmd = "kubectl apply -f $yaml_path";
log_print("Deploy devops-api..\n");
$cmd_msg = `$cmd`;
log_print("-----\n$cmd_msg\n-----\n\n");


# Deploy DevOps UI (VueJS) on kubernetes cluster
$iiidevops_domain_name = get_domain_name('iiidevops');

$yaml_path = "$Bin/../devops-ui/";
$yaml_file = $yaml_path.'devopsui-deployment.yaml';
$tmpl_file = $yaml_file.'.tmpl';
if (!-e $tmpl_file) {
	log_print("The template file [$tmpl_file] does not exist!\n");
	exit;
}
$template = `cat $tmpl_file`;
$template =~ s/{{iiidevops_ver}}/$iiidevops_ver/g;
#log_print("-----\n$template\n-----\n\n");
open(FH, '>', $yaml_file) or die $!;
print FH $template;
close(FH);

$yaml_path = "$Bin/../devops-ui/";
$yaml_file = $yaml_path.'devopsui-ingress.yaml';
if ($deploy_mode ne '' && uc($deploy_mode) ne 'IP') {
	$tmpl_file = $yaml_file.'.tmpl';
	if (!-e $tmpl_file) {
		log_print("The template file [$tmpl_file] does not exist!\n");
		exit;
	}
	$template = `cat $tmpl_file`;
	$template =~ s/{{iiidevops_domain_name}}/$iiidevops_domain_name/g;
	#log_print("-----\n$template\n-----\n\n");
	open(FH, '>', $yaml_file) or die $!;
	print FH $template;
	close(FH);
}
else {
	$cmd = "rm -f $yaml_file";
	$cmd_msg = `$cmd 2>&1`;
	if ($cmd_msg ne '') {
		log_print("$cmd Error!\n$cmd_msg-----\n");
	}
}

$cmd = "kubectl apply -f $yaml_path";
log_print("Deploy devops-ui..\n");
$cmd_msg = `$cmd`;
log_print("-----\n$cmd_msg\n-----\n\n");

# Display Wait 5 min. message
log_print("It takes 3 to 5 minutes to deploy III-DevOps services. Please wait.. \n");

# check deploy status
$isChk=1;
while($isChk) {
	$isChk = 0;
	foreach $line (split(/\n/, `kubectl get pod`)) {
		$line =~ s/( )+/ /g;
		($l_name, $l_ready, $l_status, $l_restarts, $l_age) = split(/ /, $line);
		if ($l_name eq 'NAME') {next;}
		if ($l_status ne 'Running') {
			print("[$l_name][$l_status]\n");
			$isChk ++;
		}
	}
	sleep($isChk);
}

# check iiidevops-api ready
$cmd = "curl -s --max-time 5 --location --request POST '$iiidevops_api/user/login'";
#{ "message": {
#        "username": "Missing required parameter in the JSON body or the post body or the query string" }}
$isChk=1;
while($isChk) {
	print('.');
	$isChk = 0;
	$cmd_msg = `$cmd`;
	$isChk = (index($cmd_msg, 'username')<0)?3:0;
	sleep($isChk);
}
print("\n");

# Add secrets for Rancher all projects
system("$Bin/../devops-api/add_secrets.pl");

# Sync Project templates to GitLab
$sync_key = decode_base64(substr($sync_templ_key,10,63));
system("$Bin/../bin/sync-prj-templ.pl $sync_key");

log_print("\nThe deployment of III-DevOps services has been completed. Please try to connect to the following URL.\n");
log_print("III-DevOps - http://$iiidevops_domain_name\n\n");
