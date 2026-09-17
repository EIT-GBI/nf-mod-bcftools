process BCFTOOLS_CALL {
    tag "${meta.id}"

    input:
    tuple val(meta), path(bam), path(bai)
    tuple path(fasta), path(fai)

    output:
    tuple val(meta), path("${meta.id}.calls.bcf"), path("${meta.id}.calls.bcf.csi"), emit: bcf

    script:
    def args  = task.ext.args  ?: ''   // bcftools mpileup flags
    def args2 = task.ext.args2 ?: ''   // bcftools call flags
    def args3 = task.ext.args3 ?: ''   // bcftools filter flags
    """
    bcftools mpileup -Ou -f ${fasta} ${args} ${bam} \\
        | bcftools call -mv -Ou ${args2} \\
        | bcftools filter ${args3} -Ob -o ${meta.id}.calls.bcf
    bcftools index ${meta.id}.calls.bcf
    """

    stub:
    """
    touch ${meta.id}.calls.bcf
    touch ${meta.id}.calls.bcf.csi
    """
}
