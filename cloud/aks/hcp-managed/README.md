# Deployment steps

## kubernetes-gs-deploy

1. Authenticate to Azure CLI and set HCP environmental variables on your CLI.

```sh
az login
```

```sh
export HCP_CLIENT_ID="your-hcp-client-id"
export HCP_CLIENT_SECRET="your-hcp-client-secret"
```

2. Run Terraform to deploy the following:

- An Azure network
- An AKS cluster
- An AKS Consul client
- An HCP Consul cluster
- Peering between AKS and HCP

```sh
terraform -chdir=terraform/ init
```

```sh
terraform -chdir=terraform/ apply --auto-approve
```

3. Configure your CLI to communicate with AKS.

```sh
az aks get-credentials --resource-group $(terraform -chdir=terraform/ output -raw azure_rg_name) --name $(terraform -chdir=terraform/  output -raw aks_cluster_name)
```

4. Verify all pods have successfully started.

```sh
kubectl get pods
```

```log
NAME                                           READY   STATUS    RESTARTS   AGE
consul-client-hl2tt                            1/1     Running   0          3m30s
consul-client-jlscc                            1/1     Running   0          3m30s
consul-client-qb674                            1/1     Running   0          3m30s
consul-connect-injector-776c6b6994-j2xtk       1/1     Running   0          3m30s
consul-connect-injector-776c6b6994-vbqzr       1/1     Running   0          3m30s
consul-controller-6cf4d68847-lg9pw             1/1     Running   0          3m30s
consul-webhook-cert-manager-66f95b9559-b2fll   1/1     Running   0          3m30s
```

5. Review the Consul configuration file while the environment is being deployed.

```yml
code helm/consul-values-hcp-v1.yaml
```

6. Configure your CLI to interact with Consul cluster

```sh
export CONSUL_HTTP_TOKEN=$(terraform -chdir=terraform/ output -raw consul_token) && \
export CONSUL_HTTP_ADDR=$(terraform -chdir=terraform/ output -raw consul_addr)
```

7. Run `consul members` command on the CLI.

```sh
consul members
```

8. Retrieve the Consul members list from the Consul API.

```sh
curl -k \
    --header "X-Consul-Token: $CONSUL_HTTP_TOKEN" \
    $CONSUL_HTTP_ADDR/v1/agent/members
```

9. Check out the Consul members list in the Consul UI.

```sh
echo $CONSUL_HTTP_ADDR && \
echo $CONSUL_HTTP_TOKEN
```

## kubernetes-gs-service-mesh

1. Content

```sh
kubectl apply --filename hashicups/v1/
```

2. View these services in Consul

```sh
consul catalog services
```

```log
consul
frontend
frontend-sidecar-proxy
nginx
nginx-sidecar-proxy
payments
payments-sidecar-proxy
product-api
product-api-db
product-api-db-sidecar-proxy
product-api-sidecar-proxy
public-api
public-api-sidecar-proxy
```

3. Forward the port for nginx, then open a connection to it in your browser to see the connection failure. Kill the port forward once complete.

```sh
kubectl port-forward svc/nginx --namespace default 8080:80
```

```log
http://localhost:8080 
```

4. Create intentions.

```sh
kubectl apply --filename hashicups/intentions/allow.yaml
```

5. Forward the port for nginx, then open a connection to it in your browser to see the connection success. Kill the port forward once complete.

```sh
kubectl port-forward svc/nginx --namespace default 8080:80
```

```log
http://localhost:8080 
```

## kubernetes-gs-ingress

1. Create the custom resource definitions (CRD) for the API Gateway Controller.

```sh
kubectl apply --kustomize "github.com/hashicorp/consul-api-gateway/config/crd?ref=v0.4.0"
```

2. Add this block to the bottom of `/terraform/modules/hcp-aks-client/template/consul.tpl`:

```yaml
#...
apiGateway:
  enabled: true
  image: "hashicorp/consul-api-gateway:0.4.0"
  managedGatewayClass:
    serviceType: LoadBalancer
```

3. Deploy updated Consul configuration with Terraform to deploy the API GW controller.

```sh
terraform -chdir=terraform/ apply --auto-approve
```

or run a targeted tf command.

```sh
terraform -chdir=terraform/ apply -target="module.aks_consul_client" --auto-approve
```

4. Deploy the API Gateway and the routes.

```sh
kubectl apply --filename api-gw/consul-api-gateway.yaml && \
kubectl wait --for=condition=ready gateway/api-gateway --timeout=90s && \
kubectl apply --filename api-gw/routes.yaml
```

5. Deploy the RBAC and ReferenceGrant resources

```sh
kubectl apply --filename hashicups/v2/
```

6. Retrieve information on the `api-gateway` service.

```sh
kubectl get services api-gateway
```

7. Open a connection to the listed `EXTERNAL-IP` entry in your browser to see the connection failure.

```log
http://52.137.88.78
```

8. Create this file `/terraform/azure-nsg-api-gateway.tf` and put your `EXTERNAL-IP` in the `destination_address_prefix` field.

```t
resource "azurerm_network_security_rule" "api-gateway-ingress" {
  name                        = "api-gw-http-ingress"
  priority                    = 301
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "80"
  source_address_prefix       = "*"
  destination_address_prefix  = "52.137.88.78/32"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.nsg.name
}
```

9. Deploy updated Consul configuration with Terraform to deploy the network security group rule.

```sh
terraform -chdir=terraform/ apply --auto-approve
```

10. Open a connection to the listed `EXTERNAL-IP` entry in your browser to see the connection success.

```log
http://52.137.88.78
```

## kubernetes-gs-observability

1. Content

- ./install-observability-suite.sh
- cp helm/consul-values-hcp-v3.yaml terraform/modules/aks-client/template/consul.tpl
- kubectl apply -f proxy/proxy-defaults.yaml
- terraform -chdir=terraform/ apply --auto-approve
- Check the Consul UI for metrics (Is this possible with HCP?)
- kubectl port-forward svc/grafana --namespace default 3000:3000
- [Grafana UI](http://localhost:3000/)
- kubectl port-forward svc/prometheus-server --namespace default 8888:80
- [Prometheus UI](http://localhost:8888/)
- kubectl port-forward svc/nginx --namespace default 8080:80
- [HashiCups UI](http://localhost:8080/)