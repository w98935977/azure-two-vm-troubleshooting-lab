# Fault-injection runbook

Run one fault at a time. Record the expected result, observed result, evidence, diagnosis, and recovery before continuing.

## Baseline

From VM01:

```bash
nc -vz -w 5 10.10.2.4 8080
curl -v --connect-timeout 5 http://10.10.2.4:8080/
```

Expected: TCP succeeds and HTTP returns 200.

## NSG deny

Create a temporary inbound rule on the VM02-side NSG:

- Source: `10.10.1.4/32`
- Destination port: `8080`
- Protocol: TCP
- Action: Deny
- Priority: higher precedence than the allow rule

Expected from VM01: timeout. Delete the temporary deny rule and verify HTTP 200 again.

## UFW deny and recovery

On VM02:

```bash
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow from 10.10.0.0/16 to any port 22 proto tcp comment 'Allow-SSH-from-VNet'
sudo ufw deny from 10.10.1.4/32 to any port 8080 proto tcp comment 'Deny-HTTP8080-from-VM01'
sudo ufw enable
sudo ufw status numbered verbose
```

Expected from VM01: timeout. Confirm the service still works locally on VM02, then recover:

```bash
sudo ufw delete deny from 10.10.1.4/32 to any port 8080 proto tcp
sudo ufw allow from 10.10.1.4/32 to any port 8080 proto tcp comment 'Allow-HTTP8080-from-VM01'
```

## Wrong address

```bash
nc -vz -w 5 10.10.3.4 8080
curl -v --connect-timeout 5 http://10.10.3.4:8080/
```

Expected: timeout.

## VM stopped

Stop and deallocate VM02 in Azure Portal. Confirm its status, then repeat the baseline from VM01.

Expected: timeout.

## Service stopped

Stop the HTTP process on VM02 while leaving the VM running and TCP/8080 allowed.

Expected from VM01: connection refused. Port 22 should still succeed.

## Loopback-only listener

Start the service with `--bind 127.0.0.1`.

```bash
ss -lntp | grep ':8080'
curl http://127.0.0.1:8080/
```

Expected: local curl succeeds; VM01 receives connection refused.

## Wrong port

First test TCP/8000 while UFW blocks it. Expected: timeout. Then temporarily allow only VM01:

```bash
sudo ufw allow from 10.10.1.4/32 to any port 8000 proto tcp comment 'Temporary-wrong-port-test'
```

Expected: connection refused because no process is listening. Remove the temporary rule afterward.

## HTTP 404

```bash
curl -i http://10.10.2.4:8080/ghost-file.txt
```

Expected: 404. Create the file under the configured document root and repeat; expected result becomes 200.

## HTTP 500

Start `app/lab_api.py`, then run from VM01:

```bash
curl -i http://10.10.2.4:8080/health
curl -i http://10.10.2.4:8080/fail
```

Expected: `/health` returns 200 and `/fail` returns 500. This isolates the fault to the application layer.

