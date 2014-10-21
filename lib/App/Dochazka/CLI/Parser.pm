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
# parser module
#
package App::Dochazka::CLI::Parser;

use 5.012;
use strict;
use warnings;

use App::CELL qw( $CELL );
use App::Dochazka::CLI::HTTP qw( send_req );
use Test::Deep::NoTest;

=head1 NAME

App::Dochazka::CLI::Parser - Parser for Dochazka command line client




=head1 VERSION

Version 0.021

=cut

our $VERSION = '0.021';




=head1 SYNOPSIS

    use Try::Tiny;
    
    my $status;
    my @tokens = split /\s+/, 'MY SAMPLE COMMAND';
    try { 
        App::Dochazka::CLI::Parse::parse_tokens( [], \@tokens ); 
    } catch { 
        $status = $_; 
    };




=head1 CLI COMMANDS

The parsing of CLI commands takes place in the C<parse_tokens> function,
which calls itself recursively until it gets to a rather macabre-sounding

    die send_req . . .

This causes control to return to the while loop in C<bin/dochazka-cli> with the
return value of the C<send_req>, which is a status object.

All tokens should be chosen to be distinguishable by their first
three characters.

=cut

sub parse_tokens {
    my ( $pre, $tokens ) = @_; 
    return $CELL->status_err( "No more tokens" ) unless ref $tokens;
    my @tokens = @$tokens;
    my $token = shift @tokens;


=head2 C<GET>

A lone C<GET> (equivalent to C<GET HELP>) is analogous to sending a bare GET
request to the base URI.

=cut

    # GET (...)
    if    ( $token =~ m/^get/i and eq_deeply( $pre, [] ) ) { 
        parse_tokens( [ 'GET' ], \@tokens ) if @tokens;
        die send_req( 'GET', '' );
    }   


=head2 C<GET BUGREPORT>

The same as sending a GET request for the 'bugreport' resource.

=cut

    # GET BUG[REPORT]
    elsif ( $token =~ m/^bug/i and eq_deeply( $pre, [ 'GET' ] ) ) {
        die send_req( 'GET', 'bugreport' );
    }


=head2 C<GET COOKIE>

This command dumps the cookie jar. It is client-side only, so no analogous REST resource.

=cut

    # GET COO[KIES]
    elsif ( $token =~ m/^coo/i and eq_deeply( $pre, [ 'GET' ] ) ) {
        die $CELL->status_ok( 'COOKIE_JAR', payload => App::Dochazka::CLI::HTTP::cookie_jar() );
    }


=head2 C<GET EMPLOYEE>

The same as sending a GET request for the 'employee' resource.

=cut

    elsif ( $token =~ m/^emp/i and eq_deeply( $pre, [ 'GET' ] ) ) {
        parse_tokens( [ 'GET', 'EMPLOYEE' ], \@tokens ) if @tokens;
        die send_req( 'GET', 'employee' );
    }


=head2 C<GET EMPLOYEE COUNT ([PRIV])>

The same as sending a GET request for the 'employee/count' resource.

=cut

    elsif ( $token =~ m/^cou/i and eq_deeply( $pre, [ 'GET', 'EMPLOYEE' ] ) ) {
        die send_req( 'GET', 'employee/count/' . $tokens[0] ) if @tokens;
        die send_req( 'GET', 'employee/count' );
    }


=head2 C<GET EMPLOYEE CURRENT>

The same as sending a GET request for the 'employee/current' resource.

=cut

    elsif ( $token =~ m/^cur/i and eq_deeply( $pre, [ 'GET', 'EMPLOYEE' ] ) ) {
        parse_tokens( [ 'GET', 'EMPLOYEE', 'CURRENT' ], \@tokens ) if @tokens;
        die send_req( 'GET', 'employee/current' );
    }


=head2 C<GET EMPLOYEE CURRENT PRIV>

The same as sending a GET request for the 'employee/current/priv' resource.

=cut

    elsif ( $token =~ m/^pri/i and eq_deeply( $pre, [ 'GET', 'EMPLOYEE', 'CURRENT' ] ) ) {
        die send_req( 'GET', 'employee/current/priv' );
    }


=head2 C<GET EMPLOYEE EID [INTEGER]>

Send a GET request for the 'employee/eid/:param' resource.

=cut

    elsif ( $token =~ m/^eid/i and eq_deeply( $pre, [ 'GET', 'EMPLOYEE' ] ) ) {
        die send_req( 'GET', 'employee/eid/' . $tokens[0] );
    }


=head2 C<GET EMPLOYEE NICK [STRING]>

Send a GET request for the 'employee/nick/:param' resource.

=cut

    elsif ( $token =~ m/^nic/i and eq_deeply( $pre, [ 'GET', 'EMPLOYEE' ] ) ) {
        die send_req( 'GET', 'employee/nick/' . $tokens[0] );
    }


=head2 C<GET EMPLOYEE [INTEGER]>

The same as sending a GET request for the 'employee/[INTEGER]' resource. For
example, C<GET EMPLOYEE 1> should retrieve the profile of the employee 'root'.

=cut

    elsif ( $token =~ m/^\d+$/i and eq_deeply( $pre, [ 'GET', 'EMPLOYEE' ] ) ) {
        die send_req( 'GET', "employee/eid/$token" );
    }


#=head2 C<GET EMPLOYEE [STRING]>
#
#The same as sending a GET request for the 'employee/[STRING]' resource, where
#[STRING] is an alphanumeric string. For example, C<GET EMPLOYEE root> should
#retrieve the profile of the employee 'root'.
#
#=cut
#
#    elsif ( $token =~ m/^[^\/]+$/i and eq_deeply( $pre, [ 'GET', 'EMPLOYEE' ] ) ) {
#        die send_req( 'GET', "employee/nick/$token" );
#    }
#    
#
=head2 C<GET HELP>

The same as sending a GET request for the 'help' resource.

=cut

    elsif ( $token =~ m/^hel/i and eq_deeply( $pre, [ 'GET' ] ) ) {
        die send_req( 'GET', "help" );
    }
    

=head2 C<GET METAPARAM [STRING]>

Sends the server a GET request for the resource 'metaparam/:param'

=cut

    elsif ( $token =~ m/^met/i and eq_deeply( $pre, [ 'GET' ] ) ) {
        die send_req( 'GET', "metaparam/" . $tokens[0] );
    }
    

=head2 C<GET PRIVHISTORY>

The same as sending a GET request for the 'privhistory' resource.

=cut

    elsif ( $token =~ m/^pri/i and eq_deeply( $pre, [ 'GET' ] ) ) {
        parse_tokens( [ 'GET', 'PRIVHISTORY' ], \@tokens ) if @tokens;
        die send_req( 'GET', "privhistory" );
    }
    

=head2 C<GET SESSION>

The same as sending a GET request for the 'session' resource.

=cut

    # GET SES[SION]
    elsif ( $token =~ m/^ses/i and eq_deeply( $pre, [ 'GET' ] ) ) {
        die send_req( 'GET', "session" );
    }


=head2 C<GET SITEPARAM [STRING]>

Sends the server a GET request for the resource 'siteparam/:param'

=cut

    elsif ( $token =~ m/^sit/i and eq_deeply( $pre, [ 'GET' ] ) ) {
        die send_req( 'GET', "siteparam/" . $tokens[0] );
    }
    

=head2 C<GET VERSION>

The same as sending a GET request for the 'version' resource.

=cut

    # GET VER[SION]
    elsif ( $token =~ m/^ver/i and eq_deeply( $pre, [ 'GET' ] ) ) {
        die send_req( 'GET', 'version' );
    }   


=head2 C<GET WHOAMI>

The same as sending a GET request for the 'whoami' resource.

=cut

    # GET WHO[AMI]
    elsif ( $token =~ m/^who/i and eq_deeply( $pre, [ 'GET' ] ) ) {
        die send_req( 'GET', 'whoami' );
    }   


=head2 C<PUT>

A solitary 'PUT' is equivalent to 'PUT HELP'

=cut

    elsif ( $token =~ m/^put/i and eq_deeply( $pre, [] ) ) { 
        parse_tokens( [ 'PUT' ], \@tokens ) if @tokens;
        die send_req( 'PUT', '' );
    }   


=head2 C<PUT ECHO [JSON_STRING]>

The same as sending a PUT request for the "echo" resource and providing a JSON
string in the content body.

=cut

    elsif ( $token =~ m/^ech/i and eq_deeply( $pre, [ 'PUT' ] ) ) { 
        die send_req( 'PUT', 'echo', join(' ', @tokens) );
    }   


=head2 C<PUT EMPLOYEE> 

The same as sending a PUT request for the "employee" resource.

=cut

    elsif ( $token =~ m/^emp/i and eq_deeply( $pre, [ 'PUT' ] ) ) { 
        parse_tokens( [ 'PUT', 'EMPLOYEE' ], \@tokens ) if @tokens;
        die send_req( 'PUT', 'employee' );
    }   


=head2 C<PUT EMPLOYEE EID [STRING]> 

The same as sending a PUT request for the "employee/eid/:param" resource.

=cut

    elsif ( $token =~ m/^eid/i and eq_deeply( $pre, [ 'PUT', 'EMPLOYEE' ] ) ) { 
        my $eid = shift @tokens;
        die send_req( 'PUT', "employee/eid/$eid", join( ' ' , @tokens ) );
    }   


=head2 C<PUT EMPLOYEE HELP> 

The same as sending a PUT request for the "employee/help" resource

=cut

    elsif ( $token =~ m/^hel/i and eq_deeply( $pre, [ 'PUT', 'EMPLOYEE' ] ) ) { 
        die send_req( 'PUT', 'employee' );
    }   


=head2 C<PUT EMPLOYEE NICK [STRING]> 

The same as sending a PUT request for the "employee/nick/:param" resource.

=cut

    elsif ( $token =~ m/^nic/i and eq_deeply( $pre, [ 'PUT', 'EMPLOYEE' ] ) ) { 
        my $nick = shift @tokens;
        die send_req( 'PUT', "employee/nick/$nick", join( ' ', @tokens ) );
    }   


=head2 C<PUT HELP> 

The same as sending a PUT request for the "help" resource

=cut

    elsif ( $token =~ m/^hel/i and eq_deeply( $pre, [ 'PUT' ] ) ) { 
        die send_req( 'PUT', 'help' );
    }   


=head2 C<PUT PRIVHISTORY> 

The same as sending a PUT request for the "help" resource

=cut

    elsif ( $token =~ m/^pri/i and eq_deeply( $pre, [ 'PUT' ] ) ) { 
        parse_tokens( [ 'PUT', 'PRIVHISTORY' ], \@tokens ) if @tokens;
        die send_req( 'PUT', 'privhistory' );
    }   


=head2 C<PUT PRIVHISTORY HELP> 

The same as sending a PUT request for the "help" resource

=cut

    elsif ( $token =~ m/^pri/i and eq_deeply( $pre, [ 'PUT', 'PRIVHISTORY' ] ) ) { 
        die send_req( 'PUT', 'privhistory/help' );
    }   


=head2 C<POST>

A solitary 'POST' is equivalent to 'POST HELP'

=cut

    elsif ( $token =~ m/^pos/i and eq_deeply( $pre, [] ) ) { 
        parse_tokens( [ 'POST' ], \@tokens ) if @tokens;
        die send_req( 'POST', '' );
    }   


=head2 C<POST ECHO [JSON_STRING]>

The same as sending a POST request for the "echo" resource and providing a JSON
string in the content body.

=cut

    elsif ( $token =~ m/^ech/i and eq_deeply( $pre, [ 'POST' ] ) ) { 
        die send_req( 'POST', 'echo', join(' ', @tokens) );
    }   


=head2 C<POST EMPLOYEE>

The same as sending a POST request for the "employee" resource

=cut

    elsif ( $token =~ m/^emp/i and eq_deeply( $pre, [ 'POST'] ) ) { 
        parse_tokens( [ 'POST', 'EMPLOYEE' ], \@tokens ) if @tokens;
        die send_req( 'POST', 'employee' );
    }   


=head2 C<POST EMPLOYEE NICK>

The same as sending a POST request for the "employee/nick" resource

=cut

    elsif ( $token =~ m/^nic/i and eq_deeply( $pre, [ 'POST', 'EMPLOYEE'] ) ) { 
        die send_req( 'POST', 'employee/nick', join(' ', @tokens) );
    }   



=head2 C<POST HELP> 

The same as sending a POST request for the "help" resource

=cut

    elsif ( $token =~ m/^hel/i and eq_deeply( $pre, [ 'POST' ] ) ) { 
        die send_req( 'POST', 'help' );
    }   


=head2 C<POST PRIVHISTORY>

The same as sending a POST request for the "privhistory" resource

=cut

    elsif ( $token =~ m/^pri/i and eq_deeply( $pre, [ 'POST'] ) ) { 
        parse_tokens( [ 'POST', 'PRIVHISTORY' ], \@tokens ) if @tokens;
        die send_req( 'POST', 'privhistory' );
    }   


    # DEL[ETE] ...
    elsif ( $token =~ m/^del/i and eq_deeply( $pre, [] ) ) { 
    }   

    # EXI[T], QU[IT], \Q
    elsif ( $token =~ m/^(exi)|(qu)|(\\q)/i and eq_deeply( $pre, [] ) ) { 
        die $CELL->status_ok( 'DOCHAZKA_CLI_EXIT' );
    }   

    die $CELL->status_err( 'DOCHAZKA_CLI_PARSE_ERROR' );
}

1;
