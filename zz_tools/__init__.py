try:
    from importlib.metadata import version, PackageNotFoundError
    __version__ = version("zz-tools")
except Exception:
    __version__ = "0+unknown"
# exports publics éventuels
from .common_io import *  # si nécessaire pour ton API
