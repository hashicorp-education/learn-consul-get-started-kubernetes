helm install --values helm/jaeger.yaml jaeger jaegertracing/jaeger
kubectl rollout status deployment jaeger --namespace default --timeout=90s && \
helm install --values helm/prometheus.yaml prometheus prometheus-community/prometheus --version "15.5.3" && \
kubectl rollout status deployment prometheus-server --namespace default --timeout=90s && \
helm install loki grafana/loki-stack --version "2.6.5"
kubectl rollout status statefulset loki --namespace default --timeout=90s && \
helm install --values helm/grafana.yaml grafana grafana/grafana --version "6.23.1"
kubectl rollout status deployment grafana --namespace default --timeout=90s && \
echo "#######################################" && \
echo "Observability Suite Deployment Complete" && \
echo "#######################################"