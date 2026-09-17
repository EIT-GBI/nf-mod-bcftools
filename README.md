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

Extra tool flags are passed through `task.ext.args` (and `args2`/`args3` where a
process runs more than one command). For `BCFTOOLS_CALL` these map to
`mpileup`, `call` and `filter` respectively:

```groovy
process {
    withName: BCFTOOLS_CALL {
        ext.args = '--some-flag'
    }
}
```

## Module-owned parameters

Where a setting is a property of what the module *does* rather than of a
particular pipeline, the module owns it: it declares the `params` names and
builds the tool invocation from them, so every consuming pipeline configures it
the same way instead of each one re-deriving the same flags.

`BCFTOOLS_CALL` works this way:

| Param | Becomes |
| --- | --- |
| `params.calling.min_mapq` | `-q <value>` on `bcftools mpileup` |
| `params.calling.ploidy` | `--ploidy <value>` on `bcftools call` |
| `params.calling.min_depth` | `FMT/DP<<value>` in the `bcftools filter` exclude expression |
| `params.calling.min_qual` | `QUAL<<value>` in the same expression |

```groovy
params {
    calling {
        min_mapq  = 20
        ploidy    = 1
        min_depth = 10
        min_qual  = 20
    }
}
// -> mpileup -q 20 -a AD,DP | call --ploidy 1 | filter -e 'FMT/DP<10 || QUAL<20'
```

Any of them may be left unset, which drops that flag or term. With none set the
calls are not filtered at all, so a pipeline that does not set `params.calling`
keeps its previous behaviour.

The namespace is `calling` rather than `call`, which matches the process name:
`call` cannot be used, because a `call { }` block in nf-test's params DSL is
parsed as invoking the closure and recurses until the JVM stack overflows.

`-a AD,DP` is always passed to `mpileup`. It is not a pipeline choice:
`BCFTOOLS_CSV` queries `%DP` and `[%AD]`, so the annotations have to be there.

Do **not** declare defaults for these in `conf/module.config`. Pipelines
normally `includeConfig` that file *after* their own `params` block, so a
default there would silently overwrite whatever the pipeline had set.

Setting `params.calling.min_depth`/`min_qual` and also passing `-e` through
`ext.args3` is an error: bcftools filter honours only the last `-e`, which would
silently drop one of the two filters, so the process fails instead.

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

## Tests

`nf-test test`. Each process has a stub test covering wiring and output names,
and tests that run bcftools for real against
`ghcr.io/eit-gbi/nf-mod-bcftools:latest` and snapshot what comes out. The real
tests need Docker.

`BCFTOOLS_CONSENSUS`, `BCFTOOLS_CSV` and `BCFTOOLS_VCF` run `BCFTOOLS_CALL` in a
`setup` block to get a real BCF; params set in a test's `when` block reach that
setup too, so each test calls with its own thresholds.

What `BCFTOOLS_CALL` produced is asserted in those downstream tests rather than
in its own: a `-Ob` BCF is not readable by nf-test, and its checksum differs
between two identical runs because bcftools stamps a `Date` into the header. The
VCF test reads the gzipped output as text and asserts the `##bcftools_*Command`
header lines with the version and timestamp stripped. That is what pins the
comparison operators - variant counts alone cannot tell `QUAL<` from `QUAL<=`
unless the test data happens to sit on the boundary.

## Releasing

Merging a PR to `main` with exactly one `bump:patch`, `bump:minor` or
`bump:major` label bumps `manifest.version` in `nextflow.config`, tags the
release and publishes the container image.
