version 1.0

workflow count_seq_ns_parallel {
    input {
        File assembly_fasta
    }

    call split_fasta {
        input: assembly_fasta = assembly_fasta
    }

    scatter (seq_file in split_fasta.sequence_files) {
        call count_ns {
            input: seq_file = seq_file
        }
    }

    call sum_counts {
        input: count_ns_values = count_ns.total_ns
    }

    output {
        Int total_gaps = sum_counts.total_ns
    }
}

task split_fasta {
    input {
        File assembly_fasta
    }

    command <<<
        set -eux

        mkdir split_seqs

        # Decompress if needed and split into separate files per sequence
        if [[ "${assembly_fasta}" == *.gz ]]; then
            zcat ${assembly_fasta} | awk '/^>/ {f="split_seqs/seq"++i".fa"} {print > f}'
        else
            cat ${assembly_fasta} | awk '/^>/ {f="split_seqs/seq"++i".fa"} {print > f}'
        fi

        ls split_seqs/*.fa > sequences.txt
    >>>

    output {
        Array[File] sequence_files = read_lines("sequences.txt")
    }

    runtime {
		docker: "debian:bullseye"
        preemptible: 3
    }
}

task count_ns {
    input {
        File seq_file
    }

    command {
        zgrep -v "^>" ${seq_file} | tr -d -c 'Nn' | wc -c > gaps.txt
    }

    output {
        Int total_ns = read_int("gaps.txt")
    }

    runtime {
		docker: "debian:bullseye"
        preemptible: 3
    }
}

task sum_counts {
    input {
        Array[Int] count_ns_values
    }

    command {
        echo ${sep="+" count_ns_values} | bc > total_gaps.txt
    }

    output {
        Int total_ns = read_int("total_gaps.txt")
    }

    runtime {
		docker: "debian:bullseye"
        preemptible: 3
    }
}
