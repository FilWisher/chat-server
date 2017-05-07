use strict;
use warnings;

package Server;
use parent 'Proc';
use Carp;

sub new {
    my $class = shift;
    my %args = @_;

    $args{func} = sub { Carp::confess "$class may not use this func" };
    $args{logfile} = "./test.log";
    my $self = Proc::new($class, %args);

    return $self;
}

sub child {
    my $self = shift;
    my @cmd = ("./server");
    print STDERR "execute: @cmd\n";
    exec @cmd;
    die ref($self), " exec '@cmd' failed: $!";
}

1;
