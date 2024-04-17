#!/bin/bash
# This submission should push a dockerfile to artifact registry
buildId=$(echo $RANDOM | md5sum | head -c 8)
topicName="topic_$buildId"
subscriptionName="subscription-$buildId"
if ! gcloud pubsub topics create "$topicName"; then
    echo "Topic $topicName already exists"
fi

if ! gcloud pubsub subscriptions create "$subscriptionName" --topic "$topicName"; then
    echo "Subscription $subscriptionName already exists"
fi

gcloud builds submit . --config cloudbuild.yaml --substitutions "_GIT_CLONE_URL=https://github.com/brianpipeline/test-node.git,_GIT_REPOSITORY_NAME="test-node",_GIT_REF="refs/heads/main",_GIT_HEAD_SHA="8f15568532099dba3a04eb1b74859f03046e7bca",_REPLY_TOPIC=\"projects/cloud-build-pipeline-396819/topics/$topicName\"" --region=us-central1

message=$(gcloud pubsub subscriptions pull --auto-ack "$subscriptionName" --format='value(message.data)' 2>/dev/null)
gcloud pubsub topics delete "$topicName"
gcloud pubsub subscriptions delete "$subscriptionName"
if [[ "$message" == "Pipeline succeeded." ]]; then
    echo "Received Message: $message"
else
    exit 1
fi
