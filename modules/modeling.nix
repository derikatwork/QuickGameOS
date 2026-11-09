{ config, lib, pkgs, ... }:

let
  cfg = config.quickgameos;
in
{
  # -----------------------------------------------------------------------
  # 3D modelling category - modelling, sculpting, CAD and slicing for
  # 3D printing. GPU-heavy, so off by default.
  # -----------------------------------------------------------------------
  config = lib.mkIf cfg.modeling.enable {
    environment.systemPackages = with pkgs; [
      blender              # modelling, sculpting, animation, rendering
      freecad              # parametric CAD
      openscad             # scriptable CAD
      meshlab              # mesh processing / cleanup
      prusa-slicer         # slicer for 3D printing
    ];
  };
}
