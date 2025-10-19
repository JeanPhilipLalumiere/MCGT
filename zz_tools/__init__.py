try:
    from importlib.metadata import version, PackageNotFoundError
except Exception:
    try:
        from importlib_metadata import version, PackageNotFoundError  # backport
    except Exception:
        version = None; PackageNotFoundError = Exception

try:
    __version__ = version("zz-tools")
except Exception:
    __version__ = "0+unknown"

