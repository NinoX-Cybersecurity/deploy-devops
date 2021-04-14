#!/usr/bin/perl
# Install iiidevops base applications script
#
use FindBin qw($Bin);
my $p_config = "$Bin/../env.pl";
if (!-e $p_config) {
	print("The configuration file [$p_config] does not exist!\n");
	exit;
}
require($p_config);

$prgname = substr($0, rindex($0,"/")+1);
$logfile = "$Bin/$prgname.log";
log_print("\n----------------------------------------\n");
log_print(`TZ='Asia/Taipei' date`);
$home = "$Bin/../../";

# Create Data Dir
$cmd = "sudo mkdir -p $data_dir";
$cmd_msg = `$cmd 2>&1`;
if ($cmd_msg ne '') {
	log_print("Create data directory [$data_dir] failed!\n$cmd_msg\n-----\n");
	exit;
}
log_print("Create data directory OK!\n");

# NFS
if ($first_ip eq $nfs_ip) {
	$cmd = "sudo $home/deploy-devops/bin/ubuntu20lts_install_nfsd.pl";
	log_print("\nInstall & Setting NFS service..");
	system($cmd);
	# Check NFS service is working
	$cmd = "showmount -e $nfs_ip";
	$chk_key = $nfs_dir;
	$cmd_msg = `$cmd 2>&1`;
	log_print("-----\n$cmd_msg-----\n");
	if (index($cmd_msg, $chk_key)<0) {
		log_print("NFS configuration failed!\n");
		exit;
	}
	log_print("NFS configuration OK!\n");
}
else {
	log_print("Skip NFS configuration!\n");
}

# Add insecure-registries
if ($harbor_ip ne '') {
	system("sudo $Bin/add-insecure-registries.pl $harbor_ip $harbor_domain_name");
}

# Gen K8s ssh key
if (-e "$nfs_dir/deploy-config/id_rsa") {
	$cmd = "mkdir -p ~rkeuser/.ssh/;cp -a $nfs_dir/deploy-config/id_rsa* ~rkeuser/.ssh/;chown -R rkeuser:rkeuser ~rkeuser/.ssh/";
}
else {
	$cmd = "sudo -u rkeuser ssh-keygen -t rsa -C '$admin_init_email' -f $nfs_dir/deploy-config/id_rsa;mkdir -p ~rkeuser/.ssh/;cp -a $nfs_dir/deploy-config/id_rsa* ~rkeuser/.ssh/;chown -R rkeuser:rkeuser ~rkeuser/.ssh/";
}
system($cmd);

# Copy ssh key to first_ip
$cmd = "ssh-copy-id -i $nfs_dir/deploy-config/id_rsa.pub rkeuser\@$first_ip";
system($cmd);
# Verify rkeuser permission for running docker 
$cmd = "ssh rkeuser\@$first_ip -C 'docker ps'";
$chk_key = 'CREATED';
$cmd_msg = `$cmd 2>&1`;
#CONTAINER ID        IMAGE               COMMAND             CREATED             STATUS              PORTS               NAMES
if (index($cmd_msg, $chk_key)<0) {
	log_print("Verify rkeuser permission for running docker failed!\n");
	exit;
}
log_print("Verify rkeuser permission for running docker OK!\n");

# Install K8s
system("$Bin/../kubernetes/update-k8s-cluster.pl Initial $first_ip");
system("sudo -u rkeuser rke up --config $nfs_dir/deploy-config/cluster.yml");

$cmd = "cp -a $nfs_dir/deploy-config/kube_config_cluster.yml $nfs_dir/kube-config/config; ln -f -s $nfs_dir/kube-config/config ~rkeuser/.kube/config";
$cmd_msg = `$cmd 2>&1`;
if ($cmd_msg ne '') {
	log_print("Copy kubeconf failed!..\n$cmd_msg\n");
	exit;
}

# Verify kubeconf
$cmd = 'sudo -u rkeuser kubectl get node 2>&1';
#NAME         STATUS   ROLES                      AGE   VERSION
#10.20.0.37   Ready    controlplane,etcd,worker   49m   v1.18.17
$chk_key = 'Ready';
$isChk=1;
$count=0;
$wait_sec=600;
while($isChk && $count<$wait_sec) {
	#log_print('.');
	$cmd_msg = `$cmd 2>&1`;
	log_print($cmd_msg);
	$isChk = (index($cmd_msg, $chk_key)<0)?3:0;
	$count = $count + $isChk;
	sleep($isChk);
}
log_print("\n");
if ($isChk) {
	log_print("Failed to deploy K8s!\n");
	log_print("-----\n$cmd_msg-----\n");
	exit;
}
log_print("Successfully deployed K8s!\n");

# Rancher
$cmd = "$home/deploy-devops/rancher/install_rancher.pl";
log_print("\nDeploy Rancher..");
system($cmd);
# Check Rancher service is working
$cmd = "nc -z -v $rancher_ip 31443 2>&1";
$chk_key = 'succeeded!';
$cmd_msg = `$cmd 2>&1`;
if (index($cmd_msg, $chk_key)<0) {
	log_print("Failed to deploy Rancher!\n");
	log_print("-----\n$cmd_msg-----\n");
	exit;	
}
log_print("Successfully deployed Rancher!\n");

log_print("\nplease Read https://github.com/iii-org/deploy-devops/blob/master/README.md Step 4. to continue.\n\n");

exit;

sub log_print {
	my ($p_msg) = @_;

    print "$p_msg";
	
	open(FH, '>>', $logfile) or die $!;
	print FH $p_msg;
	close(FH);	

    return;
}