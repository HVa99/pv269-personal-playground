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

  call SumInts {
    input:
      numbers = CountContigGaps.total_gaps
  }

  output {
    Int total_gap_length = SumInts.total
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

task SumInts {
  input {
    Array[Int] numbers
  }

  command <<<
    echo "~{sep=' ' numbers[@]}" | awk '{s=0; for (i=1;i<=NF;i++) s+=$i; print s}' > sum.txt
  >>>

  output {
    Int total = read_int("sum.txt")
  }

  runtime {
    docker: "ubuntu:20.04"
    preemptible: 3
    memory: "1 GB"
    cpu: 1
  }
}
