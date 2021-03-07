source ./env.sh
DOCKER_IMAGE="moletrix/tor-middle-relay"
#DOCKER_IMAGE=${1:-brunneis/tor-relay-arm:x86-64}
RELAY_TYPE="middle"

for PORT in $OR_PORT; do
    OR_PORT_DOCKER=$PORT
    break
done

docker run -id \
-p $OR_PORT_DOCKER:$OR_PORT_DOCKER \
-p $DIR_PORT:$DIR_PORT \
-e "OR_PORT=$OR_PORT" \
-e "DIR_PORT=$DIR_PORT" \
-e "NICKNAME=$NICKNAME" \
-e "CONTROL_PORT=9051" \
-e "CONTACT_INFO=$CONTACT_INFO" \
-e "BANDWIDTH_RATE=$BANDWIDTH_RATE" \
-e "BANDWIDTH_BURST=$BANDWIDTH_BURST" \
-e "MAX_MEM=$MAX_MEM" \
-e "ACCOUNTING_MAX=$ACCOUNTING_MAX" \
-e "ACCOUNTING_START=$ACCOUNTING_START" \
-e "HOST_UID=$UID" \
-v $(pwd)/tor-data:/home/tor/data:Z \
--name tor-$RELAY_TYPE-relay $DOCKER_IMAGE $RELAY_TYPE
