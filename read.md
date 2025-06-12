terraform output private_key > ../my_key

kubectl create namespace "${KARPENTER_NAMESPACE}" || true
kubectl create -f \
    "https://raw.githubusercontent.com/aws/karpenter-provider-aws/v1.5.0/pkg/apis/crds/karpenter.sh_nodepools.yaml"
kubectl create -f \
    "https://raw.githubusercontent.com/aws/karpenter-provider-aws/v1.5.0/pkg/apis/crds/karpenter.k8s.aws_ec2nodeclasses.yaml"
kubectl create -f \
    "https://raw.githubusercontent.com/aws/karpenter-provider-aws/v1.5.0/pkg/apis/crds/karpenter.sh_nodeclaims.yaml"
kubectl apply -f karpenter.yaml



aws ecr-public get-login-password --region us-east-1 --profile ankush-katkurwar30 | helm registry login --username AWS --password-stdin public.ecr.aws