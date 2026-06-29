process BCFTOOLS_CSV {
    tag "${meta.id}"

    publishDir "${params.outdir}/variants/csv", mode: 'link'

    input:
    tuple val(meta), path(bcf), path(csi)

    output:
    tuple val(meta), path("${meta.id}.calls.csv"), emit: csv

    script:
    """
    echo 'CHROM,POS,REF,ALT,DP,AD(ref,alt),QUAL,FILTER' > ${meta.id}.calls.csv
    bcftools query -f '%CHROM,%POS,%REF,%ALT,%DP,[%AD],%QUAL,%FILTER\\n' ${bcf} >> ${meta.id}.calls.csv
    """

    stub:
    """
    touch ${meta.id}.calls.csv
    """
}

