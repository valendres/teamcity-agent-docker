NUM=$1

docker run -v /var/tc-agent/$NUM/conf:/opt/buildAgent/conf -v /var/tc-agent/$NUM/data:/data --privileged --name=teamcity-agent-$NUM -e TEAMCITY_SERVER=http://10.132.21.200 -d 1on1/teamcity-agent:latest
