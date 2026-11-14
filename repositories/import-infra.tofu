# One-time import of infra, created before it was managed here. Remove after it is applied.
import {
  to = github_repository.this["infra"]
  id = "infra"
}

import {
  to = github_repository_collaborators.this["infra"]
  id = "infra"
}
