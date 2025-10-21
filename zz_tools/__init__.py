try:
    from importlib.metadata import version, PackageNotFoundError
    __version__ = "0.2.99"
except Exception:
    __version__ = "0.2.99"
# exports publics éventuels
from .common_io import *  # si nécessaire pour ton API
