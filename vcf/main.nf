process BCFTOOLS_VCF {
    tag "${meta.id}"

    publishDir "${params.outdir}/variants/vcf", mode: 'link'

    input:
    tuple val(meta), path(bcf), path(csi)

    output:
    tuple val(meta), path("${meta.id}.calls.vcf.gz"), path("${meta.id}.calls.vcf.gz.tbi"), emit: vcf

    script:
    """
    bcftools view -Oz -o ${meta.id}.calls.vcf.gz ${bcf}
    bcftools index -t ${meta.id}.calls.vcf.gz
    """

    stub:
    """
    touch ${meta.id}.calls.vcf.gz ${meta.id}.calls.vcf.gz.tbi
    """
}
