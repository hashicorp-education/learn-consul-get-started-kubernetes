# Getting Started with Consul on Kubernetes: Self Managed Consul with AKS

## Overview

Install Consul on Kubernetes and quickly explore service mesh features such as service-to-service permissions with intentions, ingress with API Gateway, and enhanced observability.

## Steps

### kubernetes-gs-deploy

1. Clone repo
2. `cd learn-consul-get-started-kubernetes/self-managed/aks`
3. Set credential environment variables for AWS
    1. 
    ```shell
    export AWS_ACCESS_KEY_ID="YOUR_AWS_ACCESS_KEY"
    export AWS_SECRET_ACCESS_KEY="YOUR_AWS_SECRET_KEY"
    ```
4. Run Terraform to create resources (takes 10-15 minutes to complete)
    1. `terraform init`
    2. `terraform apply`
    3. `yes`
5. Configure terminal to communicate with your EKS cluster
    1. `aws eks --region $(terraform output -raw region) update-kubeconfig --name $(terraform output -raw kubernetes_cluster_id)` 
6. Install Consul in your EKS cluster

```sh
helm install --values helm/values-v1.yaml consul hashicorp/consul --create-namespace --namespace consul --version "1.0.2"
```

```sh
consul-k8s install -config-file=helm/values-v1.yaml
```

7. Configure your terminal to communicate with your Consul cluster

```sh
export CONSUL_HTTP_TOKEN=$(kubectl get --namespace consul secrets/consul-bootstrap-acl-token --template={{.data.token}} | base64 -d) && \
export CONSUL_HTTP_ADDR=https://$(kubectl get services/consul-ui --namespace consul -o jsonpath='{.status.loadBalancer.ingress[0].hostname}') && \
export CONSUL_HTTP_SSL_VERIFY=false
```

8. Confirm communication with your HCP Consul cluster.
   1. `consul catalog services`
   2. `consul members`

### kubernetes-gs-service-mesh

9. Create example service resources.
    1. `kubectl apply --filename hashicups/v1/`

10. Confirm all HashiCops pods are running.
   1.  `kubectl get pods`

11. Forward this port and test the connection.
    1.  `kubectl port-forward svc/nginx --namespace default 8080:80`
    2.  [http://localhost:8080](http://localhost:8080)
    3.  You should see an error.

12. Create intentions that allow communication between microservices.
    1.  `kubectl apply --filename hashicups/intentions/allow.yaml`

13. Forward this port and test the connection again.
    1.  `kubectl port-forward svc/nginx --namespace default 8080:80`
    2.  [http://localhost:8080](http://localhost:8080)
    3.  You should see the HashiCups UI.

### kubernetes-gs-ingress

14. Add API Gateway CRDs.
    1.  `kubectl apply --kustomize "github.com/hashicorp/consul-api-gateway/config/crd?ref=v0.5.1"`

15. Update the Helm deployment to add API GW.

```sh
helm upgrade --values helm/values-v2.yaml consul hashicorp/consul --namespace consul --version "1.0.1"
```

```sh
consul-k8s upgrade -config-file=helm/values-v2.yaml
```

16. Create API Gateway and respective route resources

```sh
kubectl apply --filename api-gw/consul-api-gateway.yaml --namespace consul && \
kubectl wait --for=condition=ready gateway/api-gateway --namespace consul --timeout=90s && \
kubectl apply --filename api-gw/routes.yaml --namespace consul
```

17. Deploy RBAC and ReferenceGrant resources

```sh
kubectl apply --filename hashicups/v2/
```

18. Confirm all services are running and intentions have been created.
    1.  `consul catalog services | grep api-gateway`
    2.  `consul intention list`

19.  Locate the external IP for your API Gateway.

```sh
kubectl get svc/api-gateway --namespace consul -o json | jq -r '.status.loadBalancer.ingress[0].hostname'
```

20. Visit the following urls in the browser
    1. [http://your-aws-load-balancer-dns-name:8080](http://your-aws-load-balancer-dns-name:8080)

### kubernetes-gs-observability

21. 

2020. Clean up
    1. Destroy Terraform resources
      `terraform destroy`