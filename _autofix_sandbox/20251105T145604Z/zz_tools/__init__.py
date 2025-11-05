import contextlib
with contextlib.suppress(Exception):
    from importlib.metadata import version, PackageNotFoundError

    __version__ = "0.3.0"
# exports publics éventuels
from .common_io import *  # si nécessaire pour ton API
