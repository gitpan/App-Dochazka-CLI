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

Version 0.010

=cut

our $VERSION = '0.010';




=head1 SYNOPSIS

    use Try::Tiny;
    
    my $status;
    my @tokens = split /\s+/, 'MY SAMPLE COMMAND';
    try { 
        App::Dochazka::CLI::Parse::parse_tokens( [], \@tokens ); 
    } catch { 
        $status = $_; 
    };




=head1 FUNCTIONS


=head2 parse_tokens

The parser. It calls itself recursively until it gets to a 

    die send_req . . .

which sends it back to the while loop in C<dochazka-cli> with
the return value of the C<send_req>, which is a status object.

All tokens should be chosen to be distinguishable by their first
three characters.

=cut

sub parse_tokens {
    my ( $pre, $tokens ) = @_; 
    return $CELL->status_err( "No more tokens" ) unless ref $tokens;
    my @tokens = @$tokens;
    my $token = shift @tokens;

    # GET ...
    if    ( $token =~ m/^get/i and eq_deeply( $pre, [] ) ) { 
        parse_tokens( [ 'GET' ], \@tokens );
    }   

    # GET COO[KIES]
    elsif ( $token =~ m/^coo/i and eq_deeply( $pre, [ 'GET' ] ) ) {
        die $CELL->status_ok( 'COOKIE_JAR', payload => App::Dochazka::CLI::HTTP::cookie_jar() );
    }

    # GET EMP[LOYEE]
    elsif ( $token =~ m/^emp/i and eq_deeply( $pre, [ 'GET' ] ) ) {
        die send_req( 'GET', 'employee/current' ) if ! @tokens;
        my $param = shift @tokens;

    # GET EMP[LOYEE] $INTEGER
        if ( $param =~ m/^\d+$/ ) {
            die send_req( 'GET', "employee/eid/$param" );

    # GET EMP[LOYEE] $STRING
        } else {
            die send_req( 'GET', "employee/nick/$param" );
        }
    }
    
    # GET SES[SION]
    elsif ( $token =~ m/^ses/i and eq_deeply( $pre, [ 'GET' ] ) ) {
        die send_req( 'GET', "session" );
    }

    # PUT ...
    elsif ( $token =~ m/^put/i and eq_deeply( $pre, [] ) ) { 
    }   

    # POS[T] ...
    elsif ( $token =~ m/^pos/i and eq_deeply( $pre, [] ) ) { 
    }   

    # DEL[ETE] ...
    elsif ( $token =~ m/^del/i and eq_deeply( $pre, [] ) ) { 
    }   

    # EXI[T]
    elsif ( $token =~ m/^exi/i and eq_deeply( $pre, [] ) ) { 
        die $CELL->status_ok( 'DOCHAZKA_CLI_EXIT' );
    }   

    die $CELL->status_err( 'DOCHAZKA_CLI_PARSE_ERROR' );
}

1;
