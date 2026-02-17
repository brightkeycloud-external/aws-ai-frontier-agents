locals {
  prefix = "${var.env}-${var.project}"

  tags = {
    env        = var.env
    costcenter = var.costcenter
    managed-by = "terraform"
    repo       = var.repo
    directory  = "kiro/devops-agent-demo"
  }
}
