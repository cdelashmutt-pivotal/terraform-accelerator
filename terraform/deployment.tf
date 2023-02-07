resource "kubernetes_namespace" "gitops" {
  metadata {
    name = "gitops"
  }
}

resource "kubernetes_cluster_role_binding" "gitops-default-sa-installer" {
  metadata {
    name = "gitops-default-sa-installer"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "tanzupackage-install-admin-role"
  }
  subject {
    kind      = "ServiceAccount"
    name      = "default"
    namespace = kubernetes_namespace.gitops.metadata[0].name
  }
}

resource "kubernetes_secret" "cluster-install-secrets" {
  metadata {
    name = "cluster-install-secrets"
    namespace = kubernetes_namespace.gitops.metadata[0].name
  }
  data = {
    "tanzunet_username" = var.tanzunet_username
    "tanzunet_password" = var.tanzunet_password
  }
}

resource "kubectl_manifest" "kapp-gitops-app" {
  depends_on = [tanzu-mission-control_cluster.attach_aks_cluster_with_kubeconfig]

  yaml_body  = <<YAML
    apiVersion: kappctrl.k14s.io/v1alpha1
    kind: App
    metadata:
      name: cluster-installs
      namespace: ${kubernetes_namespace.gitops.metadata[0].name}
    spec:
      serviceAccountName: default
      fetch:
      - git:
          url: https://github.com/cdelashmutt-pivotal/terraform-accelerator
          ref: origin/main
          subPath: cluster
      template:
      - ytt:
          valuesFrom:
          - secretRef:
              name: ${kubernetes_secret.cluster-install-secrets.metadata[0].name}
      deploy:
      - kapp: {}
    YAML
}