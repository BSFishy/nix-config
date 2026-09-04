{
  lib,
  buildGoModule,
  fetchFromGitHub,
  git,
  makeWrapper,
}:

buildGoModule rec {
  pname = "open-code-review";
  version = "1.11.3";

  src = fetchFromGitHub {
    owner = "alibaba";
    repo = "open-code-review";
    rev = "v${version}";
    hash = "sha256-YBAvkS8LhuztSFQjChmEKKO5agIDvxsPFLxrTxeTn8k=";
  };

  vendorHash = "sha256-RdIDGoDx/aIqm7gD2acHi9THVjZg5DkNU0y2S/cHm28=";
  subPackages = [ "cmd/opencodereview" ];

  nativeBuildInputs = [ makeWrapper ];
  nativeCheckInputs = [ git ];

  postInstall = ''
    mv $out/bin/opencodereview $out/bin/.opencodereview-real
    makeWrapper $out/bin/.opencodereview-real $out/bin/ocr
    ln -s $out/bin/.opencodereview-real $out/bin/opencodereview
  '';

  meta = with lib; {
    description = "AI-powered code review CLI";
    homepage = "https://github.com/alibaba/open-code-review";
    license = licenses.asl20;
    mainProgram = "ocr";
    platforms = platforms.unix;
  };
}
