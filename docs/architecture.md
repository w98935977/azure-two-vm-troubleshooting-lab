# Architecture

## Resource map

| Role | Resource | Address / association |
|---|---|---|
| Client | `vm-linux-01` | `10.10.1.4`, `subnet-app`, `nsg-app` |
| Server | `vm-linux-02` | `10.10.2.4`, `subnet-mgmt`, `nsg-mgmt` |
| Network | `vnet-cloudriches-lab` | Cross-subnet private routing |
| Service | Python HTTP server | TCP/8080 on VM02 |

## Traffic path

```text
VM01 process
  -> VM01 network interface
  -> subnet-app / nsg-app
  -> Azure VNet routing
  -> subnet-mgmt / nsg-mgmt
  -> VM02 network interface
  -> UFW on VM02
  -> TCP listener on VM02:8080
  -> HTTP application and requested path
```

The NSG controls Azure network traffic. UFW controls traffic inside the guest OS. Both must permit the flow before the request can reach the listening process.

## Listener scope

| Bind address | Reachable from VM02 | Reachable from VM01 |
|---|---:|---:|
| `127.0.0.1:8080` | Yes | No |
| `0.0.0.0:8080` | Yes | Yes, when NSG and UFW permit |
| `10.10.2.4:8080` | Yes via that interface | Yes, when NSG and UFW permit |

