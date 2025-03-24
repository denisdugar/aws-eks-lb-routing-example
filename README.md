# aws-eks-lb-routing-example

This repo is an example of how to implement NLB/ALB routing in EKS cluster with several services. In two directories you will find the whole code for creating EKS cluster, deployments and additional resources for implementing infra with network routing.

## Prerequisites

1. eksctl
2. kubectl
3. aws cli
4. helm
5. terraform

## Network Load Balancer
For creating routing in EKS with TCP protocol go to nlb directory:
```bash
cd nlb/
```

Apply terraform code with network resources for cluster
```bash
terraform init
terraform apply
```

After it is applied, please paste vpc, subnets and sg IDs into cluster.yaml file. After that, you can create EKS cluster
```bash
eksctl create cluster -f cluster.yaml
```

It will take a couple of minutes and EKS cluster will be created. 
Now you can run the deployment with 2 applications (nginx and apache) and 2 services
```bash
kubectl apply -f deployments.yaml
```

After that go to the AWS console -> EC2 take all IDs of the newly created instances and paste them into variables.tf file
Uncomment resources aws_lb_target_group_attachment in main.tf file and apply changes
```bash
terraform apply
```
It will add all nodes to the target groups. Wait 5-10 minutes until you can use your NLB.
After couple of minutes all instances in Target groups should be Healthy and you can use your NLB URL to reach applications. It will work like that:

nlb-url.com:80 -> nginx

nlb-url.com:81 -> apache


## Application Load Balancer
For creating routing in EKS with HTTP protocol go to alb directory:
```bash
cd alb/
```

Apply terraform code with network resources for cluster
```bash
terraform init
terraform apply
```

After it is applied, please paste vpc and subnet IDs into cluster.yaml file. After that, you can create EKS cluster
```bash
eksctl create cluster -f cluster.yaml
```

It will take a couple of minutes and EKS cluster will be created. 
Now you can run the deployment with 2 applications (nginx and apache) and 2 services
```bash
kubectl apply -f deployments.yaml
```

After that, we need to install aws-load-balancer-controller. For that we need to create policy in AWS
```bash
POLICY_ARN=$(aws iam create-policy \
  --policy-name AWSLoadBalancerControllerIAMPolicy \
  --policy-document file://iam-policy.json \
  --query 'Policy.Arn' \
  --output text)
```

Create service account in kubernetes (paste your cluster name. It is "my-eks-cluster" in the cluster manifest by default)
```bash
eksctl create iamserviceaccount \
  --cluster <cluster_name> \
  --namespace kube-system \
  --name aws-load-balancer-controller \
  --attach-policy-arn "$POLICY_ARN" \
  --override-existing-serviceaccounts \
  --approve
```

Add helm repo and install aws controller (paste your cluster name, aws region and vpc id)
```bash
helm repo add eks https://aws.github.io/eks-charts
helm repo update

helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=<cluster_name> \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller \
  --set region=<aws_region> \
  --set vpcId=<cluster_vpc_id>
```

Now we can check if controller is installed by running this command
```bash
kubectl get deployment -n kube-system aws-load-balancer-controller
```
You should see deployment with 2 running pods

Now we are ready to apply our applications to EKS cluster
```bash
kubectl apply -f deployments.yaml
```

And create ingress for routing traffic
```bash
kubectl apply -f ingress.yaml
```

Wait 5-10 minutes, go to AWS console, find the newly created Application Load Balancer, take URL, and try to reach applications:

alb-url.com/nginx -> nginx

alb-url.com/apache -> apache
