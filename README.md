# GKE Bootstrap - Deployment Manager

Google Cloud Platform Deployment Manager bootstrap for GKE

---

## Architecture

---

![Architecture Diagram](img/architecture.png)

---

## Setup

---

### Deploy Script Usage

```bash
./deploy.sh <project_id> <resource> <action>
```

Resources must be deployed and removed in the following order

| create             | delete              |
|--------------------|---------------------|
| IAM                | Bastion             |
| Network            | GKE                 |
| Cloud Router (NAT) | Cloud Router (NAT)  |
| GKE                | Network             |
| Bastion            | IAM                 |

#### IAM

Deployment manager needs IAM permissions for particular tasks. We can temporarily add these permissions using the following

```bash
# Create
./deploy.sh <project_id> iam create

# Delete
./deploy.sh <project_id> iam delete
```

#### Network

```bash
# Create
./deploy.sh <project_id> network create

# Delete
./deploy.sh <project_id> network delete
```

#### Cloud Router (NAT)

```bash
# Create
./deploy.sh <project_id> cloud-router create

# Delete
./deploy.sh <project_id> cloud-router delete
```

#### GKE

```bash
# Create
./deploy.sh <project_id> gke create

# Delete
./deploy.sh <project_id> gke delete
```

#### Bastion

```bash
# Create
./deploy.sh <project_id> bastion create

# Delete
./deploy.sh <project_id> bastion delete
```

---

## Manage

---

### Connect

Connect to the bastion host and manage the kubernetes cluster from there using the steps below

#### SSH Bastion

```bash
gcloud compute ssh <project_id>-bastion \
    --project <project_id> \
    --zone australia-southeast1-a
```

Then pull the repo down locally to the bastion server

```bash
git clone https://github.com/t04glovern/gke-dm-bootstrap.git
```

#### Kubernetes Connect

```bash
gcloud container clusters get-credentials <project_id>-gke \
    --project <project_id> \
    --region australia-southeast1
```

#### Role-based Access Control (RBAC) [Skip]

> **NOTE**: This step is only required for Helm 2.0 or lower. By default you should have Helm 3.0+ installed on the bastion, so it is likely safe to skip this step

We'll deploy an RBAC configuration that is used by helm. Perform the following actions from the Bastion server

```bash
cd gke-dm-bootstrap/k8s

# Create tiller service account & cluster role binding
kubectl create -f rbac-config.yaml

# init helm with the service account
helm init --service-account tiller --history-max 200
```

## Helm

### Install Packages

#### Nginx External

Deploy the external version of nginx run running the following

```bash
# From within the k8s folder
cd gke-dm-bootstrap/k8s

# Install the helm templates as 'nginx'
helm install nginx ./nginx/

# Get the external IP
kubectl get services
# NAME            TYPE           CLUSTER-IP        EXTERNAL-IP     PORT(S)        AGE
# kubernetes      ClusterIP      192.168.192.1     <none>          443/TCP        115m
# nginx-service   LoadBalancer   192.168.192.132   35.244.100.27   80:30251/TCP   9m

curl http://35.244.100.27
# <h1>DevOpStar Nginx Kubernetes</h1>

# <p>Congratulations!</p>
```

#### Nginx Internal

Edit the `k8s/nginx/templates/service.yaml` file and uncomment the following lines

```yaml
  annotations:
    cloud.google.com/load-balancer-type: Internal

...

  loadBalancerIP: {{ .Values.staticIp }}
```

You can update the **staticIp** value in the `k8s/nginx/values.yaml` file

```bash
# Upgrade the helm templates called 'nginx'
helm upgrade nginx ./nginx/

curl http://192.168.189.50
# <h1>DevOpStar Nginx Kubernetes</h1>

# <p>Congratulations!</p>
```

### Delete Packages

```bash
helm delete nginx
```

## Attribution

- RBAC Configuration Example - [https://github.com/helm/helm/blob/master/docs/rbac.md](https://github.com/helm/helm/blob/master/docs/rbac.md)
- Deployment Manager samples - [https://github.com/GoogleCloudPlatform/deploymentmanager-samples](https://github.com/GoogleCloudPlatform/deploymentmanager-samples)
  - [cloud_router](https://github.com/GoogleCloudPlatform/deploymentmanager-samples/tree/master/community/cloud-foundation/templates/cloud_router)
  - [firewall](https://github.com/GoogleCloudPlatform/deploymentmanager-samples/tree/master/community/cloud-foundation/templates/firewall)
  - [gke](https://github.com/GoogleCloudPlatform/deploymentmanager-samples/tree/master/community/cloud-foundation/templates/gke) - with modifications from [Praveen Chamarthi](https://github.com/GoogleCloudPlatform/deploymentmanager-samples/pull/326)
  - [iam_member](https://github.com/GoogleCloudPlatform/deploymentmanager-samples/tree/master/community/cloud-foundation/templates/iam_member)
  - [network](https://github.com/GoogleCloudPlatform/deploymentmanager-samples/tree/master/community/cloud-foundation/templates/network)