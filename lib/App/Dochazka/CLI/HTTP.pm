# ************************************************************************* 
# Copyright (c) 2014, SUSE LLC
# 
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
# 
# 1. Redistributions of source code must retain the above copyright notice,
# this list of conditions and the following disclaimer.
# 
# 2. Redistributions in binary form must reproduce the above copyright
# notice, this list of conditions and the following disclaimer in the
# documentation and/or other materials provided with the distribution.
# 
# 3. Neither the name of SUSE LLC nor the names of its contributors may be
# used to endorse or promote products derived from this software without
# specific prior written permission.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.
# ************************************************************************* 
#
# HTTP module
#
package App::Dochazka::CLI::HTTP;

use 5.012;
use strict;
use warnings;

use App::CELL qw( $CELL $log $site $meta );
use Data::Dumper;
use Exporter qw( import );
use HTTP::Request::Common qw( GET PUT POST DELETE );
use JSON;
use LWP::UserAgent;

=head1 NAME

App::Dochazka::CLI::HTTP - HTTP for Dochazka command line client




=head1 VERSION

Version 0.064

=cut

our $VERSION = '0.064';




=head1 SYNOPSIS

    use App::Dochazka::CLI::HTTP qw( send_req );

    my $status = send_req( 'GET', 'employee/current' );





=head1 EXPORTS

=cut

our @EXPORT_OK = qw( send_req );





=head1 PACKAGE VARIABLES

=cut

# user agent
my $ua = LWP::UserAgent->new;

# dispatch table with references to HTTP::Request::Common functions
my %methods = ( 
    GET => \&GET,
    PUT => \&PUT,
    POST => \&POST,
    DELETE => \&DELETE,
);
             




=head1 FUNCTIONS


=head2 init_ua

Initialize the LWP::UserAgent singleton object.

=cut

sub init_ua {
    $ua->cookie_jar( { file => $site->DOCHAZKA_CLI_COOKIE_JAR } );
    return;
}


=head2 cookie_jar

Return the cookie_jar associated with our user agent.

=cut

sub cookie_jar { $ua->cookie_jar };


=head2 send_req

Send a request to the server, get the response, convert it from JSON and
bless it into a status object.

=cut

sub send_req {
    no strict 'refs';
    # process arguments
    my ( $method, $path, $body_data ) = @_;
    $path = "/$path" unless $path =~ m/^\//;
    $log->debug("send_req: path is $path");

    # assemble request
    my $r = $methods{$method}->( 
        $site->DOCHAZKA_REST_SERVER . $path, 
        Accept => 'application/json',
        Content_Type => 'application/json',
        Content => $body_data,
    );

    # add basic auth
    my $user = $meta->CURRENT_EMPLOYEE_NICK || 'demo';
    my $password = $meta->CURRENT_EMPLOYEE_PASSWORD || 'demo';
    $log->debug( "send_req: basic auth user $user / pass $password" );
    $r->authorization_basic( $user, $password );

    # send request, get response
    my $response = $ua->request( $r );
    my $code = $response->code;

    # if HTTP response code is not 200 or 204, return control to
    # bin/dochazka-cli (see there for how the return status is handled)
    return $CELL->status_err( 'DOCHAZKA_CLI_SERVER_ERROR', args => [ $response->status_line ] ) 
        unless grep { $code == $_ } ( 200, 204 );

    #my $hr = $ua->request( $r )->content;
    if ( $response->content ) {
        my $hr = from_json( $response->content );
        $hr->{'_http_code'} = $response->code;
        return bless $hr, 'App::CELL::Status';
    } else {
        return $CELL->status_warn( 'DOCHAZKA_CLI_HTTP_REQUEST_OK_NODATA' );
    }
}

