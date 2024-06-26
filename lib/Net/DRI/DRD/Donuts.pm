## Domain Registry Interface, Donuts Driver
##
## Copyright (c) 2013 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
##           (c) 2014-2017 Michael Holloway <michael@thedarkwinter.com>. All rights reserved.
##           (c) 2018-2021 Paulo Jorge <paullojorgge@gmail.com>. All rights reserved.
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

package Net::DRI::DRD::Donuts;

use strict;
use warnings;

use base qw/Net::DRI::DRD/;

use DateTime::Duration;

=pod

=head1 NAME

Net::DRI::DRD::DONUTS - DONUTS Driver for Net::DRI

=head1 DESCRIPTION

Additional domain extension DONUTS New Generic TLDs

Donuts utilises the following standard, and custom extensions. Please see the test files for more examples.

=head2 Standard extensions:

=head3 L<Net::DRI::Protocol::EPP::Extensions::secDNS> urn:ietf:params:xml:ns:secDNS-1.1

=head3 L<Net::DRI::Protocol::EPP::Extensions::GracePeriod> urn:ietf:params:xml:ns:rgp-1.0

=head3 L<Net::DRI::Protocol::EPP::Extensions::LaunchPhase> urn:ietf:params:xml:ns:launch-1.0

=head3 L<Net::DRI::Protocol::EPP::Extensions::IDN> urn:ietf:params:xml:ns:idn-1.0

=head2 Custom extensions:

=head3 L<NET::DRI::Protocol::EPP::Extensions::UnitedTLD::Charge> http://www.unitedtld.com/epp/charge-1.0

=head3 L<NET::DRI::Protocol::EPP::Extensions::UnitedTLD::Finance> http://www.unitedtld.com/epp/finance-1.0

=head3 L<NET::DRI::Protocol::EPP::Extensions::ARI::KeyValue> urn:X-ar:params:xml:ns:kv-1.1

=head2 DPML Blocks / Overrides:

In order to submit DPML blocks OR DMPL Overrides, submit a domain_create with the correct TLD (.dpml.zone for block) and the LaunchPhase extensions should contain the [Encoded] Signed Mark, along with the phase name 'dpml'

  $dri->domain_create('mylabel.dpml.zone',{ ... lp => {phase->'dpml',encoded_signed_mark = [ $enc ]}   });# DPML Block
  $dri->domain_create('mylabel.energy',{ ... lp => {phase->'dpml',encoded_signed_mark = [ $enc ]}   }); # DPML Override

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>netdri@dotandco.comE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

E<lt>http://www.dotandco.com/services/software/Net-DRI/E<gt>

=head1 AUTHOR

Michael Holloway, E<lt>michael@thedarkwinter.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2013 Patrick Mevzek <netdri@dotandco.com>.
(c) 2014-2016 Michael Holloway <michael@thedarkwinter.com>.
(c) 2018-2021 Paulo Jorge <paullojorgge@gmail.com>.
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
 return $self;
}

sub periods  { return map { DateTime::Duration->new(years => $_) } (1..10); }
sub name     { return 'Donuts'; }
sub tlds  {
 my @dpml = qw/dpml.pub dpml.zone/; # DPML
 my @gtlds = qw/academy accountants actor agency airforce apartments archi architect army associates attorney auction band bargains bet bike bingo bio black blue boutique broker builders business cab cafe camera camp capital cards care careers cash casino catering center chat cheap church city claims cleaning clinic clothing coach codes coffee community company computer condos construction consulting contact contractors cool coupons credit creditcard cruises dance dating deals degree delivery democrat dental dentist diamonds digital direct directory discount doctor dog domains education email energy engineer engineering enterprises equipment estate events exchange expert exposed express fail family fan farm finance financial fish fitness flights florist football forex forsale fund furniture futbol fyi gallery games gifts glass global gmbh gold golf graphics gratis green gripe group guide guru haus healthcare hockey holdings holiday hospital house immo immobilien industries institute insure international investments irish jetzt jewelry kaufen kim kitchen land lawyer lease legal lgbt life lighting limited limo live llc loans lotto ltd maison management market marketing markets mba media medical meet memorial moda money mortgage movie navy network news ninja observer organic partners parts pet pets photography photos pictures pink pizza place plumbing plus poker productions promo properties pub realty recipes red rehab reise reisen rentals repair report republican restaurant reviews rip rocks run sale salon sarl school schule services shiksha shoes shopping show singles ski soccer social software solar solutions sports studio style supplies supply support surgery systems tax taxi team technology tennis theater tienda tips tires today tools tours town toys trading training travel university vacations ventures vet viajes video villas vin vision vote voto voyage watch watches wine works world wtf xn--5tzm5g xn--6frz82g xn--czrs0t xn--fjq720a xn--unup4y xn--vhquv zone/;
 my @legacygTLDs = ('info', 'mobi', 'pro',(map { $_.'.pro'} qw/law jur bar med cpa aca eng/));
 my @ccTLDs = qw/io sh ac/;
 return (@dpml,@gtlds,@legacygTLDs,@ccTLDs);
}
sub object_types { return ('domain','contact','ns'); }
sub profile_types { return qw/epp/; }

sub transport_protocol_default
{
 my ($self,$type)=@_;
 return ('Net::DRI::Transport::Socket',{},'Net::DRI::Protocol::EPP::Extensions::UnitedTLD',{}) if $type eq 'epp';
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
