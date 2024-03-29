#!/bin/bash

trap "exit 2" 2

HELP=$(cat <<-EOM
Usage: $0 NETWORK INTERFACE [OPTIONAL PARAMS]
    
    NETWORK                 network as called in lab.conf
    INTERFACE               interface base name

    -a| --host-address      address for the host interface
    -h| --help              help
    -k| --kathara-address   address for the kathara interface
    -r| --route             add a route to the local interface
EOM
)

PARAMS=""
ROUTES=()

while (( "$#" )); do
  [[ $1 == --*=* ]] && set -- "${1%%=*}" "${1#*=}" "${@:2}"
  case "$1" in
    -a|--host-address)
      if [ ${ADDRESS_HOST+x} ]; then
        echo "ERROR: Too many host addresses"
        exit 2
      fi
      ADDRESS_HOST=$2
      shift 2
      ;;
    -h|--help)
      echo "$HELP"
      exit 0
      ;;
    -k|--kathara-address)
      if [ ${ADDRESS_KATHARA+x} ]; then
        echo "ERROR: Too many kathara addresses"
        exit 2
      fi
      ADDRESS_KATHARA=$2
      shift 2
      ;;
    -r|--route)
      ROUTES+=($2)
      shift 2
      ;;
    --) # end argument parsing
      shift
      break
      ;;
    -*|--*=) # unsupported flags
      echo "Error: Unsupported parameter $1" >&2
      exit 2
      ;;
    *) # preserve positional arguments
      PARAMS="$PARAMS \"$1\""
      shift
      ;;
  esac
done

# set positional arguments in their proper place
eval set -- "$PARAMS"


if ! ( [ $1 ] && [ $2 ] ); then
  echo "$HELP"
  exit 3
fi

INTERFACE=$2
NETWORK=$1

if ! [[ `sudo docker network ls | grep -E [[:space:]]netkit_0_$NETWORK[[:space:]]` =~ ^[[:alnum:]]* ]]; then
  echo "No such network!"
  exit 10
fi
DOCKER_NETWORK="br-${BASH_REMATCH[0]}"

if ! [[ `grep ${INTERFACE}_host /proc/net/dev` ]]; then
  sudo ip link add dev ${INTERFACE}_kathara type veth peer name ${INTERFACE}_host
  sudo ip link set ${INTERFACE}_host up
  sudo ip link set ${INTERFACE}_kathara up
fi

if [[ $ADDRESS_HOST ]]; then
  sudo ip addr flush dev ${INTERFACE}_host
  sudo ip addr add $ADDRESS_HOST dev ${INTERFACE}_host
fi

if [[ $ADDRESS_KATHARA ]]; then
  sudo ip addr flush dev ${INTERFACE}_kathara
  sudo ip addr add $ADDRESS_KATHARA dev ${INTERFACE}_kathara
fi

sudo brctl addif $DOCKER_NETWORK ${INTERFACE}_kathara

for route in "${ROUTES[@]}"; do
  sudo ip route add $route dev ${INTERFACE}_host
done
