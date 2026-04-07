{
  lib,
  fetchFromGitHub,
  makeWrapper,
  python3Packages,
}:

python3Packages.buildPythonPackage rec {
  pname = "mempalace";
  version = "3.0.0";

  pyproject = true;

  src = fetchFromGitHub {
    owner = "milla-jovovich";
    repo = "mempalace";
    rev = "v${version}";
    sha256 = "0xyf6h313zbg3q0k0qlj5ak9fsvz3h4rfz8qk41qkllzab553s2p";
  };

  build-system = [ python3Packages.setuptools ];

  propagatedBuildInputs = [
    python3Packages.chromadb
    python3Packages.grpcio
    python3Packages.pyyaml
  ];

  nativeBuildInputs = [ makeWrapper ];

  postInstall =
    let
      pythonPath = python3Packages.makePythonPath propagatedBuildInputs;
    in
    ''
      install -Dm755 hooks/mempal_save_hook.sh $out/share/mempalace/hooks/mempal_save_hook.sh
      install -Dm755 hooks/mempal_precompact_hook.sh $out/share/mempalace/hooks/mempal_precompact_hook.sh

      substituteInPlace $out/share/mempalace/hooks/mempal_save_hook.sh \
        --replace "python3 -m mempalace " "$out/bin/mempalace "
      substituteInPlace $out/share/mempalace/hooks/mempal_precompact_hook.sh \
        --replace "python3 -m mempalace " "$out/bin/mempalace "

      makeWrapper ${python3Packages.python.interpreter} $out/bin/mempalace-mcp \
        --add-flags "-m mempalace.mcp_server" \
        --set PYTHONPATH "$out/${python3Packages.python.sitePackages}:${pythonPath}"
    '';

  doCheck = false;

  meta = with lib; {
    description = "Local AI memory system with palace structure and MCP server";
    homepage = "https://github.com/milla-jovovich/mempalace";
    license = licenses.mit;
    mainProgram = "mempalace";
    platforms = platforms.all;
  };
}
