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
use HTTP::Request::Common;
use JSON;
use LWP::UserAgent;

=head1 NAME

App::Dochazka::CLI::HTTP - HTTP for Dochazka command line client




=head1 VERSION

Version 0.010

=cut

our $VERSION = '0.010';




=head1 SYNOPSIS

    use App::Dochazka::CLI::HTTP qw( send_req );

    my $status = send_req( 'GET', 'employee/current' );





=head1 EXPORTS

=cut

our @EXPORT_OK = qw( send_req );





=head1 PACKAGE VARIABLES

=cut

my $ua = LWP::UserAgent->new;





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
    # process arguments
    my ( $method, $path ) = @_;
    $path = "/$path" unless $path =~ m/^\//;

    # assemble request, send it, get response
    my $r = GET $site->DOCHAZKA_REST_SERVER . $path, 
                Accept => 'application/json';
    $r->authorization_basic( $site->DOCHAZKA_REST_LOGIN_NICK ||
                             $meta->CURRENT_EMPLOYEE_NICK ||
                             'demo',
                             $site->DOCHAZKA_REST_LOGIN_PASSWORD ||
                             $meta->CURRENT_EMPLOYEE_PASSWORD ||
                             'demo',
    );
    my $response = $ua->request( $r );
    my $code = $response->code;

    # return error status if request failed
    return $CELL->status_err( 'DOCHAZKA_CLI_SERVER_ERROR', args => [ $response->status_line ] ) 
        unless grep { $code == $_ } ( 200, 204 );

    # return status with payload if there is a payload
    my $hr = $ua->request( $r )->content;
    if ( $hr ) {
        $hr = from_json( $hr );
        $hr->{'_http_code'} = $response->code;
        return bless $hr, 'App::CELL::Status';
    } else {
        return $CELL->status_warn( 'DOCHAZKA_CLI_HTTP_REQUEST_OK_NODATA' );
    }
}
