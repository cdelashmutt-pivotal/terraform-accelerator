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
    "inline-values" : <<EOF
      tanzunet_username: ${var.tanzunet_username}
      tanzunet_password: ${var.tanzunet_password}
      tap_profile: ${var.tap_profile}
      registry:
        url: ${azurerm_container_registry.default.login_server}
        username: ${azurerm_container_registry.default.admin_username}
        password: ${azurerm_container_registry.default.admin_password}
      gitops:
        repo: ${var.gitops_repo_url}
        ref: origin/${var.gitops_repo_branch}
        branch: ${var.gitops_repo_branch}
        subPath: ${var.gitops_repo_subPath}
    EOF
  }
}

# TODO: Remove this delay after TMC Terraform provider supports applying packages
resource "time_sleep" "wait_60_seconds" {
  depends_on = [tanzu-mission-control_cluster.attach_aks_cluster_with_kubeconfig]

  create_duration = "60s"
}

resource "kubectl_manifest" "kapp-gitops-app" {
  depends_on = [tanzu-mission-control_cluster.attach_aks_cluster_with_kubeconfig, time_sleep.wait_60_seconds]

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
          url: ${var.gitops_repo_url}
          ref: origin/${var.gitops_repo_branch}
          subPath: ${var.gitops_repo_subPath}
      template:
      - ytt:
          valuesFrom:
          - secretRef:
              name: ${kubernetes_secret.cluster-install-secrets.metadata[0].name}
      deploy:
      - kapp: {}
    YAML
}