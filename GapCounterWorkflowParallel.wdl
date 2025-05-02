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

  runtime {
    docker: "staphb/seqkit:latest"
    max_retries: 3
    disks: "local-disk 20 SSD"
    cpu: 6
    memory: "8 GB"
    preemptible: 3
  }

  output {
    Array[File] assembly_files = glob("assembly_parts/*")
    Int num_parts = length(assembly_files)
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

  runtime {
    docker: "quay.io/biocontainers/gzip:1.11"
    preemptible: 1
  }

  output {
    Int num_gaps = read_int(stdout())
  }
}

