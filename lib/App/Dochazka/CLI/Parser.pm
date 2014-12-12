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

Version 0.064

=cut

our $VERSION = '0.064';
our $anything = qr/^.+$/i;



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

my $method; # store the HTTP method in a package variable so it is remembered

sub parse_tokens {
    my ( $pre, $tokens ) = @_; 
    return $CELL->status_err( "No more tokens" ) unless ref $tokens;
    my @tokens = @$tokens;
    my $token = shift @tokens;

    # the first token designates the HTTP method
    if ( @$pre == 0 ) { # first token is supposed to be the HTTP method

        # GET ''
        if ( $token =~  m/^GET/i ) {
            $method = 'GET';
            parse_tokens( [ 'GET' ], \@tokens ) if @tokens;
            die send_req( 'GET', '' );
        }

        # PUT ''
        elsif ( $token =~ m/^PUT/i ) {
            $method = 'PUT';
            parse_tokens( [ 'PUT' ], \@tokens ) if @tokens;
            die send_req( 'PUT', '' );
        } 
        
        # POST ''
        elsif ( $token =~ m/^POS/i ) {
            $method = 'POST';
            parse_tokens( [ 'POST' ], \@tokens ) if @tokens;
            die send_req( 'POST', '' );
        } 
        
        # DELETE ''
        elsif ( $token =~ m/^DEL/i ) {
            $method = 'DELETE';
            parse_tokens( [ 'DELETE' ], \@tokens ) if @tokens;
            die send_req( 'DELETE', '' );
        }

        # EXIT, QUIT, and the like
        elsif ( $token =~ m/^(exi)|(qu)|(\\q)/i and eq_deeply( $pre, [] ) ) { 
            die $CELL->status_ok( 'DOCHAZKA_CLI_EXIT' );
        }   

        die $CELL->status_err( 'DOCHAZKA_CLI_PARSE_ERROR' );
    }

    # second token represents the resource class ( top-level, employee, priv, etc.)
    if ( @$pre == 1 ) {

        #
        # activity resource: recurse
        #
        if ( $token =~ m/^act/i ) {
            parse_tokens( [ $method, 'ACTIVITY' ], \@tokens ) if @tokens;
            die send_req( $method, 'activity' );
        }

        #
        # employee resource: recurse
        #
        if ( $token =~ m/^emp/i ) {
            parse_tokens( [ $method, 'EMPLOYEE' ], \@tokens ) if @tokens;
            die send_req( $method, 'employee' );
        }

        #
        # priv resource: recurse
        #
        if ( $token =~ m/^pri/i ) {
            parse_tokens( [ $method, 'PRIV' ], \@tokens ) if @tokens;
            die send_req( $method, 'priv' );
        }

        #
        # schedule resource: recurse
        #
        if ( $token =~ m/^sch/i ) {
            parse_tokens( [ $method, 'SCHEDULE' ], \@tokens ) if @tokens;
            die send_req( $method, 'schedule' );
        }

        #
        # interval resource: recurse
        #
        if ( $token =~ m/^int/i ) {
            parse_tokens( [ $method, 'INTERVAL' ], \@tokens ) if @tokens;
            die send_req( $method, 'interval' );
        }

        #
        # lock resource: recurse
        #
        if ( $token =~ m/^loc/i ) {
            parse_tokens( [ $method, 'LOCK' ], \@tokens ) if @tokens;
            die send_req( $method, 'lock' );
        }

        #
        # top-level resource: handle it here
        #
        # "/bugreport"
        if ( $token =~ m/^bug/i ) {
            die send_req( $method, 'bugreport' );
        }

        # "/cookies"
        if ( $token =~ m/^coo/i ) {
            die $CELL->status_ok( 'COOKIE_JAR', payload => App::Dochazka::CLI::HTTP::cookie_jar() );
        }
    
        # "/dbstatus" 
        if ( $token =~ m/^dbs/i ) {
            die send_req( $method, 'dbstatus' );
        }

        # "/docu $RESOURCE"
        if ( $token =~ m/^doc/i ) { 
            if ( @tokens ) {
                if ( $tokens[0] =~ m/^htm/i ) {
                    my $resource = join(' ', @tokens[1..$#tokens]);
                    $resource = '"' . $resource . '"' unless $resource =~ m/^\".*\"$/;
                    die send_req( $method, 'docu/html', "{ \"resource\" : $resource }" );
                } else {
                    my $resource = join(' ', @tokens);
                    $resource = '"' . $resource . '"' unless $resource =~ m/^\".*\"$/;
                    die send_req( $method, 'docu', "{ \"resource\" : $resource }" );
                }
            } else {
                die send_req( $method, 'docu' );
            }
        }   

        # "/echo [$JSON]"
        if ( $token =~ m/^ech/i ) { 
            die send_req( $method, 'echo', join(' ', @tokens) );
        }   

        # "/forbidden"
        if ( $token =~ m/^for/i ) {
            die send_req( $method, "forbidden" );
        }

        # "/help"
        if ( $token =~ m/^hel/i ) {
            die send_req( $method, "help" );
        }
    
        # "/metaparam $JSON"
        # "/metaparam/:param"
        if ( $token =~ m/^met/i ) {
            if ( @tokens ) {
                if ( $method =~ m/^(GET)|(PUT)|(DELETE)$/ ) {
                    die send_req( $method, "metaparam/$tokens[0]" );
                }
                if ( $tokens[0] =~ m/^{/ ) {
                    die send_req( $method, "metaparam", join(' ', @tokens) );
                } 
                my $new_value = join(' ', @tokens[1..$#tokens]);
                $new_value = '"' . $new_value . '"' unless $new_value =~ m/^({)|(\[)/;
                die send_req( $method, "metaparam", "{ \"name\" : \"$tokens[0]\", \"value\" : $new_value }" );
            }
        }
    
        # "/not_implemented"
        if ( $token =~ m/^not/i ) {
            die send_req( $method, "not_implemented" );
        }

        # "/session"
        if ( $token =~ m/^ses/i ) {
            die send_req( $method, "session" );
        }

        # "/siteparam/:param"
        if ( $token =~ m/^sit/i ) {
            if ( @tokens ) {
                die send_req( $method, "siteparam/$tokens[0]" );
            }
        }
    
        # "/version"
        if ( $token =~ m/^ver/i and eq_deeply( $pre, [ $method ] ) ) {
            die send_req( $method, 'version' );
        }   

        # "/whoami"
        if ( $token =~ m/^who/i and eq_deeply( $pre, [ $method ] ) ) {
            die send_req( $method, 'whoami' );
        }   
    }

    #
    # interval resource handlers
    #
    if ( exists $pre->[1] and $pre->[1] eq 'INTERVAL' ) {

        # "/interval/eid/:eid/:tsrange"
        if ( $token =~ m/^eid$/ ) {
            if ( @tokens ) {
                if ( $tokens[0] =~ m/^\d+$/ ) {
                    my $eid = shift @tokens;
                    if ( @tokens ) {
                        my $tsrange = join(' ', @tokens);
                        if ( $tsrange =~ m/\[.+\)/ ) {
                            die send_req( $method, "interval/eid/$eid/$tsrange" );
                        }
                    }
                }
            }
        }

        # "/interval/help"
        if ( $token =~ m/^hel/i ) {
            die send_req( $method, 'interval/help' );
        }

        # "/interval/iid"
        # "/interval/iid/:iid"
        if ( $token =~ m/^iid$/i ) {
            if ( @tokens ) {
                if ( $tokens[0] =~ m/^[\[{]/ ) {
                    die send_req( $method, "interval/iid", join(' ', @tokens) );
                } elsif ( $tokens[0] =~ m/^\d+/ ) {
                    die send_req( $method, "interval/iid/$tokens[0]", join(' ', @tokens[1..$#tokens]) );
                }
            }
        }

        # "/interval/new"
        if ( $token =~ m/^new/i ) {
            if ( @tokens ) {
                die send_req( $method, 'interval/new', join(' ', @tokens) );
            }
        }

        # "/interval/nick/:nick/:tsrange"
        if ( $token =~ m/^nick$/ ) {
            if ( @tokens ) {
                if ( $tokens[0] =~ m/^[A-Za-z0-9_].+/ ) {
                    my $nick = shift @tokens;
                    if ( @tokens ) {
                        my $tsrange = join(' ', @tokens);
                        if ( $tsrange =~ m/\[.+\)/ ) {
                            die send_req( $method, "interval/nick/$nick/$tsrange" );
                        }
                    }
                }
            }
        }

        # "/interval/self/:tsrange"
        if ( $token =~ m/^self$/ ) {
            if ( @tokens ) {
                 my $tsrange = join(' ', @tokens);
                 if ( $tsrange =~ m/\[.+\)/ ) {
                     die send_req( $method, "interval/self/$tsrange" );
                 }
            }
        }

    }


    #
    # lock resource handlers
    #
    if ( exists $pre->[1] and $pre->[1] eq 'LOCK' ) {

        # "/lock/eid/:eid/:tsrange"
        if ( $token =~ m/^eid$/ ) {
            if ( @tokens ) {
                if ( $tokens[0] =~ m/^\d+$/ ) {
                    my $eid = shift @tokens;
                    if ( @tokens ) {
                        my $tsrange = join(' ', @tokens);
                        if ( $tsrange =~ m/\[.+\)/ ) {
                            die send_req( $method, "lock/eid/$eid/$tsrange" );
                        }
                    }
                }
            }
        }

        # "/lock/help"
        if ( $token =~ m/^hel/i ) {
            die send_req( $method, 'lock/help' );
        }

        # "/lock/lid"
        # "/lock/lid/:lid"
        if ( $token =~ m/^lid$/i ) {
            if ( @tokens ) {
                if ( $tokens[0] =~ m/^[\[{]/ ) {
                    die send_req( $method, "lock/lid", join(' ', @tokens) );
                } elsif ( $tokens[0] =~ m/^\d+/ ) {
                    die send_req( $method, "lock/lid/$tokens[0]", join(' ', @tokens[1..$#tokens]) );
                }
            }
        }

        # "/lock/new"
        if ( $token =~ m/^new/i ) {
            if ( @tokens ) {
                die send_req( $method, 'lock/new', join(' ', @tokens) );
            }
        }

        # "/lock/nick/:nick/:tsrange"
        if ( $token =~ m/^nick$/ ) {
            if ( @tokens ) {
                if ( $tokens[0] =~ m/^[A-Za-z0-9_].+/ ) {
                    my $nick = shift @tokens;
                    if ( @tokens ) {
                        my $tsrange = join(' ', @tokens);
                        if ( $tsrange =~ m/\[.+\)/ ) {
                            die send_req( $method, "lock/nick/$nick/$tsrange" );
                        }
                    }
                }
            }
        }

        # "/lock/self/:tsrange"
        if ( $token =~ m/^self$/ ) {
            if ( @tokens ) {
                 my $tsrange = join(' ', @tokens);
                 if ( $tsrange =~ m/\[.+\)/ ) {
                     die send_req( $method, "lock/self/$tsrange" );
                 }
            }
        }

    }


    #
    # schedule resource handlers
    #
    if ( exists $pre->[1] and $pre->[1] eq 'SCHEDULE' ) {

        # "/schedule/all"
        # "/schedule/all/disabled"
        if ( $token =~ m/^all/i ) {
            if ( @tokens ) {
                if ( $tokens[0] =~ m/^dis/i ) {
                    die send_req( $method, "schedule/all/disabled" );
                }
            }
            die send_req( $method, "schedule/all" );
        }

        # "/schedule/eid/:eid/?:ts"
        if ( $token =~ m/^eid/i ) {
            if ( $tokens[1] ) {
                die send_req( $method, "schedule/eid/$tokens[0]/$tokens[1]" );
            } 
            if ( $tokens[0] ) {
                die send_req( $method, "schedule/eid/$tokens[0]" );
            }
        }
        
        # "/schedule/help"
        if ( $token =~ m/^hel/i ) {
            die send_req( $method, 'schedule/help' );
        }

        # "/schedule/history..."
        if ( $token =~ m/^his/i ) {
    
            # "/schedule/history"
            if ( not @tokens ) {
                die send_req( $method, "schedule/history" );
            }

            # "/schedule/history/eid/:eid [$JSON]"
            # "/schedule/history/eid/:eid/:tsrange"
            if ( $tokens[0] and $tokens[0] =~ m/^eid/i and $tokens[1] and $tokens[1] =~ m/^\d+$/ ) {
                if ( $tokens[2] and $tokens[2] =~ m/^\[/ ) {
                    die send_req( $method, "schedule/history/eid/$tokens[1]/" . join(' ', @tokens[2..$#tokens]) );
                }
                die send_req( $method, "schedule/history/eid/$tokens[1]", join(' ', @tokens[2..$#tokens]) );
            }
            
            # "/schedule/history/nick/:nick [$JSON]
            # "/schedule/history/nick/:nick/:tsrange
            if ( $tokens[0] and $tokens[0] =~ m/^nic/i and $tokens[1] ) {
                if ( $tokens[2] and $tokens[2] =~ m/^\[/ ) {
                    die send_req( $method, "schedule/history/nick/$tokens[1]/" . join(' ', @tokens[2..$#tokens]) );
                }
                die send_req( $method, "schedule/history/nick/$tokens[1]", join(' ', @tokens[2..$#tokens]));
            }

            # "/schedule/history/self"
            # "/schedule/history/self/:tsrange"
            if ( $tokens[0] and $tokens[0] =~ m/^sel/i ) {
                if ( $tokens[1] and $tokens[1] =~ m/^\[/ ) {
                    die send_req( $method, "schedule/history/self/" . join(' ', @tokens[1..$#tokens]) );
                }
                die send_req( $method, "schedule/history/self" );
            }

            # "/schedule/history/shid/:shid
            if ( $tokens[0] and $tokens[0] =~ m/^shi/i and $tokens[1] ) {
                die send_req( $method, "schedule/history/shid/$tokens[1]" );
            }

        }

        # "/schedule/intervals"
        if ( $token =~ m/^int/i ) {
            if ( @tokens ) {
                if ( $tokens[0] =~ m/^({)|(\[)/ ) {
                    die send_req( $method, "schedule/intervals", join(' ', @tokens) );
                }
            }
            die send_req( $method, "schedule/intervals" );
        }

        # "/schedule/new"
        if ( $token =~ m/^new/i ) {
            if ( @tokens ) {
                if ( $tokens[0] =~ m/^({)|(\[)/ ) {
                    die send_req( $method, "schedule/new", join(' ', @tokens) );
                }
            }
        }

        # "/schedule/nick/:nick/?:ts"
        if ( $token =~ m/^nic/i ) {
            if ( $tokens[1] ) {
                die send_req( $method, "schedule/nick/$tokens[0]/$tokens[1]" );
            } 
            if ( $tokens[0] ) {
                die send_req( $method, "schedule/nick/$tokens[0]" );
            }
        }

        # "/schedule/self/?:ts"
        if ( $token =~ m/^sel/i ) {
            if ( not @tokens ) {
                die send_req( $method, "schedule/self" );
            } else {
                die send_req( $method, "schedule/self/$tokens[0]" );
            }
        }

        # "/schedule/sid/:sid"
        if ( $token =~ m/^sid/i ) {
            if ( @tokens ) {
                if ( $tokens[0] =~ m/^\d+/ ) {
                    if ( $method =~ m/^(GET)|(DELETE)$/ ) {
                        die send_req( $method, "schedule/sid/$tokens[0]" );
                    }
                    if ( exists $tokens[1] ) {
                        die send_req( $method, "schedule/sid/$tokens[0]", join(' ', @tokens[1..$#tokens]) );
                    }
                }
            }
        }

    }

    #
    # activity resource handlers
    #
    if ( exists $pre->[1] and $pre->[1] eq 'ACTIVITY' ) {
        
        # "/activity/aid"
        # "/activity/aid/:aid"
        if ( $token =~ m/^aid/i ) {
#            if ( $tokens[0] =~ m/^\d+$/ ) {
            if ( @tokens ) {
                my $aid = $tokens[0];
                if ( $method =~ m/^(GET)|(DELETE)$/ ) {
                    die send_req( $method, "activity/aid/$aid" );
                } elsif ( $method =~ m/PUT$/ ) {
                    die send_req( $method, "activity/aid/$aid", join(' ', @tokens[1..$#tokens]) );
                } elsif ( $method =~ m/POST$/ ) {
                    die send_req( $method, "activity/aid", join(' ', @tokens) );
                }
            } else {
                die send_req( $method, "activity/aid" );
            }
        }

        # "/activity/all"
        # "/activity/all/disabled"
        if ( $token =~ m/^all/i ) {
            if ( @tokens ) {
                die send_req( $method, 'activity/all/disabled' ) if $tokens[0] =~ m/^dis/;
            } else {
                die send_req( $method, 'activity/all' );
            }
        }

        # "/activity/code"
        # "/activity/code/:code"
        if ( $token =~ m/^cod/i ) {
#            if ( $tokens[0] =~ m/^\d+$/ ) {
            if ( @tokens ) {
                my $code = $tokens[0];
                if ( $method =~ m/^(GET)|(DELETE)$/ ) {
                    die send_req( $method, "activity/code/$code" );
                } elsif ( $method =~ m/^PUT$/ ) {
                    die send_req( $method, "activity/code/$code", join(' ', @tokens[1..$#tokens]) );
                } elsif ( $method =~ m/^POST$/ ) {
                    die send_req( $method, "activity/code", join(' ', @tokens) );
                }
            } else {
                die send_req( $method, "activity/code" );
            }
        }

        # "/activity/help"
        if ( $token =~ m/^hel/i ) {
            die send_req( $method, 'activity/help' );
        }

    }

    #
    # employee resource handlers
    #
    elsif ( exists $pre->[1] and $pre->[1] eq 'EMPLOYEE' ) {
        
        # "/employee/count"
        # "/employee/count/:priv"
        if ( $token =~ m/^cou/i ) {
            parse_tokens( [ $method, 'EMPLOYEE', 'COUNT' ], \@tokens ) if @tokens;
            die send_req( $method, 'employee/count' );
        } elsif ( $token =~ $anything and eq_deeply( $pre, [ $method, 'EMPLOYEE', 'COUNT' ] ) ) {
            die send_req( $method, 'employee/count/' . $token );
        }

        # "/employee/current"
        # "/employee/current/priv"
        # "/employee/self"
        # "/employee/self/priv"
        if ( $token =~ m/^sel/i or $token =~ m/^cur/i ) {
            if ( @tokens ) {
                if ( $tokens[0] =~ m/^pri/i ) {
                    die send_req( $method, 'employee/self/priv' );
                } elsif ( $method ne 'GET' ) {
                    die send_req( $method, 'employee/self', join(' ', @tokens ) );
                }
            } else {
                die send_req( $method, 'employee/self' );
            }
        }

        # "/employee/eid [$JSON]"
        # "/employee/eid/:eid [$JSON]"
        if ( $token =~ m/^eid/i ) {
            if ( @tokens ) {
                if ( $tokens[0] =~ m/^\d+/ ) {
                    my $eid = $tokens[0];
                    die send_req( $method, "employee/eid/$eid", join(' ', @tokens[1..$#tokens]) );
                } else {
                    die send_req( $method, 'employee/eid', join(' ', @tokens) );
                }
            }   
        }

        # "/employee/help"
        if ( $token =~ m/^hel/i ) {
            die send_req( $method, 'employee/help' );
        }

        # "/employee/nick [$JSON]"
        # "/employee/nick/:nick [$JSON]"
        if ( $token =~ m/^nic/i ) {
            if ( @tokens ) {
                if ( $tokens[0] =~ m/^\{/ ) {
                    die send_req( $method, "employee/nick", join(' ', @tokens) );
                } else {
                    my $nick = $tokens[0];
                    die send_req( $method, "employee/nick/$nick", join(' ', @tokens[1..$#tokens]) );
                }
            }
        }
    }   

    #
    # priv resource handlers
    #
    if ( exists $pre->[1] and $pre->[1] eq 'PRIV' ) {

        # "/priv"
        if ( $token =~ m/^pri/i and eq_deeply( $pre, [ $method ] ) ) {
            parse_tokens( [ $method, 'PRIV' ], \@tokens ) if @tokens;
            die send_req( $method, "priv" );
        }
    
        # "/priv/self/?:ts"
        if ( $token =~ m/^sel/i ) {
            if ( not @tokens ) {
                die send_req( $method, "priv/self" );
            } else {
                die send_req( $method, "priv/self/$tokens[0]" );
            }
        }

        # "/priv/eid/:eid/?:ts"
        if ( $token =~ m/^eid/i ) {
            if ( $tokens[1] ) {
                die send_req( $method, "priv/eid/$tokens[0]/$tokens[1]" );
            } 
            if ( $tokens[0] ) {
                die send_req( $method, "priv/eid/$tokens[0]" );
            }
        }
        
        # "/priv/help"
        if ( $token =~ m/^hel/i ) {
            die send_req( $method, 'priv/help' );
        }
    
        # "/priv/history..."
        if ( $token =~ m/^his/i ) {
    
            # "/priv/history"
            if ( not @tokens ) {
                die send_req( $method, "priv/history" );
            }

            # "/priv/history/eid/:eid [$JSON]"
            # "/priv/history/eid/:eid/:tsrange"
            if ( $tokens[0] and $tokens[0] =~ m/^eid/i and $tokens[1] and $tokens[1] =~ m/^\d+$/ ) {
                if ( $tokens[2] and $tokens[2] =~ m/^\[/ ) {
                    die send_req( $method, "priv/history/eid/$tokens[1]/" . join(' ', @tokens[2..$#tokens]) );
                }
                die send_req( $method, "priv/history/eid/$tokens[1]", join(' ', @tokens[2..$#tokens]) );
            }
            
            # "/priv/history/nick/:nick [$JSON]
            # "/priv/history/nick/:nick/:tsrange
            if ( $tokens[0] and $tokens[0] =~ m/^nic/i and $tokens[1] ) {
                if ( $tokens[2] and $tokens[2] =~ m/^\[/ ) {
                    die send_req( $method, "priv/history/nick/$tokens[1]/" . join(' ', @tokens[2..$#tokens]) );
                }
                die send_req( $method, "priv/history/nick/$tokens[1]", join(' ', @tokens[2..$#tokens]));
            }

            # "/priv/history/phid/:phid
            if ( $tokens[0] and $tokens[0] =~ m/^phi/i and $tokens[1] ) {
                die send_req( $method, "priv/history/phid/$tokens[1]" );
            }

            # "/priv/history/self"
            # "/priv/history/self/:tsrange"
            if ( $tokens[0] and $tokens[0] =~ m/^sel/i ) {
                if ( $tokens[1] and $tokens[1] =~ m/^\[/ ) {
                    die send_req( $method, "priv/history/self/" . join(' ', @tokens[1..$#tokens]) );
                }
                die send_req( $method, "priv/history/self" );
            }

        }

        # "/priv/nick/:nick/?:ts"
        if ( $token =~ m/^nic/i ) {
            if ( $tokens[1] ) {
                die send_req( $method, "priv/nick/$tokens[0]/$tokens[1]" );
            } 
            if ( $tokens[0] ) {
                die send_req( $method, "priv/nick/$tokens[0]" );
            }
        }

    
    }

    # we have gone all the way through the state machine without a match
    die $CELL->status_err( 'DOCHAZKA_CLI_PARSE_ERROR' );
}

1;
