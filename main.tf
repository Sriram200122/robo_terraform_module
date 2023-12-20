resource "null_resource" "sample" {
  provisioner "local-exec" {
    command = "echo Hello World - Env is ${var.env}"
  }
}