version 1.0

task hello {
  input {
    String name
  }

  command {
    echo 'hello ${name}!'
  }

  output {
    File response = stdout()
  }

  runtime {
   docker: 'ubuntu:impish-20220105'
   preemptible: 3
  }
}

workflow test {
  call hello
}
