#!/bin/sh

sysctl -w net.core.default_qdisc=fq_codel
FLANNEL_DEV="flannel.1"
DEV=$(ip r show default | cut -d ' ' -f 5)
tc qdisc del dev "$DEV" root 2>/dev/null || true
tc qdisc add dev "$DEV" root handle 0: mq || true

# wait until flannel device is created
while ! ip link | grep "${FLANNEL_DEV}:" > /dev/null; do sleep 1; done

tc qdisc del dev $FLANNEL_DEV root 2>/dev/null || true
tc qdisc add dev $FLANNEL_DEV root handle 1: prio bands 2 priomap 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1
tc qdisc add dev $FLANNEL_DEV parent 1:2 handle 12: fq_codel
tc qdisc add dev $FLANNEL_DEV parent 1:1 handle 11: netem delay 4ms 1ms distribution pareto
tc filter add dev $FLANNEL_DEV protocol all parent 1: prio 1 handle 0x100/0x100 fw flowid 1:1
iptables -A POSTROUTING -t mangle -p udp --dport 5353 -m string -m u32 --u32 "28 & 0xF8 = 0" --hex-string "|00001C0001|" --algo bm --from 40 -j MARK --set-mark 0x100/0x100

# sleep forever
cat
