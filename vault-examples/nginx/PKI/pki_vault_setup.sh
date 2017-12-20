vault mount pki

vault write pki/root/generate/internal \
	  common_name=service.consul

vault write pki/roles/consul-service \
    generate_lease=true \
    allowed_domains="service.consul" \
    allow_subdomains="true"

vault write pki/issue/consul-service \
    common_name=nginx.service.consul \
    ttl=2h

POLICY='path "*" { capabilities = ["create", "read", "update", "delete", "list", "sudo"] }'

echo $POLICY > policy-superuser.hcl

vault policy-write superuser policy-superuser.hcl