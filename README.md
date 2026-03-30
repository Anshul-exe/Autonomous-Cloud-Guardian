# Autonomous-Cloud-Guardian

## A FinOps and DevSecOps Project
<img width="574" height="1135" alt="mermaid-diagram" src="https://github.com/user-attachments/assets/caade9ca-c58a-4ee9-ad6e-5f853e0e52b7" />

## Terraform SSH IP handling
SSH ingress now auto-detects your current public IP at `terraform plan/apply` time and uses it as `/32`.

If needed, you can still override it manually:

`terraform plan -var="my_ip=<your-public-ip>/32"`
