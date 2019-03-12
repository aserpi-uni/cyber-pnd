ping dns.pndeflab.edu -c 1 && ping gw.pndeflab.edu -c 1 && ping pc1.pndeflab.edu -c 1 && ping pc2.pndeflab.edu -c 1 && ping google.com -c 1 && echo -e "\nSuccess!" && exit 0

echo -e "\nFailure!" && exit 1
