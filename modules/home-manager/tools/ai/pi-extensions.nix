{ lib, pkgs, ... }:

let
  onnxRuntimeDylib =
    if pkgs.stdenv.hostPlatform.isDarwin then
      "${pkgs.onnxruntime}/lib/libonnxruntime.dylib"
    else
      "${pkgs.onnxruntime}/lib/libonnxruntime.so";

  # Use a pre-exported ONNX variant of all-MiniLM-L6-v2 so the Rust backend can
  # load a local model file directly via ort. The tokenizer is paired from the
  # same model repository.
  memoryModel = pkgs.fetchurl {
    url = "https://huggingface.co/Xenova/all-MiniLM-L6-v2/resolve/main/onnx/model.onnx";
    hash = "sha256-dZw80rf+fpOTOtI8TJGBtzlkQqLtdG7HwdRhksRpxG4=";
  };

  memoryTokenizer = pkgs.fetchurl {
    url = "https://huggingface.co/Xenova/all-MiniLM-L6-v2/resolve/main/tokenizer.json";
    hash = "sha256-2g55kzue1ReYo64niT08X6SiARJs73VYYpbfm00sYqA=";
  };

  memoryBackend = pkgs.rustPlatform.buildRustPackage {
    pname = "pi-memory-backend";
    version = "0.1.0";

    src = ./memory_backend;
    cargoLock.lockFile = ./memory_backend/Cargo.lock;

    nativeBuildInputs = [
      pkgs.makeWrapper
    ];

    postInstall = ''
      wrapProgram $out/bin/pi-memory-backend \
        --set PI_MEMORY_ORT_DYLIB_PATH ${onnxRuntimeDylib} \
        --set PI_MEMORY_MODEL_PATH ${memoryModel} \
        --set PI_MEMORY_TOKENIZER_PATH ${memoryTokenizer} \
        --set PI_MEMORY_MODEL_NAME all-MiniLM-L6-v2
    '';

    meta = {
      description = "Rust memory backend for the Pi memory extension";
      platforms = lib.platforms.unix;
    };
  };

  memoryExtension =
    pkgs.runCommand "pi-memory-extension-0.1.0"
      {
        nativeBuildInputs = [ pkgs.gnused ];
        meta = {
          description = "Pi memory extension client for an external memory backend";
          platforms = lib.platforms.unix;
        };
      }
      ''
        mkdir -p $out/memory
        cp -r ${./extensions/memory}/. $out/memory/

        substituteInPlace $out/memory/backend.ts \
          --replace-fail '__PI_MEMORY_BACKEND__' '${memoryBackend}/bin/pi-memory-backend'
      '';
in
{
  home.file.".pi/agent/extensions/verification.ts".source = ./extensions/verification.ts;
  home.file.".pi/agent/extensions/memory".source = "${memoryExtension}/memory";
}
