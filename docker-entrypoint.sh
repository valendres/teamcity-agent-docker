#!/bin/bash
if [ -z "$TEAMCITY_SERVER" ]; then
    echo "TEAMCITY_SERVER variable not set, launch with -e TEAMCITY_SERVER=http://mybuildserver"
    exit 1
fi

if [ ! -d "$AGENT_DIR/bin" ]; then
    echo "$AGENT_DIR/bin doesn't exist; pulling build agent from server $TEAMCITY_SERVER";
    let waiting=0
    until curl -s -f -I -X GET $TEAMCITY_SERVER/update/buildAgent.zip; do
        let waiting+=10
        sleep 10
        if [ $waiting -ge 300 ]; then
            echo "Teamcity server did not respond within 120 seconds"...
            exit 42
        fi
    done
    wget $TEAMCITY_SERVER/update/buildAgent.zip && unzip -d $AGENT_DIR buildAgent.zip && rm buildAgent.zip

    chmod +x $AGENT_DIR/bin/agent.sh
fi

PROPS_FILE=$AGENT_DIR/conf/buildAgent.properties

if [ ! -f "$PROPS_FILE" ]; then
    echo "serverUrl=${TEAMCITY_SERVER}" > $PROPS_FILE
#    echo "workDir=/data/work" >> $PROPS_FILE
#    echo "tempDir=/data/temp" >> $PROPS_FILE
#    echo "systemDir=/data/system" >> $PROPS_FILE
fi

echo "Starting buildagent..."
chown -R teamcity:teamcity /opt/buildAgent

wrapdocker gosu teamcity /opt/buildAgent/bin/agent.sh run
