package server;

use strict;
use warnings;
use 5.00001;

use Client;
use Server;

# TODO:
# run client
# kill client
# kill server
# check what happened (in logs)

sub chat_client {
    my $self = shift;
    # make requests in here
    print "ok?";
}

my $srv = Server->new();
my $cli = Client->new(
    func => \&chat_client,
    logfile => "./test.log"
);

$srv->run();
$cli->run();
print "done\n";

$srv->kill_child();


1;
