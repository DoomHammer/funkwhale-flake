{
  description = "Funkwhale";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";

  outputs =
    { self, nixpkgs }:
    let
      version = "2.0.0-rc5";
      funkwhale-sha256 = "sha256-9Hq27CEEwKl1WVYhZVQf4pc91uT55Qr+dqVA9avxzWA=";
      funkwhale-front-sha256 = "sha256-FvZ/8q7WS+xfaH+fcLPiK0STVJVCqwSyqV1sBSDgEWE=";
      systems = [
        "x86_64-linux"
        "i686-linux"
        "aarch64-linux"
      ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f system);
      # Memoize nixpkgs for different platforms for efficiency.
      nixpkgsFor = forAllSystems (
        system:
        import nixpkgs {
          inherit system;
          overlays = [ self.overlays.default ];
        }
      );
    in
    {
      overlays.default = final: prev: {

        funkwhale-front =
          with final;
          stdenv.mkDerivation {
            pname = "funkwhale-front";
            inherit version;

            nativeBuildInputs = [ pkgs.unzip ];
            unpackCmd = "unzip $curSrc";

            src = fetchurl {
              url = "https://dev.funkwhale.audio/funkwhale/funkwhale/-/jobs/artifacts/${version}/download?job=build_front";
              sha256 = funkwhale-front-sha256;
            };

            installPhase = ''
              mkdir $out
              cp -R ./dist/* $out
            '';
          };

        funkwhale =
          with final;
          (stdenv.mkDerivation {
            pname = "funkwhale";
            inherit version;

            src = fetchurl {
              url = "https://dev.funkwhale.audio/funkwhale/funkwhale/-/archive/${version}/funkwhale-${version}.tar.bz2";
              sha256 = funkwhale-sha256;
            };

            propagatedBuildInputs = [

            ];

            patches = [ ./funkwhale.patch ];

            buildPhase = ''echo Skipping build phase'';

            installPhase = ''
              mkdir $out
              cp -R ./* $out
            '';

            meta = with lib; {
              description = "A modern, convivial and free music server";
              homepage = "https://funkwhale.audio/";
              license = licenses.agpl3Plus;
              platforms = platforms.linux;
              maintainers = with maintainers; [ mmai ];
            };
          });

        # ------------- new packages -------------------

        requests-http-message-signatures =
          with final;
          with pkgs.python3.pkgs;
          (buildPythonPackage rec {
            pname = "requests-http-message-signatures";
            version = "0.3.1";
            src = fetchPypi {
              inherit pname version;
              sha256 = "sha256-AjW7XNP0p9ZZZF4qyTfacnkTIUNOd1cPfiEELlEIINo=";
            };

            buildInputs = [
              poetry-core
            ];
            propagatedBuildInputs = [
              requests
              cryptography
            ];
            doCheck = false;

            pyproject = true;
            build_system = [ "poetry" ];
          });

        countryinfo =
          with final;
          with pkgs.python3.pkgs;
          (buildPythonPackage rec {
            pname = "countryinfo";
            version = "5b95b184cbdff6de8820be0b811a6cc65448c954";
            format = "setuptools";

            src = fetchFromGitHub {
              owner = "porimol";
              repo = "countryinfo";
              rev = "${version}";
              fetchSubmodules = true;
              hash = "sha256-k9GvqjnXE6xDAKD2fqAfAWU5r8qHDGRIu3ngeMfX19k=";
            };
            #
            # # Make a minimal pyproject.toml that can be built
            # unpackPhase = ''
            #   cat > pyproject.toml << EOF
            #   [project]
            #   name = "${pname}"
            #   version = "${version}"
            #   EOF
            # '';

            # buildInputs = [
            #   setuptools
            # ];

            pythonImportsCheck = [
              "countryinfo"
            ];

            meta = with lib; {
              description = "A python module for returning data about countries, ISO info and states/provinces within them.";
              homepage = "https://github.com/porimol/countryinfo";
              license = licenses.mit;
            };
          });

        django-cache-memoize =
          with final;
          with pkgs.python3.pkgs;
          (buildPythonPackage rec {
            pname = "django-cache-memoize";
            version = "0.2.0";
            src = fetchPypi {
              inherit pname version;
              sha256 = "sha256-eZUKAnukDkr/Tv7Vh7dgNr9bofWTKdexWHl7gyvnLKY=";
            };
            propagatedBuildInputs = [ ];

            buildInputs = [
              setuptools
            ];
            doCheck = false;

            pyproject = true;
            build_system = [ "setup_tools" ];
          });

        django-versatileimagefield =
          with final;
          with pkgs.python3.pkgs;
          (buildPythonPackage rec {
            pname = "django-versatileimagefield";
            version = "3.0";

            src = fetchPypi {
              inherit pname version;
              hash = "sha256-FlHbLtNthDz7F4jyYBRyopPZuoZyk2m29uVZERI1esc=";
            };
            propagatedBuildInputs = [
              django
              pillow
              python-magic
            ];

            nativeCheckInputs = [ django ];

            # tests not included with pypi release
            doCheck = false;

            pythonImportsCheck = [ "versatileimagefield" ];

            meta = with lib; {
              description = "Replaces django's ImageField with a more flexible interface";
              homepage = "https://github.com/respondcreate/django-versatileimagefield/";
              license = licenses.mit;
              maintainers = with maintainers; [ mmai ];
            };
          });

        # ------------- will be in 23.11
        jsonschema-specifications =
          with final;
          with pkgs.python3.pkgs;
          (buildPythonPackage rec {
            pname = "jsonschema-specifications";
            version = "2023.7.1";
            format = "pyproject";

            disabled = pythonOlder "3.8";

            src = fetchPypi {
              pname = "jsonschema_specifications";
              inherit version;
              hash = "sha256-yRpQQE6Iofa6QGNneOLuCPbiTFYT/kxTrCRXilp/crs=";
            };

            nativeBuildInputs = [
              hatch-vcs
              hatchling
            ];

            propagatedBuildInputs = [
              referencing
            ]
            ++ lib.optionals (pythonOlder "3.9") [
              importlib-resources
            ];

            nativeCheckInputs = [
              pytestCheckHook
            ];

            pythonImportsCheck = [
              "jsonschema_specifications"
            ];

            meta = with lib; {
              description = "Support files exposing JSON from the JSON Schema specifications";
              homepage = "https://github.com/python-jsonschema/jsonschema-specifications";
              license = licenses.mit;
              maintainers = with maintainers; [ SuperSandro2000 ];
            };
          });

        lb_matching_tools =
          with final;
          with pkgs.python3.pkgs;
          (buildPythonPackage rec {
            pname = "listenbrainz-matching-tools";
            version = "2024.01.30.1";
            format = "pyproject";

            src = fetchFromGitHub {
              owner = "metabrainz";
              repo = "listenbrainz-matching-tools";
              rev = "refs/tags/v${version}";
              fetchSubmodules = true;
              hash = "sha256-RQ4X6DKigQsNxaAWXB1meATKP+ddMUgkoAIyX8iIisU=";
            };

            build_system = [ "setup_tools" ];

            buildInputs = [
              setuptools
              setuptools-scm
            ];

            propagatedBuildInputs = [
              regex
            ];

            pythonImportsCheck = [
              "lb_matching_tools"
            ];

            meta = with lib; {
              description = "Useful tools for matching metadata to and from MusicBrainz.";
              homepage = "https://github.com/metabrainz/listenbrainz-matching-tools";
              license = licenses.gpl3;
            };
          });

        liblistenbrainz =
          with final;
          with pkgs.python3.pkgs;
          (buildPythonPackage rec {
            pname = "liblistenbrainz";
            version = "0.6.1";
            format = "pyproject";

            src = fetchFromGitHub {
              owner = "metabrainz";
              repo = "liblistenbrainz";
              rev = "refs/tags/v${version}";
              fetchSubmodules = true;
              hash = "sha256-2/EUzkC+8u6SQZYstIqJnlWcz74f5UpuXh/r4ImNd0g=";
            };

            build_system = [
              "setuptools"
            ];

            buildInputs = [
              setuptools
              setuptools-scm
            ];

            propagatedBuildInputs = [
              requests
            ];

            pythonImportsCheck = [
              "liblistenbrainz"
            ];

            meta = with lib; {
              description = "A simple ListenBrainz client library for Python";
              homepage = "https://pylistenbrainz.readthedocs.io/en/latest/";
              license = licenses.gpl3;
            };
          });

        referencing =
          with final;
          with pkgs.python3.pkgs;
          (buildPythonPackage rec {
            pname = "referencing";
            version = "0.30.0";
            format = "pyproject";

            disabled = pythonOlder "3.7";

            src = fetchFromGitHub {
              owner = "python-jsonschema";
              repo = "referencing";
              rev = "refs/tags/v${version}";
              fetchSubmodules = true;
              hash = "sha256-nJSnZM3gg2+yfFAnOJzzXsmIEQdNf5ypt5R0O60NphA=";
            };

            SETUPTOOLS_SCM_PRETEND_VERSION = version;

            nativeBuildInputs = [
              hatch-vcs
              hatchling
            ];

            propagatedBuildInputs = [
              attrs
              rpds-py
            ];

            nativeCheckInputs = [
              jsonschema
              pytest-subtests
              pytestCheckHook
            ];

            # avoid infinite recursion with jsonschema
            doCheck = false;

            passthru.tests.referencing = self.overridePythonAttrs { doCheck = true; };

            pythonImportsCheck = [
              "referencing"
            ];

            meta = with lib; {
              description = "Cross-specification JSON referencing";
              homepage = "https://github.com/python-jsonschema/referencing";
              changelog = "https://github.com/python-jsonschema/referencing/blob/${version}/CHANGELOG.rst";
              license = licenses.mit;
              maintainers = with maintainers; [ fab ];
            };
          });

        rpds-py =
          with final;
          with pkgs.python3.pkgs;
          (buildPythonPackage rec {
            pname = "rpds-py";
            version = "0.9.2";
            format = "pyproject";

            disabled = pythonOlder "3.8";

            src = fetchPypi {
              pname = "rpds_py";
              inherit version;
              hash = "sha256-jXDo8UkA8mV8JJ6k3vljvthqKbgfgfW3a1qSFWgN6UU=";
            };

            cargoDeps = rustPlatform.fetchCargoTarball {
              inherit src;
              name = "${pname}-${version}";
              hash = "sha256-2LiQ+beFj9+kykObPNtqcg+F+8wBDzvWcauwDLHa7Yo=";
            };

            nativeBuildInputs = [
              rustPlatform.cargoSetupHook
              rustPlatform.maturinBuildHook
              cargo
              rustc
            ];

            buildInputs = lib.optionals stdenv.hostPlatform.isDarwin [
              libiconv
            ];

            nativeCheckInputs = [
              pytestCheckHook
            ];

            pythonImportsCheck = [
              "rpds"
            ];

            meta = with lib; {
              description = "Python bindings to Rust's persistent data structures (rpds";
              homepage = "https://pypi.org/project/rpds-py/";
              license = licenses.mit;
              maintainers = with maintainers; [ fab ];
            };
          });

        typesense =
          with final;
          with pkgs.python3.pkgs;
          (buildPythonPackage rec {
            pname = "typesense";
            version = "1.0.3";
            format = "pyproject";

            src = fetchFromGitHub {
              owner = "typesense";
              repo = "typesense-python";
              rev = "refs/tags/v${version}";
              fetchSubmodules = true;
              hash = "sha256-Ij4AFldTXMu3s/SMrd5aFHDKEx0kYtBsdQLO45hMALc=";
            };

            build_system = [ "setup_tools" ];

            buildInputs = [
              setuptools
            ];

            propagatedBuildInputs = [
              requests
              typing-extensions
            ];

            pythonImportsCheck = [
              "typesense"
            ];

            meta = with lib; {
              description = "Python client for Typesense, an open source and typo tolerant search engine.";
              homepage = "https://github.com/typesense/typesense-python";
              license = licenses.asl20;
            };
          });

        troi =
          with final;
          with pkgs.python3.pkgs;
          (buildPythonPackage rec {
            pname = "troi";
            version = "2025.08.06.3";
            format = "pyproject";

            src = fetchFromGitHub {
              owner = "metabrainz";
              repo = "troi-recommendation-playground";
              rev = "refs/tags/v${version}";
              fetchSubmodules = true;
              hash = "sha256-qLnXaNb1Kon+XPJYCPe31EgXpukIfzTa+LADOzFjE9Q=";
            };

            build_system = [ "setup_tools" ];

            buildInputs = [
              setuptools
              setuptools-scm
            ];

            propagatedBuildInputs = [
              click
              countryinfo
              lb_matching_tools
              liblistenbrainz
              more-itertools
              mutagen
              peewee
              psycopg2-binary
              py-sonic
              python-dateutil
              requests
              scikit-learn
              spotipy
              tqdm
              ujson
              unidecode
            ];

            nativeBuildInputs = [ pythonRelaxDepsHook ];
            pythonRelaxDeps = [ "mutagen" ];

            pythonImportsCheck = [
              "troi"
            ];

            meta = with lib; {
              description = "A recommendation engine playground that should hopefully make playing with music recommendations easy.";
              homepage = "https://github.com/metabrainz/troi-recommendation-playground";
              license = licenses.gpl2;
            };
          });

        django-allauth =
          with final;
          pkgs.python3.pkgs.django-allauth.overrideAttrs (oa: rec {
            version = "65.4.1";
            src = pkgs.fetchFromGitea {
              domain = "codeberg.org";
              owner = "allauth";
              repo = "django-allauth";
              tag = version;
              hash = "sha256-z5vaNopIk1CAV+TpH/V3Y6lXf7ztU4QeHZ9OTSPCgc0=";
            };
            doCheck = false;
            dontUsePytestCheck = "please dont";
          });

        unicode-slugify =
          with final;
          with pkgs.python3.pkgs;
          (buildPythonPackage rec {
            pname = "unicode-slugify";
            version = "0.1.5";
            format = "setuptools";

            src = fetchPypi {
              inherit pname version;
              sha256 = "25f424258317e4cb41093e2953374b3af1f23097297664731cdb3ae46f6bd6c3";
            };

            patches = [
              ./use_pytest_instead_of_nose.patch
              # mozilla/unicode-slugify#41: Fix Python 3.12 SyntaxWarning
              (fetchpatch {
                url = "https://github.com/mozilla/unicode-slugify/commit/a18826f440d0b74e536f5e32ebdcf30e720f20d8.patch";
                hash = "sha256-B27psp0XI5GhoR0l5lFpUOh88hHzjJYzJS5PnIkfFws=";
              })
            ];

            propagatedBuildInputs = [
              six
              unidecode
            ];

            nativeCheckInputs = [ pytestCheckHook ];

            doCheck = false;

            pytestFlagsArray = [ "slugify/tests.py" ];

            meta = with lib; {
              description = "Generates unicode slugs";
              homepage = "https://pypi.org/project/unicode-slugify/";
              license = licenses.bsd3;
              maintainers = with maintainers; [ mmai ];
            };
          });

      };

      packages = forAllSystems (system: {
        inherit (nixpkgsFor.${system}) funkwhale;
        inherit (nixpkgsFor.${system}) funkwhale-front;
        inherit (nixpkgsFor.${system}) requests-http-message-signatures;
        inherit (nixpkgsFor.${system}) django-cache-memoize;
        inherit (nixpkgsFor.${system}) lb_matching_tools;
        inherit (nixpkgsFor.${system}) liblistenbrainz;
        inherit (nixpkgsFor.${system}) typesense;
        inherit (nixpkgsFor.${system}) troi;
        inherit (nixpkgsFor.${system}) django-allauth;
        inherit (nixpkgsFor.${system}) unicode-slugify;
      });

      defaultPackage = forAllSystems (system: self.packages.${system}.funkwhale);

      # funkwhale service module
      nixosModules.default = (import ./module.nix);

    };
}
