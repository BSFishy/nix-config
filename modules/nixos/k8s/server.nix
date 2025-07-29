{ config, ... }:

{
  age.secrets.k3s-token.file = ../../../secrets/k3s-token.age;

  services.k3s = {
    role = "agent";
    serverAddr = "https://10.0.1.2:6443";
    tokenFile = config.age.secrets.k3s-token.path;
  };
}
