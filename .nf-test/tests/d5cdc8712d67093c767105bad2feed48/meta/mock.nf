import groovy.json.JsonGenerator
import groovy.json.JsonGenerator.Converter

nextflow.enable.dsl=2

// comes from nf-test to store json files
params.nf_test_output  = ""

// include dependencies


// include test process
include { BCFTOOLS_CONSENSUS } from '/Users/pauline.fourgoux/Documents/Code/nf-dnaseq/modules/bcftools/consensus/tests/../main.nf'

// define custom rules for JSON that will be generated.
def jsonOutput =
    new JsonGenerator.Options()
        .addConverter(Path) { value -> value.toAbsolutePath().toString() } // Custom converter for Path. Only filename
        .build()

def jsonWorkflowOutput = new JsonGenerator.Options().excludeNulls().build()


workflow {

    // run dependencies
    

    // process mapping
    def input = []
    
                input[0] = [[id:'test'], file("https://raw.githubusercontent.com/nf-core/test-datasets/modules/data/genomics/sarscov2/illumina/bam/test.paired_end.sorted.bam", checkIfExists: true), file("https://raw.githubusercontent.com/nf-core/test-datasets/modules/data/genomics/sarscov2/illumina/bam/test.paired_end.sorted.bam.bai", checkIfExists: true)]
                input[1] = [file("https://raw.githubusercontent.com/nf-core/test-datasets/modules/data/genomics/sarscov2/genome/genome.fasta", checkIfExists: true), file("https://raw.githubusercontent.com/nf-core/test-datasets/modules/data/genomics/sarscov2/genome/genome.fasta.fai", checkIfExists: true)]
                
    //----

    //run process
    BCFTOOLS_CONSENSUS(*input)

    if (BCFTOOLS_CONSENSUS.output){

        // consumes all named output channels and stores items in a json file
        for (def name in BCFTOOLS_CONSENSUS.out.getNames()) {
            serializeChannel(name, BCFTOOLS_CONSENSUS.out.getProperty(name), jsonOutput)
        }	  
      
        // consumes all unnamed output channels and stores items in a json file
        def array = BCFTOOLS_CONSENSUS.out as Object[]
        for (def i = 0; i < array.length ; i++) {
            serializeChannel(i, array[i], jsonOutput)
        }    	

    }
  
}

def serializeChannel(name, channel, jsonOutput) {
    def _name = name
    def list = [ ]
    channel.subscribe(
        onNext: {
            list.add(it)
        },
        onComplete: {
              def map = new HashMap()
              map[_name] = list
              def filename = "${params.nf_test_output}/output_${_name}.json"
              new File(filename).text = jsonOutput.toJson(map)		  		
        } 
    )
}


workflow.onComplete {

    def result = [
        success: workflow.success,
        exitStatus: workflow.exitStatus,
        errorMessage: workflow.errorMessage,
        errorReport: workflow.errorReport
    ]
    new File("${params.nf_test_output}/workflow.json").text = jsonWorkflowOutput.toJson(result)
    
}
