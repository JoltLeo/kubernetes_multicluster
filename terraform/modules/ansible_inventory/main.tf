
locals {
  inventory = templatefile(
    "${path.module}/ansible-inventory.tmpl", {
      hosts      = var.hosts
      extra_vars = var.extra_vars
    }
  )
  inventory_command = "echo '${base64encode(local.inventory)}' | base64 -d  > ${var.inventory_filename}"
}

resource "null_resource" "inventory_file" {
  count = var.run_playbook != "" ? 1 : 0

  triggers = merge({
    inventory = local.inventory
    playbook  = file(var.run_playbook)
  }, var.triggers)

  provisioner "local-exec" {
    command = local.inventory_command
  }
}

resource "null_resource" "run_ansible" {
  count = var.run_playbook != "" ? 1 : 0

  triggers = merge({
    inventory = local.inventory
    playbook  = file(var.run_playbook)
  }, var.triggers)

  provisioner "local-exec" {
    command = <<EOT
      export ANSIBLE_HOST_KEY_CHECKING=False
      export ANSIBLE_PIPELINING=1
      export ANSIBLE_SSH_RETRIES=3
      export ANSIBLE_TIMEOUT=20
      export ANSIBLE_SSH_EXTRA_ARGS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
      export ANSIBLE_PYTHON_INTERPRETER=${var.python_interpreter}
      export ANSIBLE_COLLECTIONS_PATHS=./
      export ANSIBLE_ROLES_PATH=./ansible_roles

      %{if var.galaxy_requirements != ""}
      ansible-galaxy install -r ${var.galaxy_requirements} --force
      %{endif}

      %{for collection in var.galaxy_install_collections~}
      ansible-galaxy collection install ${collection}
      %{endfor~}

      echo "Check connection on ansible hosts"
      ansible -o -i ${var.inventory_filename} -m wait_for_connection all -a "delay=10 timeout=180"


      %{for role in var.galaxy_install_roles~}
      ansible-galaxy install ${role} --force
      %{endfor~}

      ansible-playbook -i ${var.inventory_filename} ${var.run_playbook}
    EOT
  }

  depends_on = [null_resource.inventory_file]
}

