#!/bin/bash
# ─────────────────────────────────────────────────────────────
# Disc Player — EC2 Bootstrap Script
# Installs Docker + minikube, builds app image, deploys to K8s
# ─────────────────────────────────────────────────────────────
set -ex
exec > >(tee /var/log/user-data.log) 2>&1

echo ">>> [1/11] Updating system..."
apt-get update -y
apt-get install -y docker.io curl wget unzip socat jq

echo ">>> [2/11] Starting Docker..."
systemctl enable --now docker
usermod -aG docker ubuntu
# Ensure docker socket is accessible
chmod 666 /var/run/docker.sock

echo ">>> [3/11] Installing AWS CLI v2..."
curl -s "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o /tmp/awscliv2.zip
unzip -q /tmp/awscliv2.zip -d /tmp
/tmp/aws/install
rm -rf /tmp/awscliv2.zip /tmp/aws

echo ">>> [4/11] Installing kubectl..."
KUBECTL_VERSION=$(curl -Ls https://dl.k8s.io/release/stable.txt)
curl -LO "https://dl.k8s.io/release/$${KUBECTL_VERSION}/bin/linux/amd64/kubectl"
chmod +x kubectl
mv kubectl /usr/local/bin/

echo ">>> [5/11] Installing minikube..."
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
chmod +x minikube-linux-amd64
mv minikube-linux-amd64 /usr/local/bin/minikube

echo ">>> [6/11] Starting minikube (Docker driver)..."
su - ubuntu -c "minikube start --driver=docker --cpus=2 --memory=3072"
su - ubuntu -c "minikube addons enable metrics-server"

echo ">>> [7/11] Pulling app files from S3..."
su - ubuntu -c "mkdir -p /home/ubuntu/app/assets"
su - ubuntu -c "aws s3 cp s3://${s3_bucket}/index.html /home/ubuntu/app/ --region ${region}"
su - ubuntu -c "aws s3 cp s3://${s3_bucket}/assets/ /home/ubuntu/app/assets/ --recursive --region ${region}"

echo ">>> [8/11] Creating Dockerfile + nginx config..."
cat > /home/ubuntu/Dockerfile <<'DOCKERFILE'
FROM nginx:alpine
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY app/ /usr/share/nginx/html/
EXPOSE 80
DOCKERFILE

cat > /home/ubuntu/nginx.conf <<'NGINXCONF'
server {
    listen 80;
    server_name _;
    root /usr/share/nginx/html;
    index index.html;

    location / {
        try_files $uri $uri/ =404;
    }

    # Support range requests for video seeking
    location ~* \.(mp4)$ {
        add_header Accept-Ranges bytes;
    }
}
NGINXCONF

chown -R ubuntu:ubuntu /home/ubuntu/Dockerfile /home/ubuntu/nginx.conf /home/ubuntu/app

echo ">>> [9/11] Building Docker image inside minikube..."
su - ubuntu -c 'eval $(minikube docker-env) && docker build -t disc-player:latest -f /home/ubuntu/Dockerfile /home/ubuntu/'

echo ">>> [10/11] Deploying to Kubernetes..."

# Create Deployment manifest
cat > /home/ubuntu/deployment.yaml <<'K8SDEP'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: disc-player
  labels:
    app: disc-player
spec:
  replicas: 1
  selector:
    matchLabels:
      app: disc-player
  template:
    metadata:
      labels:
        app: disc-player
    spec:
      containers:
      - name: disc-player
        image: disc-player:latest
        imagePullPolicy: Never
        ports:
        - containerPort: 80
          name: http
        resources:
          requests:
            cpu: "100m"
            memory: "128Mi"
          limits:
            cpu: "500m"
            memory: "256Mi"
K8SDEP

# Create Service manifest (LoadBalancer)
cat > /home/ubuntu/service.yaml <<'K8SSVC'
apiVersion: v1
kind: Service
metadata:
  name: disc-player
  labels:
    app: disc-player
spec:
  type: LoadBalancer
  selector:
    app: disc-player
  ports:
  - port: 80
    targetPort: 80
    protocol: TCP
    name: http
K8SSVC

# Create HPA manifest
cat > /home/ubuntu/hpa.yaml <<'K8SHPA'
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: disc-player-hpa
  labels:
    app: disc-player
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: disc-player
  minReplicas: 1
  maxReplicas: 5
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 50
K8SHPA

chown ubuntu:ubuntu /home/ubuntu/deployment.yaml /home/ubuntu/service.yaml /home/ubuntu/hpa.yaml

# Apply manifests
su - ubuntu -c "kubectl apply -f /home/ubuntu/deployment.yaml"
su - ubuntu -c "kubectl apply -f /home/ubuntu/service.yaml"
su - ubuntu -c "kubectl apply -f /home/ubuntu/hpa.yaml"

# Wait for pod to be ready
su - ubuntu -c "kubectl wait --for=condition=ready pod -l app=disc-player --timeout=180s"

echo ">>> [11/11] Setting up minikube tunnel and socat forwarding..."

# Create systemd service for minikube tunnel
cat > /etc/systemd/system/minikube-tunnel.service <<'SYSTEMD'
[Unit]
Description=Minikube Tunnel
After=network.target

[Service]
Type=simple
User=root
Environment="HOME=/home/ubuntu"
Environment="KUBECONFIG=/home/ubuntu/.kube/config"
ExecStart=/usr/local/bin/minikube tunnel
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
SYSTEMD

# Create systemd service for persistent socat port forwarding to LoadBalancer External IP
cat > /etc/systemd/system/kube-socat-forward.service <<'SYSTEMD'
[Unit]
Description=Socat TCP Forwarding to LoadBalancer — Disc Player
After=minikube-tunnel.service
StartLimitIntervalSec=0

[Service]
Type=simple
User=root
Environment="KUBECONFIG=/home/ubuntu/.kube/config"
ExecStart=/bin/sh -c 'while [ -z "$(/usr/local/bin/kubectl get svc disc-player -o jsonpath=\"{.status.loadBalancer.ingress[0].ip}\" 2>/dev/null)" ]; do sleep 2; done && LB_IP=$(/usr/local/bin/kubectl get svc disc-player -o jsonpath=\"{.status.loadBalancer.ingress[0].ip}\") && exec /usr/bin/socat TCP4-LISTEN:${app_port},fork,reuseaddr TCP4:$LB_IP:80'
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
SYSTEMD

systemctl daemon-reload
systemctl enable --now minikube-tunnel
systemctl enable --now kube-socat-forward

echo "==========================================="
echo "  DEPLOYMENT COMPLETE"
echo "  App listening on port ${app_port}"
echo "==========================================="
echo "$(date)" > /home/ubuntu/deploy-complete
