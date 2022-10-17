global:
  enabled: false
  name: consul
  datacenter: ${datacenter}
  image: "hashicorp/consul-enterprise:${consul_version}-ent"
  acls:
    manageSystemACLs: true
    bootstrapToken:
      secretName: ${cluster_id}-hcp
      secretKey: bootstrapToken
  tls:
    enabled: true
    enableAutoEncrypt: true
    caCert:
      secretName: ${cluster_id}-hcp
      secretKey: caCert
  gossipEncryption:
    secretName: ${cluster_id}-hcp
    secretKey: gossipEncryptionKey
  metrics:
    enabled: true
    enableAgentMetrics: true
    agentMetricsRetentionTime: "1m"

externalServers:
  enabled: true
  hosts: ${consul_hosts}
  httpsPort: 443
  useSystemRoots: true
  k8sAuthMethodHost: ${k8s_api_endpoint}

server:
  enabled: false

client:
  enabled: true
  join: ${consul_hosts}
  nodeMeta:
    terraform-module: "hcp-eks-client"

connectInject:
  enabled: true
  metrics:
    defaultEnabled: true
    defaultEnableMerging: true

controller:
  enabled: true

apiGateway:
  enabled: true
  image: "hashicorp/consul-api-gateway:0.4.0"
  managedGatewayClass:
    serviceType: LoadBalancer