# Getting Started with Consul on Kubernetes

## 01 - Install Consul

- kind create cluster --config=kind/cluster.yaml
- helm install --values helm/consul-values-v1.yaml consul hashicorp/consul --create-namespace --namespace consul --version "0.48.0"
- kubectl port-forward svc/consul-ui --namespace consul 6443:443
- [Consul UI](https://localhost:6443/ui/)

## 02 - Install HashiCups

- kubectl apply --filename hashicups/v1/
- kubectl apply --filename hashicups/intentions/allow.yaml
- kubectl port-forward svc/nginx --namespace default 8080:80
- [HashiCups UI](http://localhost:8080/)

## 03 - Ingress with Consul on Kubernetes

- kubectl apply --kustomize "github.com/hashicorp/consul-api-gateway/config/crd?ref=v0.4.0"
- helm upgrade --values helm/consul-values-v2.yaml consul hashicorp/consul --namespace consul --version "0.48.0"
- kubectl apply --filename api-gw/consul-api-gateway.yaml --namespace consul && \
 kubectl wait --for=condition=ready gateway/api-gateway --namespace consul --timeout=90s && \
 kubectl apply --filename api-gw/routes.yaml --namespace consul
- kubectl apply --filename hashicups/v2/
- kubectl port-forward svc/consul-ui --namespace consul 6443:443
- [Consul UI](https://localhost:6443/ui/)
- [HashiCups UI](https://localhost:8443/)

## 04 - Observability with Consul on Kubernetes

- helm upgrade --values helm/consul-values-v3.yaml consul hashicorp/consul --namespace consul --version "0.48.0"
- kubectl apply -f proxy/proxy-defaults.yaml
- kubectl delete --filename hashicups/v1/ && \
 kubectl apply --filename hashicups/v1/
- ./install-observability-suite.sh
- kubectl port-forward svc/consul-ui --namespace consul 6443:443
- [Consul UI](https://localhost:6443/ui/)
- kubectl port-forward svc/grafana --namespace default 3000:3000
- [Grafana UI](http://localhost:3000/)
- kubectl port-forward svc/prometheus-server --namespace default 8888:80
- [Prometheus UI](http://localhost:8888/)
- kubectl port-forward svc/nginx --namespace default 8080:80
- [HashiCups UI](http://localhost:8080/)
