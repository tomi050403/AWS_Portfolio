#!/bin/bash

# ネットワークスタック作成
aws cloudformation create-stack \
    --stack-name Flask-APP-Network \
    --template-body file://Flask-APP_01_Network.yml \
    --capabilities CAPABILITY_NAMED_IAM

# スタック作成完了を待機
aws cloudformation wait stack-create-complete --stack-name Flask-APP-Network

# セキュリティスタック作成
aws cloudformation create-stack \
    --stack-name Flask-APP-Security \
    --template-body file://Flask-APP_02_Security.yml \
    --capabilities CAPABILITY_NAMED_IAM

# スタック作成完了を待機
aws cloudformation wait stack-create-complete --stack-name Flask-APP-Security

# アプリケーションスタック作成
aws cloudformation create-stack \
    --stack-name Flask-APP-Application \
    --template-body file://Flask-APP_03_Application.yml \
    --capabilities CAPABILITY_NAMED_IAM

# スタック作成完了を待機
aws cloudformation wait stack-create-complete --stack-name Flask-APP-Application

# アプリケーションスタック作成
aws cloudformation create-stack \
    --stack-name Flask-APP-Application-RDS \
    --template-body file://Flask-APP_04_Application_RDS.yml \
    --capabilities CAPABILITY_NAMED_IAM

# スタック作成完了を待機
aws cloudformation wait stack-create-complete --stack-name Flask-APP-Application-RDS

echo "All stacks created successfully."

aws ec2 describe-instances \
  --filters "Name=instance-state-name,Values=pending,running,stopping,stopped" \
  --query 'Reservations[*].Instances[*].[Tags[?Key==`Name`].Value|[0], InstanceId, State.Name]' \
  --output table
  