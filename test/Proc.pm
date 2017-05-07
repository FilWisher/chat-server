use strict;
use warnings;

package Proc;
use Errno;
use Carp;

my %CHILDREN;

sub kill_children {
    my @pids = @_ ? @_ : keys %CHILDREN
	    or return;

    my @perms;

    foreach my $pid (@pids) {
	    if (kill(TERM => $pid) != 1 and $!{EPERM}) {
	      push @perms, $pid
	    }
    }
    if (my $sudo = $ENV{SUDO} and @perms) {
	    local $?;
	    my @cmd = ($sudo, '/bin/kill', '-TERM', @perms);
	    system(@cmd);
    }
    delete @CHILDREN{@pids};
}

sub new {
    my $class = shift;
    my $self = { @_ };

    $self->{func} && ref($self->{func}) eq 'CODE' 
	    or croak "$class func not given";

    $self->{logfile}
	    or croak "$class logfile not given";
   
    open(my $fh, '>', $self->{logfile})
	    or die "$class logfile $self->{logfile} create failed: $!";

    $self->{log} = $fh;

    return bless $self, $class;
}

sub run {
    my $self = shift;

    pipe(my $reader, my $writer)
	    or die ref($self), "pipe to child failed: $!";
    defined(my $pid = fork())
	    or die ref($self), "fork child failed: $!";

    if ($pid) {
	    $CHILDREN{pid} = $pid;

	    $self->{pid} = $pid;
	    close($reader);
	    $self->{pipe} = $writer;
	    return $self;
    }

    %CHILDREN = ();
    close($reader);
	
    $self->child();
    $self->{func}->($self);
}

sub wait {
    my $self = shift;
    my $flags = shift;

    my $pid = $self->{pid}
      or croak ref($self), " no child pid";
   
    my $kid = waitpid($pid, $flags);
    if ($kid > 0) {
	    my $status = $?;
	    my $code;
	    delete $CHILDREN{$pid} if WIFEXITED($?) || WIFSIGNALED($?);
	    return wantarray ? ($kid, $status, $code) : $kid;
    }
    return $kid;
};


sub kill_child {
    my $self = shift;
    kill_children($self->{pid});
    return $self;
}

1;
