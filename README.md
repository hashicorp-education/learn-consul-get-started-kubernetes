# learn-consul-get-started-kubernetes

## 01 - Why Consul on Kubernetes?

## 02 - Install Consul

- kind create cluster --config=kind/cluster.yaml
- helm install --values helm/consul-v1.yaml consul hashicorp/consul --create-namespace --namespace consul --version "0.46.1"
- kubectl port-forward svc/consul-ui --namespace consul 6443:443
- [Consul UI](https://localhost:6443/ui/)

## 03 - Install HashiCups

- kubectl apply --filename hashicups/v1/
- kubectl port-forward svc/nginx --namespace default 8080:80
- [HashiCups UI](http://localhost:8080/)

## 04 - Ingress with Consul on Kubernetes

- kubectl apply --kustomize "github.com/hashicorp/consul-api-gateway/config/crd?ref=v0.3.0"
- helm upgrade --values helm/consul-v2.yaml consul hashicorp/consul --namespace consul --version "0.46.1"
- kubectl apply --filename api-gw/consul-api-gateway.yaml --namespace consul && \
 kubectl wait --for=condition=ready gateway/api-gateway --namespace consul --timeout=90s && \
 kubectl apply --filename api-gw/routes.yaml --namespace consul
- kubectl apply --filename hashicups/v2/
- kubectl port-forward svc/consul-ui --namespace consul 6443:443
- [Consul UI](https://localhost:6443/ui/)
- [HashiCups UI](https://localhost:8443/)
- kubectl apply --filename hashicups/intentions/deny.yaml
- kubectl apply --filename hashicups/intentions/allow.yaml

## 05 - Observability with Consul on Kubernetes

- **Add Helm Repositories**
```sh
helm repo add prometheus
helm repo add grafana
helm repo add jaegertracing https://jaegertracing.github.io/helm-charts
```
- **Install Observability Suite**
```sh
chmod 755 install-observability-suite.sh && \
./install-observability-suite.sh
```
- helm upgrade --values helm/consul-v3.yaml consul hashicorp/consul --namespace consul --version "0.46.1"
- kubectl apply -f proxy/proxy-defaults-grpc.yaml
- kubectl apply -f hashicups/v3/

- kubectl port-forward svc/consul-ui --namespace consul 6443:443
- [Consul UI](https://localhost:6443/ui/)
- kubectl port-forward svc/grafana --namespace default 3000:3000
- [Grafana UI](http://localhost:3000/)
- ***Login with admin/admin***
- kubectl port-forward svc/simplest-query --namespace default 9999:16686
- [Jaeger UI](http://localhost:9999/)
- kubectl port-forward svc/prometheus-server --namespace default 8888:80
- [Prometheus UI](http://localhost:8888/)
- kubectl port-forward svc/nginx --namespace default 8080:80
- [HashiCups UI](http://localhost:8080/)


### Metrics testing - CLI

- ***public api - not exposing/merging metrics***
- kubectl exec -it public-api-78f66bddd8-wjhbh -c public-api -- wget -qO- 127.0.0.1:20200/metrics | tail -n 10
- ***frontend - not exposing/merging metrics***
- kubectl exec -it frontend-54bd899c74-tn2s8 -c frontend -- wget -qO- 127.0.0.1:20200/metrics | tail -n 10
- ***product api - SUCCESS !***
- kubectl exec -it product-api-7665d5c597-l9tqr -c product-api -- wget -qO- 127.0.0.1:20200/metrics | tail -n 10
- ***product api db - SUCCESS !***
- kubectl exec -it product-api-db-c99d599f6-8svff  -c postgres-exporter -- wget -qO- 127.0.0.1:20200/metrics | tail -n 10
- ***payments - SUCCESS !***
- kubectl exec -it payments-6fc9d744f4-8l6jg -c payments -- wget -qO- 127.0.0.1:20200/metrics | tail -n 10
- ***nginx - SUCCESS !***
- kubectl exec -it nginx-65d59b8f9b-z7v4w  -c nginx -- wget -qO- 127.0.0.1:20200/metrics | tail -n 10

### Envoy troubleshooting/diagnostics

- kubectl exec -it payments-6fc9d744f4-gjwlz  -c payments -- wget -qO- 127.0.0.1:19000/config_dump > output.txt
- kubectl exec -it payments-6fc9d744f4-gjwlz  -c payments -- curl -v http://127.0.0.1:19000/json -H 'Content-Type: application/json'
- kubectl exec -it payments-6888957c45-2vk9b  -c payments -- wget -qO- 127.0.0.1:19000/clusters