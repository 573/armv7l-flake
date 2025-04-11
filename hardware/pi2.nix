{
  pkgs,
  lib,
  inputs,
  modulesPath,
  ...
}: {
  imports = [
    inputs.nixos-hardware.nixosModules.raspberry-pi-2
    (modulesPath + "/installer/scan/not-detected.nix")
    (modulesPath + "/installer/sd-card/sd-image-armv7l-multiplatform-installer.nix")
  ];

  boot = {
    initrd.availableKernelModules = ["xhci_pci"];
    kernelParams = [
      "compat_uts_machine=armv7l"
    ];

    # error: Package ‘zfs-kernel-2.2.7-6.13.1’ in /nix/store/5bni29qxcvbqygs8asgzd7gf5vvrs6ay-source/pkgs/os-specific/linux/zfs/generic.nix:309 is marked as broken, refusing to evaluate.
    kernelPackages = lib.mkForce pkgs.zfs.latestCompatibleLinuxPackages;
    kernelPatches = [
      {
        name = "disable-bpf";
        patch = null;
        extraConfig = ''
          DEBUG_INFO_BTF n
          CONFIG_DEBUG_INFO_BTF n
        '';
      }

      # https://discourse.nixos.org/t/cannot-build-arm-linux-kernel-on-an-actual-arm-device/54218/13
      {
        name = "compat_uts_machine";
        patch = pkgs.fetchpatch {
          url = "https://git.launchpad.net/~ubuntu-kernel/ubuntu/+source/linux/+git/jammy/patch/?id=c1da50fa6eddad313360249cadcd4905ac9f82ea";
          sha256 = "sha256-357+EzMLLt7IINdH0ENE+VcDXwXJMo4qiF/Dorp2Eyw=";
        };
      }
    ];
  };

  nix.extraOptions = "extra-platforms = armv7l-linux";
  nixpkgs.hostPlatform = lib.mkDefault "armv7l-linux";
  swapDevices = [];
}
