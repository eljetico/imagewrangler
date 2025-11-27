# ImageWrangler

Somewhat convoluted image handling toolbox providing wrappers for ImageMagick (MiniMagick, Ghostscript etc), Exiftool and C2PA.

The main program loading this gem should be equipped with these packages already loaded and configured (`policy.xml` etc).

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

Run docker-compose:

```bash
dc up -d
```

Run tests:

```bash
docker exec imagewrangler rake
```

Run linter (standardrb):

```bash
docker exec imagewrangler rake standard
```
