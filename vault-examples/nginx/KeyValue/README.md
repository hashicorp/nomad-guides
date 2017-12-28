#Nomad-Vault Nginx Key/Value 

### Demo TLDR
```bash
vagrant@node1:/vagrant/vault-examples/nginx/KeyValue$ ./kv_vault_setup.sh
Successfully authenticated! You are now logged in.
token: 25bf4150-94a4-7292-974c-9c3fa4c8ee53
token_duration: 0
token_policies: [root]
Success! Data written to: secret/test
Policy 'test' written.

vagrant@node1:/vagrant/vault-examples/nginx/KeyValue$ nomad run nginx-kv-secret.nomad

# in your browser goto:
http://localhost:8080/nginx-secret/
#Good morning. secret: Live demos rock!!!

```




#Guide: TODO