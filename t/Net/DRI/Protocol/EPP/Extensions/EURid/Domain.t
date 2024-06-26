#!/usr/bin/perl

use strict;
use warnings;
use utf8;

use Net::DRI;
use Net::DRI::Data::Raw;
use DateTime;
use DateTime::Duration;

use Test::More tests => 233;
eval { no warnings; require Test::LongString; Test::LongString->import(max => 100); $Test::LongString::Context=50; };
if ( $@ ) { no strict 'refs'; *{'main::is_string'}=\&main::is; }

our $E1='<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd">';
our $E2='</epp>';
our $TRID='<trID><clTRID>TRID-0001</clTRID><svTRID>eurid-488059</svTRID></trID>';

our ($R1,$R2);
sub mysend { my ($transport,$count,$msg)=@_; $R1=$msg->as_string(); return 1; }
sub myrecv { return Net::DRI::Data::Raw->new_from_string($R2? $R2 : $E1.'<response>'.r().$TRID.'</response>'.$E2); }
sub r      { my ($c,$m)=@_; return '<result code="'.($c || 1000).'"><msg>'.($m || 'Command completed successfully').'</msg></result>'; }

my $dri=Net::DRI::TrapExceptions->new({cache_ttl => 10, trid_factory => sub { return 'ABC-12345'}, logging => 'null' });
$dri->add_registry('EURid');
$dri->target('EURid')->add_current_profile('p1','epp',{f_send=>\&mysend,f_recv=>\&myrecv});

my ($rc,$s,$d,$co,$toc,$cs,$h,$dh,$e,@c,@d);

########################################################################################################

## Process greetings to select namespace versions
# We need secDNS and domain-ext to select correct versions in the test file
$R2=$E1.'<greeting><svID>eurid.eu</svID><svDate>2016-11-17T14:30:12.230Z</svDate><svcMenu><version>1.0</version><lang>en</lang><objURI>urn:ietf:params:xml:ns:contact-1.0</objURI><objURI>urn:ietf:params:xml:ns:domain-1.0</objURI><objURI>http://www.eurid.eu/xml/epp/registrarFinance-1.0</objURI><objURI>http://www.eurid.eu/xml/epp/registrarHitPoints-1.0</objURI><objURI>http://www.eurid.eu/xml/epp/registrationLimit-1.1</objURI><objURI>http://www.eurid.eu/xml/epp/nsgroup-1.1</objURI><objURI>http://www.eurid.eu/xml/epp/keygroup-1.1</objURI><svcExtension><extURI>http://www.eurid.eu/xml/epp/contact-ext-1.3</extURI><extURI>http://www.eurid.eu/xml/epp/domain-ext-2.4</extURI><extURI>urn:ietf:params:xml:ns:secDNS-1.1</extURI><extURI>http://www.eurid.eu/xml/epp/idn-1.0</extURI><extURI>http://www.eurid.eu/xml/epp/dnsQuality-1.0</extURI><extURI>http://www.eurid.eu/xml/epp/authInfo-1.1</extURI><extURI>http://www.eurid.eu/xml/epp/poll-1.2</extURI><extURI>http://www.eurid.eu/xml/epp/homoglyph-1.0</extURI></svcExtension></svcMenu><dcp><access><all /></access><statement><purpose><admin /><prov /></purpose><recipient><ours /><public /></recipient><retention><stated /></retention></statement></dcp></greeting>'.$E2;
$rc=$dri->process('session','noop',[]);
is($dri->protocol()->ns()->{'secDNS'}->[0],'urn:ietf:params:xml:ns:secDNS-1.1','secDNS 1.1 for server announcing 1.0 + 1.1');
is($dri->protocol()->ns()->{'domain-ext'}->[0],'http://www.eurid.eu/xml/epp/domain-ext-2.4','domain-ext 2.4 for server announcing 2.4');

########################################################################################################
### DOMAIN_CHECK
## Note, the tests are still from 2.1.09 (domain-ext-1.2). domain-ext-2.0 had a schema correction for the domain transfer, but is otherwise the same.
## Therefore, I have string replaced the schema versions in these tests
## domain-ext-2.4 adds the delayed flag


## 2.1.09/domains/domain-check/domain-check01-resp.xml
# Example of domain check command of multiple domain names
# Response edited, long domain removed, and we need to check availableDate and idn extensions
$R2=$E1.'<response>'.r().'<resData><domain:chkData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:cd><domain:name avail="true">some-domain-info-0000000000.eu</domain:name></domain:cd><domain:cd><domain:name avail="false">some-domain-info-1349951245.eu</domain:name><domain:reason lang="en">in use</domain:reason></domain:cd><domain:cd><domain:name avail="false">some-domain-info-1349951246.eu</domain:name><domain:reason lang="en">quarantine</domain:reason></domain:cd><domain:cd><domain:name avail="false">andalucia.eu</domain:name><domain:reason lang="en">reserved</domain:reason></domain:cd><domain:cd><domain:name avail="false">andalucía.eu</domain:name><domain:reason lang="en">reserved</domain:reason></domain:cd><domain:cd><domain:name avail="false">agias.eu</domain:name><domain:reason lang="en">blocked</domain:reason></domain:cd><domain:cd><domain:name avail="false">rey-españa.eu</domain:name><domain:reason lang="en">blocked</domain:reason></domain:cd><domain:cd><domain:name avail="false">20karat.eu</domain:name><domain:reason lang="en">in use</domain:reason></domain:cd><domain:cd><domain:name avail="false">crédit-suisse.eu</domain:name><domain:reason lang="en">in use</domain:reason></domain:cd><domain:cd><domain:name avail="false">bandit-corp.eu</domain:name><domain:reason lang="en">suspended</domain:reason></domain:cd><domain:cd><domain:name avail="false">court-order-seized.eu</domain:name><domain:reason lang="en">seized</domain:reason></domain:cd></domain:chkData></resData><extension><domain-ext:chkData xmlns:domain-ext="http://www.eurid.eu/xml/epp/domain-ext-2.4"><domain-ext:domain><domain-ext:name>some-domain-info-1349951246.eu</domain-ext:name><domain-ext:availableDate>2014-10-23T13:52:13.392Z</domain-ext:availableDate></domain-ext:domain></domain-ext:chkData><idn:mapping xmlns:idn="http://www.eurid.eu/xml/epp/idn-1.0"><idn:name><idn:ace>xn--andaluca-i2a.eu</idn:ace><idn:unicode>andalucía.eu</idn:unicode></idn:name><idn:name><idn:ace>xn--crdit-suisse-ceb.eu</idn:ace><idn:unicode>crédit-suisse.eu</idn:unicode></idn:name><idn:name><idn:ace>xn--rey-espaa-s6a.eu</idn:ace><idn:unicode>rey-españa.eu</idn:unicode></idn:name></idn:mapping></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_check('some-domain-info-0000000000.eu','some-domain-info-1349951245.eu','some-domain-info-1349951246.eu','andalucia.eu','andalucía.eu','agias.eu','rey-españa.eu','20karat.eu','crédit-suisse.eu','bandit-corp.eu','court-order-seized.eu');
is_string($R1,'<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd"><command><check><domain:check xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>some-domain-info-0000000000.eu</domain:name><domain:name>some-domain-info-1349951245.eu</domain:name><domain:name>some-domain-info-1349951246.eu</domain:name><domain:name>andalucia.eu</domain:name><domain:name>andalucía.eu</domain:name><domain:name>agias.eu</domain:name><domain:name>rey-españa.eu</domain:name><domain:name>20karat.eu</domain:name><domain:name>crédit-suisse.eu</domain:name><domain:name>bandit-corp.eu</domain:name><domain:name>court-order-seized.eu</domain:name></domain:check></check><clTRID>ABC-12345</clTRID></command></epp>','domain_check build');
is($rc->is_success(),1,'domain_check is_success');
is($dri->get_info('exist','domain','some-domain-info-0000000000.eu'),0,'domain_check get_info(exist)');
is($dri->get_info('exist','domain','some-domain-info-1349951245.eu'),1,'domain_check get_info(exist)');
is($dri->get_info('exist_reason','domain','some-domain-info-1349951245.eu'),'in use','domain_check get_info(exist_reason)');
is($dri->get_info('exist','domain','some-domain-info-1349951246.eu'),1,'domain_check get_info(exist)');
is($dri->get_info('exist_reason','domain','some-domain-info-1349951246.eu'),'quarantine','domain_check get_info(exist_reason)');
$d=$dri->get_info('availableDate','domain','some-domain-info-1349951246.eu');
isa_ok($d,'DateTime','domain_check get_info(availableDate)');
is(''.$d,'2014-10-23T13:52:13','domain_check get_info(availableDate) value');
is($dri->get_info('exist','domain','andalucia.eu'),1,'domain_check get_info(exist)');
is($dri->get_info('exist_reason','domain','andalucia.eu'),'reserved','domain_check get_info(exist_reason)');
is($dri->get_info('exist','domain','andalucía.eu'),1,'domain_check get_info(exist)');
is($dri->get_info('exist_reason','domain','andalucía.eu'),'reserved','domain_check get_info(exist_reason)');
is($dri->get_info('name_ace','domain','andalucía.eu'),'xn--andaluca-i2a.eu','domain_check get_info(name_ace)');
is($dri->get_info('ace','domain','andalucía.eu'),'xn--andaluca-i2a.eu','domain_check get_info(ace)');
is($dri->get_info('exist','domain','agias.eu'),1,'domain_check get_info(exist)');
is($dri->get_info('exist_reason','domain','agias.eu'),'blocked','domain_check get_info(exist_reason)');
is($dri->get_info('exist','domain','rey-españa.eu'),1,'domain_check get_info(exist)');
is($dri->get_info('exist_reason','domain','rey-españa.eu'),'blocked','domain_check get_info(exist_reason)');
is($dri->get_info('exist','domain','20karat.eu'),1,'domain_check get_info(exist)');
is($dri->get_info('exist_reason','domain','20karat.eu'),'in use','domain_check get_info(exist_reason)');
is($dri->get_info('exist','domain','crédit-suisse.eu'),1,'domain_check get_info(exist)');
is($dri->get_info('exist_reason','domain','crédit-suisse.eu'),'in use','domain_check get_info(exist_reason)');
is($dri->get_info('exist','domain','bandit-corp.eu'),1,'domain_check get_info(exist)');
is($dri->get_info('exist_reason','domain','bandit-corp.eu'),'suspended','domain_check get_info(exist_reason)');
is($dri->get_info('exist','domain','court-order-seized.eu'),1,'domain_check get_info(exist)');
is($dri->get_info('exist_reason','domain','court-order-seized.eu'),'seized','domain_check get_info(exist_reason)');

## 2.1.09/domains/domain-check/domain-check02-resp.xml
# Querying the availability of a locked domain name
$R2=$E1.'<response>'.r().'<resData><domain:chkData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:cd><domain:name avail="false">europa.eu</domain:name><domain:reason lang="en">in use</domain:reason></domain:cd></domain:chkData></resData><extension><domain-ext:chkData xmlns:domain-ext="http://www.eurid.eu/xml/epp/domain-ext-2.4"><domain-ext:domain><domain-ext:name>europa.eu</domain-ext:name><domain-ext:status s="serverTransferProhibited"/></domain-ext:domain></domain-ext:chkData></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_check('europa.eu');
is_string($R1,'<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd"><command><check><domain:check xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>europa.eu</domain:name></domain:check></check><clTRID>ABC-12345</clTRID></command></epp>','domain_check build');
is($rc->is_success(),1,'domain_check is_success');
$s=$dri->get_info('status');
isa_ok($s,'Net::DRI::Data::StatusList','domain_check get_info(status)');
is_deeply([$s->list_status()],['serverTransferProhibited'],'domain_check get_info(status) list');

## 2.2.1/domains/domain-check/domain-check03-resp.xml
# homoglyphs!
$dri->cache_clear();
$R2=$E1.'<response>'.r().'<resData><domain:chkData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:cd><domain:name avail="false">123.ею</domain:name><domain:reason lang="en">homoglyph blocked</domain:reason></domain:cd><domain:cd><domain:name avail="false">xn--80aicaztaaflfnmi8azba8ddf.xn--e1a4c</domain:name><domain:reason lang="en">suspended on hold</domain:reason></domain:cd></domain:chkData></resData><extension xmlns:homoglyph="http://www.eurid.eu/xml/epp/homoglyph-1.0" xmlns:idn="http://www.eurid.eu/xml/epp/idn-1.0"><idn:mapping><idn:name><idn:ace>123.xn--e1a4c</idn:ace><idn:unicode>123.ею</idn:unicode></idn:name><idn:name><idn:ace>xn--80aicaztaaflfnmi8azba8ddf.xn--e1a4c</idn:ace><idn:unicode>аырхеытсеччыкодпннтн.ею</idn:unicode></idn:name></idn:mapping><homoglyph:chkData><homoglyph:domain><homoglyph:name>123.ею</homoglyph:name><homoglyph:blockedBy>123.eu</homoglyph:blockedBy></homoglyph:domain></homoglyph:chkData></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_check('123.xn--e1a4c','xn--80aicaztaaflfnmi8azba8ddf.xn--e1a4c');
is_string($R1,'<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd"><command><check><domain:check xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>123.xn--e1a4c</domain:name><domain:name>xn--80aicaztaaflfnmi8azba8ddf.xn--e1a4c</domain:name></domain:check></check><clTRID>ABC-12345</clTRID></command></epp>','domain_check build');
is($rc->is_success(),1,'domain_check is_success');
is($dri->get_info('exist', 'domain', 'xn--80aicaztaaflfnmi8azba8ddf.xn--e1a4c'),1,'domain_check get_info(exist)');
is($dri->get_info('exist_reason','domain','xn--80aicaztaaflfnmi8azba8ddf.xn--e1a4c'),'suspended on hold','domain_check get_info(exist_reason)');
is($dri->get_info('exist', 'domain', '123.ею'),1,'domain_check get_info(exist)');
is($dri->get_info('exist_reason','domain','123.ею'),'homoglyph blocked','domain_check get_info(exist_reason)');
is($dri->get_info('blocked_by','domain','123.ею'),'123.eu','domain_check get_info(blocked by)'); # homoglyph

########################################################################################################
### DOMAIN_INFO

## 2.1.09/domains/domain-info/domain-info01-resp.xml
# Status in use and not locked/1 onsite & 1 tech contact/2 name servers with glues (IPv4 and IPv6)/no DNSSEC
$R2=$E1.'<response>'.r().'<resData><domain:infData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>domain-0006.eu</domain:name><domain:roid>domain_0006_eu-EURID</domain:roid><domain:status s="ok" /><domain:registrant>c160</domain:registrant><domain:contact type="billing">c10</domain:contact><domain:contact type="tech">c159</domain:contact><domain:ns><domain:hostAttr><domain:hostName>ns1.domain-0006.eu</domain:hostName><domain:hostAddr ip="v6">2001:db8:85a3:0:0:8a2e:370:7333</domain:hostAddr><domain:hostAddr ip="v4">192.11.11.11</domain:hostAddr></domain:hostAttr><domain:hostAttr><domain:hostName>ns1.other-domain.pt</domain:hostName></domain:hostAttr></domain:ns><domain:clID>a987654</domain:clID><domain:crID>a987654</domain:crID><domain:crDate>2014-09-13T15:57:54.223Z</domain:crDate><domain:upID>a987654</domain:upID><domain:upDate>2014-09-13T15:57:54.000Z</domain:upDate><domain:exDate>2015-09-13T21:59:59.999Z</domain:exDate></domain:infData></resData><extension><domain-ext:infData xmlns:domain-ext="http://www.eurid.eu/xml/epp/domain-ext-2.4"><domain-ext:onHold>false</domain-ext:onHold><domain-ext:quarantined>false</domain-ext:quarantined><domain-ext:suspended>false</domain-ext:suspended><domain-ext:seized>false</domain-ext:seized><domain-ext:contact type="onsite">c163</domain-ext:contact></domain-ext:infData></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_info('domain-0006.eu');
is_string($R1,'<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd"><command><info><domain:info xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>domain-0006.eu</domain:name></domain:info></info><clTRID>ABC-12345</clTRID></command></epp>','domain_info build');
is($rc->is_success(),1,'domain_info is_success');
is($dri->get_info('exist'),1,'domain_info get_info(exist)');
is($dri->get_info('roid'),'domain_0006_eu-EURID','domain_info get_info(roid)');
$s=$dri->get_info('status');
isa_ok($s,'Net::DRI::Data::StatusList','domain_info get_info(status)');
is_deeply([$s->list_status()],['ok'],'domain_info get_info(status) list');
is($s->is_active(),1,'domain_info get_info(status) is_active');
$s=$dri->get_info('contact');
isa_ok($s,'Net::DRI::Data::ContactSet','domain_info get_info(contact)');
is_deeply([$s->types()],['billing','onsite','registrant','tech'],'domain_info get_info(contact) types');
is($s->get('registrant')->srid(),'c160','domain_info get_info(contact) registrant srid');
is($s->get('billing')->srid(),'c10','domain_info get_info(contact) billing srid');
is($s->get('tech')->srid(),'c159','domain_info get_info(contact) tech srid');
is($s->get('onsite')->srid(),'c163','domain_info get_info(contact) tech srid');
$dh=$dri->get_info('ns');
isa_ok($dh,'Net::DRI::Data::Hosts','domain_info get_info(ns)');
@c=$dh->get_names();
is_deeply(\@c,['ns1.domain-0006.eu','ns1.other-domain.pt'],'domain_info get_info(ns) get_names');
@d=$dh->get_details(1);
is_deeply(\@d,['ns1.domain-0006.eu',['192.11.11.11'],['2001:db8:85a3:0:0:8a2e:370:7333'],undef],'domain_info get_info(ns) get_names');
is($dri->get_info('clID'),'a987654','domain_info get_info(clID)');
is($dri->get_info('crID'),'a987654','domain_info get_info(crID)');
$d=$dri->get_info('crDate');
isa_ok($d,'DateTime','domain_info get_info(crDate)');
is(''.$d,'2014-09-13T15:57:54','domain_info get_info(crDate) value');
is($dri->get_info('upID'),'a987654','domain_info get_info(upID)');
$d=$dri->get_info('upDate');
isa_ok($d,'DateTime','domain_info get_info(upDate)');
is(''.$d,'2014-09-13T15:57:54','domain_info get_info(upDate) value');
$d=$dri->get_info('exDate');
isa_ok($d,'DateTime','domain_info get_info(exDate)');
is(''.$d,'2015-09-13T21:59:59','domain_info get_info(exDate) value');

## 2.1.09/domains/domain-info/domain-info02-cmd.xml
# Example with request for authcode: status in use and not locked/1 tech contact and no onsite contact/no DNS and no DNSSSEC Status in use and not locked/1 onsite & 1 tech contact/2 name servers with glues (IPv4 and IPv6)/no DNSSEC
# Response edited, checking received authInfo
$R2=$E1.'<response>'.r().'<resData><domain:infData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>domain-0007.eu</domain:name><domain:authInfo><domain:pw>XXXX-2MRN-MRAP-MXVR</domain:pw></domain:authInfo></domain:infData></resData><extension><authInfo:infData xmlns:authInfo="http://www.eurid.eu/xml/epp/authInfo-1.1"><authInfo:validUntil>2017-04-02T17:04:14.000Z</authInfo:validUntil></authInfo:infData></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_info('domain-0007.eu',{authinfo_request => 1});
is_string($R1,'<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd"><command><info><domain:info xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>domain-0007.eu</domain:name></domain:info></info><extension><authInfo:info xmlns:authInfo="http://www.eurid.eu/xml/epp/authInfo-1.1" xsi:schemaLocation="http://www.eurid.eu/xml/epp/authInfo-1.1 authInfo-1.1.xsd"><authInfo:request/></authInfo:info></extension><clTRID>ABC-12345</clTRID></command></epp>','domain_info build');
is($rc->is_success(),1,'domain_info is_success');
is_deeply($dri->get_info('auth'),{'pw' => 'XXXX-2MRN-MRAP-MXVR'},'domain_info get_info(authInfo) value');
is_deeply($dri->get_info('auth_valid_until'),'2017-04-02T17:04:14','domain_info get_info(authInfo) value');

## Since April 26 2017, we can cancel authinfo too
$rc=$dri->domain_info('domain-0007c.eu',{authinfo_cancel => 1});
is_string($R1,'<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd"><command><info><domain:info xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>domain-0007c.eu</domain:name></domain:info></info><extension><authInfo:info xmlns:authInfo="http://www.eurid.eu/xml/epp/authInfo-1.1" xsi:schemaLocation="http://www.eurid.eu/xml/epp/authInfo-1.1 authInfo-1.1.xsd"><authInfo:cancel/></authInfo:info></extension><clTRID>ABC-12345</clTRID></command></epp>','domain_info build');

## 2.1.09/domains/domain-info/domain-info04-cmd.xml
# Status in use and not locked/in other registrar's portfolio and using authcode on request/2 onsite contacts and no tech contacts/2 name servers with no glue/no DNSSEC
# Response edited, checking building and received clid
$dri->cache_clear();
$R2=$E1.'<response>'.r().'<resData><domain:infData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>domain-0007.eu</domain:name><domain:roid>domain_0007_eu-EURID</domain:roid><domain:status s="ok"/><domain:registrant>c160</domain:registrant><domain:clID>#non-disclosed#</domain:clID></domain:infData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_info('domain-0007.eu',{auth => {'pw' => 'XXXX-2MRN-MRAP-MXVR'}});
is_string($R1,'<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd"><command><info><domain:info xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>domain-0007.eu</domain:name><domain:authInfo><domain:pw>XXXX-2MRN-MRAP-MXVR</domain:pw></domain:authInfo></domain:info></info><clTRID>ABC-12345</clTRID></command></epp>','domain_info build');
is($rc->is_success(),1,'domain_info is_success');
is($dri->get_info('clID'),'#non-disclosed#','domain_info get_info(clID)');


## 2.1.09/domains/domain-info/domain-info05-resp.xml
# Status in quarantine/IDN Latin/1 tech & 1 onsite contact/1 name server and no glue/1 DNSSEC key
# Response edited, checking status and dnssec
# I have enabled force_native_idn in the DRD, so checking name_ace and name_idn too
# -- on top of that we will also check the old school implementation from eurids IDN implementation
# 2.2.1 (domain-ext-2.4) adds delayed emlement which i have monkeyed into this response

$R2=$E1.'<response>'.r().'<resData><domain:infData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>domínio-qq.eu</domain:name><domain:roid>xn__domnio_qq_i5a_eu-EURID</domain:roid><domain:status s="ok"/><domain:registrant>c160</domain:registrant></domain:infData></resData><extension><domain-ext:infData xmlns:domain-ext="http://www.eurid.eu/xml/epp/domain-ext-2.4"><domain-ext:onHold>false</domain-ext:onHold><domain-ext:quarantined>true</domain-ext:quarantined><domain-ext:suspended>false</domain-ext:suspended><domain-ext:seized>false</domain-ext:seized><domain-ext:availableDate>2014-10-23T16:11:55.109Z</domain-ext:availableDate><domain-ext:deletionDate>2014-09-13T16:11:55.109Z</domain-ext:deletionDate><domain-ext:contact type="onsite">c163</domain-ext:contact><domain-ext:delayed>true</domain-ext:delayed></domain-ext:infData><secDNS:infData xmlns:secDNS="urn:ietf:params:xml:ns:secDNS-1.1"><secDNS:keyData><secDNS:flags>257</secDNS:flags><secDNS:protocol>3</secDNS:protocol><secDNS:alg>5</secDNS:alg><secDNS:pubKey>AwEAAc8mj6eqspwxX/E+OVoA/+MTawDce72K8UOgFmDAvilVqWKsXv9a6HQVPW/feDGHQ3cvGAisb1tv4/DFJBqWniLVr77S20JhhpB+MtuJkKSmb59basCItUo/B9MohZ4hFWsgWtL8HnIuJq1jMwXzmAO236EsUjXVzAdxhqsVX7v1</secDNS:pubKey></secDNS:keyData></secDNS:infData><idn:mapping xmlns:idn="http://www.eurid.eu/xml/epp/idn-1.0"><idn:name><idn:ace>xn--domnio-qq-i5a.eu</idn:ace><idn:unicode>domínio-qq.eu</idn:unicode></idn:name></idn:mapping></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_info('domínio-qq.eu',{auth => {'pw' => 'XXXX-2MRN-MRAP-MXVR'}});
is_string($R1,'<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd"><command><info><domain:info xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>domínio-qq.eu</domain:name><domain:authInfo><domain:pw>XXXX-2MRN-MRAP-MXVR</domain:pw></domain:authInfo></domain:info></info><clTRID>ABC-12345</clTRID></command></epp>','domain_info build');
is($rc->is_success(),1,'domain_info is_success');
is($dri->get_info('name'), 'domínio-qq.eu', 'domain get_info(name)');
is($dri->get_info('name_ace'), 'xn--domnio-qq-i5a.eu', 'domain get_info(name_ace)');
is($dri->get_info('name_idn'), 'domínio-qq.eu', 'domain get_info(name_idn)');
is($dri->get_info('ace'), 'xn--domnio-qq-i5a.eu', 'domain get_info(name_ace)');
is($dri->get_info('unicode'), 'domínio-qq.eu', 'domain get_info(name_idn)');
$s=$dri->get_info('status');
isa_ok($s,'Net::DRI::Data::StatusList','domain_info get_info(status)');
is_deeply([$s->list_status()],['delayed','ok','quarantined'],'domain_info get_info(status) list');
is($s->is_active(),1,'domain_info get_info(status) is_active'); # hmm, this shout probably not be active? but lets not break old implementation [yet?]
$e=$dri->get_info('secdns');
is_deeply($e,[{key_flags=>'257',key_protocol=>3,key_alg=>5,key_pubKey=>'AwEAAc8mj6eqspwxX/E+OVoA/+MTawDce72K8UOgFmDAvilVqWKsXv9a6HQVPW/feDGHQ3cvGAisb1tv4/DFJBqWniLVr77S20JhhpB+MtuJkKSmb59basCItUo/B9MohZ4hFWsgWtL8HnIuJq1jMwXzmAO236EsUjXVzAdxhqsVX7v1'}],'domain_info get_info(secdns)');
$d=$dri->get_info('availableDate');
isa_ok($d,'DateTime','domain_info get_info(availableDate)');
is(''.$d,'2014-10-23T16:11:55','domain_info get_info(availableDate) value');
$d=$dri->get_info('deletionDate');
isa_ok($d,'DateTime','domain_info get_info(deletionDate)');
is(''.$d,'2014-09-13T16:11:55','domain_info get_info(deletionDate) value');
is($dri->get_info('delayed'), 'true', 'domain get_info(delayed)');
is($dri->get_info('quarantined'), 'true', 'domain get_info(quarantined)');
is($dri->get_info('onHold'), 'false', 'domain get_info(onHold)');

## 2.1.09/domains/domain-info/domain-info06-cmd.xml
# Domain name in own portfolio with a deletion date, nsgroup and 1 keygroup
# Response edited, checking nsgroup and keygroup only
$R2=$E1.'<response>'.r().'<resData><domain:infData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>nomen-hawg3nwn.eu</domain:name><domain:roid>nomen_hawg3nwn_eu-EURID</domain:roid><domain:status s="ok"/><domain:registrant>c160</domain:registrant></domain:infData></resData><extension><domain-ext:infData xmlns:domain-ext="http://www.eurid.eu/xml/epp/domain-ext-2.4"><domain-ext:onHold>false</domain-ext:onHold><domain-ext:quarantined>false</domain-ext:quarantined><domain-ext:suspended>false</domain-ext:suspended><domain-ext:seized>false</domain-ext:seized><domain-ext:deletionDate>2015-01-01T00:00:00.000Z</domain-ext:deletionDate><domain-ext:contact type="onsite">c163</domain-ext:contact><domain-ext:nsgroup>nsg-a-1349684934</domain-ext:nsgroup><domain-ext:keygroup>keygroup-1350898304165</domain-ext:keygroup></domain-ext:infData></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_info('nomen-hawg3nwn.eu',{auth => {'pw' => 'XXXX-2MRN-MRAP-MXVR'}});
is_string($R1,'<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd"><command><info><domain:info xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>nomen-hawg3nwn.eu</domain:name><domain:authInfo><domain:pw>XXXX-2MRN-MRAP-MXVR</domain:pw></domain:authInfo></domain:info></info><clTRID>ABC-12345</clTRID></command></epp>','domain_info build');
is($rc->is_success(),1,'domain_info is_success');
is($dri->get_info('name'), 'nomen-hawg3nwn.eu', 'domain get_info(name)');
#is($dri->get_info('nsgroup'), 'nsg-a-1349684934', 'domain get_info(name)');
$dh=$dri->get_info('nsgroup');
isa_ok($dh->[0],'Net::DRI::Data::Hosts','domain_info get_info(nsgroup)');
is($dri->get_info('keygroup'), 'keygroup-1350898304165', 'domain_info get_info(name)');


# <domain:info> with registrantCountry and maxExtensionPeriod
$R2=$E1.'<response>'.r().'<resData><domain:infData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>20190315-test001.eu</domain:name><domain:roid>foobar-EURID</domain:roid><domain:status s="ok"/><domain:registrant>c160</domain:registrant></domain:infData></resData><extension><domain-ext:infData xmlns:domain-ext="http://www.eurid.eu/xml/epp/domain-ext-2.4"><domain-ext:onHold>false</domain-ext:onHold><domain-ext:quarantined>true</domain-ext:quarantined><domain-ext:suspended>false</domain-ext:suspended><domain-ext:seized>false</domain-ext:seized><domain-ext:availableDate>2014-10-23T16:11:55.109Z</domain-ext:availableDate><domain-ext:deletionDate>2014-09-13T16:11:55.109Z</domain-ext:deletionDate><domain-ext:contact type="onsite">c163</domain-ext:contact><domain-ext:delayed>true</domain-ext:delayed><domain-ext:onHold>false</domain-ext:onHold><domain-ext:quarantined>false</domain-ext:quarantined><domain-ext:suspended>false</domain-ext:suspended><domain-ext:seized>false</domain-ext:seized><domain-ext:delayed>false</domain-ext:delayed><domain-ext:maxExtensionPeriod>9</domain-ext:maxExtensionPeriod><domain-ext:registrantCountry>PT</domain-ext:registrantCountry><domain-ext:registrantCountryOfCitizenship>PT</domain-ext:registrantCountryOfCitizenship></domain-ext:infData></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_info('20190315-test001.eu');
is_string($R1,'<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd"><command><info><domain:info xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>20190315-test001.eu</domain:name></domain:info></info><clTRID>ABC-12345</clTRID></command></epp>','domain_info build');
is($rc->is_success(),1,'domain_info is_success');
is_deeply($dri->get_info('maxExtensionPeriod'),'9','domain_info get_info(maxExtensionPeriod) value');
is_deeply($dri->get_info('registrantCountry'),'PT','domain_info get_info(registrantCountry) value');
is_deeply($dri->get_info('registrantCountryOfCitizenship'),'PT','domain_info get_info(registrantCountryOfCitizenship) value');

########################################################################################################
### DOMAIN_CREATE

## 2.1.09/domains/domain-create/domain-create02-cmd.xml
# Domain create with IDN, 2 name servers, 1 onsite and a reseller contact
$R2=$E1.'<response>'.r().'<resData><domain:creData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>domínio-0002.eu</domain:name><domain:crDate>2014-09-13T13:15:17.075Z</domain:crDate><domain:exDate>2015-09-13T21:59:59.999Z</domain:exDate></domain:creData></resData><extension><idn:mapping xmlns:idn="http://www.eurid.eu/xml/epp/idn-1.0"><idn:name><idn:ace>xn--domnio-0002-qcb.eu</idn:ace><idn:unicode>domínio-0002.eu</idn:unicode></idn:name></idn:mapping></extension>'.$TRID.'</response>'.$E2;
$cs=$dri->local_object('contactset');
$cs->set($dri->local_object('contact')->srid('c113'),'registrant');
$cs->set($dri->local_object('contact')->srid('c10'),'billing');
$cs->set($dri->local_object('contact')->srid('c163'),'onsite');
$cs->set($dri->local_object('contact')->srid('c164'),'reseller');
$dh=$dri->local_object('hosts');
$dh->add('a.alpha.al');
$dh->add('b.bravo.bb');
$rc=$dri->domain_create('domínio-0002.eu',{pure_create=>1,contact=>$cs,ns=>$dh});
is_string($R1,'<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd"><command><create><domain:create xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>domínio-0002.eu</domain:name><domain:ns><domain:hostAttr><domain:hostName>a.alpha.al</domain:hostName></domain:hostAttr><domain:hostAttr><domain:hostName>b.bravo.bb</domain:hostName></domain:hostAttr></domain:ns><domain:registrant>c113</domain:registrant><domain:contact type="billing">c10</domain:contact><domain:authInfo><domain:pw/></domain:authInfo></domain:create></create><extension><domain-ext:create xmlns:domain-ext="http://www.eurid.eu/xml/epp/domain-ext-2.4" xsi:schemaLocation="http://www.eurid.eu/xml/epp/domain-ext-2.4 domain-ext-2.4.xsd"><domain-ext:contact type="onsite">c163</domain-ext:contact><domain-ext:contact type="reseller">c164</domain-ext:contact></domain-ext:create></extension><clTRID>ABC-12345</clTRID></command></epp>','domain_create build');
is($rc->is_success(),1,'domain_create is_success');
is($dri->get_info('name'),'domínio-0002.eu','domain_create get_info(name)');
is($dri->get_info('name_idn'),'domínio-0002.eu','domain_create get_info(name_idn)');
is($dri->get_info('name_ace'),'xn--domnio-0002-qcb.eu','domain_create get_info(name_ace)');
is($dri->get_info('unicode'),'domínio-0002.eu','domain_create get_info(unicode)');
is($dri->get_info('ace'),'xn--domnio-0002-qcb.eu','domain_create get_info(ace)');
is($dri->get_info('crDate'),'2014-09-13T13:15:17','domain_create get_info(crDate)');
is($dri->get_info('exDate'),'2015-09-13T21:59:59','domain_create get_info(exDate)');

## 2.1.09/domains/domain-create/domain-create03-cmd.xml
# Domain create with 2 name servers with glue (IPv4 and IPv6), 2 name server groups, 1 tech and 1 onsite contact and for a period of 3 years
$R2=$E1.'<response>'.r().'<resData><domain:creData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>domaine-0004.eu</domain:name><domain:crDate>2014-09-13T13:15:17.075Z</domain:crDate><domain:exDate>2015-09-13T21:59:59.999Z</domain:exDate></domain:creData></resData>'.$TRID.'</response>'.$E2;
$cs=$dri->local_object('contactset');
$cs->set($dri->local_object('contact')->srid('c160'),'registrant');
$cs->set($dri->local_object('contact')->srid('c10'),'billing');
$cs->set($dri->local_object('contact')->srid('c159'),'tech');
$cs->set($dri->local_object('contact')->srid('c163'),'onsite');
$dh=$dri->local_object('hosts');
$dh->add('a.domaine-0004.eu',['123.45.67.8']);
$dh->add('b.domaine-0004.eu',[],['2001:da8:85a3:0:0:8a2e:371:7333']);
my $dh2=$dri->local_object('hosts')->name('nsg-a-1349684934');
my $dh3=$dri->local_object('hosts')->name('nsg-b-1349684934');
$rc=$dri->domain_create('domaine-0004.eu',{pure_create=>1,contact=>$cs,ns=>$dh});
is_string($R1,'<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd"><command><create><domain:create xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>domaine-0004.eu</domain:name><domain:ns><domain:hostAttr><domain:hostName>a.domaine-0004.eu</domain:hostName><domain:hostAddr ip="v4">123.45.67.8</domain:hostAddr></domain:hostAttr><domain:hostAttr><domain:hostName>b.domaine-0004.eu</domain:hostName><domain:hostAddr ip="v6">2001:da8:85a3:0:0:8a2e:371:7333</domain:hostAddr></domain:hostAttr></domain:ns><domain:registrant>c160</domain:registrant><domain:contact type="billing">c10</domain:contact><domain:contact type="tech">c159</domain:contact><domain:authInfo><domain:pw/></domain:authInfo></domain:create></create><extension><domain-ext:create xmlns:domain-ext="http://www.eurid.eu/xml/epp/domain-ext-2.4" xsi:schemaLocation="http://www.eurid.eu/xml/epp/domain-ext-2.4 domain-ext-2.4.xsd"><domain-ext:contact type="onsite">c163</domain-ext:contact></domain-ext:create></extension><clTRID>ABC-12345</clTRID></command></epp>','domain_create build');
is($rc->is_success(),1,'domain_create is_success');
is($dri->get_info('name'),'domaine-0004.eu','domain_create get_info(name)');
is($dri->get_info('crDate'),'2014-09-13T13:15:17','domain_create get_info(crDate)');
is($dri->get_info('exDate'),'2015-09-13T21:59:59','domain_create get_info(exDate)');

## 2.1.09/domains/domain-create/domain-create04-cmd.xml
# Domain create with 1 tech contact, 1 name server (1 glue IPv4), DNSSEC with 2 keys (KSK, ZSK) and for a period of 1 year
# See SecDNS

# Domain create Greek TLD extension
$R2='';
$cs=$dri->local_object('contactset');
$cs->set($dri->local_object('contact')->srid('z789'),'registrant');
$cs->set($dri->local_object('contact')->srid('z345'),'billing');
$cs->set($dri->local_object('contact')->srid('z123'),'tech');
$rc=$dri->domain_create('xn--mxafcslcjjd9a.xn--qxa6a',{pure_create=>1,contact=>$cs,auth=>{pw=>'foobar'}});
is_string($R1,'<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd"><command><create><domain:create xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>σομεδομαιν.ευ</domain:name><domain:registrant>z789</domain:registrant><domain:contact type="billing">z345</domain:contact><domain:contact type="tech">z123</domain:contact><domain:authInfo><domain:pw>foobar</domain:pw></domain:authInfo></domain:create></create><clTRID>ABC-12345</clTRID></command></epp>','domain_create Greek TLD extension build');
is($rc->is_success(),1,'domain_create (Greek TLD extension) is_success');

########################################################################################################
### DOMAIN_UPDATE

## 2.1.09/domains/domain-update/domain_update01 && 02-cmd.xml
# Add and remove tech contact, add and remove onsite contact, add reseller contact, change registrant
# Change NSGroup (KeyGroup not supported)
# Only checking onsite/reseller
$R2=$E1.'<response>'.r().''.$TRID.'</response>'.$E2;
$toc=$dri->local_object('changes');
my $cs1 = $dri->local_object('contactset');
my $cs2 = $dri->local_object('contactset');
$cs1->set($dri->local_object('contact')->srid('c165'),'onsite');
$cs1->set($dri->local_object('contact')->srid('c164'),'reseller');
$cs2->set($dri->local_object('contact')->srid('c163'),'onsite');
$toc->add('contact',$cs1);
$toc->del('contact',$cs2);
$toc->add('nsgroup', $dri->local_object('hosts')->name('nsg-b-1349684934'));
$toc->del('nsgroup', $dri->local_object('hosts')->name('nsg-a-1349684934'));
# $toc->add('keygroup','keygroup-1350898304275'); FIXME, not supported yet in KeyGroup
# $toc->del('keygroup','keygroup-1350898304165'); FIXME, not supported yet in KeyGroup
$rc=$dri->domain_update('testmldomupd-14092012001-01.eu',$toc);
is_string($R1,'<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd"><command><update><domain:update xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>testmldomupd-14092012001-01.eu</domain:name></domain:update></update><extension><domain-ext:update xmlns:domain-ext="http://www.eurid.eu/xml/epp/domain-ext-2.4" xsi:schemaLocation="http://www.eurid.eu/xml/epp/domain-ext-2.4 domain-ext-2.4.xsd"><domain-ext:add><domain-ext:nsgroup>nsg-b-1349684934</domain-ext:nsgroup><domain-ext:contact type="onsite">c165</domain-ext:contact><domain-ext:contact type="reseller">c164</domain-ext:contact></domain-ext:add><domain-ext:rem><domain-ext:nsgroup>nsg-a-1349684934</domain-ext:nsgroup><domain-ext:contact type="onsite">c163</domain-ext:contact></domain-ext:rem></domain-ext:update></extension><clTRID>ABC-12345</clTRID></command></epp>','domain_update build');
# ADD <domain-ext:keygroup>keygroup-1350898304275</domain-ext:keygroup>
is($rc->is_success(),1,'domain_update 1 is_success');

## The rest are all standard EPP / SecDNS

########################################################################################################
### DOMAIN_RENEW

## 2.1.09/domains/domain-renew/domain-renew02-resp.xml && 2.1.09/domains/domain-renew/domain-renew04-resp.xml
# Extend domain for 8y deletion date is removed && Extend the term of an IDN
$R2=$E1.'<response>'.r().'<resData><domain:renData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>extend-term2y-idn-café-1349786342.eu</domain:name><domain:exDate>2023-09-13T21:59:59.999Z</domain:exDate></domain:renData></resData><extension><domain-ext:renData xmlns:domain-ext="http://www.eurid.eu/xml/epp/domain-ext-2.4"><domain-ext:removedDeletionDate/></domain-ext:renData><idn:mapping xmlns:idn="http://www.eurid.eu/xml/epp/idn-1.0"><idn:name><idn:ace>xn--extend-term2y-idn-caf-1349786342-v3c.eu</idn:ace><idn:unicode>extend-term2y-idn-café-1349786342.eu</idn:unicode></idn:name></idn:mapping></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_renew('extend-term2y-idn-café-1349786342.eu',{duration => $dri->local_object('duration',years=>8), current_expiration => $dri->local_object('datetime',year=>2015,month=>9,day=>13)});
is($rc->is_success(),1,'domain_renew is_success');
is($dri->get_info('exDate'),'2023-09-13T21:59:59','domain_renew get_info(exDate)');
is($dri->get_info('removedDeletionDate'),1,'domain_renew get_info(removedDeletionDate)');
is($dri->get_info('name'),'extend-term2y-idn-café-1349786342.eu','domain_renew get_info(name)');
is($dri->get_info('ace'),'xn--extend-term2y-idn-caf-1349786342-v3c.eu','domain_renew get_info(ace)');
is($dri->get_info('unicode'),'extend-term2y-idn-café-1349786342.eu','domain_renew get_info(unicde)');
is($dri->get_info('name_ace'),'xn--extend-term2y-idn-caf-1349786342-v3c.eu','domain_renew get_info(name_ace)');
is($dri->get_info('name_idn'),'extend-term2y-idn-café-1349786342.eu','domain_renew  get_info(name_idn)');


## 2.1.09/domains/domain-renew/domain-renew05-cmd.xml
# Extend term for 4y a quarantined domain (reactivate)
## Note, reactive was removed a long time ago, its just a renewal now

########################################################################################################
### DOMAIN_DELETE

## 2.1.09/domains/domain-delete/domain-delete01-cmd.xml
# Delete domain with a deletion date
$R2=$E1.'<response>'.r().''.$TRID.'</response>'.$E2;
$rc=$dri->domain_delete('testdelete-1349683848.eu',{pure_delete=>1,deleteDate=>DateTime->new(year=>2015,month=>1,day=>1,hour=>0,minute=>0,second=>0)});
is_string($R1,'<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd"><command><delete><domain:delete xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>testdelete-1349683848.eu</domain:name></domain:delete></delete><extension><domain-ext:delete xmlns:domain-ext="http://www.eurid.eu/xml/epp/domain-ext-2.4" xsi:schemaLocation="http://www.eurid.eu/xml/epp/domain-ext-2.4 domain-ext-2.4.xsd"><domain-ext:schedule><domain-ext:delDate>2015-01-01T00:00:00.000000000Z</domain-ext:delDate></domain-ext:schedule></domain-ext:delete></extension><clTRID>ABC-12345</clTRID></command></epp>','domain_delete (exDate) build');
is($rc->is_success(),1,'domain_delete is_success');

## 2.1.09/domains/domain-delete/domain-delete02-cmd.xml
# Delete domain immediately
$R2=$E1.'<response>'.r().''.$TRID.'</response>'.$E2;
$rc=$dri->domain_delete('testdelete-1349683850.eu',{pure_delete=>1});
is_string($R1,'<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd"><command><delete><domain:delete xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>testdelete-1349683850.eu</domain:name></domain:delete></delete><clTRID>ABC-12345</clTRID></command></epp>','domain_delete (exDate) build');
is($rc->is_success(),1,'domain_delete is_success');

## 2.1.09/domains/domain-delete/domain-undelete01-cmd.xml
# Cancel scheduled deletion
$R2=$E1.'<response>'.r().''.$TRID.'</response>'.$E2;
$rc=$dri->domain_delete('testdelete-1349683848.eu',{pure_delete=>1,cancel=>1});
is_string($R1,'<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd"><command><delete><domain:delete xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>testdelete-1349683848.eu</domain:name></domain:delete></delete><extension><domain-ext:delete xmlns:domain-ext="http://www.eurid.eu/xml/epp/domain-ext-2.4" xsi:schemaLocation="http://www.eurid.eu/xml/epp/domain-ext-2.4 domain-ext-2.4.xsd"><domain-ext:cancel/></domain-ext:delete></extension><clTRID>ABC-12345</clTRID></command></epp>','domain_delete (exDate) build');
is($rc->is_success(),1,'domain_delete is_success');

########################################################################################################
### DOMAIN_TRANSFER

## 2.1.09/domains/domain-transfer/domain-transfer01 && 03-cmd.xml
# Transfer of domain, new registrant, period tag added, 1 tech & 1 onsite contact

$R2=$E1.'<response>'.r().''.$TRID.'</response>'.$E2;
my %rd;
$cs=$dri->local_object('contactset');
$cs->set($dri->local_object('contact')->srid('c160'),'registrant');
$cs->set($dri->local_object('contact')->srid('c10'),'billing');
$cs->set($dri->local_object('contact')->srid('c163'),'onsite');
$cs->set($dri->local_object('contact')->srid('c164'),'reseller');
$dh=$dri->local_object('hosts');
$dh->add('ns1.quarantine-domain-for-transfer.eu',['123.45.67.8']);
$dh->add('ns2.quarantine-domain-for-transfer.eu',[],['2001:0db8:85a3::7344']);
$rd{auth}={pw=>'XXXX-3ZHA-6FVM-6CLK'};
$rd{contact}=$cs;
$rd{ns}=$dh;
$rd{nsgroup}=$dri->local_object('hosts')->name('some-group');
$rc=$dri->domain_transfer_start('quarantine-domain-for-transfer.eu',\%rd);
is_string($R1,'<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd"><command><transfer op="request"><domain:transfer xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>quarantine-domain-for-transfer.eu</domain:name><domain:authInfo><domain:pw>XXXX-3ZHA-6FVM-6CLK</domain:pw></domain:authInfo></domain:transfer></transfer><extension><domain-ext:transfer xmlns:domain-ext="http://www.eurid.eu/xml/epp/domain-ext-2.4" xsi:schemaLocation="http://www.eurid.eu/xml/epp/domain-ext-2.4 domain-ext-2.4.xsd" xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain-ext:request><domain-ext:registrant>c160</domain-ext:registrant><domain-ext:contact type="billing">c10</domain-ext:contact><domain-ext:contact type="onsite">c163</domain-ext:contact><domain-ext:contact type="reseller">c164</domain-ext:contact><domain-ext:ns><domain:hostAttr><domain:hostName>ns1.quarantine-domain-for-transfer.eu</domain:hostName><domain:hostAddr ip="v4">123.45.67.8</domain:hostAddr></domain:hostAttr><domain:hostAttr><domain:hostName>ns2.quarantine-domain-for-transfer.eu</domain:hostName><domain:hostAddr ip="v6">2001:0db8:85a3::7344</domain:hostAddr></domain:hostAttr></domain-ext:ns><domain-ext:nsgroup>some-group</domain-ext:nsgroup></domain-ext:request></domain-ext:transfer></extension><clTRID>ABC-12345</clTRID></command></epp>','domain_transfer_start build');
is($rc->is_success(),1,'domain_transfer_start is_success');

## 2.1.09/domains/domain-transfer/domain-transfer02-resp.xml
# Transfer of IDN domain
$R2=$E1.'<response>'.r().'<resData><domain:trnData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:name>some-domain-nãme.eu</domain:name><domain:trStatus>serverApproved</domain:trStatus><domain:reID>a987654</domain:reID><domain:reDate>2014-09-13T20:18:21.846Z</domain:reDate><domain:acID>t000021</domain:acID><domain:acDate>2014-09-13T20:18:21.846Z</domain:acDate><domain:exDate>2016-09-13T21:59:59.999Z</domain:exDate></domain:trnData></resData><extension><idn:mapping xmlns:idn="http://www.eurid.eu/xml/epp/idn-1.0"><idn:name><idn:ace>xn--some-domain-nme-wkb.eu</idn:ace><idn:unicode>some-domain-nãme.eu</idn:unicode></idn:name></idn:mapping></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_transfer_start('some-domain-nãme.eu',\%rd);
is($rc->is_success(),1,'domain_transfer_start is_success');
is($dri->get_info('name'),'some-domain-nãme.eu','domain_transfer_start get_info(name)');
is($dri->get_info('name_ace'),'xn--some-domain-nme-wkb.eu','domain_transfer_start get_info(name_ace)');
is($dri->get_info('name_idn'),'some-domain-nãme.eu','domain_transfer_start get_info(name_idn)');
is($dri->get_info('ace'),'xn--some-domain-nme-wkb.eu','domain_transfer_start get_info(ace)');
is($dri->get_info('unicode'),'some-domain-nãme.eu','domain_transfer_start get_info(unicode)');

## 2.2.1/domains/domain-transfer/domain-transfer05-cmd.xml
# Transfer query
## Note, transfer_from_quarantine was removed a long time ago, its just a transfer now
$R2=$E1.'<response>'.r().'<resData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain:trnData><domain:name>вмкйршаудхыийведйкгг.ею</domain:name><domain:trStatus>pending</domain:trStatus><domain:reID>t000002</domain:reID><domain:reDate>2016-05-23T11:50:13.129Z</domain:reDate><domain:acID>eurid.eu</domain:acID><domain:acDate>2016-05-28T11:50:13.129Z</domain:acDate><domain:exDate>2018-05-23T21:59:59.999Z</domain:exDate></domain:trnData></resData><extension xmlns:domain-ext-2.4="http://www.eurid.eu/xml/epp/domain-ext-2.4" xmlns:idn="http://www.eurid.eu/xml/epp/idn-1.0"><domain-ext-2.4:trnData><domain-ext-2.4:onHold>false</domain-ext-2.4:onHold><domain-ext-2.4:quarantined>false</domain-ext-2.4:quarantined><domain-ext-2.4:suspended>false</domain-ext-2.4:suspended><domain-ext-2.4:registrant>c15</domain-ext-2.4:registrant><domain-ext-2.4:contact type="billing">c14</domain-ext-2.4:contact><domain-ext-2.4:contact type="tech">c17</domain-ext-2.4:contact><domain-ext-2.4:delayed>true</domain-ext-2.4:delayed></domain-ext-2.4:trnData><idn:mapping><idn:name><idn:ace>xn--80adbeadbhzhddejt0e9bxb3cwd.xn--e1a4c</idn:ace><idn:unicode>вмкйршаудхыийведйкгг.ею</idn:unicode></idn:name></idn:mapping></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_transfer_query('xn--80adbeadbhzhddejt0e9bxb3cwd.xn--e1a4c');
is_string($R1,'<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd"><command><transfer op="query"><domain:transfer xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>вмкйршаудхыийведйкгг.ею</domain:name></domain:transfer></transfer><clTRID>ABC-12345</clTRID></command></epp>','domain_transfer_query build');
is($rc->is_success(),1,'domain_transfer_query is_success');
is($dri->get_info('trStatus'),'pending','domain_transfer_query get_info(trStatus)');
is($dri->get_info('reID'),'t000002','domain_transfer_query get_info(reID)');
is($dri->get_info('delayed'),'true','domain_transfer_query get_info(delayed)');
$s=$dri->get_info('contact');
isa_ok($s,'Net::DRI::Data::ContactSet','domain_transfer_query get_info(contact)');
is_deeply([$s->types()],['billing','registrant','tech'],'domain_info get_info(contact) types');
is($s->get('registrant')->srid(),'c15','domain_info get_info(contact) registrant srid');
is($s->get('billing')->srid(),'c14','domain_info get_info(contact) billing srid');
is($s->get('tech')->srid(),'c17','domain_info get_info(contact) tech srid');
is($dri->get_info('name'),'вмкйршаудхыийведйкгг.ею','domain_transfer_query get_info(name)');
is($dri->get_info('name_ace'),'xn--80adbeadbhzhddejt0e9bxb3cwd.xn--e1a4c','domain_transfer_query get_info(name_ace)');
is($dri->get_info('name_idn'),'вмкйршаудхыийведйкгг.ею','domain_transfer_query get_info(name_idn)');
is($dri->get_info('ace'),'xn--80adbeadbhzhddejt0e9bxb3cwd.xn--e1a4c','domain_transfer_query get_info(ace)');
is($dri->get_info('unicode'),'вмкйршаудхыийведйкгг.ею','domain_transfer_query get_info(unicode)');


########################################################################################################
## dnsQuality Info

$R2=$E1.'<response>'.r().'<resData><dnsQuality:infData xmlns:dnsQuality="http://www.eurid.eu/xml/epp/dnsQuality-2.0"><dnsQuality:name>dnsq_domain.eu</dnsQuality:name><dnsQuality:checkTime>2017-08-17T11:23:44.312+02:00</dnsQuality:checkTime><dnsQuality:score>1000</dnsQuality:score></dnsQuality:infData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->dns_quality_info('dnsq_domain.eu');
is_string($R1,$E1.'<command><info><dnsQuality:info xmlns:dnsQuality="http://www.eurid.eu/xml/epp/dnsQuality-2.0" xsi:schemaLocation="http://www.eurid.eu/xml/epp/dnsQuality-2.0 dnsQuality-2.0.xsd"><dnsQuality:name>dnsq_domain.eu</dnsQuality:name></dnsQuality:info></info><clTRID>ABC-12345</clTRID></command></epp>','domain_info build');
is($rc->is_success(),1,'domain_info is_success');
is($dri->get_info('action'),'info','domain_info get_info(action)');
is($dri->get_info('exist'),1,'domain_info get_info(exist)');
is($dri->get_info('name'),'dnsq_domain.eu','domain_info get_info(name)');
is($dri->get_info('check_time'),'2017-08-17T11:23:44','domain_info get_info(name)');
is($dri->get_info('score'),1000,'domain_info get_info(name)');


########################################################################################################
## GDPR context updates

# chapter 3: change for EPP contact info domain: details are not available if a transfer auth code is provided (in case domain not under Registrar portfolio)
$R2=$E1.'<response>'.r().'<resData><domain:infData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>somedomain.eu</domain:name><domain:roid>somedomain_eu-EURID</domain:roid><domain:status s="ok"/><domain:clID>#non-disclosed#</domain:clID><domain:crID>#non-disclosed#</domain:crID><domain:crDate>2018-03-23T10:03:49.428Z</domain:crDate><domain:upID>#non-disclosed#</domain:upID><domain:upDate>2018-03-23T10:03:49.000Z</domain:upDate><domain:exDate>2019-03-23T22:59:59.999Z</domain:exDate></domain:infData></resData><extension xmlns:domain-ext-2.4="http://www.eurid.eu/xml/epp/domain-ext-2.4" xmlns:idn="http://www.eurid.eu/xml/epp/idn-1.0"><domain-ext-2.4:infData><domain-ext-2.4:onHold>false</domain-ext-2.4:onHold><domain-ext-2.4:quarantined>false</domain-ext-2.4:quarantined><domain-ext-2.4:suspended>false</domain-ext-2.4:suspended><domain-ext-2.4:seized>false</domain-ext-2.4:seized><domain-ext-2.4:delayed>false</domain-ext-2.4:delayed></domain-ext-2.4:infData></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_info('somedomain.eu',{auth=>{pw=>'XXXX-393Y-DCZA-7XNS'}});
is($R1,$E1.'<command><info><domain:info xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>somedomain.eu</domain:name><domain:authInfo><domain:pw>XXXX-393Y-DCZA-7XNS</domain:pw></domain:authInfo></domain:info></info><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_info build with auth - GDPR');
is($dri->get_info('action'),'info','domain_info get_info(action)');
is($dri->get_info('exist'),1,'domain_info get_info(exist)');
is($dri->get_info('name'),'somedomain.eu','domain_info get_info(name)');
is($dri->get_info('roid'),'somedomain_eu-EURID','domain_info get_info(roid)');
$s=$dri->get_info('status');
isa_ok($s,'Net::DRI::Data::StatusList','domain_info get_info(status)');
is_deeply([$s->list_status()],['ok'],'domain_info get_info(status) list');
is($s->is_active(),1,'domain_info get_info(status) is_active');
is($dri->get_info('clID'),'#non-disclosed#','domain_info get_info(clID)');
is($dri->get_info('crID'),'#non-disclosed#','domain_info get_info(crID)');
$d=$dri->get_info('crDate');
isa_ok($d,'DateTime','domain_info get_info(crDate)');
is("".$d,'2018-03-23T10:03:49','domain_info get_info(crDate) value');
is($dri->get_info('upID'),'#non-disclosed#','domain_info get_info(upID)');
$d=$dri->get_info('upDate');
isa_ok($d,'DateTime','domain_info get_info(upDate)');
is("".$d,'2018-03-23T10:03:49','domain_info get_info(upDate) value');
$d=$dri->get_info('exDate');
isa_ok($d,'DateTime','domain_info get_info(exDate)');
is("".$d,'2019-03-23T22:59:59','domain_info get_info(exDate) value');


########################################################################################################
## dnssecEligibility Info

$R2=$E1.'<response>'.r().'<resData><dnssecEligibility:infData xmlns:dnssecEligibility="http://www.eurid.eu/xml/epp/dnssecEligibility-1.0"><dnssecEligibility:name>somedomain.eu</dnssecEligibility:name><dnssecEligibility:eligible>true</dnssecEligibility:eligible><dnssecEligibility:msg>Eligible for DNSSEC discount</dnssecEligibility:msg><dnssecEligibility:code>1001</dnssecEligibility:code></dnssecEligibility:infData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->dnssec_eligibility_info('somedomain.eu');
is_string($R1,$E1.'<command><info><dnssecEligibility:info xmlns:dnssecEligibility="http://www.eurid.eu/xml/epp/dnssecEligibility-1.0" xsi:schemaLocation="http://www.eurid.eu/xml/epp/dnssecEligibility-1.0 dnssecEligibility-1.0.xsd"><dnssecEligibility:name>somedomain.eu</dnssecEligibility:name></dnssecEligibility:info></info><clTRID>ABC-12345</clTRID></command></epp>','dnssec_eligibility_info build');
is($rc->is_success(),1,'dnssec_eligibility_info is_success');
is($dri->get_info('action'),'info','dnssec_eligibility_info get_info(action)');
is($dri->get_info('exist'),1,'dnssec_eligibility_info get_info(exist)');
is($dri->get_info('name'),'somedomain.eu','dnssec_eligibility_info get_info(name)');
is($dri->get_info('eligible'),'true','dnssec_eligibility_info get_info(eligible)');
is($dri->get_info('msg'),'Eligible for DNSSEC discount','dnssec_eligibility_info get_info(msg)');
is($dri->get_info('code'),'1001','dnssec_eligibility_info get_info(code)');

$R2=$E1.'<response>'.r().'<resData><dnssecEligibility:infData xmlns:dnssecEligibility="http://www.eurid.eu/xml/epp/dnssecEligibility-1.0"><dnssecEligibility:name>somedomain2.eu</dnssecEligibility:name><dnssecEligibility:eligible>false</dnssecEligibility:eligible><dnssecEligibility:msg>Not eligible for DNSSEC Discount</dnssecEligibility:msg><dnssecEligibility:code>2000</dnssecEligibility:code></dnssecEligibility:infData></resData>'.$TRID.'</response>'.$E2;
$rc=$dri->dnssec_eligibility_info('somedomain2.eu');
is_string($R1,$E1.'<command><info><dnssecEligibility:info xmlns:dnssecEligibility="http://www.eurid.eu/xml/epp/dnssecEligibility-1.0" xsi:schemaLocation="http://www.eurid.eu/xml/epp/dnssecEligibility-1.0 dnssecEligibility-1.0.xsd"><dnssecEligibility:name>somedomain2.eu</dnssecEligibility:name></dnssecEligibility:info></info><clTRID>ABC-12345</clTRID></command></epp>','dnssec_eligibility_info2 build');
is($rc->is_success(),1,'dnssec_eligibility_info2 is_success');
is($dri->get_info('action'),'info','dnssec_eligibility_info2 get_info(action)');
is($dri->get_info('exist'),1,'dnssec_eligibility_info2 get_info(exist)');
is($dri->get_info('name'),'somedomain2.eu','dnssec_eligibility_info2 get_info(name)');
is($dri->get_info('eligible'),'false','dnssec_eligibility_info2 get_info(eligible)');
is($dri->get_info('msg'),'Not eligible for DNSSEC Discount','dnssec_eligibility_info2 get_info(msg)');
is($dri->get_info('code'),'2000','dnssec_eligibility_info2 get_info(code)');



########################################################################################################
## lock service and multiyear transfers allowed related

# <domain:info>
$R2=$E1.'<response>'.r().'<resData><domain:infData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>somedomainlock.eu</domain:name><domain:roid>test_eu-EURID</domain:roid><domain:status s="clientDeleteProhibited"/><domain:status s="clientTransferProhibited"/><domain:status s="clientUpdateProhibited"/><domain:registrant>c11</domain:registrant><domain:contact type="billing">c10</domain:contact><domain:clID>t000001</domain:clID><domain:crID>t000001</domain:crID><domain:crDate>2020-03-02T10:00:43.027Z</domain:crDate><domain:upID>t000001</domain:upID><domain:upDate>2020-03-02T10:02:41.000Z</domain:upDate><domain:exDate>2021-03-02T22:59:59.999Z</domain:exDate></domain:infData></resData><extension xmlns:domain-ext-2.4="http://www.eurid.eu/xml/epp/domain-ext-2.4"><domain-ext-2.4:infData><domain-ext-2.4:onHold>false</domain-ext-2.4:onHold><domain-ext-2.4:quarantined>false</domain-ext-2.4:quarantined><domain-ext-2.4:suspended>false</domain-ext-2.4:suspended><domain-ext-2.4:seized>false</domain-ext-2.4:seized><domain-ext-2.4:contact type="onsite">c12</domain-ext-2.4:contact><domain-ext-2.4:delayed>false</domain-ext-2.4:delayed><domain-ext-2.4:maxExtensionPeriod>9</domain-ext-2.4:maxExtensionPeriod><domain-ext-2.4:registrantCountry>BE</domain-ext-2.4:registrantCountry></domain-ext-2.4:infData></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_info('somedomainlock.eu');
is_string($R1,'<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd"><command><info><domain:info xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>somedomainlock.eu</domain:name></domain:info></info><clTRID>ABC-12345</clTRID></command></epp>','domain_info build');
is($rc->is_success(),1,'domain_info is_success');
is($dri->get_info('exist'),1,'domain_info get_info(exist)');
is($dri->get_info('roid'),'test_eu-EURID','domain_info get_info(roid)');
$s=$dri->get_info('status');
isa_ok($s,'Net::DRI::Data::StatusList','domain_info get_info(status)');
is_deeply([$s->list_status()],['clientDeleteProhibited', 'clientTransferProhibited', 'clientUpdateProhibited'],'domain_info get_info(status) list');
$s=$dri->get_info('contact');
isa_ok($s,'Net::DRI::Data::ContactSet','domain_info get_info(contact)');
is_deeply([$s->types()],['billing', 'onsite', 'registrant'],'domain_info get_info(contact) types');
is($s->get('registrant')->srid(),'c11','domain_info get_info(contact) registrant srid');
is($s->get('billing')->srid(),'c10','domain_info get_info(contact) billing srid');
is($dri->get_info('clID'),'t000001','domain_info get_info(clID)');
is($dri->get_info('crID'),'t000001','domain_info get_info(crID)');
$d=$dri->get_info('crDate');
isa_ok($d,'DateTime','domain_info get_info(crDate)');
is(''.$d,'2020-03-02T10:00:43','domain_info get_info(crDate) value');
is($dri->get_info('upID'),'t000001','domain_info get_info(upID)');
$d=$dri->get_info('upDate');
isa_ok($d,'DateTime','domain_info get_info(upDate)');
is(''.$d,'2020-03-02T10:02:41','domain_info get_info(upDate) value');
$d=$dri->get_info('exDate');
isa_ok($d,'DateTime','domain_info get_info(exDate)');
is(''.$d,'2021-03-02T22:59:59','domain_info get_info(exDate) value');

# <domain:check>
$R2=$E1.'<response>'.r().'<resData><domain:chkData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:cd><domain:name avail="false">somedomainlock.eu</domain:name><domain:reason lang="en">registered</domain:reason></domain:cd></domain:chkData></resData><extension xmlns:domain-ext-2.4="http://www.eurid.eu/xml/epp/domain-ext-2.4"><domain-ext-2.4:chkData><domain-ext-2.4:domain><domain-ext-2.4:name>somedomainlock.eu</domain-ext-2.4:name><domain-ext-2.4:status s="clientTransferProhibited"/></domain-ext-2.4:domain></domain-ext-2.4:chkData></extension>'.$TRID.'</response>'.$E2;
$rc=$dri->domain_check('somedomainlock.eu');
is_string($R1,'<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd"><command><check><domain:check xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>somedomainlock.eu</domain:name></domain:check></check><clTRID>ABC-12345</clTRID></command></epp>','domain_check build');
is($rc->is_success(),1,'domain_check is_success');
is($dri->get_info('exist', 'domain', 'somedomainlock.eu'),1,'domain_check get_info(exist)');
is($dri->get_info('exist_reason','domain','somedomainlock.eu'),'registered','domain_check get_info(exist_reason)');
$s=$dri->get_info('status','domain','somedomainlock.eu');
isa_ok($s,'Net::DRI::Data::StatusList','domain_check get_info(status)');
is_deeply([$s->list_status()],['clientTransferProhibited'],'domain_check get_info(status) list');

# multiyear transfer domain
$R2=$E1.'<response>'.r().'<resData><domain:trnData xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>somedomain-multiyear-transfer.eu</domain:name><domain:trStatus>serverApproved</domain:trStatus><domain:reID>t000002</domain:reID><domain:reDate>2020-02-24T14:36:27.200Z</domain:reDate><domain:acID>t000002</domain:acID><domain:acDate>2020-02-24T14:36:27.200Z</domain:acDate><domain:exDate>2026-02-24T22:59:59.999Z</domain:exDate></domain:trnData></resData>'.$TRID.'</response>'.$E2;
$cs=$dri->local_object('contactset');
$cs->set($dri->local_object('contact')->srid('c24'),'registrant');
$cs->set($dri->local_object('contact')->srid('c23'),'billing');
$cs->set($dri->local_object('contact')->srid('c25'),'onsite');
my %rd2;
$rd2{auth}={pw=>'XXXX-3GN6-Y27V-LTYY'};
$rd2{duration}=DateTime::Duration->new(years=>5);
$rd2{contact}=$cs;
$rc=$dri->domain_transfer_start('somedomain-multiyear-transfer.eu',\%rd2);
is_string($R1,'<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd"><command><transfer op="request"><domain:transfer xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>somedomain-multiyear-transfer.eu</domain:name><domain:period unit="y">5</domain:period><domain:authInfo><domain:pw>XXXX-3GN6-Y27V-LTYY</domain:pw></domain:authInfo></domain:transfer></transfer><extension><domain-ext:transfer xmlns:domain-ext="http://www.eurid.eu/xml/epp/domain-ext-2.4" xsi:schemaLocation="http://www.eurid.eu/xml/epp/domain-ext-2.4 domain-ext-2.4.xsd" xmlns:domain="urn:ietf:params:xml:ns:domain-1.0"><domain-ext:request><domain-ext:registrant>c24</domain-ext:registrant><domain-ext:contact type="billing">c23</domain-ext:contact><domain-ext:contact type="onsite">c25</domain-ext:contact></domain-ext:request></domain-ext:transfer></extension><clTRID>ABC-12345</clTRID></command></epp>','domain_transfer_start multi year build');
is($rc->is_success(),1,'domain_transfer_start multiyear is_success');
is($dri->get_info('name'),'somedomain-multiyear-transfer.eu','domain_transfer_query get_info(name)');
is($dri->get_info('trStatus'),'serverApproved','domain_transfer_query get_info(trStatus)');
is($dri->get_info('reID'),'t000002','domain_transfer_query get_info(reID)');
$d=$dri->get_info('reDate');
isa_ok($d,'DateTime','domain_transfer_query get_info(reDate)');
is(''.$d,'2020-02-24T14:36:27','domain_transfer_query get_info(crDate) value');
is($dri->get_info('acID'),'t000002','domain_transfer_query get_info(acID)');
$d=$dri->get_info('acDate');
isa_ok($d,'DateTime','domain_transfer_query get_info(acDate)');
is(''.$d,'2020-02-24T14:36:27','domain_transfer_query get_info(acDate) value');
$d=$dri->get_info('exDate');
isa_ok($d,'DateTime','domain_transfer_query get_info(exDate)');
is(''.$d,'2026-02-24T22:59:59','domain_transfer_query get_info(exDate) value');

exit 0;
