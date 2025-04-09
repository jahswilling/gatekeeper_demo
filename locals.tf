locals {
  gatekeeper_policies = {
    required_labels = {
      template   = "${path.module}/manifests/gatekeeper/required_labels_template.yaml"
      constraint = "${path.module}/manifests/gatekeeper/required_labels_constraint.yaml"
    }
    allowed_repos = {
      template   = "${path.module}/manifests/gatekeeper/allowed_repos_template.yaml"
      constraint = "${path.module}/manifests/gatekeeper/allowed_repos_constraint.yaml"
    }
    resource_limits = {
      template   = "${path.module}/manifests/gatekeeper/resource_limits_template.yaml"
      constraint = "${path.module}/manifests/gatekeeper/resource_limits_constraint.yaml"
    }
  }
}