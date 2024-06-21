{ pkgs }:

redirects:

pkg:

let
  libName = "libredirect" + pkgs.stdenv.hostPlatform.extensions.sharedLibrary;
  nixRedirects = pkgs.lib.concatStringsSep ":" (
    map (redirect: "${redirect.from}=${redirect.to}") redirects
  );
  redirectDirs = pkgs.lib.concatStringsSep "\n" (
    map (redirect: "echo \"mkdir -p ${redirect.to}\" >> \"$out/bin/$(basename $file)\"") redirects
  );
in
(pkg.overrideAttrs (old: {
  name = "${pkg.name}-prefixed";
  buildCommand = ''
    set -eo pipefail

    ${
      # Heavily inspired by https://stackoverflow.com/a/68523368/6259505
      pkgs.lib.concatStringsSep "\n" (
        map (outputName: ''
          echo "Copying output ${outputName}"
          set -x
          cp -rs --no-preserve=mode "${pkg.${outputName}}" "''$${outputName}"
          set +x
        '') (old.outputs or [ "out" ])
      )
    }

    rm -rf $out/bin/*
    shopt -s nullglob # Prevent loop from running if no files
    for file in ${pkg.out}/bin/*; do
      echo "#!${pkgs.bash}/bin/bash" > "$out/bin/$(basename $file)"
      ${redirectDirs}
      echo "export LD_PRELOAD=\"${pkgs.libredirect}/lib/${libName}\"" >> "$out/bin/$(basename $file)"
      echo "export NIX_REDIRECTS=\"${nixRedirects}\"" >> "$out/bin/$(basename $file)"
      echo "source $file \"\$@\"" >> "$out/bin/$(basename $file)"
      chmod +x "$out/bin/$(basename $file)"
    done
    shopt -u nullglob # Revert nullglob back to its normal default state
  '';
}))
