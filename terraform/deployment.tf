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
      tap:
        profile: ${var.tap_profile}
        domain: ${azurerm_dns_zone.dns.name}
        view_cluster_domain: ${var.view_cluster_domain}
      registry:
        url: ${azurerm_container_registry.default.login_server}
        username: ${azurerm_container_registry.default.admin_username}
        password: ${azurerm_container_registry.default.admin_password}
      gitops:
        repo: ${var.gitops_repo_url}
        ref: origin/${var.gitops_repo_branch}
        branch: ${var.gitops_repo_branch}
        subPath: ${var.gitops_repo_subPath}
      azure:
        tenant_id: ${data.azurerm_client_config.current.tenant_id}
        subscription_id: ${data.azurerm_client_config.current.subscription_id}
        external_dns:
          resource_group: ${azurerm_resource_group.default.name}
          client_id: ${azuread_application.external_dns.application_id}
          client_secret: ${azuread_application_password.external_dns.value}

    EOF
  }
}

# TODO: Remove this delay after TMC Terraform provider supports applying packages
resource "time_sleep" "wait_for_package_extension" {
  depends_on = [tanzu-mission-control_cluster.attach_aks_cluster_with_kubeconfig]

  create_duration = "40s"
}

resource "kubectl_manifest" "kapp-gitops-app" {
  depends_on = [tanzu-mission-control_cluster.attach_aks_cluster_with_kubeconfig, 
    time_sleep.wait_for_package_extension,
    kubernetes_cluster_role_binding.gitops-default-sa-installer,
    kubernetes_namespace.gitops,
    azurerm_role_assignment.resource_group_reader,
    azurerm_role_assignment.dns_contributer]
  wait = true
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

resource "kubernetes_namespace" "tap-gui" {
  metadata {
    name = "tap-gui"
  }
}

resource "kubernetes_service_account" "tap-gui-viewer" {
  metadata {
    name = "tap-gui-viewer"
    namespace = kubernetes_namespace.tap-gui.metadata[0].name
  }
}

resource "kubernetes_secret_v1" "tap-gui-viewer" {
  metadata {
    name = kubernetes_service_account.tap-gui-viewer.metadata[0].name
    namespace = kubernetes_namespace.tap-gui.metadata[0].name
    annotations = {
      "kubernetes.io/service-account.name" = kubernetes_service_account.tap-gui-viewer.metadata[0].name
    }
  }

  type = "kubernetes.io/service-account-token"
}

resource "kubernetes_cluster_role" "k8s-reader" {
  metadata {
    name = "k8s-reader"
  }
  rule {
    api_groups = [""]
    resources  = ["pods", "pods/log", "services", "configmaps", "limitranges"]
    verbs      = ["get", "watch", "list"]
  }
  rule {
    api_groups = ["metrics.k8s.io"]
    resources  = ["pods"]
    verbs      = ["get", "watch", "list"]
  }
  rule {
    api_groups = ["apps"]
    resources  = ["deployments", "replicasets", "statefulsets", "daemonsets"]
    verbs      = ["get", "watch", "list"]
  }
  rule {
    api_groups = ["autoscaling"]
    resources  = ["horizontalpodautoscalers"]
    verbs      = ["get", "watch", "list"]
  }
  rule {
    api_groups = ["networking.k8s.io"]
    resources  = ["ingresses"]
    verbs      = ["get", "watch", "list"]
  }
  rule {
    api_groups = ["networking.internal.knative.dev"]
    resources  = ["serverlessservices"]
    verbs      = ["get", "watch", "list"]
  }
  rule {
    api_groups = ["autoscaling.internal.knative.dev"]
    resources  = ["podautoscalers"]
    verbs      = ["get", "watch", "list"]
  }
  rule {
    api_groups = ["serving.knative.dev"]
    resources  = ["configurations", "revisions", "routes", "services"]
    verbs      = ["get", "watch", "list"]
  }
  rule {
    api_groups = ["carto.run"]
    resources  = ["clusterconfigtemplates", "clusterdeliveries", 
      "clusterdeploymenttemplates", "clusterimagetemplates", 
      "clusterruntemplates", "clustersourcetemplates", "clustersupplychains",
      "clustertemplates", "deliverables", "runnables", "workloads"]
    verbs      = ["get", "watch", "list"]
  }
  rule {
    api_groups = ["source.toolkit.fluxcd.io"]
    resources  = ["gitrepositories"]
    verbs      = ["get", "watch", "list"]
  }
  rule {
    api_groups = ["source.apps.tanzu.vmware.com"]
    resources  = ["imagerepositories", "mavenartifacts"]
    verbs      = ["get", "watch", "list"]
  }
  rule {
    api_groups = ["conventions.apps.tanzu.vmware.com"]
    resources  = ["podintents"]
    verbs      = ["get", "watch", "list"]
  }
  rule {
    api_groups = ["kpack.io"]
    resources  = ["images", "builds"]
    verbs      = ["get", "watch", "list"]
  }
  rule {
    api_groups = ["scanning.apps.tanzu.vmware.com"]
    resources  = ["sourcescans", "imagescans", "scanpolicies"]
    verbs      = ["get", "watch", "list"]
  }
  rule {
    api_groups = ["tekton.dev"]
    resources  = ["taskruns", "pipelineruns"]
    verbs      = ["get", "watch", "list"]
  }
  rule {
    api_groups = ["kappctrl.k14s.io"]
    resources  = ["apps"]
    verbs      = ["get", "watch", "list"]
  }
  rule {
    api_groups = ["batch"]
    resources  = ["jobs","cronjobs"]
    verbs      = ["get", "watch", "list"]
  }
  rule {
    api_groups = ["conventions.carto.run"]
    resources  = ["podintents"]
    verbs      = ["get", "watch", "list"]
  }
}

resource "kubernetes_cluster_role_binding" "tap-gui-read-k8s" {
  metadata {
    name = "tap-gui-read-k8s"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.k8s-reader.metadata[0].name
  }
  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.tap-gui-viewer.metadata[0].name
    namespace = kubernetes_namespace.gitops.metadata[0].name
  }
}