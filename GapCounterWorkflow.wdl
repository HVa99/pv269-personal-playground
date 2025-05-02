version 1.0

workflow GapCounterWorkflow {
  input {
    File assembly_fasta
  }

  call CountGaps {
    input:
      fasta = assembly_fasta
  }

  output {
    Int total_gap_length = CountGaps.total_gaps
  }
}

task CountGaps {
  input {
    File fasta
  }

  command {
    gzip -cd ${assembly_fasta} | grep -v "^>" | tr -d -c 'Nn' | wc -c > gap_count.txt
  }

  output {
    Int total_gaps = read_int("gap_count.txt")
  }

  runtime {
    docker: "ubuntu:20.04"
    preemptible: 2
    memory: "1 GB"
    cpu: 1
  }
}
