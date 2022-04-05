
resource "helm_release" "metrics_server" {
  name       = "metrics-server"
  repository = local.helm_repository.metrics_server
  chart      = "metrics-server"
  version    = "3.8.2"
  namespace  = kubernetes_namespace.acme_namespace.id
  wait       = false

  values = [
    file("${path.module}/chart-values/metrics-server.yaml"),
  ]

}