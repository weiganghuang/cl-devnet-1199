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
  * DNS targets in the network

### Requirements

* Use Cisco NSO manage DNS servers, invoke an action of synchronize operations from master to targets.
* Install Cisco NSO and service packages, device inventory on host N. NSO host manages DNS hosts, M, T1, and T2.
* To meet security compliance, the communication between NSO to hosts it manages (M, T1 and T2) is limited to no-login, key based ssh.
* To meet security compliance, the transport among DNS hosts is limited to non-interactive, no-login, key based. 
* Users:
  * dvnso: owns and runs NSO
  * cl00254: device (DNS servers) 
  * cl94644: performs synchronization from master to targets

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

* RDP to Jump start server
* putty to your assigned ansible host. (H)

[Jump start server and VM Assignment](https://app.smartsheet.com/b/publish?EQBCT=794506e345394e7daa069aeb2c931a1c)  

### Create Ansible playbook diretories

1. A set of directories and files are pre-defined on each ansible controller vm. 

   * check home directory, expect to see ansibleproject, hosts, and roles are created. 
   
   * Sample output:

     ```
     [dvans@cl-lab-212 ~]$ ls
     ansibleproject      ncs-4.5.0.1-unix- bind-2.0.0.tar.gz      solution
     dns-manager.tar.gz nso-4.5.0.1.linux.x86_64.installer.bin	inventory.tar.gz    scripts
     [dvans@cl-lab-212 ~]$ ls ansibleproject/
     group_vars hosts  roles  vars
     ```
   
1. Create roles using ansible-galaxy. `ansible-galaxy init` creates directories roles skeleton directories.  
   * Sample output:    

     ```
     [dvans@cl90 ~]$ cd ansibleproject/roles
     [dvans@cl90 roles]$ ansible-galaxy init se
     - se was created successfully
     [dvans@cl90 roles]$ ansible-galaxy init nso
     - nso was created successfully
     [dvans@cl90 roles]$ ansible-galaxy init device  
     - device was created successfully  
     [dvans@cl90 roles]$ ansible-galaxy init target  
     - target was created successfully  
     [dvans@cl90 roles]$ ls  
     device  nso  se  target
     ```
  
3.  View inventory file `/home/dvans/home/ansibleproject/hosts`.  
    The contents of hosts file should contain the ip address of N, M, T1, and T2.   
    Sample contents of hosts, make sure the ip address of NSO matches to [Jump start server and VM Assignment](https://app.smartsheet.com/b/publish?EQBCT=794506e345394e7daa069aeb2c931a1c) 
    
    [hosts](https://github.com/weiganghuang/cl-devnet-1199/blob/master/ansibleproject/hosts)
  
4. Create tasks for role "nso". List of tasks:
   * Copy images to NSO host.
   * Install NSO.
   * Install packages (ned, service package, and inventory packages)
   * Start NSO.
   * Load devices
   * Post check.
   
   All the above nso tasks are implemented with seperate playbook yml files. 
   
   **Note, the nso task yml files should be at directory `/home/dvans/ansibleproject/roles/nso/tasks/`.**   
   
   * `nso_copy_images.yml` This yml file uses ansible copy and synchroize modules. Varialbes such as nso\_binary, nso\_image\_path, and etc, are defined under `group_vars/nso`, which will be covered in later steps.   
   
     Sample file: [nso\_copy\_images.yml](https://github.com/weiganghuang/cl-devnet-1199/blob/master/ansibleproject/roles/nso/tasks/nso\_copy\_images.yml)
   
   * `nso_install.yml` This yml file defines play to install NSO and set nso environment.  
     Sample file: [nso_install.yml](https://github.com/weiganghuang/cl-devnet-1199/blob/master/ansibleproject/roles/nso/tasks/nso_install.yml)
    
   * `nso_install_packages.yml`, this yml file is to install unix-bind ned and  dns manager service package, and inventory package. In this play book, we use blockinfile module.  
      
     Sample file: [nso\_install\_packages.yml](https://github.com/weiganghuang/cl-devnet-1199/blob/master/ansibleproject/roles/nso/tasks/nso_install_packages.yml)
    
            
   * `nso_start.yml` defines a play to start NSO application.  

     Sample file: [nso_start.yml](https://github.com/weiganghuang/cl-devnet-1199/blob/master/ansibleproject/roles/nso/tasks/nso_start.yml)
      
      
   * `nso_add_devices.yml`. This yml file creates devices and service inventory instances for NSO. We use xml based config files to load merge to NSO's cdb. In this play book, we use templates. The template files, `device.j2` and `inventory.j2` are covered at later steps.  
    
     Sample file: [nso\_add\_devices.yml](https://github.com/weiganghuang/cl-devnet-1199/blob/master/ansibleproject/roles/nso/tasks/nso_add_devices.yml)
    
      
   * `nso_postcheck.yml`.  In this play book, we pick two actions to make sure the installation is sucessful, rsa keys are exchanged among N,M,T1,T2 to allow required secure communication, and sudoers are set properly.    

     Sample file: [nso_postcheck.yml](https://github.com/weiganghuang/cl-devnet-1199/blob/master/ansibleproject/roles/nso/tasks/nso_postcheck.yml)
     
   * The above 7 tasks are putting together and invoked from playbook `main.yml`.    
    
     Sample file: [main.yml](https://github.com/weiganghuang/cl-devnet-1199/blob/master/ansibleproject/roles/nso/tasks/main.yml)

5. Create template files for role "nso"
   
   Templates are used to create device instances and inventory instances in NSO in `nso_add_devices.yml'.  
   
   **Note, below two template files, `device.j2` and `inventory.j2` should be created at `/home/dvans/ansibleproject/roles/nso/templates/` directory.**
   
      
    * `device.j2`, the xml format device config file with two variables. 
        
      Sample file: [device.j2](https://github.com/weiganghuang/cl-devnet-1199/blob/master/ansibleproject/roles/nso/templates/device.j2) 
    
    * `inventory.j2`, the xml format inventory template file to create inventory model in NSO's cdb. There is no veriable in this template.  

      Sample file: [inventory.j2](https://github.com/weiganghuang/cl-devnet-1199/blob/master/ansibleproject/roles/nso/templates/inventory.j2) 
       
5. Create tasks for role "device". As mentioned in requirements, dns master M is managed by NSO. To meet the security compliance, the communication between NSO host N and the device M is limited to non-login, non-interactive, key based ssh. The tasks for role "device" is to add rsa public key of N to M, for NSO's southbound user, and limit sudoers to perform the allowed operations.  
  
    The synchronization from master to targets is performed by a syncdns package from DNS master. Thus,we also need to define a task to install syncdns package onto dns master M.  
     
    For this play, we define tasks in `/home/dvans/ansibleproject/roles/device/tasks/main.yml`.  

   Sample file: [main.yml](https://github.com/weiganghuang/cl-devnet-1199/blob/master/ansibleproject/roles/device/tasks/main.yml)
   
   
6. Create tasks for role "target". DNS master synchronize end user chosed directory to targets. To comply with the company's security requirements, the communication between master (M) to targets (T1,T2) is no-login, non-interaction, key based ssh. The tasks defined for this role is to add rsa public key to T1 and T2 for peer user, and limit sudoers to perform the allowed operations. Similar to that for "device", we define tasks in `/home/dvans/ansibleproject/roles/target/tasks/main.yml`. 
  
   Sample file: [main.yml](https://github.com/weiganghuang/cl-devnet-1199/blob/master/ansibleproject/roles/target/tasks/main.yml)
   
11. Create tasks for role "se". We add this role to ease the key exchange for nso host N, dns master M and dns targets T1/T2. The task of this role is to pre fetch public rsa key files from M, T1 and T2 to ansible controller A. The fetched publick key files are then distributed to proper user's authorized keys files. We define the task in `/home/dvans/ansibleproject/roles/se/tasks/main.yml`.  
    
    Sample file: [main.yml](https://github.com/weiganghuang/cl-devnet-1199/blob/master/ansibleproject/roles/se/tasks/main.yml)

7. Prepare image/helper scripts files for roles "nso" and "device". The required images and helper scripts files are created under `files` directory for each role. In this workshop, we only need to put files to roles "nso" and "device". 

    The required files are made available at `/home/dvans` for your ansible host, H.

    * Copy nso binary, ned, service package, and inventory package to nso/files. From your ansible controller, copy required files from `/home/dvans/` to `/home/dvans/ansibleproject/roles/nso/files`.  
      
      Sample output:  
      
      ```
      [dvans@cl90 ~]$ cd ~/ansibleproject/roles/nso/files
      [dvans@cl90 files]$ cp ~/nso-4.5.0.1.linux.x86_64.installer.bin .
      [dvans@cl90 files]$ cp ~/ncs-4.5.0.1-unix-bind-2.0.0.tar.gz .
      [dvans@cl90 files]$ cp ~/dns-manager.tar.gz .
      [dvans@cl90 files]$ cp ~/inventory.tar.gz .
      [dvans@cl90 files]$ cp -r ~/scripts/ .
      ```
        
    * Copy syncdns package to `device/files`. From your ansible controller, copy the required file from `/home/dvans/` to `/home/dvans/ansibleproject/roles/device/files/`.   
  
      Sample output: 
     
      ```shell
      [dvans@cl90 ~]$ cd ~/ansibleproject/roles/device/files
      [dvans@cl90 files]$ cp ~/syncdns.tar.gz .
      ```
8. Create variables.
     * Create group variables. As shown at the previous steps, the play books have used several variables. Role based variables are defined at `group_vars` directory.
       * Variables for role "nso" is defined in `/home/dvans/ansibleproject/group_vars/nso`.   
         
         Sample file: [nso](https://github.com/weiganghuang/cl-devnet-1199/blob/master/ansibleproject/group_vars/nso)
         
       * We also defined a variable to be used for install syncdns package. It is pre-defined at `/home/dvans/ansibleproject/vars/labuser`. The sample file below shows the variable for lab user 17.
              
         Sample file: [labuser](https://github.com/weiganghuang/cl-devnet-1199/blob/master/ansibleproject/vars/labuser)
         
9. Put everything together  
   We have defined all play books for each role. Now we are ready to put everything together in `/home/dvans/ansibleproject/cl-playbook.yml`. This play book calls out all roles; the associated main.yml play book for each role are executed in the order defined in `cl-playbook.yml`.  
     
   Sample file: [cl-playbook.yml](https://github.com/weiganghuang/cl-devnet-1199/blob/master/ansibleproject/cl-playbook.yml)
   
10. Testing  
    Now we are ready to test the top level play book cl-playbook.yml. To execute, we invoke ansible-playbook command `ansible-playbook -i hosts cl-playbook.yml`   
    We expect it runs through successfully.  
     
    Sample output: [sample_output](https://github.com/weiganghuang/cl-devnet-1199/blob/master/ansibleproject/sample_output/output)
    
    
    
    

      
     
      


    




      




   
 




