# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

namespace "default" {
  capabilities = ["list-jobs"]
}

agent {
  policy = "read"
}

node {
  policy = "read"
}
