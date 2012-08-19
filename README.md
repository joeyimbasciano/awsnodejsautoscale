# AWS Autoscaling with NodeJS

Proof of concept using NodeJS and AWS to demonstrate the capabilities of AWS autoscaling groups.

This guide outlines how to create a NodeJS service that adds additional resources when CPU utilization is greater than 80% for 2 consecutive minutes, and removes resources when the CPU Utiliation is less than 20% for consecutive 2 minutes.

## Run the Proof of Concept

Install siege
```
sudo apt-get install siege
```

Run run_siege.sh
```
./run_siege.sh
```

## Triggers for Adding Resources:
1. Basic Health Check: A basic HTTP request to / should respond with 200 OK. If it does not, the instance is not considered healthy. This check runs on all instances within the AutoScaling group.

2. High CPU Utilization Check: A CloudWatch check that is monitoring one instance in the AutoScaling group. When CPU Utilization is greater than 80% for 2 consecutive minutes a scale-up event is triggered, launching another instance.

3. Low CPU Utilization Check: A CloudWatch check that is monitoring the same instance as the High CPU Check. When CPU Utilization is less than 20% for 2 consecutive minutes a scale-down event is triggered, terminating one instance.

## Setup

This is a rough outline of what is required to re-create this setup.

### Prereqs

1. Create security group with port 22 and 8000 TCP open.
2. Create ELB

### Bundle Base AMI

1. Launch Ubuntu 12.04 AMI
2. Install NodeJS
3. Create unprivileged nodejs user.
4. Install node_load.js to /home/nodejs/node_load.js
5. Install node.conf to /etc/init/node.conf
6. Bundle AMI

### Autoscaling Config

#### Launch Config

This config is used when more nodes are needed for autoscaling.

```
as-create-launch-config nodeload --image-id ami-770bbe1e --instance-type t1.micro --key joeyi --group node_scale
```

#### AutoScaling Group

This group is used to set:

1. Max running instances.
2. Min running instances.
3. ELB Used
4. Basic Health Check
5. Graceperiod before determining an instance is unhealthy.

```
as-create-auto-scaling-group nodeload --launch-configuration nodeload --availability-zones us-east-1a --min-size 1 --max-size 3 --load-balancers nodeload --health-check-type ELB --grace-period 120
```

#### AutoScaling Policy

A policy that can be triggered from CloudWatch to launch additional resources.

```
as-put-scaling-policy --auto-scaling-group nodeload --name scale-up --adjustment 1 --type ChangeInCapacity --cooldown 60
```

A policy that can be triggered from CloudWatch to terminate resources.

```
as-put-scaling-policy --auto-scaling-group nodeload --name scale-dn "--adjustment=-1" --type ChangeInCapacity --cooldown 60
```

#### CloudWatch Triggers

These are triggers for when to add and remove capacity from the autoscaling group.

A limitation of this proof of concept is that the triggers are only installed on one instance. If the instance is terminated then the triggers will not work.


Scale up when there is more than 80% CPU utilization.

```
mon-put-metric-alarm --alarm-name node-scale-up --alarm-description "Scale up at 80% load" --metric-name CPUUtilization --namespace AWS/EC2 --statistic Average  --period 60 --threshold 80 --comparison-operator GreaterThanThreshold --dimensions InstanceId=i-8b1046f0 --evaluation-periods 2  --unit Percent --alarm-actions arn:aws:autoscaling:us-east-1:940982398162:scalingPolicy:fe9d632b-7c2a-4d32-ae74-7ef9aa1a3bf6:autoScalingGroupName/nodeload:policyName/scale-up
```

Scale down when there is less than 20% CPU utilization.

```
mon-put-metric-alarm --alarm-name node-scale-dn --alarm-description "Scale down at 20% load" --metric-name CPUUtilization --namespace AWS/EC2 --statistic Average --period 60 --threshold 20 --comparison-operator LessThanThreshold --dimensions InstanceId=i-8b1046f0 --evaluation-periods 2 --unit Percent --alarm-actions arn:aws:autoscaling:us-east-1:940982398162:scalingPolicy:8f24c56b-76db-4df5-906b-a34f1c390d9d:autoScalingGroupName/nodeload:policyName/scale-dn
```