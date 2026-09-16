# nf-mod-bcftools

Nextflow module for BCFtools (variant calling and VCF/BCF manipulation). Used as a git submodule by pipelines.

Image: `ghcr.io/eit-gbi/nf-mod-bcftools:v0.0.0`

## Processes

Each subtool lives in its own folder (nf-core style), with a `main.nf`, a
`meta.yml` and an nf-test case under `tests/`.

| Process | Path | Inputs | Emits |
| --- | --- | --- | --- |
| `BCFTOOLS_CALL` | `call/main.nf` | `tuple val(meta), path(bam), path(bai)`<br>`tuple path(fasta), path(fai)` | `bcf` |
| `BCFTOOLS_CONSENSUS` | `consensus/main.nf` | `tuple val(meta), path(bcf), path(csi)`<br>`tuple path(fasta), path(fai)` | `consensus` |
| `BCFTOOLS_CSV` | `csv/main.nf` | `tuple val(meta), path(bcf), path(csi)` | `csv` |
| `BCFTOOLS_VCF` | `vcf/main.nf` | `tuple val(meta), path(bcf), path(csi)` | `vcf` |

## Publishing

These processes do **not** publish their own outputs. Publishing is the
consuming pipeline's job, via a workflow `output {}` block. This keeps the
module reusable across pipelines that want different result layouts.

## Tool arguments

Flags are passed through `task.ext.args` (and `args2`/`args3` where a process
runs more than one command) rather than read from pipeline `params`, so the
module never depends on a particular pipeline's parameter names:

```groovy
process {
    withName: BCFTOOLS_CALL {
        ext.args = '--some-flag'
    }
}
```

## Use as submodule

Pin to a release tag rather than a branch, so pipeline runs stay reproducible:

```bash
git submodule add https://github.com/EIT-GBI/nf-mod-bcftools.git modules/bcftools
git -C modules/bcftools checkout v0.0.0
```

Then include the module's container config from your `nextflow.config`. Nextflow
does not read a submodule's config on its own, so without this line the
processes have no image:

```groovy
includeConfig 'modules/bcftools/conf/module.config'
```

`conf/module.config` pins the image to the version built from this same commit,
and carries no `manifest {}` block, so it will not overwrite your pipeline's
own manifest. Override it in your pipeline with a `withName` selector if needed.

And include the processes:

```groovy
include { BCFTOOLS_CALL } from './modules/bcftools/call/main.nf'
include { BCFTOOLS_CONSENSUS } from './modules/bcftools/consensus/main.nf'
include { BCFTOOLS_CSV } from './modules/bcftools/csv/main.nf'
include { BCFTOOLS_VCF } from './modules/bcftools/vcf/main.nf'
```

## Requirements

Nextflow 26.04.4 or newer.

## Releasing

Merging a PR to `main` with exactly one `bump:patch`, `bump:minor` or
`bump:major` label bumps `manifest.version` in `nextflow.config`, tags the
release and publishes the container image.
