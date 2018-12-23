#   Network Policy

This document will explain the network policies implemented on automation cluster for following namespaces:

```
monitoring
logging
ci
heptio-ark
autoscaler
```

Following steps were taken into consideration while implementing the network policy:

```
Deny all ingress (incoming) traffic to the namespace.
Deny all egress (outgoing) traffic from the namespace.
Limit ingress traffic to each application.
Limit egress traffic from each application.
```

Note:- Important point to remember is that first policy which should be implemented on the any namespace should be always `default deny all ingress & egress traffic`.

Now let's understand in details:

# Deny all ingress (incoming) traffic to the namespace

``` 
kind: NetworkPolicy
apiVersion: networking.k8s.io/v1
metadata:
  namespace: ci
  name: default-deny-ci-ingress
spec:
  podSelector: {}
  policyTypes:
  - Ingress
```

Save the above manifest in `00default-deny-ingress.yaml` and apply on the namespace using the following command. 

`kubectl create -f 00default-deny-ingress.yaml`

Few remarks about this manifest:

	`namespace: ci` says deploy this policy to the ci namespace.
	`podSelector: {}` means it will select all the pods in this namespace.
	No ingress rule is specified which means no traffic is allowed on the namespace.

# Deny all egress (outgoing) traffic to the namespace

```
kind: NetworkPolicy
apiVersion: networking.k8s.io/v1
metadata:
  name: default-deny-ci-egress
  namespace: ci
spec:
  podSelector: {}
  policyTypes:
  - Egress
  egress:
  - ports:
    - port: 53
      protocol: TCP
    - port: 53
      protocol: UDP
```

Save following manifest in `01default-deny-egress.yaml` and apply on the namespace using the following command:

`kubectl create -f 01default-deny-egress.yaml` 

Few remarks about this manifest:

	`namespace: ci` says deploy this policy to the ci namespace.
	`podSelector: {}` means it will select all the pods in this namespace.
	only one egress rule is specified to allow outgoing traffic on only `port 53`.

You can test it by doing curl on particular url or do a telnet on IP/Hostname & port.

```Note:- After applying a deny-all policy which blocks all non-whitelisted traffic to the application, now we need to allow access to an application to accept the traffic. Applying this policy will make any other policies restricting the traffic to the pod void, and allow traffic to it as we specify.```

To understand this let's take an example of `nexus`. We will whitelist `ingress` and `egress` traffic for it.

# Limit ingress traffic to an application

```
apiVersion: extensions/v1beta1
kind: NetworkPolicy
metadata:
  name: allow-nexus-ingress
  namespace: ci
spec:
  policyTypes:
  - Ingress
  podSelector:
    matchLabels:
      app: nexus  
  ingress:
  - ports:
    - port: 5000
      protocol: TCP
    - port: 8081
      protocol: TCP
```

Save following manifest in `02-NetworkPolicy-allow-nexus-ingress.yaml` and apply on the namespace using the following command:

`kubectl create -f 02-NetworkPolicy-allow-nexus-ingress.yaml`

Few remarks about this manifest:

	`namespace: ci` says deploy this policy to the ci namespace.
	`podSelector` applies the ingress rule to pods with `app: nexus`
	Only one ingress rule is specified, which allows all the incoming traffic on only `port 8081` which is for `nexus-ui` & `port 5000` which is for `nexus-registry`.

	
# Limit egress traffic to an application

```
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-nexus-egress
  namespace: ci
spec:
  podSelector: 
    matchLabels:
      app: nexus
  policyTypes:
  - Egress
  egress:
  - ports:
    - protocol: TCP
      port: 443
# Squid
  - to:
    - podSelector:
        matchLabels:
          app: squid
    ports:
    - protocol: TCP
      port: 3128
# LDAP Servers
  - to:
    - ipBlock:
        cidr: 100.66.12.22/32
    ports:
    - protocol: TCP
      port: 3268
  - to:
    - ipBlock:
        cidr: 100.66.12.46/32
    ports:
    - protocol: TCP
      port: 3268
```

Save following manifest in `03-NetworkPolicy-allow-nexus-egress.yaml` and apply on the namespace using the following command:

`kubectl create -f 03-NetworkPolicy-allow-nexus-egress.yaml`

Few remarks about this manifest:

	`namespace: ci` says deploy this policy to the ci namespace.
	`podSelector` applies the ingress rule to pods with `app: nexus`
	Egress rules are specified as below
		Port 443 is allowed to make secure connection with any application outside.
		Squid is allowed on `port 3128` to make Internet connection.
		LDAP servers are allowed on `port 3268` with IPs specified as nexus ui is integrated with LDAP for web login.


