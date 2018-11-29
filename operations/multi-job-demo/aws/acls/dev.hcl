namespace "default" {
  capabilities = ["list-jobs"]
}

namespace "dev" {
  policy = "write"
}

agent {
  policy = "read"
}

node {
  policy = "read"
}
