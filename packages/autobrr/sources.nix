{ fetchFromGitHub }:
rec {
  pname = "autobrr";
  version = "1.48.0";
  src = fetchFromGitHub {
    owner = "autobrr";
    repo = "autobrr";
    rev = "v${version}";
    hash = "sha256-aCIjdVSBxR2Uq96ZtKrU97LpzIR6Pcfv0vLJNCdRrC0=";
  };

  vendorHash = "sha256-C+SzLqdzOLp4BDwE097RtsrR34davPzylgWN3mMoGaU=";
  pnpmDepsHash = "sha256-Fkr/VFTh7foQBKbw0C5oJLr3pFA1wdYNmjEsoCemJ/I=";
}

