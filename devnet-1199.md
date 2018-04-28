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
   
   * nso\_copy\_images.yml, uses ansible copy and synchroize modules. Varialbes such as nso\_binary, nso\_image\_path, and etc, are defined under group-vars, which will be covered in later steps. 
   
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
    * nso\_install.yml. 
    
      ```
      ---
      #roles/nso/tasks/nso_install.yml
      
      - name: clean up any previous old installation
        file:
          state: absent
          path: "{{ nso_install_path }}/"

      - name: local install nso
      	 shell: sh {{ nso_image_path}}/{{ nso_binary}} {{ nso_install_path}}
        
      - name: set nso
        shell: source {{ nso_install_path}}/ncsrc; ncs-setup --dest {{ nso_run_dir}}

      - name: update .bashrc to source ncsrc
        lineinfile:
          dest: '{{ansible_env.HOME}}/.bashrc'
          state: present
          line: '. {{ nso_install_path }}/ncsrc'
           
       ```
    * nso\_install\_packages.yml, this play book is to install unix-bind ned and  dns manager service package, and inventory package. In this play book, we use block and looping:
    
      ```
      ---
      #roles/nso/tasks/nso_install_packages.yml

      - name: clean packages directory
        block:
          - file:
              path: "{{ nso_run_dir}}/packages"
              state: absent

          - file:
              path: "{{ nso_run_dir}}/packages"
              state: directory

      - name: link unix bind ned
        file:
          path: "{{ nso_run_dir}}/packages/{{ ned_file }}"
          src: "{{ nso_image_path }}/{{ ned_file }}"
          state: "link"
          mode: "0444"

      - name: install service model packages
        unarchive:
          src: "{{ item }}"
          dest: "{{ nso_run_dir}}/packages/"
        with_items:
          - "{{ dns_manager_pkg }}"
          - "{{ inventory_pkg }}"
      ```
      
    * nso\_start.yml:
      
      ```
      ---
      #roles/nso/tasks/nso_start.yml

      - name: stop nso
        shell: "source {{ nso_install_path}}/ncsrc;{{ nso_install_path }}/bin/ncs --stop"
        ignore_errors: yes

      - name: start nso
        shell: " source {{ nso_install_path}}/ncsrc;{{ nso_install_path }}/bin/ncs  --with-package-reload --cd {{ansible_env.HOME}}/ncs-run"
        
      ```
      
    * nso\_add\_devices.yml. This play book create devices and inventory to NSO. We use xml based config files to load merge to NSO's cdb. In this play book, we utlize template files for device and inventory xml files. The template files, device.j2 and inventory.j2 will be covered at later steps.
    
      ```
      ---
      #rules/nso/tasks/nso_add_devices.yml

      - name: fetch master host key
        shell: "ssh-keyscan -4 -T 5 -t rsa {{groups['master'][0]}} > /tmp/hostkey.txt"

      - name: master hostkey
        shell: ssh-keyscan -4 -T 5 -t rsa {{groups['master'][0]}}   2>/dev/null | awk '{ print $3; }' > /tmp/key.txt

      - name: cat key
        shell: cat /tmp/key.txt
        register: catkey

      - name: copy device xml and inventory xml files
        vars:
          host_key: "{{catkey.stdout}}"

        template:
          src: "{{ item }}.j2"
          dest: '{{ansible_env.HOME}}/{{item}}.xml'
        with_items:
         - device
         - inventory

      - name: load merge devices and inventory files
        shell: "source {{ nso_install_path}}/ncsrc;{{ nso_install_path }}/bin/ncs  --mergexmlfiles {{ansible_env.HOME}}/{{item}}.xml --cd {{ansible_env.HOME}}/ncs-run"
        with_items:
          - device
          - inventory

      - name: sync device master
        shell: "source {{ nso_install_path}}/ncsrc; sh {{ansible_env.HOME}}/scripts/sync-device.sh master"
      ```
    * nso\_postcheck.yml:

      ```
      ---
      #rules/nso/tasks/nso_add_devices.yml

      - include_vars:
          file: vars/labuser

      - name: check device sync status
        shell: "source {{ nso_install_path}}/ncsrc;sh {{ansible_env.HOME}}/scripts/check-sync.sh master"
        register: syncoutput

      - debug:
          msg: "device sync result: {{syncoutput.stdout}}"

      - name: test python scripts runs on master
        shell: "source {{ nso_install_path}}/ncsrc; sh {{ansible_env.HOME}}/scripts/test-python-scripts.sh master {{labuser}}"
        register: pythontestoutput
      - debug:
          msg: "python test: {{pythontestoutput.stdout}}"
      ```


    




      




   
 



