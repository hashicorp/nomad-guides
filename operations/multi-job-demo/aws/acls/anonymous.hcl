# Copyright IBM Corp. 2017, 2026

namespace "default" {
  capabilities = ["list-jobs"]
}

agent {
  policy = "read"
}

node {
  policy = "read"
}
