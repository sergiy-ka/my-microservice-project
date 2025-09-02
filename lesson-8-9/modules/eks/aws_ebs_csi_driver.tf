# Create IAM OIDC Provider for IRSA
resource "aws_iam_openid_connect_provider" "oidc" {
  url = aws_eks_cluster.main.identity[0].oidc[0].issuer

  client_id_list = ["sts.amazonaws.com"]

  thumbprint_list = ["9e99a48a9960b14926bb7f3b02e22da2ecd6c6f9"]
}

# IAM role for EBS CSI Driver
resource "aws_iam_role" "ebs_csi_irsa_role" {
  name = "${var.cluster_name}-ebs-csi-irsa-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Federated = aws_iam_openid_connect_provider.oidc.arn
      },
      Action = "sts:AssumeRoleWithWebIdentity",
      Condition = {
        StringEquals = {
          "${replace(aws_eks_cluster.main.identity[0].oidc[0].issuer, "https://", "")}:sub" = "system:serviceaccount:kube-system:ebs-csi-controller-sa"
        }
      }
    }]
  })
}

# Attach the official policy to this role
resource "aws_iam_role_policy_attachment" "ebs_irsa_policy" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  role       = aws_iam_role.ebs_csi_irsa_role.name
}

# EKS Addon with bound IRSA IAM role
resource "aws_eks_addon" "ebs_csi_driver" {
  cluster_name             = aws_eks_cluster.main.name
  addon_name               = "aws-ebs-csi-driver"
  addon_version            = "v1.35.0-eksbuild.1"
  service_account_role_arn = aws_iam_role.ebs_csi_irsa_role.arn
  resolve_conflicts_on_update = "PRESERVE"

  depends_on = [
    aws_iam_openid_connect_provider.oidc,
    aws_iam_role_policy_attachment.ebs_irsa_policy
  ]
}