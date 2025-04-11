{
  pkgs,
  lib,
  rootPath,
  ...
}:
# build: nix build --builders "ssh://eu.nixbuild.net armv7l-linux - 100 1 big-parallel,benchmark" --max-jobs 0 --system armv7l-linux .#nixosConfigurations.armv7l-linux.raspi2.config.system.build.sdImage -L -vvv --show-trace
{
  imports = ["${rootPath}/hardware/pi2.nix"];

  networking.useDHCP = lib.mkDefault true;

  # modules/users.nix - https://blog.yaymukund.com/posts/nixos-raspberry-pi-nixbuild-headless/
  users.users.dani = {
    isNormalUser = true;
    home = "/home/dani";
    extraGroups = [
      "wheel"
      "networkmanager"
      "audio"
      "video"
    ];
    password = "test";
  };

  security.sudo.execWheelOnly = true;

  security.sudo.extraRules = [
    {
      users = ["dani"];
      commands = [
        {
          command = "ALL";
          options = ["NOPASSWD"];
        }
      ];
    }
  ];

  # modules/networking.nix
  networking = {
    useNetworkd = true;
    hostName = "testpi";
  };

  programs.ssh.startAgent = true;
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
  };

  users.users."dani".openssh.authorizedKeys.keyFiles = [
  ];

  # modules/builder.nix
  boot.tmp.useTmpfs = true;
  boot.tmp.tmpfsSize = "50%";

  zramSwap.enable = true;
  zramSwap.memoryPercent = 150;

  swapDevices = [
    {
      device = "/swapfile";
      size = 2048;
    }
  ];

  services.getty.helpLine = ''
    \e[0;93mReset password now, please !\e[0m
    Issue \e[0;32mcat /etc/issue\e[0m to show these messages again
  '';

  console = {
    useXkbConfig = true;
    packages = [pkgs.terminus_font];
  };

  services.xserver = {
    enable = false;
    xkb.layout = "us";
    xkb.variant = "intl";
  };

  systemd.network.wait-online.timeout = 0;
  systemd.network.networks = {
    "10-ethernet-api-dhcp" = {
      enable = true;
      matchConfig.Name = "eth0";
      dhcpV4Config.RouteMetric = 20;
      networkConfig.DHCP = "yes";
      linkConfig.RequiredForOnline = "no";
      ipv6AcceptRAConfig.RouteMetric = 20;
    };
  };

  environment.systemPackages = builtins.attrValues {
    inherit
      (pkgs)
      pciutils
      usbutils
      ethtool
      lshw
      nmap
      ;
  };

  disabledModules = [
          "profiles/base.nix"
        ];

  networking.firewall.enable = false;

  system.stateVersion = lib.mkForce "24.05";

  # https://discourse.nixos.org/t/help-using-a-nixpkgs-overlay-in-a-flake/46075/7
  # https://stackoverflow.com/a/61158675/3320256
 # https://discourse.nixos.org/t/trying-to-make-a-libreoffice-overlay-to-skip-checks-because-i-want-to-complicate-my-life/48708
  nixpkgs.overlays = [
    (final: prev: {
      # https://gist.github.com/pbogdan/547fb6854500bc93995b486022f286f9
      haskell = prev.haskell // {
        packages = prev.haskell.packages // {
          ghc928 = prev.haskell.packages.ghc928.override {
	    overrides = hsSelf: hsSuper: {
	      time-compat = prev.haskell.lib.dontCheck hsSuper.time-compat;
	      unordered-containers = prev.haskell.lib.dontCheck hsSuper.unordered-containers;
            };
	  };
	};
      };
      makeModulesClosure = x: prev.makeModulesClosure (x // { allowMissing = true; });
      # https://discourse.nixos.org/t/trying-to-make-a-libreoffice-overlay-to-skip-checks-because-i-want-to-complicate-my-life/48708
    })
  ];
}
