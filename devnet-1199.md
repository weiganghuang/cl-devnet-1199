# Using Ansible to Automate Environement Configuration, Application (NSO) Deployment, and Beyond  
## Hands On Guide

****
## Setup  
![](https://github.com/weiganghuang/cl-devnet-1199/blob/master/image/setup.png)  

The set up is composed of five VM's: Ansible controller (A), NSO(N), DNS master server (M), and two DNS targets (T1 and T2).  

### Role of each host  

* Ansbile controller (Host A):  
  * Ansible playbook host.

* Cisco NSO application VM (Host N):
  * Cisco NSO application host manages DNS master server M. 
  * Hosts M, T1, and T2 are also known to NSO.
  * DNS synchronization operation from M to T1 and T2 are initiated from NSO as the service action. 

* DNS master M:
  * DNS master managed by NSO. NSO end users can pick and choose the DNS configration portion to synchronize to targets.

* DNS targets T1 and T2:
  * DNS targets in the network. 

### Requirements

* Use Cisco NSO manage DNS servers, perform synchronize operations from master to targets.
* Install Cisco NSO and service packages, device inventory on host N. NSO host manages DNS hosts, M, T1, and T2.
* To meet security compliance, the communicataion between NSO to hosts it manages (M, T1 and T2) is limited to no-login, key based ssh.
* To meet security copliance, the transport among DNS hosts is limited to non-interactive, no-login, key based. 
* Users:
  * dvnso: owns and runs NSO
  * cl00254: device (DNS servers) 

### Ansible Playbook Design

* Inventory (hosts) with three groups:
  * nso
  * master
  * targets

* Roles:
  * se
     * tasks: pre-fetch ssh public key files
  * nso
     * tasks: NSO install and testing
  * device
     * tasks: sync script install, authorized keys
  * target
     * tasks: set authorized keys

### Lab Access

Lab access steps:  

* step1: RDP to Jump start server
* putty to your assigned ansible host. (H)

[Jump start server and VM Assignment](https://app.smartsheet.com/b/home)  

### Create Ansible playbook diretories

1. Create roles using ansible-galaxy. "ansible-galaxy init" creates directories roles skeleton directories.  
  * Sample output:    

  ```
[dvans@cl90 ~]$ mkdir ansibleproject 
[dvans@cl90 ~]$ cd ansibleproject
[dvans@cl90 ansibleproject]$ mkdir roles
[dvans@cl90 ansibleproject]$ cd role
[dvans@cl90 roles]$ ansible-galaxy init se
- se was created successfully
[dvans@cl90 roles]$ ansible-galaxy init ns
- nso was created successfully
[dvans@cl90 roles]$ ansible-galaxy init devivce  
- devivce was created successfully  
[dvans@cl90 roles]$ ansible-galaxy init target  
- target was created successfully  
[dvans@cl90 roles]$ ls  
devivce  nso  se  target
   ```

2.  Create group_vars directory
  * `[dvans@cl90 ansibleproject]$ mkdir group_vars`
  
3.  Create inventory file at `/home/dvans/home/ansibleproject`, name the file `hosts`. 
  * The contents of `hosts` file should contain the ip address of N, M, T1, and T2. 
  * Sample contents of `hosts`, make sure the ip address of NSO matches to [Jump start server and VM Assignment](https://app.smartsheet.com/b/home) 
  
   ```
[nso]
172.23.123.212
[master]
172.23.123.227
[target1]
172.23.123.228
[target2]
172.23.123.229
[targets:children]
target1
target2
[all:children]
nso
master
targets
   ```
4. Create tasks for role nso. List of tasks:
   * Copy images to NSO host.
   * Install NSO.
   * Install packages (ned, service package, and inventory packages)
   * Start NSO.
   * Load devices
   * Post check.
   
   All the above tasks are implemented to seperate playbooks.   
   
   * nso\_copy_images.yml, uses ansible copy and synchroize modules. 
   
     ```
     ---
     #roles/nso/task/nso_copy_images.yml

     - name: copy nso image
       copy:
         src: "{{ nso_binary }}"
         dest: "{{ nso_image_path }}"
     - name: copy ned
       copy:
         src: "{{ ned_file }}"
         dest: "{{ nso_image_path }}"

     - name: copy nso helper scripts
       synchronize:
         src: "{{ helper_script_dir}}"
         dest: "{{ansible_env.HOME}}/scripts"
     ```
    * nso install 





   
 




