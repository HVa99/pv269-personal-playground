version 1.0

workflow GapLengthWorkflow {
  input {
    File assembly_fasta
  }

  call CountGaps {
    input: fasta = assembly_fasta
  }

  output {
    Int total_gap_length = CountGaps.gap_length
  }
}

task CountGaps {
  input {
    File fasta
  }

  command <<<
    grep -v "^>" ~{fasta} | tr -d '\n' | grep -o "N\+" | awk '{ total += length($0) } END { print total }' > gap_length.txt
  >>>

  output {
    Int gap_length = read_int("gap_length.txt")
  }

  runtime {
    docker: "ubuntu:20.04"
    preemptible: 3
    cpu: 1
    memory: "1 GB"
  }
}
