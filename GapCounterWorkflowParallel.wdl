version 1.0

workflow GapCounterWorkflowParallel {
  input {
    File assembly
  }

  call split_fasta_files {
    input:
      assembly = assembly
  }

  scatter (assembly_file in split_fasta_files.assembly_files) {
    call sum_gaps {
      input:
        assembly = assembly_file
    }
  }

  call sum {
    input:
      ints = sum_gaps.num_gaps
  }

  output {
    Int num_gaps_fast = sum.total
  }
}

task split_fasta_files {
  input {
    File assembly
  }

  command <<< 
    seqkit split --by-part 100 --out-dir assembly_parts --threads 4 "~{assembly}"
  >>>

  output {
    Array[File] assembly_files = glob("assembly_parts/*")
    Int num_parts = length(assembly_files)
  }

  runtime {
    docker: "staphb/seqkit:latest"
    max_retries: 3
    disks: "local-disk 20 SSD"
    cpu: 6
    memory: "8 GB"
    preemptible: 3
  }
}

task sum_gaps {
  input {
    File assembly
  }

  command <<< 
    if [[ "~{assembly}" == *.gz ]]; then
      gzip -cd "~{assembly}"
    else
      cat "~{assembly}"
    fi | grep -v "^>" | tr -d -c 'Nn' | wc -c
  >>>

  output {
    Int num_gaps = read_int(stdout())
  }

  runtime {
    docker: "quay.io/biocontainers/gzip:1.11"
    preemptible: 1
  }
}

task sum {
  input {
    Array[Int]+ ints
  }

  command <<< 
    printf '~{sep=" " ints}' | awk '{tot=0; for(i=1;i<=NF;i++) tot+=$i; print tot}'
  >>>

  output {
    Int total = read_int(stdout())
  }

  runtime {
    docker: "ubuntu:20.04"
    preemptible: 3
  }
}
