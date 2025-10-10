if __name__ == "__main__":
    import argparse, pathlib
    parser = argparse.ArgumentParser()
    parser.add_argument("--outdir", type=pathlib.Path, default=pathlib.Path(".ci-out"))
    parser.add_argument("--seed", type=int, default=None)
    parser.add_argument("--dpi", type=int, default=150)
    args = parser.parse_args()
    pass
