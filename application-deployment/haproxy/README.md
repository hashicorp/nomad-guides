HAPROXY example

### TLDR;
```bash
#Assumes Vagrantfile (lots of port forwarding), fix IP's and ports accordingly

vagrant@node1:/vagrant/application-deployment/haproxy$ nomad run haproxy.nomad

vagrant@node1:/vagrant/application-deployment/haproxy$ nomad run /vagrant/application-deployment/go-blue-green/go-app.nomad

#Golang app (routed via HAPROXY)
http://localhost:9080/

#Vault GUI: 
http://localhost:3200/ui/vault/auth

#Consul GUI:
http://localhost:3500/ui/#/dc1/services

#Nomad GUI:
http://localhost:3646/ui/jobs

```





# GUIDE: TODO