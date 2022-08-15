# learn-consul-get-started-kubernetes

## 01 - Why Consul on Kubernetes?

## 02 - Install Consul and a Demo Application

- kind create cluster --config=kind/cluster.yaml
- helm install --values helm/consul-v1.yaml consul hashicorp/consul --create-namespace --namespace consul --version "0.46.1"
- kubectl apply --filename hashicups/v1/
  
- kubectl port-forward svc/consul-ui --namespace consul 6443:443
- [Consul UI](https://localhost:6443/ui/)
- kubectl port-forward svc/nginx --namespace default 8080:80
- [HashiCups UI](http://localhost:8080/)

## 03 - Ingress with Consul on Kubernetes

- kubectl apply --kustomize "github.com/hashicorp/consul-api-gateway/config/crd?ref=v0.3.0"
- helm upgrade --values helm/consul-v2.yaml consul hashicorp/consul --namespace consul --version "0.46.1"
- kubectl apply --filename api-gw/consul-api-gateway.yaml --namespace consul && \
 kubectl wait --for=condition=ready gateway/api-gateway --namespace consul --timeout=90s && \
 kubectl apply --filename api-gw/routes.yaml --namespace consul
- kubectl apply --filename hashicups/v2/
  
- kubectl port-forward svc/consul-ui --namespace consul 6443:443
- [Consul UI](https://localhost:6443/ui/)
- [HashiCups UI](https://localhost:8443/)

## 04 - Observability with Consul on Kubernetes

- **Install Observability Suite**
```sh
kubectl apply --filename https://github.com/cert-manager/cert-manager/releases/download/v1.9.1/cert-manager.yaml && \
kubectl rollout status deployment cert-manager --namespace cert-manager --timeout=90s && \
kubectl create namespace observability && \
kubectl apply --filename https://github.com/jaegertracing/jaeger-operator/releases/download/v1.36.0/jaeger-operator.yaml -n observability && \
kubectl rollout status deployment jaeger-operator --namespace observability --timeout=90s && \
kubectl apply -f helm/jaeger-allinone.yaml && \
kubectl rollout status deployment simplest --namespace default --timeout=90s && \
helm install --values helm/prometheus-stack.yaml prometheus prometheus-community/prometheus --version "15.5.3" && \
kubectl rollout status deployment prometheus-server --namespace default --timeout=90s && \
helm install loki grafana/loki-stack --version "2.6.5"
kubectl rollout status statefulset loki --namespace default --timeout=90s && \
helm install --values helm/grafana.yaml grafana grafana/grafana --version "6.23.1"
kubectl rollout status deployment grafana --namespace default --timeout=90s && \
echo "#################################################################################" && \
echo "Observability Suite Deployment Complete"
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


### prometheus operator test
- kubectl apply --server-side -f https://github.com/prometheus-operator/prometheus-operator/releases/download/v0.58.0/bundle.yaml
- must add annotations at this point

### kube-prometheus test
- kubectl apply --server-side -k https://github.com/prometheus-operator/kube-prometheus
- kubectl port-forward svc/grafana --namespace monitoring 3000:3000
- [Grafana UI](http://localhost:3000/)
- ***Login with admin/admin***