#
# from: http://www.stonehenge.com/merlyn/UnixReview/col41.html
#

    sub ping_a_host {
      my $host = shift;
      `ping -i 1 -c 1 $host 2>/dev/null` =~ /0 packets rec/ ? 0 : 1;
    }

    my %pid_to_host;
    my %host_result;

    sub wait_for_a_kid {
      my $pid = wait;
      return 0 if $pid < 0;
      my $host = delete $pid_to_host{$pid}
        or warn("Why did I see $pid ($?)\n"), next;
      warn "reaping $pid for $host\n";
      $host_result{$host} = $? ? 0 : 1;
      1;
    }

    my @hosts = map "172.16.19.$_", "001".."050";

    for (@hosts) {
      wait_for_a_kid() if keys %pid_to_host > 10;
      if (my $pid = fork) {
        ## parent does...
        $pid_to_host{$pid} = $_;
        warn "$pid is processing $_\n";
      } else { # child does
        ## child does...
        exit !ping_a_host($_);
      }
    }

    ## final reap:
    1 while wait_for_a_kid();

    for (sort keys %host_result) {
      print "$_ is ", ($host_result{$_} ? "good" : "bad"), "\n";
    }
