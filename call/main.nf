process BCFTOOLS_CALL {
    tag "${meta.id}"

    input:
    tuple val(meta), path(bam), path(bai)
    tuple path(fasta), path(fai)

    output:
    tuple val(meta), path("${meta.id}.calls.bcf"), path("${meta.id}.calls.bcf.csi"), emit: bcf

    script:
    // The calling and filtering thresholds belong to the module rather than the
    // consuming pipeline: every pipeline sets the same params.calling.* names and
    // the three bcftools invocations are assembled here, once. A threshold left
    // unset is dropped, so with none set this is a plain unfiltered call.
    def min_mapq  = params.calling?.min_mapq
    def ploidy    = params.calling?.ploidy
    def min_depth = params.calling?.min_depth
    def min_qual  = params.calling?.min_qual

    def mapq_opt   = min_mapq != null ? "-q ${min_mapq}" : ''
    def ploidy_opt = ploidy   != null ? "--ploidy ${ploidy}" : ''

    // bcftools filter -e drops records matching the expression, so the
    // thresholds are expressed as the reject condition and OR'd together.
    def excluded = []
    if( min_depth != null )
        excluded << "FMT/DP<${min_depth}"
    if( min_qual != null )
        excluded << "QUAL<${min_qual}"
    // The single quotes are load-bearing: they keep || and < away from the shell.
    def filter_expr = excluded ? "-e '${excluded.join(' || ')}'" : ''

    def args  = task.ext.args  ?: ''   // extra bcftools mpileup flags
    def args2 = task.ext.args2 ?: ''   // extra bcftools call flags
    def args3 = task.ext.args3 ?: ''   // extra bcftools filter flags

    // bcftools filter honours only the last -e, so a pipeline setting both would
    // have one of its two filters silently dropped. Fail loudly instead.
    if( excluded && (args3 =~ /(^|\s)-e(\s|=|$)/) )
        error "BCFTOOLS_CALL: params.calling.min_depth/min_qual and an '-e' in ext.args3 are both set; bcftools would silently honour only the latter. Use one or the other."
    """
    bcftools mpileup -Ou -f ${fasta} ${mapq_opt} -a AD,DP ${args} ${bam} \\
        | bcftools call -mv -Ou ${ploidy_opt} ${args2} \\
        | bcftools filter ${filter_expr} ${args3} -Ob -o ${meta.id}.calls.bcf
    bcftools index ${meta.id}.calls.bcf
    """

    stub:
    """
    touch ${meta.id}.calls.bcf
    touch ${meta.id}.calls.bcf.csi
    """
}
