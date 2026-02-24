# Patch region 0: forward camunda-region1 → region 1's NLB IP
kubectl --context paul-region0 -n kube-system get configmap coredns -o jsonpath='{.data.Corefile}' > /tmp/corefile0.txt

cat > /tmp/corefile0-new.txt <<'EOF'
.:53 {
    errors
    health {
        lameduck 5s
      }
    ready
    kubernetes cluster.local in-addr.arpa ip6.arpa {
      pods insecure
      fallthrough in-addr.arpa ip6.arpa
    }
    prometheus :9153
    forward . /etc/resolv.conf
    cache 30
    loop
    reload
    loadbalance
}
camunda-region1.svc.cluster.local:53 {
    errors
    cache 30
    forward . 10.202.171.190 {
        force_tcp
    }
}
EOF

kubectl --context paul-region0 -n kube-system create configmap coredns \
  --from-file=Corefile=/tmp/corefile0-new.txt --dry-run=client -o yaml | \
  kubectl --context paul-region0 -n kube-system apply -f -

# Patch region 1: forward camunda-region0 → region 0's NLB IP
cat > /tmp/corefile1-new.txt <<'EOF'
.:53 {
    errors
    health {
        lameduck 5s
      }
    ready
    kubernetes cluster.local in-addr.arpa ip6.arpa {
      pods insecure
      fallthrough in-addr.arpa ip6.arpa
    }
    prometheus :9153
    forward . /etc/resolv.conf
    cache 30
    loop
    reload
    loadbalance
}
camunda-region0.svc.cluster.local:53 {
    errors
    cache 30
    forward . 10.192.68.124 {
        force_tcp
    }
}
EOF

kubectl --context paul-region1 -n kube-system create configmap coredns \
  --from-file=Corefile=/tmp/corefile1-new.txt --dry-run=client -o yaml | \
  kubectl --context paul-region1 -n kube-system apply -f -

# Restart CoreDNS in both
kubectl --context paul-region0 -n kube-system rollout restart deployment/coredns
kubectl --context paul-region1 -n kube-system rollout restart deployment/coredns

# Wait for rollout
sleep 15