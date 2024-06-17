{ pkgs, lib, stdenv, fetchFromGitHub, rustPlatform, coreutils, bash, direnv, openssl, git }:

rustPlatform.buildRustPackage {
  pname = "mise";
  version = "2024.6.2";

  src = lib.cleanSource ./.;

  cargoLock = {
    lockFile = ./Cargo.lock;
  };

  nativeBuildInputs = with pkgs; [ pkg-config ];
  buildInputs = with pkgs; [
    coreutils
    bash
    direnv
    gnused
    git
    gawk
    openssl
  ] ++ lib.optionals stdenv.isDarwin [ darwin.apple_sdk.frameworks.Security darwin.apple_sdk.frameworks.SystemConfiguration ];

  prePatch = ''
    substituteInPlace ./test/data/plugins/**/bin/* \
      --replace '#!/usr/bin/env bash' '#!${bash}/bin/bash'
    substituteInPlace ./src/fake_asdf.rs \
      --replace '#!/bin/sh' '#!${bash}/bin/sh'
    substituteInPlace ./src/env_diff.rs \
      --replace '"bash"' '"${bash}/bin/bash"'
    substituteInPlace ./src/cli/direnv/exec.rs \
      --replace '"env"' '"${coreutils}/bin/env"' \
      --replace 'cmd!("direnv"' 'cmd!("${direnv}/bin/direnv"'
    substituteInPlace ./src/test.rs \
      --replace '"git"' '"${git}/bin/git"' \
      --replace '/usr/bin/env bash' '${bash}/bin/bash'
  '';

  # Skip the test_plugin_list_urls as it uses the .git folder, which
  # is excluded by default from Nix.
  checkPhase = ''
    RUST_LOG=debug RUST_BACKTRACE=full cargo test --all-features -- \
      cli::generate::git_pre_commit::tests::test_git_pre_commit_write \
      --skip cli::plugins::ls::tests::test_plugin_list_urls \
      --nocapture
  '';

  meta = with lib; {
    description = "The front-end to your dev env";
    homepage = "https://github.com/jdx/mise";
    license = licenses.mit;
  };
}
