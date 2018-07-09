# flannel-tc

This is creating a workaround container that has to be rolled out as
sidecar of flannel.

Kubernetes upstream issue
https://github.com/kubernetes/kubernetes/issues/62628.

Original script got from this [blogpost](https://blog.quentin-machu.fr/2018/06/24/5-15s-dns-lookups-on-kubernetes/).

## some notes

https://blog.quentin-machu.fr/2018/06/24/5-15s-dns-lookups-on-kubernetes/
presents workarounds that does not makes sense, because alpine would
not be useable (musslc has no support for the workaround)

Looking at conntrack -S, we had thousands of insert_failed, this is
it. It turns out that a few engineers have noticed the issue and have
gone through the troubleshooting process as well, identifying a SNAT
race condition, ironically briefly documented in netfilter’s code.

The solution would be to add –random-fully on all masquerading rules,
which are set by several components in Kubernetes: kubelet,
kube-proxy, weave and docker itself. There is only one little problem
here… This is an early feature and not available on Container Linux,
nor in Alpine’s iptables package nor in the Go wrapper of
iptables. Regardless, it seems generally accepted that this would be
the solution to the issue, and some developers are now implementing
the missing flag support, but behold, this does not stop here.

Based on various traces, Martynas Pumputis discovered that there also
was a race with DNAT, as the DNS server is reached via a virtual
IP. Due to UDP being a connectionless protocol, connect(2) does not
send any packet and therefore no entry is created in the conntrack
hash table. During the translation, the following netfilter hooks are
called in order: nf_conntrack_in (creates conntrack hash object, adds
it to the unconfirmed entries list), nf_nat_ipv4_fn (does the
translation, updates the conntrack tuple), and nf_conntrack_confirm
(confirms the entry, adds it to the hash table). The two parallel UDP
requests race for the entry confirmation and end up using different
DNS endpoints, as there are multiple DNS server replicas
available. Therefore, insert_failed is incremented, and the request is
dropped. This means that adding –random-fully does not mitigate the
packet loss, as the flag would only help mitigate the SNAT race! The
only reliable fix would be to patch netfilter directly, which Martynas
Pumputis is currently attempting to do.

    # shows we offload rx-checksumming: on and tx-checksumming: on
    ethtool --show-offload flannel.1
    ethtool --show-offload eth0


## other options

- wait for upstream fixes in kernel, kubernetes etc. being merged and rolled out
- https://github.com/coreos/flannel/pull/1001 does not work according to
the PR creator.
