# Getting Started with Consul on Kubernetes: HCP Consul with EKS

## Overview

Install Consul on Kubernetes and quickly explore service mesh features such as service-to-service permissions with intentions, ingress with API Gateway, and enhanced observability.

## Steps

### kubernetes-gs-deploy

1. Clone repo
2. `cd learn-consul-get-started-kubernetes/cloud/hcp-managed/eks`
3. Set credential environment variables for AWS and HCP
    1. 
    ```shell
    export AWS_ACCESS_KEY_ID="YOUR_AWS_ACCESS_KEY"
    export AWS_SECRET_ACCESS_KEY="YOUR_AWS_SECRET_KEY"
    export HCP_CLIENT_ID="YOUR_HCP_CLIENT_ID"
    export HCP_CLIENT_SECRET="YOUR_HCP_SECRET"
    ```
4. Run Terraform to create resources (takes 10-15 minutes to complete)
    1. `terraform -chdir=terraform/ init`
    2. `terraform -chdir=terraform/ apply`
    3. `yes`

    Terraform will perform the following actions:
    - Create VPC and HVN networks
    - Peer VPC and HVN networks
    - Create HCP Consul cluster
    - Create EKS cluster

5. Configure terminal to communicate with your EKS cluster
    1. `aws eks --region $(terraform output -raw region) update-kubeconfig --name $(terraform output -raw kubernetes_cluster_id)` 
6. Configure terminal to communicate with your HCP Consul cluster

```sh
export CONSUL_HTTP_TOKEN=$(terraform output -raw consul_token) && \
export CONSUL_HTTP_ADDR=$(terraform output -raw consul_addr)
```

7. Confirm communication with your HCP Consul cluster.
   1. `consul catalog services`
   2. `consul members`

### kubernetes-gs-service-mesh

8. Create example service resources.
    1. `kubectl apply --filename hashicups/v1/`

9. Confirm all HashiCops pods are running.
   1.  `kubectl get pods`

10. Forward this port and test the connection.
    1.  `kubectl port-forward svc/nginx --namespace default 8080:80`
    2.  [http://localhost:8080](http://localhost:8080)
    3.  You should see an error.

11. Create intentions that allow communication between microservices.
    1.  `kubectl apply --filename hashicups/intentions/allow.yaml`

12. Forward this port and test the connection again.
    1.  `kubectl port-forward svc/nginx --namespace default 8080:80`
    2.  [http://localhost:8080](http://localhost:8080)
    3.  You should see the HashiCups UI.

### kubernetes-gs-ingress

13. Add API Gateway CRDs.
    1.  `kubectl apply --kustomize "github.com/hashicorp/consul-api-gateway/config/crd?ref=v0.5.1"`

13. Enable API Gateway and upgrade your Consul Helm deployment.
    1.  do this
    2.  `cp helm/values-v2.yaml modules/eks-client/template/consul.tpl` 
    3.  `terraform apply`
    4.  `yes`

14. Create API Gateway and respective route resources

```sh
kubectl apply --filename api-gw/consul-api-gateway.yaml --namespace consul && \
kubectl wait --for=condition=ready gateway/api-gateway --namespace consul --timeout=90s && \
kubectl apply --filename api-gw/routes.yaml --namespace consul
```

15. Deploy RBAC and ReferenceGrant resources

```sh
kubectl apply --filename hashicups/v2/
```

16. Confirm all services are running and intentions have been created.
    1.  `consul catalog services | grep api-gateway`
    2.  `consul intention list`

17.  Locate the external IP for your API Gateway.

```sh
kubectl get svc/api-gateway --namespace consul -o json | jq -r '.status.loadBalancer.ingress[0].hostname'
```

18. Visit the following urls in the browser
    1. [http://your-aws-load-balancer-dns-name:8080](http://your-aws-load-balancer-dns-name:8080)

### kubernetes-gs-observability

19. 

2020. Clean up
    1. Destroy Terraform resources
      `terraform destroy`