try:
    from importlib.metadata import version, PackageNotFoundError
    __version__ = "0.3.13"
except Exception:
    __version__ = "0.3.13"
# exports publics éventuels
from .common_io import *  # si nécessaire pour ton API
