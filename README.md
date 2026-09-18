# nf-mod-bcftools

Nextflow module for BCFtools (variant calling and VCF/BCF manipulation). Used as a git submodule by pipelines.

Image: `ghcr.io/eit-gbi/nf-mod-bcftools:v1.0.0`

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

For `BCFTOOLS_CALL` the three slots map to the three commands it pipes together:

```groovy
process {
    withName: BCFTOOLS_CALL {
        ext.args  = '-q 20 -a AD,DP'                    // bcftools mpileup
        ext.args2 = '--ploidy 1'                        // bcftools call
        ext.args3 = "-e 'FMT/DP<10 || QUAL<20'"         // bcftools filter
    }
}
```

`-a AD,DP` is worth passing whenever `BCFTOOLS_CSV` runs downstream: it queries
`%DP` and `[%AD]`, which are only present if mpileup was asked for them. The
single quotes around the filter expression are load-bearing - they keep `||` and
`<` away from the shell.

## Use as submodule

Pin to a release tag rather than a branch, so pipeline runs stay reproducible:

```bash
git submodule add https://github.com/EIT-GBI/nf-mod-bcftools.git modules/bcftools
git -C modules/bcftools checkout v1.0.0
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

## Tests

`nf-test test`. Each process has a stub test covering wiring and output names,
and tests that run bcftools for real against
`ghcr.io/eit-gbi/nf-mod-bcftools:latest` and snapshot what comes out. The real
tests need Docker. `tests.config` gives the container; `tests-thresholds.config`
adds mpileup/call/filter flags through `ext.args`, and the `-strict` variant
raises the minimum depth so the filter can be seen changing what survives.

`BCFTOOLS_CONSENSUS`, `BCFTOOLS_CSV` and `BCFTOOLS_VCF` run `BCFTOOLS_CALL` in a
`setup` block to get a real BCF. The config a test names applies to that setup
too, so each test calls with its own flags.

What `BCFTOOLS_CALL` produced is asserted in those downstream tests rather than
in its own: a `-Ob` BCF is not readable by nf-test, and its checksum differs
between two identical runs because bcftools stamps a `Date` into the header. The
VCF test reads the gzipped output as text and asserts the `##bcftools_*Command`
header lines with the version and timestamp stripped, which confirms the flags
reached each of the three commands intact.

## Releasing

Merging a PR to `main` with exactly one `bump:patch`, `bump:minor` or
`bump:major` label bumps `manifest.version` in `nextflow.config`, tags the
release and publishes the container image.
