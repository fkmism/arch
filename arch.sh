{ config, pkgs, lib, ... }:

{
  # ⚙️
  nixpkgs.config.allowUnfree = true;

  # 💻
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # 🌐
  networking.hostName = "nixos";
  networking.networkmanager.enable = true;
  networking.nameservers = [ "9.9.9.9" ];

  # 👤
  users.users.w = {
    isNormalUser = true;
    description = "w";
    extraGroups = [ "networkmanager" "wheel" "disk" ];
    packages = with pkgs; [
      firefox
    ];
    shell = pkgs.fish;
    initialPassword = "changeme";
  };

  # 🔊
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
  };

  # 🛡️
  services.dbus.enable = true;
  security.polkit.enable = true;
  security.sudo.enable = true;

  # 🚀
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  # 🎣
  programs.fish.enable = true;

  # 🚪
  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-wlr ];
    configPackages = [ pkgs.xdg-desktop-portal-wlr ];
  };

  # 📌
  system.stateVersion = "25.05";
}
