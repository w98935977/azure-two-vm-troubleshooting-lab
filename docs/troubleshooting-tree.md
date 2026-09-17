# Troubleshooting decision tree

```text
VM01 requests 10.10.2.4:8080
|
+-- Timeout
|   +-- Is VM02 running?
|   +-- Is the private IP correct?
|   +-- Does the effective NSG allow TCP/8080?
|   +-- Does UFW allow the VM01 source?
|
+-- Connection refused
|   +-- Is a process listening on 8080?
|   +-- Is it bound to 0.0.0.0 or 10.10.2.4?
|   +-- Was the service restarted after VM reboot?
|
+-- HTTP response
    +-- 200: end-to-end path is healthy
    +-- 404: application reached; path/file is missing
    +-- 500: application reached; internal handling failed
```

## Commands by layer

```bash
# VM01: transport and HTTP tests
nc -vz -w 5 10.10.2.4 8080
curl -v --connect-timeout 5 http://10.10.2.4:8080/

# VM02: firewall and listener
sudo ufw status numbered verbose
ss -lntp | grep ':8080'

# VM02: bypass the network path and test the service locally
curl -v http://127.0.0.1:8080/
```

