# nf-mod-bcftools


Nextflow module for bcftools. Used as a git submodule by pipelines.

Image: `ghcr.io/eit-gbi/nf-mod-bcftools:latest`

## Processes

- `BCFTOOLS` — TODO: describe inputs/outputs

## Use as submodule
```bash
git submodule add https://github.com/eit-gbi/nf-mod-bcftools.git modules/bcftools
```

Then in your pipeline:
```
include { BCFTOOLS } from './modules/bcftools/main.nf'
```
