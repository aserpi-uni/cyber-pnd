#!/bin/bash

trap "exit 2" 2

HELP=$(cat <<-EOM
Usage: $0 [options]

    -a| --host-address      address for the host interface [optional]
    -h| --help              help [optional]
    -i| --interface         interface base name
    -n| --network           network as called in lab.conf
    -o| --netkit-address    address for the netkit interface [optional]
    -r| --route             add a route to the local interface [optional]
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
    -i|--interface)
      if [ ${INTERFACE+x} ]; then
        echo "ERROR: Too many interfaces"
        exit 2
      fi
      INTERFACE=$2
      shift 2
      ;;
    -n|--network)
      if [ ${NETWORK+x} ]; then
        echo "ERROR: Too many networks"
        exit 2
      fi
      NETWORK=$2
      shift 2
      ;;
    -o|--netkit-address)
      if [ ${ADDRESS_NETKIT+x} ]; then
        echo "ERROR: Too many netkit addresses"
        exit 2
      fi
      ADDRESS_NETKIT=$2
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
      PARAMS="$PARAMS $1"
      shift
      ;;
  esac
done

# set positional arguments in their proper place
eval set -- "$PARAMS"


if ! ( [ $INTERFACE ] && [ $NETWORK ] ); then
  echo "$HELP"
  exit 3
fi

if ! [[ `sudo docker network ls | grep -E [[:space:]]netkit_0_$NETWORK[[:space:]]` =~ ^[[:alnum:]]* ]]; then
  echo "No such network!"
  exit 10
fi
DOCKER_NETWORK="br-${BASH_REMATCH[0]}"

if ! [[ `grep ${INTERFACE}_host /proc/net/dev` ]]; then
  sudo ip link add dev ${INTERFACE}_netkit type veth peer name ${INTERFACE}_host
  sudo ip link set ${INTERFACE}_host up
  sudo ip link set ${INTERFACE}_netkit up
fi

if [[ $ADDRESS_HOST ]]; then
  sudo ip addr flush dev ${INTERFACE}_host
  sudo ip addr add $ADDRESS_HOST dev ${INTERFACE}_host
fi

if [[ $ADDRESS_NETKIT ]]; then
  sudo ip addr flush dev ${INTERFACE}_netkit
  sudo ip addr add $ADDRESS_NETKIT dev ${INTERFACE}_netkit
fi

sudo brctl addif $DOCKER_NETWORK ${INTERFACE}_netkit

for route in "${ROUTES[@]}"; do
  sudo ip route add $route dev ${INTERFACE}_host
done
