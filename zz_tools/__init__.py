try:
    from importlib.metadata import version, PackageNotFoundError
    __version__ = "0.2.99"
except Exception:
    __version__ = "0.2.99"
# exports publics éventuels
from .common_io import *  # si nécessaire pour ton API

# --- Version helpers (ajoutés pour exposer dist_version et __version__) ---
try:
    # On importe depuis importlib.metadata, mais avec des alias internes
    from importlib.metadata import (
        PackageNotFoundError as _PkgNotFoundError,
        version as _dist_version,
    )
except Exception:  # pragma: no cover - cas très exotique
    _PkgNotFoundError = Exception  # type: ignore[assignment]
    def _dist_version(dist_name: str = "zz-tools") -> str:  # type: ignore[no-redef]
        raise RuntimeError("importlib.metadata.version indisponible")

def dist_version(dist_name: str = "zz-tools") -> str:
    """
    Retourne la version installée d'un paquet (par défaut zz-tools),
    en s'appuyant sur importlib.metadata.version.

    Exemple :
        >>> import zz_tools
        >>> zz_tools.dist_version()
        '0.3.2.dev0'
    """
    return _dist_version(dist_name)

try:
    # __version__ reflète la version de la distribution installée
    __version__ = dist_version()
except _PkgNotFoundError:  # pragma: no cover - cas editable/local sans metadata
    # Fallback raisonnable pour les installs locales / dev sans metadata
    __version__ = "0.0.0+local"
