## Domain Registry Interface, PIR (.ORG) policies
##
## Copyright (c) 2006-2009 Rony Meyer <perl@spot-light.ch>. All rights reserved.
##           (c) 2010-2011,2016 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
##           (c) 2014-2017 Michael Holloway <michael@thedarkwinter.com>. All rights reserved.
##           (c) 2022 Paulo Castanheira <paulo.s.castanheira@gmail.com>. All rights reserved.
##
## This file is part of Net::DRI
##
## Net::DRI is free software; you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation; either version 2 of the License, or
## (at your option) any later version.
##
## See the LICENSE file that comes with this distribution for more details.
####################################################################################################

package Net::DRI::DRD::Donuts::PIR;

use strict;
use warnings;

use base qw/Net::DRI::DRD/;

use DateTime::Duration;

=pod

=head1 NAME

Additional domain extensions for the PIR Registry Platform

Donuts/PIR has extended the .ORG plaform to include these TLDs in a Shared Registry System

Donuts utilises the following standard extensions. Please see the test files for more examples.

=head2 Standard extensions:

=head3 L<Net::DRI::Protocol::EPP::Extensions::secDNS> urn:ietf:params:xml:ns:secDNS-1.1

=head3 L<Net::DRI::Protocol::EPP::Extensions::GracePeriod> urn:ietf:params:xml:ns:rgp-1.0

=head3 L<Net::DRI::Protocol::EPP::Extensions::LaunchPhase> urn:ietf:params:xml:ns:launch-1.0

=head3 L<Net::DRI::Protocol::EPP::Extensions::IDN> urn:ietf:params:xml:ns:idn-1.0

=head2 Custom extensions:

=head3 L<NET::DRI::Protocol::EPP::Extensions::UnitedTLD::Charge> http://www.unitedtld.com/epp/charge-1.0

=head3 L<NET::DRI::Protocol::EPP::Extensions::UnitedTLD::Finance> http://www.unitedtld.com/epp/finance-1.0

=head3 L<NET::DRI::Protocol::EPP::Extensions::ARI::KeyValue> urn:X-ar:params:xml:ns:kv-1.1

=head1 DESCRIPTION

Please see the README file for details.

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>netdri@dotandco.comE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

E<lt>http://www.dotandco.com/services/software/Net-DRI/E<gt>

=head1 AUTHOR

Patrick Mevzek, E<lt>netdri@dotandco.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2006-2009 Rony Meyer <perl@spot-light.ch>.
          (c) 2010-2011,2016 Patrick Mevzek <netdri@dotandco.com>.
          (c) 2017 Michael Holloway <michael@thedarkwinter.com>.
          (c) 2022 Paulo Castanheira <paulo.s.castanheira@gmail.com>.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut

####################################################################################################

sub new
{
 my $class=shift;
 my $self=$class->SUPER::new(@_);
 $self->{info}->{host_as_attr}=0;
 $self->{info}->{contact_i18n}=4; ## LOC+INT
 $self->{info}->{check_limit}=13;
 return $self;
}

sub periods  { return map { DateTime::Duration->new(years => $_) } (1..10); }
sub name     { return 'Donuts::PIR'; }
sub tlds     { return qw/org xn--c1avg xn--i1b6b1a6a2e xn--nqv7f ngo ong charity foundation gives/; }
sub object_types { return ('domain','contact','ns'); }
sub profile_types { return qw/epp whois/; }

sub transport_protocol_default
{
 my ($self,$type)=@_;

 return ('Net::DRI::Transport::Socket',{},'Net::DRI::Protocol::EPP::Extensions::UnitedTLD',{}) if $type eq 'epp';
 return ('Net::DRI::Transport::Socket',{remote_host=>'whois.publicinterestregistry.org'},'Net::DRI::Protocol::Whois',{}) if $type eq 'whois';
 return;
}

####################################################################################################

sub verify_name_domain
{
 my ($self,$ndr,$domain,$op)=@_;
 return $self->_verify_name_rules($domain,$op,{check_name => 1,
                                               my_tld => 1,
                                               icann_reserved => 1,
                                              });
}

####################################################################################################
1;
