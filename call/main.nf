process BCFTOOLS_CALL {
    tag "${meta.id}"

    publishDir "${params.outdir}/variants/bcf", mode: 'link'

    input:
    tuple val(meta), path(bam), path(bai)
    tuple path(fasta), path(fai)

    output:
    tuple val(meta), path("${meta.id}.calls.bcf"), path("${meta.id}.calls.bcf.csi"), emit: bcf

    script:
    def args = task.ext.args ?: ''
    def filter = "FMT/DP<${params.min_depth} || QUAL<${params.min_qual}"
    """
    bcftools mpileup -Ou -f ${fasta} -q ${params.min_mapq} -a AD,DP ${bam} \\
        | bcftools call --ploidy ${params.ploidy} -mv -Ou ${args} \\
        | bcftools filter -e '${filter}' -Ob -o ${meta.id}.calls.bcf
    bcftools index ${meta.id}.calls.bcf
    """

    stub:
    """
    touch ${meta.id}.calls.bcf
    touch ${meta.id}.calls.bcf.csi
    """
}
