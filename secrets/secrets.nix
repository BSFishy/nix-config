let
  matt = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGOo7iBDgCXP99GA4NStJudsWkZQVaA9iDqDo6IQF2ve";
  work = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFfD9CzSpDp1VNx/ciax6PMJJ5WFCIeR1ogoI4HXadz8";
in
{
  "github-mcp-pat.age".publicKeys = [ matt work ];
  "k3s-token.age".publicKeys = [ matt ];
}
