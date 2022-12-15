# Getting Started with Consul on Kubernetes: HCP Consul with AKS

## Overview

Install Consul on Kubernetes and quickly explore service mesh features such as service-to-service permissions with intentions, ingress with API Gateway, and enhanced observability.

## Steps

### kubernetes-gs-deploy

1. Clone repo
2. `cd learn-consul-get-started-kubernetes/cloud/aks/hcp-managed`
3. Authenticate to Azure CLI.

```sh
az login
```

4. Set environment variables for HCP.

```sh
export HCP_CLIENT_ID="YOUR_HCP_CLIENT_ID"
export HCP_CLIENT_SECRET="YOUR_HCP_SECRET"
```

5. Run Terraform to create resources (takes 10-15 minutes to complete)
    1. `terraform init`
    2. `terraform apply`
    3. `yes`

    Terraform will perform the following actions:
    - Create Azure and HVN networks
    - Create HCP Consul cluster
    - Create AKS cluster

6. Configure terminal to communicate with your EKS cluster

```sh
az aks get-credentials --resource-group $(terraform output -raw azure_rg_name) --name $(terraform output -raw aks_cluster_name)
```

7. Configure terminal to communicate with your HCP Consul cluster

```sh
export CONSUL_HTTP_TOKEN=$(terraform output -raw consul_root_token) && \
export CONSUL_HTTP_ADDR=$(terraform output -raw consul_url)
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

15. Enable API Gateway and upgrade your Consul Helm deployment.
    1.  do this
    2.  `cp helm/values-v2.yaml modules/hcp-aks-client/templates/consul.tpl` 
    3.  `terraform apply`
    4.  `yes`

16. Create API Gateway and respective route resources.

```sh
kubectl apply --filename api-gw/consul-api-gateway.yaml --namespace consul && \
kubectl wait --for=condition=ready gateway/api-gateway --namespace consul --timeout=90s && \
kubectl apply --filename api-gw/routes.yaml --namespace consul
```

17. Deploy RBAC and ReferenceGrant resources.

```sh
kubectl apply --filename hashicups/v2/
```

18. Confirm all services are running and intentions have been created.
    1.  `consul catalog services | grep api-gateway`
    2.  `consul intention list`

19.  Locate the external IP for your API Gateway.

```sh
kubectl get svc/api-gateway --namespace consul -o json | jq -r '.status.loadBalancer.ingress[0].ip'
```

20.  Visit the following urls in the browser - you will experience a connection failure.
    1. [http://your-azure-load-balancer-ip:8080](http://your-azure-load-balancer-ip:8080)

21. Create this file `/terraform/azure-nsg-api-gateway.tf` and put your `EXTERNAL-IP` in the `destination_address_prefix` field.

```t
resource "azurerm_network_security_rule" "api-gateway-ingress" {
  name                        = "api-gw-http-ingress"
  priority                    = 301
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "8080"
  source_address_prefix       = "*"
  destination_address_prefix  = "52.137.88.78/32"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.nsg.name
}
```

22. Deploy updated Consul configuration with Terraform to deploy the network security group rule.

```sh
terraform --auto-approve
```

23.  Visit the following urls in the browser - you will see a connection success.
    1. [http://your-azure-load-balancer-ip:8080](http://your-azure-load-balancer-ip:8080)


### kubernetes-gs-observability

24. do this

- ./install-observability-suite.sh
- cp helm/values-v3.yaml modules/hcp-aks-client/templates/consul.tpl
- kubectl apply -f proxy/proxy-defaults.yaml
- terraform -chdir=terraform/ apply --auto-approve
- Check the Consul UI for metrics (Is this possible with HCP?)
- kubectl port-forward svc/grafana --namespace default 3000:3000
- [Grafana UI](http://localhost:3000/)
- kubectl port-forward svc/prometheus-server --namespace default 8888:80
- [Prometheus UI](http://localhost:8888/)
- kubectl port-forward svc/nginx --namespace default 8080:80
- [HashiCups UI](http://localhost:8080/)

1.    Clean up
    1. Destroy Terraform resources
      `terraform destroy`