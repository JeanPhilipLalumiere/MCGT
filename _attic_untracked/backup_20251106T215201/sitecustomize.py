# sitecustomize.py — MCGT help-sweep (argparse monkeypatch, no SystemExit at import)
import os, sys
if os.environ.get("MCGT_HELP_SHIM","") == "1" and any(x in sys.argv for x in ("-h","--help")):
    try:
        import argparse, os as _os

        _orig_exit = argparse.ArgumentParser.exit
        _orig_parse = argparse.ArgumentParser.parse_args
        _orig_parse_known = argparse.ArgumentParser.parse_known_args

        def _shim_exit(self, status=0, message=None):
            # force code 0 pour --help intercepté; sinon, passe-through
            if status == 0:
                if message:
                    try: self._print_message(message, sys.stderr)
                    except Exception: pass
                _os._exit(0)
            return _orig_exit(self, status, message)

        def _shim_parse(self, *a, **k):
            # imprimer l'aide et sortir proprement sans exécuter le script
            self.print_help()
            _os._exit(0)

        def _shim_parse_known(self, *a, **k):
            self.print_help()
            _os._exit(0)

        argparse.ArgumentParser.exit = _shim_exit
        argparse.ArgumentParser.parse_args = _shim_parse
        argparse.ArgumentParser.parse_known_args = _shim_parse_known
    except Exception:
        # en cas d'échec, on ne casse pas le démarrage normal
        pass
