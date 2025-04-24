version 1.0

workflow count_total_assembly_gaps_parallel {
    input {
        File assembly_fasta
    }

    call split_fasta_sequences {
        input:
            fasta_file = assembly_fasta
    }

    scatter (seq in split_fasta_sequences.sequence_files) {
        call calculate_gap_bases {
            input:
                sequence = seq
        }
    }

    output {
        Int total_gaps = sum(calculate_gap_bases.total_ns)
    }
}

task split_fasta_sequences {
    input {
        File fasta_file
    }

    command <<<
        mkdir sequences
        csplit -z -f sequences/seq_ -b "%03d.fa" ~{fasta_file} '/^>/' '{*}'
        ls sequences/*.fa > sequence_list.txt
    >>>

    output {
        Array[File] sequence_files = read_lines("sequence_list.txt")
    }

    runtime {
        docker: "debian:bullseye"
        cpu: 1
        memory: "1 GB"
        preemptible: 3
    }
}

task calculate_gap_bases {
    input {
        File sequence
    }

    command {
        grep -v "^>" ${sequence} | tr -d -c 'Nn' | wc -c > gaps.txt
    }

    output {
        Int total_ns = read_int("gaps.txt")
    }

    runtime {
        docker: "debian:bullseye"
        cpu: 1
        memory: "500 MB"
        preemptible: 3
    }
}
