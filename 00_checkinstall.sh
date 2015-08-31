#!/bin/bash
if [ -z "$TEAMCITY_SERVER" ]; then
    echo "TEAMCITY_SERVER variable not set, launch with -e TEAMCITY_SERVER=http://mybuildserver"
    exit 1
fi

if [ ! -d "$AGENT_DIR/bin" ]; then
    echo "$AGENT_DIR/bin doesn't exist; pulling build agent from server $TEAMCITY_SERVER";
    wget $TEAMCITY_SERVER/update/buildAgent.zip
    unzip -d $AGENT_DIR buildAgent.zip
    rm buildAgent.zip
    chmod +x $AGENT_DIR/bin/agent.sh
fi

PROPS_FILE=$AGENT_DIR/conf/buildAgent.properties

if [ ! -f "$PROPS_FILE" ]
    echo "serverUrl=${TEAMCITY_SERVER}" > $PROPS_FILE
    echo "workDir=/data/work" >> $PROPS_FILE
    echo "tempDir=/data/temp" >> $PROPS_FILE
    echo "systemDir=/data/system" >> $PROPS_FILE
fi
