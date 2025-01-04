# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, lib, ... }:

let
  unstablePkgs = import <unstable> { config = config.nixpkgs.config; };
in
{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "nixos"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "America/New_York";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.sdavis = {
    isNormalUser = true;
    description = "Samuel Davis";
    extraGroups = [ "networkmanager" "wheel" "video" "audio" "docker" ];
    ### packages = with pkgs; [];
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  ### environment.systemPackages = with pkgs; [
  ### #  vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
  ### #  wget
  ### ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.11"; # Did you read the comment?

  #########
  # SOUND #
  #########

  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    pulse.enable = true;
    jack.enable = true;
    alsa = {
      enable = true;
      support32Bit= true;
    };
  };

  ############
  # GRAPHICS #
  ############

  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia.open = false;
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  ##################
  # WINDOW MANAGER #
  ##################

  environment.loginShellInit = ''
    [[ "$(tty)" == /dev/tty1 ]] && sway --unsupported-gpu
  '';

  environment.sessionVariables = {
    ### WLR_NO_HARDWARE_CURSORS = "1";
    ### NIXOS_OZONE_WL = "1";
    EDITOR = "nvim";
    VISUAL = "nvim";
    BROWSER = "brave";
    TERM = "foot";
    CUDA_cublas_LIBRARY = "/etc/profiles/per-user/sdavis/lib/libcublas.so";
  };

  environment.systemPackages = with pkgs; [
    unstablePkgs.neovim
    unzip
  ];

  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-wlr ];
  };

  programs.light.enable = true;
  ### programs.hyprland.enable = true;
  programs.sway = {
    enable = true;
    wrapperFeatures.gtk = true;
    extraPackages = with pkgs; [
      foot
      wmenu
      sway-audio-idle-inhibit
      swayidle
      swaylock
      swaybg
    ];
  };

  ########
  # APPS #
  ########

  fonts.packages = with pkgs; [
    (nerdfonts.override { fonts = [ "JetBrainsMono" ]; })
    jetbrains-mono
  ];

  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
    "nvidia-x11"
    "nvidia-settings"
    "1password"
    "1password-cli"
    "steam"
    "steam-original"
    "steam-unwrapped"
    "steam-run"
    "discord"
    "obsidian"
  ];

  programs.steam = {
  	enable = true;
	remotePlay.openFirewall = true;
	dedicatedServer.openFirewall = true;
	localNetworkGameTransfers.openFirewall = true;
  };

  users.users.sdavis.packages = with pkgs; [
    # Utilities
    wl-clipboard
    playerctl
    brightnessctl
    xdg-utils
    # Apps
    unstablePkgs.brave
    audacity
    discord
    obsidian
    # Gaming
    wine
    unstablePkgs.lutris
    # Programming
    nmap
    yt-dlp
    ffmpeg
    fzf
    ripgrep
    gcc
    gnumake
    git
    nodejs
    python3
    rustc
    cargo
    godot_4
  ];
  programs._1password.enable = true;
  programs._1password-gui = {
    enable = true;
    polkitPolicyOwners = [ "sdavis" ];
  };
  virtualisation.docker.enable = true;
  programs.nix-ld.enable = true;
}
