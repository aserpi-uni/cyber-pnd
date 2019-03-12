ping 192.168.12.1 -c 1 && ping 192.168.12.2 -c 1 && ping 192.168.12.3 -c 1 && ping 192.168.12.9 -c 1 && ping 192.168.12.10 -c 1 && ping 192.168.12.11 -c 1 && ping 192.168.12.30 -c 1 && ping 192.168.12.29 -c 1 && ping 192.168.12.28 -c 1 && ping 1.1.1.1 -c 1 && echo -e "\nSuccess!" && exit 0

echo -e "\nFailure!"
exit 1
