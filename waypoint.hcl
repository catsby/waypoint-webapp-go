project = "go-gitops-0"

pipeline "mario" {
  step "all-of-it" {
    use "up" {
    }
  }
  step "hammer" {
    use "build" {
      disable_push = false
    }
  }
  step "level-up" {
    use "deploy" {
      release = false
    }
  }
  step "the-end" {
    use "release" {
    }
  }
  step "superstar" {
    use "exec" {
      command = "echo"
      args    = ["\nhello!!"]
    }
  }
  step "mushroom" {
    use "exec" {
      command = "ls"
      args    = ["-lah"]
    }
  }
  step "castle" {
    use "exec" {
      command = "echo"
      args    = ["\ngoodbye o/"]
    }
  }
}

runner {
  enabled = true

  data_source "git" {
    url  = "https://github.com/catsby/waypoint-webapp-go.git"
    path = ""
    ref = "refs/heads/dev"
    //ref  = config.internal.DATA_REF
  }
}

app "go" {
  config {
    env = {
      PORT=3000
    }

    workspace "dev" {
      env = {
        PORT=8080
      }
    }
  }

  # config {
  #   env = {
  #     PORT=var.port
  #     # PORT={
  #     #   "default"    = 3000
  #     #   "dev" = 8080
  #     # }[workspace.name]
  #   }
  # }

  build {
    use "pack" {}

    registry {
      use "docker" {
        image    = var.image
        # tag      = var.tag
        tag = gitrefpretty()
        username = var.registry_username
        password = var.registry_password
        local    = false
      }
    }
  }

  deploy {
    use "kubernetes" {
      namespace = {
        "default"    = "default"
        "dev" = "dev"
      }[workspace.name]
      probe_path   = "/"
      image_secret = var.regcred_secret
      service_port = var.port
    }
  }

  release {
    use "kubernetes" {
      load_balancer = true
      port = {
        "default"    = 3000
        "dev" = 8080
      }[workspace.name]
    }
  }
}

variable "image" {
  # free tier, old container registry
  default     = "catsby.jfrog.io/waypoint-go-docker/waygo"
  #default     = "team-waypoint-dev-docker-local.artifactory.hashicorp.engineering/go"
  type        = string
  description = "Image name for the built image in the Docker registry."
}
#variable "image_updated" {
#  # free tier, old container registry
#  default     = "catsby.jfrog.io/waypoint-go-docker/waygo-updated"
#  #default     = "team-waypoint-dev-docker-local.artifactory.hashicorp.engineering/go"
#  type        = string
#  description = "Image name for the built image in the Docker registry."
#}

variable "tag" {
  default     = "latest"
  type        = string
  description = "Image tag for the image"
}

variable "registry_username" {
  default = dynamic("vault", {
    path = "secret/data/jfrogcreds"
    key = "/data/username"
  })
  type        = string
  sensitive   = true
  description = "username for container registry"
}

variable "registry_password" {
  default = dynamic("vault", {
    path = "secret/data/jfrogcreds"
    key = "/data/password"
  })
  type        = string
  sensitive   = true
  description = "password for registry" // don't hack me plz
}

variable "regcred_secret" {
  default     = "regcred"
  type        = string
  description = "The existing secret name inside Kubernetes for authenticating to the container registry"
}

variable "port" {
  type = number
  # default = 3000
  default = {
    "default"    = 3000
    "dev" = 8080
  }[workspace.name]
}


