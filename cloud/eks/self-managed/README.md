# Deployment steps

## kubernetes-gs-deploy

1. Set environmental variables on your CLI.

```sh
export AWS_ACCESS_KEY_ID="your-aws-access-key-id"
export AWS_SECRET_ACCESS_KEY="your aws-secret-key"
export HCP_CLIENT_ID="your-hcp-client-id"
export HCP_CLIENT_SECRET="your-hcp-client-secret"
```

2. Run Terraform to deploy the following:

- An EKS cluster
- An EKS Consul client
- An HCP Consul cluster
- Peering between EKS and HCP

```sh
terraform -chdir=terraform/ init
```

```sh
terraform -chdir=terraform/ apply --auto-approve
```

3. Configure your CLI to communicate with EKS.

```sh
aws eks --region $(terraform -chdir=terraform/ output -raw region) update-kubeconfig --name $(terraform -chdir=terraform/  output -raw kubernetes_cluster_id)
```

4. Verify all pods have successfully started.

```sh
kubectl get pods
```

```log
NAME                                           READY   STATUS    RESTARTS   AGE
consul-client-4v8jp                            1/1     Running   0          6m27s
consul-client-brcxj                            1/1     Running   0          6m27s
consul-client-hb77j                            1/1     Running   0          6m26s
consul-connect-injector-548b99fdc8-hrbrm       1/1     Running   0          6m27s
consul-connect-injector-548b99fdc8-qhqqx       1/1     Running   0          6m27s
consul-controller-88975c6d7-5shb2              1/1     Running   0          6m26s
consul-webhook-cert-manager-7597cbb5d4-l9xwb   1/1     Running   0          6m27s
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

2. Add this block to the bottom of `/terraform/modules/eks-client/template/consul.tpl`:

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

7. Open a connection to the listed `EXTERNAL-IP` DNS entry in your browser to see the connection success.

```log
http://a290ae604f3104037ae12c5d743eddc9-935877010.us-east-1.elb.amazonaws.com
```

## kubernetes-gs-observability

1. Content

- ./install-observability-suite.sh
- cp helm/consul-values-hcp-v3.yaml terraform/modules/eks-client/template/consul.tpl
- kubectl apply -f proxy/proxy-defaults.yaml
- terraform -chdir=terraform/ apply --auto-approve
- Check the Consul UI for metrics (Is this possible with HCP?)
- kubectl port-forward svc/grafana --namespace default 3000:3000
- [Grafana UI](http://localhost:3000/)
- kubectl port-forward svc/prometheus-server --namespace default 8888:80
- [Prometheus UI](http://localhost:8888/)
- kubectl port-forward svc/nginx --namespace default 8080:80
- [HashiCups UI](http://localhost:8080/)