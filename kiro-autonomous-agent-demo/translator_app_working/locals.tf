locals {
  prefix = "${var.env}-${var.project}"

  # Discover latest Claude Haiku model dynamically
  # Filter to base Haiku models (exclude context-window variants like :48k, :200k)
  haiku_base_models = {
    for m in data.aws_bedrock_foundation_models.anthropic.model_summaries :
    regex("([0-9]{8})", m.model_id)[0] => m.model_id
    if can(regex("haiku", lower(m.model_name))) && can(regex("^anthropic\\.claude[^:]+v1:0$", m.model_id))
  }
  latest_date      = reverse(sort(keys(local.haiku_base_models)))[0]
  bedrock_model_id = local.haiku_base_models[local.latest_date]

  # Newer Bedrock models require inference profiles for on-demand invocation.
  # The US cross-region inference profile ID is always "us.<model_id>".
  # PREREQUISITE: The model's Marketplace agreement must be accepted in the
  # deployment region. Use `aws bedrock create-foundation-model-agreement`
  # if you get AccessDeniedException about Marketplace actions.
  bedrock_inference_profile_id = "us.${local.bedrock_model_id}"

  tags = {
    env        = var.env
    costcenter = var.costcenter
    managed-by = "terraform"
    repo       = var.repo
    directory  = "kiro-autonomous-agent-demo"
  }
}
