try:
    from importlib.metadata import version, PackageNotFoundError
    __version__ = "0.3.11"
except Exception:
    __version__ = "0.3.11"
# exports publics éventuels
from .common_io import *  # si nécessaire pour ton API
