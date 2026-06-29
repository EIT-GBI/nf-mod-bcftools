process BCFTOOLS_CONSENSUS {
    tag "${meta.id}"

    publishDir "${params.outdir}/consensus", mode: 'link'

    input:
    tuple val(meta), path(bcf), path(csi)
    tuple path(fasta), path(fai)

    output:
    tuple val(meta), path("${meta.id}.consensus.fna"), emit: consensus

    script:
    """
    bcftools consensus -f ${fasta} ${bcf} > ${meta.id}.consensus.fna
    """

    stub:
    """
    touch ${meta.id}.consensus.fna
    """
}

