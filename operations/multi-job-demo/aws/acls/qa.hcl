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
