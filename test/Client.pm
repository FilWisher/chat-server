use strict;
use warnings;

package Client;
use parent 'Proc';
use Socket;
use IO::Socket;

sub new {
    my $class = shift;
    my %args = @_;
    my $self = Proc::new($class, %args);
    return $self;
}

sub child {
    my $self = shift;

    my $sock = IO::Socket::INET->new(
	Proto => "tcp",
	Domain => AF_INET,
	PeerAddr => "127.0.0.1",
	PeerPort => 8080
    ) or die ref($self), " INET socket connection failed: $!";

    *STDIN = *STDOUT = $self->{sock} = $sock;


}

1;
