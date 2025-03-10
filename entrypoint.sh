#!/bin/sh
set -e

echo "Setting up SSH directory"
SSH_PATH="$HOME/.ssh"
mkdir -p "$SSH_PATH"
chmod 700 "$SSH_PATH"

echo "Saving SSH key"
echo "$PRIVATE_KEY" > "$SSH_PATH/deploy_key"
chmod 600 "$SSH_PATH/deploy_key"

echo "Adding dokku as a git remote"

GIT_SSH_COMMAND="git remote add dokku@$HOST:$PROJECT &&"

GIT_COMMAND="$GIT_COMMAND git push dokku@$HOST:$PROJECT"



if [ -n "$BRANCH" ]; then
    git checkout dokku/$BRANCH
    GIT_COMMAND="$GIT_COMMAND $BRANCH:master"
else
    GIT_COMMAND="$GIT_COMMAND HEAD:master"
fi

if [ -n "$FORCE_DEPLOY" ]; then
    echo "Enabling force deploy"
    GIT_COMMAND="$GIT_COMMAND --force"
fi

GIT_SSH_COMMAND="ssh -p ${PORT-22} -i $SSH_PATH/deploy_key"
if [ -n "$HOST_KEY" ]; then
    echo "Adding hosts key to known_hosts"
    echo "$HOST_KEY" >> "$SSH_PATH/known_hosts"
    chmod 600 "$SSH_PATH/known_hosts"
else
    echo "Disabling host key checking"
    GIT_SSH_COMMAND="$GIT_SSH_COMMAND -o StrictHostKeyChecking=no"
fi

if [ -n "$APP_CONFIG" ]; then
    echo "Setting app config"
    {
        $GIT_SSH_COMMAND dokku@$HOST config:set --no-restart $PROJECT $APP_CONFIG > /dev/null 2>&1
    } || {
        echo "Setting app config failed, processed to deployment"
    }
fi

echo "The deploy is starting"

GIT_SSH_COMMAND="$GIT_SSH_COMMAND" $GIT_COMMAND
