# Azure Two-VM Troubleshooting Lab

Evidence-based troubleshooting lab for Azure east-west traffic across two Ubuntu VMs.

The lab intentionally injects failures at the Azure network, Linux firewall, TCP listener, and HTTP application layers. Each scenario records the observed symptom, the command used to isolate it, and the recovery action.

## Architecture

```text
VM01 Client                              VM02 HTTP Service
10.10.1.4                                10.10.2.4:8080
subnet-app / nsg-app                     subnet-mgmt / nsg-mgmt
       |                                        ^
       +---------- private TCP/8080 ------------+
                 vnet-cloudriches-lab
```

VM02 does not require a public IP. VM01 reaches it through its private IP inside the VNet.

## What this project demonstrates

- Cross-subnet private connectivity in an Azure VNet
- The difference between Azure NSG rules and Linux UFW rules
- TCP diagnosis with `nc`, `curl`, and `ss`
- Listener binding behavior: `127.0.0.1` versus `0.0.0.0`
- Interpreting timeout, connection refused, HTTP 404, and HTTP 500
- A repeatable troubleshooting order instead of random configuration changes

## Fault-injection results

| Scenario | Observed result | What it indicates | Recovery |
|---|---|---|---|
| Healthy baseline | HTTP 200 | Network, listener, and app all work | None |
| NSG denies TCP/8080 | Timeout | Azure network layer drops traffic | Remove the temporary deny rule |
| UFW denies TCP/8080 | Timeout | Guest firewall drops traffic | Remove deny and restore the narrow allow rule |
| Wrong private IP | Timeout | Target is unreachable or absent | Verify VM NIC private IP |
| VM02 stopped/deallocated | Timeout | Destination VM is unavailable | Start VM and confirm Portal status |
| Service stopped | Connection refused | Host is reachable, but no process listens on 8080 | Start the service |
| Service bound to `127.0.0.1` | Local success; remote refused | Listener accepts loopback traffic only | Bind to `0.0.0.0` or the VM private IP |
| Wrong port 8000 | Timeout while UFW blocks it; refused after allow | A firewall can mask a missing listener | Check firewall, then `ss -lntp` |
| Missing HTTP path | HTTP 404 | Request reached the application, resource is absent | Correct or create the path |
| `/fail` endpoint | HTTP 500 | Request reached the application, which failed | Inspect application behavior/logs |

> Symptoms are clues, not absolute proof. For example, a wrong port may time out when a firewall drops it and become “connection refused” only after the firewall allows it.

## Troubleshooting order

1. Confirm the destination VM is running.
2. Verify the destination private IP and port.
3. Test TCP from VM01 with `nc`.
4. Review the effective NSG path.
5. Review UFW on VM02.
6. Check the listener with `ss -lntp`.
7. Test locally on VM02.
8. Inspect the HTTP status and application behavior.

See [the decision tree](docs/troubleshooting-tree.md) and [the complete runbook](docs/lab-runbook.md).

## Quick start

On VM02:

```bash
mkdir -p ~/lab-http
printf 'vm-linux-02 lab service is healthy\n' > ~/lab-http/index.html
bash scripts/start-static-server.sh
```

From VM01:

```bash
nc -vz -w 5 10.10.2.4 8080
curl -v --connect-timeout 5 http://10.10.2.4:8080/
```

To test application-layer responses on VM02:

```bash
bash scripts/start-test-api.sh
```

```bash
curl -i http://10.10.2.4:8080/health
curl -i http://10.10.2.4:8080/fail
```

## Repository structure

```text
app/lab_api.py                    Minimal HTTP 200/404/500 test API
scripts/start-static-server.sh    Static lab service launcher
scripts/start-test-api.sh         Test API launcher
docs/architecture.md              Network and control-plane notes
docs/troubleshooting-tree.md      Symptom-based decision tree
docs/lab-runbook.md               Reproducible fault-injection exercises
```

## Security notes

- SSH is limited to the lab VNet range in this exercise.
- TCP/8080 is limited to VM01's private IP after recovery.
- Subscription IDs, public IPs, resource IDs, and credentials are intentionally excluded.
- This is a learning lab, not a production reference architecture.

