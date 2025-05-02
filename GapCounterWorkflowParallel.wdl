version 1.0

workflow GapCounterWorkflowParallel {
  input {
    File assembly_fasta
  }

  call SplitFasta {
    input:
      fasta = assembly_fasta
  }

  scatter (contig in SplitFasta.contigs) {
    call CountContigGaps {
      input:
        contig_fasta = contig
    }
  }

  output {
    Int total_gap_length = sum(CountContigGaps.total_gaps)
  }
}

task SplitFasta {
  input {
    File fasta
  }

  command <<<
    mkdir contigs
    gzip -cd ~{fasta} | awk '/^>/{close(out); out="contigs/"++i".fa"; print > out; next} {print > out}'
    ls contigs/*.fa > contigs.list
  >>>

  output {
    Array[File] contigs = read_lines("contigs.list")
  }

  runtime {
    docker: "ubuntu:20.04"
    preemptible: 2
    memory: "2 GB"
    cpu: 1
  }
}

task CountContigGaps {
  input {
    File contig_fasta
  }

  command {
    grep -v "^>" ~{contig_fasta} | tr -d -c 'Nn' | wc -c > gaps.txt
  }

  output {
    Int total_gaps = read_int("gaps.txt")
  }

  runtime {
    docker: "ubuntu:20.04"
    preemptible: 2
    memory: "1 GB"
    cpu: 1
  }
}
