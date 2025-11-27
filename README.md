# ImageWrangler

Somewhat convoluted image handling toolbox providing wrappers for ImageMagick (MiniMagick, Ghostscript etc), Exiftool and C2PA.

The main program loading this gem should be equipped with these packages - this repo contains fixed versions of them (except c2patool which is loaded using `rustup`) for consistency in development.

## Development

To set up for local development, first build the base image:

```bash
# From the project root
./build_base.sh
```

Then, build the main image:

```bash
./build.sh
```
