# RADV-only Mesa, same nixpkgs version as the system one, with u_trace GPU tracepoints compiled in
# (-Dradv-u_trace=true; the stock nixpkgs build has them compiled out) plus two small patches:
#   * every draw/dispatch tracepoint also records the RADV pipeline hash (the id RGP shows as "pipeline hash"),
#   * vkCmdBeginRendering records the render area and attachment count, so passes can be told apart.
# Build:  nix --extra-experimental-features 'nix-command flakes' build --impure --no-link --print-out-paths -f tools/gpuprof/mesa-radv-utrace.nix
# Use:    VK_DRIVER_FILES=<out>/share/vulkan/icd.d/radeon_icd.x86_64.json  (64-bit only: that is all vkd3d-proton needs)
{ pkgs ? (builtins.getFlake "nixpkgs").legacyPackages.${builtins.currentSystem} }:
(pkgs.mesa.override { vulkanDrivers = [ "amd" ]; galliumDrivers = [ ]; }).overrideAttrs (o: {
  pname = "mesa-radv-utrace";
  outputs = [ "out" ];
  postInstall = "";
  postFixup = "";
  mesonFlags = o.mesonFlags ++ [
    "-Dradv-u_trace=true"
    "-Dauto_features=auto" "-Dglvnd=disabled" "-Dopengl=false" "-Dgles1=disabled" "-Dgles2=disabled"
    "-Dglx=disabled" "-Degl=disabled" "-Dteflon=false" "-Dgallium-rusticl=false" "-Dvulkan-layers="
    "-Dtools=" "-Dvideo-codecs=" "-Dgbm=disabled" "-Dlibgbm-external=false"
  ];
  postPatch = (o.postPatch or "") + ''
    python3 ${./patch-utrace.py} src/amd/vulkan
  '';
})
