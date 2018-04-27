# Using Ansible to Automate Environement Configuration, Application (NSO) Deployment, and Beyond  
## Hands on guide

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

### Requirements of the server configuration and deployment

* Install Cisco NSO on host N. NSO host manages DNS hosts, M, T1, and T2.

* Preconfiguration for hosts N, M, T1 and T2
  * Install application (Cisco NSO) on N.
  * Install NSO Ned on N.
  * Install Service Model.
  * Add devices and inventory model to NSO instance. 
  * Post testing.
   
 




