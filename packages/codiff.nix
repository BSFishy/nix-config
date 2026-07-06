{
  lib,
  stdenvNoCC,
  fetchurl,
  unzip,
  autoPatchelfHook,
  dpkg,
  alsa-lib,
  at-spi2-atk,
  cairo,
  cups,
  dbus,
  expat,
  gdk-pixbuf,
  glib,
  gtk3,
  libdrm,
  libxkbcommon,
  mesa,
  nspr,
  nss,
  pango,
  libx11,
  libxcomposite,
  libxdamage,
  libxext,
  libxfixes,
  libxrandr,
  libxcb,
  libGL,
  makeWrapper,
}:

let
  version = "1.6.1";

  sources = {
    "aarch64-darwin" = {
      url = "https://github.com/nkzw-tech/codiff/releases/download/v${version}/Codiff-darwin-arm64-${version}.zip";
      hash = "sha256-diHqoYjAwecE5ZCNYkaqEz0yFTMNbyruOVcZL/jiD38=";
    };
    "x86_64-linux" = {
      url = "https://github.com/nkzw-tech/codiff/releases/download/v${version}/codiff_${version}_amd64.deb";
      hash = "sha256-xNgUViLnh7btMd1j6Lbp33xWGRG2SUubFAhr/+FDqKo=";
    };
  };

  src = fetchurl sources.${stdenvNoCC.hostPlatform.system};
in
if stdenvNoCC.hostPlatform.isDarwin then
  stdenvNoCC.mkDerivation {
    pname = "codiff";
    inherit version src;

    sourceRoot = ".";

    nativeBuildInputs = [ unzip ];

    installPhase = ''
      runHook preInstall

      mkdir -p "$out/Applications" "$out/bin"
      cp -r Codiff.app "$out/Applications/"

      # symlink the bundled CLI helper
      ln -s "$out/Applications/Codiff.app/Contents/Resources/app/bin/codiff-app" "$out/bin/codiff"

      runHook postInstall
    '';

    meta = {
      description = "A fast local diff viewer";
      homepage = "https://github.com/nkzw-tech/codiff";
      license = lib.licenses.mit;
      platforms = [ "aarch64-darwin" ];
      mainProgram = "codiff";
    };
  }
else
  stdenvNoCC.mkDerivation {
    pname = "codiff";
    inherit version src;

    nativeBuildInputs = [
      dpkg
      autoPatchelfHook
      makeWrapper
    ];

    buildInputs = [
      alsa-lib
      at-spi2-atk
      cairo
      cups
      dbus
      expat
      gdk-pixbuf
      glib
      gtk3
      libdrm
      libxkbcommon
      mesa
      nspr
      nss
      pango
      libx11
      libxcomposite
      libxdamage
      libxext
      libxfixes
      libxrandr
      libxcb
      libGL
    ];

    unpackPhase = ''
      dpkg-deb -x $src .
    '';

    installPhase = ''
      runHook preInstall

      mkdir -p "$out/lib" "$out/bin" "$out/share"

      cp -r usr/lib/codiff "$out/lib/codiff"
      cp -r usr/share/* "$out/share/"

      makeWrapper "$out/lib/codiff/codiff" "$out/bin/codiff" \
        --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath [
          libGL
          libxkbcommon
          libx11
        ]}"

      runHook postInstall
    '';

    meta = {
      description = "A fast local diff viewer";
      homepage = "https://github.com/nkzw-tech/codiff";
      license = lib.licenses.mit;
      platforms = [ "x86_64-linux" ];
      mainProgram = "codiff";
    };
  }
