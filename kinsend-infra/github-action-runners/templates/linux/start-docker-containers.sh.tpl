#!/bin/bash

sudo yum install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm
sudo yum install -y awscli jq amazon-efs-utils zip unzip htop mc

sudo amazon-linux-extras install docker
sudo service docker start

sudo systemctl status amazon-ssm-agent
sudo systemctl enable amazon-ssm-agent
sudo systemctl start amazon-ssm-agent

cd /opt && \
  curl http://aws-cloudwatch.s3.amazonaws.com/downloads/CloudWatchMonitoringScripts-1.2.1.zip -O  && \
  unzip CloudWatchMonitoringScripts-1.2.1.zip && \
  rm -f CloudWatchMonitoringScripts-1.2.1.zip && \
  echo "*/5 * * * * /opt/aws-scripts-mon/mon-put-instance-data.pl --mem-used-incl-cache-buff --mem-util --disk-space-util --disk-path=/ --from-cron" | crontab -

# Note that this isn't actually being used, but it's currently useful for debugging
# TODO: This should be removed once we're confident that the runner is working well.
cat > /usr/local/bin/getpass.sh <<EOF
#!/bin/bash
echo ${github_token}
EOF

chmod +x /usr/local/bin/getpass.sh

# Login to ECR
$(aws ecr get-login --region us-east-1 --no-include-email)

docker run -d --restart always --name github-runner1 \
  -e DISABLE_AUTO_UPDATE="true" \
  -e RUNNER_WORKDIR="/actions-runner" \
  -e ACCESS_TOKEN="${github_token}" \
  -e RUNNER_SCOPE="org" \
  -e ORG_NAME="kinsend" \
  -e LABELS="ks-linux" \
  -v /var/run/docker.sock:/var/run/docker.sock \
  ${runner_image}:${runner_image_version}

docker run -d --restart always --name github-runner2 \
  -e DISABLE_AUTO_UPDATE="true" \
  -e RUNNER_WORKDIR="/actions-runner" \
  -e ACCESS_TOKEN="${github_token}" \
  -e RUNNER_SCOPE="org" \
  -e ORG_NAME="kinsend" \
  -e LABELS="ks-linux" \
  -v /var/run/docker.sock:/var/run/docker.sock \
  ${runner_image}:${runner_image_version}
