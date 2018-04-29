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
    
    [hosts](https://github.com/weiganghuang/cl-devnet-1199/blob/master/ansibleproject/hosts)
  
4. Create tasks for role "nso". List of tasks:
   * Copy images to NSO host.
   * Install NSO.
   * Install packages (ned, service package, and inventory packages)
   * Start NSO.
   * Load devices
   * Post check.
   
   All the above tasks are implemented with seperate playbook yml files.   
   
   * nso\_copy\_images.yml. This task playbook uses ansible copy and synchroize modules. Varialbes such as nso\_binary, nso\_image\_path, and etc, are defined under group-vars, which will be covered in later steps.   
   
     Sample file: [nso\_copy\_images.yml](https://github.com/weiganghuang/cl-devnet-1199/blob/master/ansibleproject/roles/nso/tasks/nso\_copy\_images.yml)
   
   * nso_install.yml. This tasks yml file defines play to install NSO and set nso environment.  
     Sample file: [nso_install.yml](https://github.com/weiganghuang/cl-devnet-1199/blob/master/ansibleproject/roles/nso/tasks/nso_install.yml)
    
   * nso\_install\_packages.yml, this play book is to install unix-bind ned and  dns manager service package, and inventory package. In this play book, we use block and looping.  
      
     Sample file: [nso\_install\_packages.yml](https://github.com/weiganghuang/cl-devnet-1199/blob/master/ansibleproject/roles/nso/tasks/nso_install_packages.yml)
    
            
   * nso_start.yml defines play to start NSO application.  

     Sample file: [nso_start.yml](https://github.com/weiganghuang/cl-devnet-1199/blob/master/ansibleproject/roles/nso/tasks/nso_start.yml)
      
      
   * nso\_add\_devices.yml. This play book create devices and inventory to NSO. We use xml based config files to load merge to NSO's cdb. In this play book, we utlize template files for device and inventory xml files. The template files, device.j2 and inventory.j2 will be covered at later steps.  
    
     Sample file: [nso\_add\_devices.yml](https://github.com/weiganghuang/cl-devnet-1199/blob/master/ansibleproject/roles/nso/tasks/nso_add_devices.yml)
    
      
   * nso_postcheck.yml.  In this play book, we pick two action to make sure the installation is sucessful, key exchange among N,M,T1,T2 allows necessary communication, and suders setting is proper.    

     Sample file: [nso_postcheck.yml](https://github.com/weiganghuang/cl-devnet-1199/blob/master/ansibleproject/roles/nso/tasks/nso_postcheck.yml)
     
   * The above 7 tasks are putting together and invoked for role nso from playbook main.yml.    
    
     Sample file: [main.yml](https://github.com/weiganghuang/cl-devnet-1199/blob/master/ansibleproject/roles/nso/tasks/main.yml)
    
   * We have used a couple of variables and templates in the tasks of nso. Template files are defined under template directory of each role. device.j2 file for creating auth group, DNS master (M), and targets (T1, T2) to NSO's cdb.   
      
      device.j2, xml format device config file with two variables.   
      Sample file: [device.j2](https://github.com/weiganghuang/cl-devnet-1199/blob/master/ansibleproject/roles/nso/templates/device.j2) 
    
      inventory.j2, an xml format inventory template file to create inventory model in NSO's cdb. There is no veriables in this template.  
      Sample file: [inventory.j2](https://github.com/weiganghuang/cl-devnet-1199/blob/master/ansibleproject/roles/nso/templates/inventory.j2) 
       
5. Create tasks for role "device". As mentioned in requirements, dns master M is managed by NSO. To meet the security compliance, the communication between NSO host N and the device M is limited to non-login, non-interactive, key based ssh. The tasks for role "device" is to add rsa public key of N to M, for NSO's southbound user, and limit sudoers to perform the allowed operations.  
  
    The synchronization from master to targets is performed by a syncdns package from DNS master. Thus,we also need to define a task to install syncdns package onto dns master M.  
     
    For this play, we define tasks in main.yml file.  

   Sample file: [main.yml](https://github.com/weiganghuang/cl-devnet-1199/blob/master/ansibleproject/roles/device/tasks/main.yml)
   
   
6. Create tasks for role "target". DNS master synchronize end user chosed directory to targets. To comply with the company's security requirements, the communication between master (M) to targets (T1,T2) is no-login, non-interaction, key based ssh. The tasks defined for this role is to add rsa public key to T1 and T2 for peer user, and limit sudoers to perform the allowed operations. Similar to that for "device", we define tasks in main.yml file. 
  
   Sample file: [main.yml](https://github.com/weiganghuang/cl-devnet-1199/blob/master/ansibleproject/roles/target/tasks/main.yml)

7. Prepare image/helper scripts files for roles "nso" and "device". We will put required image/helper scripts files under files directory for each role. In this workshop, we only need to put files to role "nso" and "device". The required files are made available at /var/tmp/dvans for your ansible host, H.

    * Copy nso binary, ned, service package, and inventory package to nso/files. From your ansible controller, copy required files from /var/tmp/dvans to /home/dvans/ansibleproject/roles/nso/files.  
      
      Sample output:  
        
    * Copy syncdns to device/files. From your ansible controller, copy the required file from /var/tmp/dvans/ to /home/dvans/ansibleproject/roles/device./files.   
  
      Sample output: 
     
      ```
    [dvans@cl90 ~]$ cd ansibleproject/roles/device/files
    [dvans@cl90 files]$ cp /var/tmp/dvans/syndns.tar.gz .
    ```
8. Create variables.
     * Create group variables. As shown at previous st
9. Put everything together
10. Testing

      
     
      


    




      




   
 




