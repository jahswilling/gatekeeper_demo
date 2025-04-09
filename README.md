# **Terraform Module: Kubernetes Gatekeeper with Policies**  

This Terraform module installs **Gatekeeper** (Open Policy Agent's Kubernetes admission controller) and applies **custom policies** (ConstraintTemplates and Constraints) to enforce governance rules in your cluster.  

---

## **Features**  
✅ **Helm-based Installation** – Automatically deploys Gatekeeper using the official Helm chart.  
✅ **Policy Enforcement** – Applies custom policies (e.g., mandatory labels on namespaces).  
✅ **Precondition Checks** – Fails early if policy YAML files are missing.  
✅ **Terraform-managed** – All resources (Helm release, CRDs, policies) are managed via Terraform state.  

---

## **Prerequisites**  
- **Terraform** (`>= 1.9`)  
- **Kubernetes cluster** (access via `kubeconfig`)  
- **Helm provider** (for Gatekeeper installation) `> 2.12.1`

---

## **Usage**  

### **1. Clone/Add This Module**  
```sh
git clone https://github.com/Opsfleet/labs-terraform
cd /templates/aws/charts/system_charts/gatekeeper
```

### **2. Define Policy Files**  
Place your Gatekeeper policies in `manifests/gatekeeper/`:  
```
manifests/
└── gatekeeper/
    ├── required_labels_template.yaml         # ConstraintTemplate
    └── required_labels_constraint.yaml       # Constraint
    └── allowed_repos_template.yaml           # ConstraintTemplate
    └── allowed_repos_constraint.yaml         # Constraint
    └── resource_limits_constraint.yaml       # ConstraintTemplate
    └── resource_limits_constraint.yaml       # Constraint
```

### **3. Customize Variables (Optional)**  
Edit `variables.tf` if you need to parameterize policies (e.g., inject `var.cluster_name`).  

### **4. Deploy**  
```sh
terraform init
terraform plan
terraform apply
```

---

## **File Structure**  
```
terraform-gatekeeper/
├── main.tf                  # Helm + Kubernetes resources
├── variables.tf             # (Optional) Input variables
├── outputs.tf               # (Optional) Module outputs
├── manifests/
└── gatekeeper/
    ├── required_labels_template.yaml         # ConstraintTemplate
    └── required_labels_constraint.yaml       # Constraint
    └── allowed_repos_template.yaml           # ConstraintTemplate
    └── allowed_repos_constraint.yaml         # Constraint
    └── resource_limits_constraint.yaml       # ConstraintTemplate
    └── resource_limits_constraint.yaml       # Constraint
```

---

## **How It Works**  

### **1. Installs Gatekeeper via Helm**  
```hcl
resource "helm_release" "gatekeeper" {
  name       = "gatekeeper"
  repository = "https://open-policy-agent.github.io/gatekeeper/charts"
  chart      = "gatekeeper"
  version    = "3.13.0"
  namespace  = "gatekeeper-system"
  create_namespace = true
}
```

### **2. Applies Policies with Precondition Checks**  
- **Fails fast** if YAML files are missing.  
- **Applies in order**:  
  1. `ConstraintTemplate` (`require_labels.yaml`)  
  2. `Constraint` (`require_ns_labels.yaml`)  

```hcl
resource "kubernetes_manifest" "gatekeeper_constraint_template" {
  lifecycle {
    precondition {
      condition     = fileexists(local.constraint_template_path)
      error_message = "ERROR: Missing file at ${local.constraint_template_path}"
    }
  }
  # ...
}
```

---

## **Example Policies**  

### **1. `require_labels.yaml` (ConstraintTemplate)**  
```yaml
apiVersion: templates.gatekeeper.sh/v1
kind: ConstraintTemplate
metadata:
  name: k8srequiredlabels
spec:
  crd:
    spec:
      names:
        kind: K8sRequiredLabels
  targets:
    - target: admission.k8s.gatekeeper.sh
      rego: |
        package k8srequiredlabels
        violation[{"msg": msg, "details": {"missing_labels": missing}}] {
          provided := {label | input.review.object.metadata.labels[label]}
          required := {label | label := input.parameters.labels[_]}
          missing := required - provided
          count(missing) > 0
          msg := sprintf("You must provide labels: %v", [missing])
        }
```

### **2. `require_ns_labels.yaml` (Constraint)**  
```yaml
apiVersion: constraints.gatekeeper.sh/v1beta1
kind: K8sRequiredLabels
metadata:
  name: ns-must-have-gk
spec:
  match:
    kinds:
      - apiGroups: [""]
        kinds: ["Namespace"]
  parameters:
    labels: ["gatekeeper"]
```

---

## **Verification**  

### **Check Gatekeeper Deployment**  
```sh
kubectl get pods -n gatekeeper-system
```

### **Check Applied Policies**  
```sh
kubectl get constrainttemplates
kubectl get k8srequiredlabels
```

### **Test Enforcement**  
```sh
kubectl create ns test-ns --dry-run=server  # Should fail if label is missing
kubectl create ns test-ns --labels gatekeeper=enabled  # Should succeed
```

---

## **Cleanup**  
```sh
terraform destroy
```

---

## **Alternatives**  
- **[Kyverno](https://kyverno.io/)** – Policy engine using YAML (no Rego required).  
- **[OPA (Standalone)](https://www.openpolicyagent.org/)** – More flexible but complex.  

---

## **Contributing**  
1. Clone this repo branch out.  
2. Add new policies in `manifests/gatekeeper/`.  
3. Submit a PR!  

# gatekeeper_demo
