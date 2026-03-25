let
  matt = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGOo7iBDgCXP99GA4NStJudsWkZQVaA9iDqDo6IQF2ve";
in
{
  "github-mcp-pat.age".publicKeys = [ matt ];
  "k3s-token.age".publicKeys = [ matt ];
}
