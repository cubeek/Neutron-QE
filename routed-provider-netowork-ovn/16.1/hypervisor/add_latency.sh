## SPINE-LEAF add latency

sudo tc qdisc add dev dcn1-data root netem delay 50ms limit 15000000
sudo modprobe ifb numifbs=6
sudo ip link set dev ifb0 up
sudo tc qdisc add dev dcn1-data ingress
sudo tc filter add dev dcn1-data parent ffff: protocol ip u32 match u32 0 0 flowid 1:1 action mirred egress redirect dev ifb0
sudo tc qdisc add dev ifb0 root netem delay 50ms limit 15000000

sudo tc qdisc add dev dcn2-data root netem delay 50ms limit 15000000
sudo ip link set dev ifb1 up
sudo tc qdisc add dev dcn2-data ingress
sudo tc filter add dev dcn2-data parent ffff: protocol ip u32 match u32 0 0 flowid 1:1 action mirred egress redirect dev ifb1
sudo tc qdisc add dev ifb1 root netem delay 50ms limit 15000000

sudo tc qdisc add dev dcn1-management root netem delay 50ms limit 15000000
sudo ip link set dev ifb2 up
sudo tc qdisc add dev dcn1-management ingress
sudo tc filter add dev dcn1-management parent ffff: protocol ip u32 match u32 0 0 flowid 1:1 action mirred egress redirect dev ifb2
sudo tc qdisc add dev ifb2 root netem delay 50ms limit 15000000

sudo tc qdisc add dev dcn2-management root netem delay 50ms limit 15000000
sudo ip link set dev ifb3 up
sudo tc qdisc add dev dcn2-management ingress
sudo tc filter add dev dcn2-management parent ffff: protocol ip u32 match u32 0 0 flowid 1:1 action mirred egress redirect dev ifb3
sudo tc qdisc add dev ifb3 root netem delay 50ms limit 15000000

sudo tc -s qdisc show dev dcn1-data
sudo tc -s qdisc show dev ifb0
sudo tc -s qdisc show dev dcn2-data
sudo tc -s qdisc show dev ifb1
sudo tc -s qdisc show dev dcn1-management
sudo tc -s qdisc show dev ifb2
sudo tc -s qdisc show dev dcn2-management
sudo tc -s qdisc show dev ifb3
