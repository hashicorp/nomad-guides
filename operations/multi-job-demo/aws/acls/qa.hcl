# Copyright IBM Corp. 2017, 2026

namespace "default" {
  capabilities = ["list-jobs"]
}

namespace "qa" {
  policy = "write"
}

agent {
  policy = "read"
}

node {
  policy = "read"
}
