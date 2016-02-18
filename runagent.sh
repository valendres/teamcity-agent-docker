NUM=$1

docker run \
  -v /etc/timezone:/etc/timezone:ro
  -v /var/tc-agent/$NUM/conf:/opt/buildAgent/conf \
  -v /var/tc-agent/$NUM/data:/data \
  --privileged \
  --name=teamcity-agent-$NUM \
  --restart=always
  -e TEAMCITY_SERVER=http://10.132.21.200 \
  -d \
  1on1/teamcity-agent:latest
