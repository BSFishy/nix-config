{ ... }:

{
  networking = {
    useDHCP = false;

    interfaces.enp1s0 = {
      ipv4.addresses = [
        {
          address = "10.0.1.3";
          prefixLength = 24;
        }
      ];

      ipv6.addresses = [
        {
          address = "2603:8080:1e00:1b00:5a47:caff:fe78:85b3";
          prefixLength = 64;
        }
      ];
    };

    defaultGateway = {
      address = "10.0.1.1";
      interface = "enp1s0";
    };

    defaultGateway6 = {
      address = "2603:8080:1e00:1b00::1";
      interface = "enp1s0";
    };

    nameservers = [
      "1.1.1.1"
      "1.0.0.1"
    ];
  };
}
