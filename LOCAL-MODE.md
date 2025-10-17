# Deploying IBM Event Automation In A Local Microk8s Environment

This page is dedicated to documenting how to use the ansible script to deploy the IBM Event Automation demo environment in a local microk8s environment on Linux (or Linux under WSL on Windows).

## Scope

This tutorial and instructions are unsupported. The instructions are to try and assist with simplifying the prerequisite hardware requirements for deploying and learning some of the key features of IBM Event Automation products.

## Prerequisites

The instrutions here are supplied for an Ubuntu 22.04 system (or Windows system running Ubuntu 22.04 under WSL2).

### WSL on Windows

The following instructions were used by the author to install and configure WSL on windows and are provided for reference only.  You are encouraged to consult the [official documentation](https://learn.microsoft.com/en-us/windows/wsl/install).

  - Start a powershell

  - Run `wsl --install -d Ubuntu-22.04`

  - Reboot the system

  - Wait for wsl installation to complete, at the prompt for a default unix user account enter `eatest` and supply a password when prompted

  - Configure WSL Memory and CPU by adding the following content to a .wslconfig file your windows user's home directory (i.e C:\Users\Administrator).

    ```
    [wsl2]
    memory=22GB
    processors=12
    ```

  - Shutdown wsl with the command `wsl --shutdown`

  - For WSL2, run the command `restart-service WslService` in PowerShell as administrator

  - For WSL1, run the command `restart-service LxssManager` in PowerShell as administrator

  - Run `wsl -d Ubuntu-22.04`


### Microk8s Installation

The microk8s environment must be able to run linux/amd64 docker images and have a minimum of 12 CPUs and 22Gb RAM.  The following commands assume you are running on Ubuntu 22.04 and are provided as a reference point.  You are encouraged to consult the [official documentation](https://microk8s.io/docs)

  - Ensure your system is up to date

        ```
        sudo apt-get update
        sudo apt-get upgrade -y
        ```

  - Install microk8s and wait for it to start

        ```
        sudo snap install microk8s --classic
        sudo microk8s status --wait-ready
        ```

    If you are rate limited or unable to access dockerhub, the following alternate image locations may assist in bringing up microk8s.  Please note, that depending on your version of microk8s you may require alternate versions of these images:

        - quay.io/calico/kube-controllers:v3.28.1
        - quay.io/calico/node:v3.28.1
        - quay.io/calico/cni:v3.28.1
        - quay.io/calico/cni:v3.28.1
        - k8s.gcr.io/coredns/coredns:v1.10.1

  - Enable the user (commands below assume you are logged in as eatest) to run microk8s and set command aliases and env vars in your current shell, substitte with the relevant userid for your environment.

        ```
        sudo usermod -a -G microk8s eatest
        mkdir -p /home/eatest/.kube
        sudo chown -R eatest ~/.kube
        newgrp microk8s

        alias kubectl="microk8s kubectl"
        alias helm="microk8s helm"
        microk8s config > ~/kubeconf
        export KUBECONFIG=~/kubeconf
        ```

  - Add these commands to your .profile or basrc equivalent such that they are available when you log back in

        ```
        echo alias kubectl=\"microk8s kubectl\" >> ~/.profile
        echo alias helm=\"microk8s helm\" >> ~/.profile
        echo export KUBECONFIG=~/kubeconf >> ~/.profile
        ```

  - Enable the ingress, cert-manager and registry addons

        ```
        microk8s enable ingress
        microk8s enable cert-manager
        microk8s enable registry
        ```

### TLS Passthrough enablement

TLS pass-through must be enabled on the microk8s nginx ingress controller.  If you do not enable this, then Event Gateway instances are not able to communicate with the Event Manager.

  - Enable TLS pass-through

        ```
        microk8s kubectl patch ds -n ingress nginx-ingress-microk8s-controller --type='json' -p='[{"op": "add", "path": "/spec/template/spec/containers/0/args/1", "value":"--enable-ssl-passthrough"}]'
        ```

### Ansible Installation

Ansible must be installed with kubernetes.core and community.general collections

  - On Ubuntu 22.04 you can install ansible as follows

        ```
        sudo add-apt-repository ppa:ansible/ansible
        sudo apt update
        sudo apt-get install ansible -y
        ```

  - Add the kubernetes.core and community.general collections as follows

        ```
        ansible-galaxy collection install kubernetes.core
        ansible-galaxy collection install community.general
        ```

### PIP3 for Python

Python and pip3 must be installed, it is likley python is already installed and you only need to add pip3.

  - To install pip3

        ```
        sudo add-apt-repository universe
        sudo apt update
        sudo apt install python3-pip -y
        ```

### Helm Installation

Helm must be installed and on the PATH, the following commands should install helm on an Ubuntu system

        ```
        sudo apt-get install curl gpg apt-transport-https --yes

        curl -fsSL https://packages.buildkite.com/helm-linux/helm-debian/gpgkey | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null

        echo "deb [signed-by=/usr/share/keyrings/helm.gpg] https://packages.buildkite.com/helm-linux/helm-debian/any/ any main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list

        sudo apt-get update
        sudo apt-get install helm
        ```

### Maven, Git, Docker and Java 17+

You will need the mvn, git and docker commands available to build git repos, download dependencies and build the kafkaconnect image used to pre-populate topics, to install these technologies:

  - `sudo apt install maven -y`
  - `sudo apt install git -y`
  - `sudo snap install docker`

You will also need Java 17 or higher

  - `sudo apt install openjdk-17-jdk -y`


### Build the kafkaconnect docker image

Obtain your IBM entitlement key so that you can access the IBM Event Automation product images.  Your entitlement key is available from the [IBM Container software library](https://myibm.ibm.com/products-services/containerlibrary).  Log into the IBM registry using your entitlement key.

  - Login to cp.icr.io

        ```
        sudo docker login cp.icr.io -u cp
        ```

  - Git clone this repo and cd into it

        ```
        git clone https://github.com/IBM/event-automation-demo.git
        cd event-automation-demo
        ```

  - Build the kafkaconnect resources used in this demo

        ```
        ./install/local/kakfka-connect-build.sh
        ```

  - Build and tag the image, assuming your local microk8s registry is available as localhost:32000 (the default)

        ```
        sudo docker build -t localhost:32000/event-automation:demo -f install/local/Dockerfile .
        ```

  - Upload this image to the microk8s registry.  Wherever you push this image will be the value you specify as the kafkaconnect_image on the ansible command to install and setup the environment. Assuming your microk8s registry is the default localhost:32000

        ```
        sudo docker push localhost:32000/event-automation:demo
        ```


### Configure Local DNS Resoultion

Configure the system dns resolution both on your host system and your microk8s cluster dns.  For this you will need the internal IP address of your microk8s node obtained from `microk8s kubectl get nodes -o wide`

  - If on Windows edit `C:\Windows\System32\drivers\etc\hosts`, if on linux edit `/etc/hosts` and add the following lines (replacing 172.18.241.41 with the internal IP obtained above):

        ```
        172.18.241.41 my-kafka-cluster-adminui.running.local
        172.18.241.41 apicurioregistry.running.local
        172.18.241.41 my-kafka-cluster-adminapi.running.local
        172.18.241.41 my-kafka-cluster-broker-3.running.local
        172.18.241.41 my-kafka-cluster-broker-4.running.local
        172.18.241.41 my-kafka-cluster-broker-5.running.local
        172.18.241.41 my-kafka-cluster-bootstrap.running.local
        172.18.241.41 eem.qs-eem-server.running.local
        172.18.241.41 qs-eem-gateway.running.local
        172.18.241.41 qs-gateway.running.local
        172.18.241.41 qs-gateway-1.running.local
        172.18.241.41 qs-gateway-2.running.local
        172.18.241.41 qs-eem-ui.running.local
        172.18.241.41 qs-eem-admin.running.local
        172.18.241.41 my-event-processing.running.local
        ```

  - Edit the coredns configmap of your cluster to include the hosts addon and specify the same entries along with the fallthrough directive.  Run the command `microk8s kubectl edit configmap coredns -n kube-system`, and add the hosts section in the .53 such that your data section resembles something akin to:

        ```
        data:
            Corefile: |
                .:53 {
                    hosts {
                        172.18.241.41 my-kafka-cluster-adminui.running.local
                        172.18.241.41 apicurioregistry.running.local
                        172.18.241.41 my-kafka-cluster-adminapi.running.local
                        172.18.241.41 my-kafka-cluster-broker-3.running.local
                        172.18.241.41 my-kafka-cluster-broker-4.running.local
                        172.18.241.41 my-kafka-cluster-broker-5.running.local
                        172.18.241.41 my-kafka-cluster-bootstrap.running.local
                        172.18.241.41 eem.qs-eem-server.running.local
                        172.18.241.41 qs-eem-gateway.running.local
                        172.18.241.41 qs-gateway.running.local
                        172.18.241.41 qs-gateway-1.running.local
                        172.18.241.41 qs-gateway-2.running.local
                        172.18.241.41 qs-eem-ui.running.local
                        172.18.241.41 qs-eem-admin.running.local
                        172.18.241.41 my-event-processing.running.local
                        fallthrough
                    }
                    errors
                    health {
                        lameduck 5s
                    }
                    ready
                    log . {
                        class error
                    }
                    kubernetes cluster.local in-addr.arpa ip6.arpa {
                        pods insecure
                        fallthrough in-addr.arpa ip6.arpa
                    }
                    prometheus :9153
                    forward . /etc/resolv.conf
                    cache 30
                    loop
                    reload
                    loadbalance
                }
        ```

  - On windows, you will need to restart your wsl such that the Ubuntu environment's /etc/hosts mirrors the entries added to the windows file.  Use `wsl.exe --shutdown` and then restart with `wsl -d Ubuntu-22.04`.

**IMPORTANT:** Note that if you restart your system, or connect to a different network - the IP address of your node could change.  If this happens, you will need to update the IP address in both the hosts file and the coredns configmap.

---

## Step 1 - Deploy

To install with persistence run

```sh
ansible-playbook \
    -e experimental=true \
    -e license_accept=true \
    -e ibm_entitlement_key=<YOUR-KEY-HERE> \
    -e eventstreams_storage_class=microk8s-hostpath \
    -e eventendpointmanagement_storage_class=microk8s-hostpath \
    -e eventprocessing_storage_class=microk8s-hostpath \
    -e eventautomation_namespace=event-automation \
    -e kafkaconnect_image=localhost:32000/event-automation:demo \
    install/event-automation-local.yaml
```

After the installation completes, check all the pods are running using the command `microk8s kubectl get pods -n event-automation`.  It may take a couple of minutes to finish starting.  You should find the product UIs available at:

- Event Endpoint Management (EEM) : https://qs-eem-ui.running.local
- Event Processing (EP) : https://my-event-processing.running.local
- Event Streams (ES) : https://my-kafka-cluster-adminui.running.local


### Installation Options

#### `license_accept`

Set this to `true` to indicate that you accept the terms of the Event Automation license. This value is used for each of the components that the playbook installs.

#### `ibm_entitlement_key`

Set this to the key you created in the [IBM Container software library](https://myibm.ibm.com/products-services/containerlibrary).

#### `eventautomation_namespace`

Namespace to deploy the Event Automation components into.

#### `eventstreams_storage_class`

Storage class to use for persistent storage for Kafka brokers and Kraft nodes from Event Streams.

If omitted, ephemeral storage is used.

#### `eventendpointmanagement_storage_class`

Storage class to use for the Event Endpoint Management manager.

If omitted, ephemeral storage is used.

#### `eventprocessing_storage_class`

Storage class to use for the Event Processing authoring environment.

If omitted, ephemeral storage is used.

#### `kafkaconnect_image`

The image built as a pre-requisite step that will populate topics with messages (localhost:32000/event-automation:demo)

#### `experimental`

This flag indicates that you understand this scripting and software is not designed for running locally and that you could well experience issues that relate specifically to running in an unsupported environment.


## Step 2 - Populate the catalog

A helper script is provided to populate the Event Endpoint Management catalog with documentation for the tutorial Kafka topics.

This will allow you to discover the tutorial topics in the catalog.

You need an access token to be able to run the helper script.

To create an access token, visit the **Profile** page in the Event Endpoint Management catalog by clicking on the user icon in the header. For more detailed instructions, see the [Event Endpoint Management documentation](https://ibm.github.io/event-automation/eem/security/api-tokens/#creating-a-token).

`./eem-seed/reset-all-data.sh <eventautomation_namespace>  <access_token>`

For example:
```sh
./eem-seed/reset-all-data.sh event-automation 00000000-0000-0000-0000-000000000000
```

> **Warning**:
>
> This will delete ALL data stored in Event Endpoint Management (including cluster definitions, topic documentation, subscriptions), and replace it with documentation for the topics included in the tutorial.
>
> You should not run this script if you have any data in Event Endpoint Management that you want to keep.
>

---

## Step 3 - Try the tutorials

For instructions on how to start using your new demo environment, you can follow the [tutorial instructions in the IBM Event Automation documentation](https://ibm.biz/ea-tutorials).

---
