resource "helm_release" "gatekeeper" {
  name             = var.name
  repository       = var.repository
  chart            = var.name
  version          = var.chart_version
  namespace        = var.namespace
  create_namespace = var.namespace != "kube-system"
  wait             = true

  set {
    name  = "postInstall.labelNamespace.enabled"
    value = "true"
  }
}

# Wait for Gatekeeper pods to be ready
resource "null_resource" "wait_for_gatekeeper" {
  depends_on = [helm_release.gatekeeper]

  provisioner "local-exec" {
    command = <<-EOT
      kubectl wait --namespace ${var.namespace} \
        --for=condition=ready pod \
        --selector=control-plane=controller-manager \
        --timeout=300s
    EOT
  }
}

# ConstraintTemplates
resource "kubectl_manifest" "required_labels_template" {
  yaml_body = file(local.gatekeeper_policies.required_labels.template)
  
  lifecycle {
    precondition {
      condition     = fileexists(local.gatekeeper_policies.required_labels.template)
      error_message = "Missing ConstraintTemplate file at ${local.gatekeeper_policies.required_labels.template}"
    }
  }
  
  depends_on = [null_resource.wait_for_gatekeeper]
}

resource "kubectl_manifest" "allowed_repos_template" {
  yaml_body = file(local.gatekeeper_policies.allowed_repos.template)
  
  lifecycle {
    precondition {
      condition     = fileexists(local.gatekeeper_policies.allowed_repos.template)
      error_message = "Missing ConstraintTemplate file at ${local.gatekeeper_policies.allowed_repos.template}"
    }
  }
  
  depends_on = [null_resource.wait_for_gatekeeper]
}

resource "kubectl_manifest" "resource_limits_template" {
  yaml_body = file(local.gatekeeper_policies.resource_limits.template)
  
  lifecycle {
    precondition {
      condition     = fileexists(local.gatekeeper_policies.resource_limits.template)
      error_message = "Missing ConstraintTemplate file at ${local.gatekeeper_policies.resource_limits.template}"
    }
  }
  
  depends_on = [null_resource.wait_for_gatekeeper]
}

# Constraints
resource "kubectl_manifest" "required_labels_constraint" {
  yaml_body = file(local.gatekeeper_policies.required_labels.constraint)
  
  lifecycle {
    precondition {
      condition     = fileexists(local.gatekeeper_policies.required_labels.constraint)
      error_message = "Missing Constraint file at ${local.gatekeeper_policies.required_labels.constraint}"
    }
  }
  
  depends_on = [kubectl_manifest.required_labels_template]
}

resource "kubectl_manifest" "allowed_repos_constraint" {
  yaml_body = file(local.gatekeeper_policies.allowed_repos.constraint)
  
  lifecycle {
    precondition {
      condition     = fileexists(local.gatekeeper_policies.allowed_repos.constraint)
      error_message = "Missing Constraint file at ${local.gatekeeper_policies.allowed_repos.constraint}"
    }
  }
  
  depends_on = [kubectl_manifest.allowed_repos_template]
}

resource "kubectl_manifest" "resource_limits_constraint" {
  yaml_body = file(local.gatekeeper_policies.resource_limits.constraint)
  
  lifecycle {
    precondition {
      condition     = fileexists(local.gatekeeper_policies.resource_limits.constraint)
      error_message = "Missing Constraint file at ${local.gatekeeper_policies.resource_limits.constraint}"
    }
  }
  
  depends_on = [kubectl_manifest.resource_limits_template]
}