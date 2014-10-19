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
# placeholder module
#
package App::Dochazka::CLI;

use 5.006;
use strict;
use warnings FATAL => 'all';

=head1 NAME

App::Dochazka::CLI - Dochazka command line client

=head1 VERSION

Version 0.013

=cut

our $VERSION = '0.013';


=head1 SYNOPSIS

Dochazka command line client.

    bash$ dochazka-cli
    Dochazka(2014-08-08) demo> 



=head1 DESCRIPTION

This is the Dochazka command line client.



=head1 COMMANDS

The command syntax is intended to be closely coupled with the underlying REST resources.


=head2 Top-level resources

The top-level REST resources are documented at L<App::Dochazka::REST::Dispatch>.


=head3 C<GET>

A lone C<GET> (equivalent to C<GET HELP>) is analogous to sending a bare GET
request to the base URI.

=head3 C<GET HELP>

The same as sending a GET request for the 'help' resource.

=head3 C<GET COOKIE>

This command dumps the cookie jar. It is client-side only, so no analogous REST resource.

=head3 C<GET EMPLOYEE>

The same as sending a GET request for the 'employee' resource.

=head3 C<GET EMPLOYEE CURRENT>

The same as sending a GET request for the 'employee/current' resource.

=head3 C<GET EMPLOYEE [INTEGER]>

The same as sending a GET request for the 'employee/[INTEGER]' resource. For
example, C<GET EMPLOYEE 1> should retrieve the profile of the employee 'root'.

=head3 C<GET EMPLOYEE [STRING]>

The same as sending a GET request for the 'employee/[STRING]' resource, where
[STRING] is an alphanumeric string. For example, C<GET EMPLOYEE root> should
retrieve the profile of the employee 'root'.

=head3 C<GET WHOAMI>

The same as sending a GET request for the 'whoami' resource.

=cut

1; # End of App::Dochazka::CLI
