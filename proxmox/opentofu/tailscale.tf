resource "tailscale_acl" "policy" {
  acl = file("${path.module}/tailscale-policy.hujson")
}
