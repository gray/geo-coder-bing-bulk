use strict;
use warnings;
use Encode;
use Geo::Coder::Bing::Bulk;
use Test::More;

unless ($ENV{BING_MAPS_KEY}) {
    plan skip_all => 'BING_MAPS_KEY environment variable must be set';
}
else {
    plan tests => 11;
}

my $debug = $ENV{GEO_CODER_BING_DEBUG};
unless ($debug) {
    diag "Set GEO_CODER_BING_DEBUG to see request/response data";
}

my @addresses = (
    'Sunset Blvd and Los Liones Dr, Pacific Palisades, CA',
    '2001 North Fuller Avenue, Los Angeles, CA',
    '4730 Crystal Springs Drive, Los Angeles, CA',
    'Hollywood & Highland, Los Angeles, CA',
    qq(Albrecht-Th\xE4r-Stra\xDFe 6 48147 M\xFCnster GERMANY),
    decode(
        'latin1', qq(Albrecht-Th\xE4r-Stra\xDFe 6 48147 M\xFCnster GERMANY)
    ),
    encode('utf-8',
        decode(
            'latin1',
            qq(Albrecht-Th\xE4r-Stra\xDFe 6 48147 M\xFCnster GERMANY)
        )
    ),
    'testing testing, 123',
);

my $bulk = Geo::Coder::Bing::Bulk->new(
    key      => $ENV{BING_MAPS_KEY},
    debug    => $debug,
    compress => 0,
);

my $id = $bulk->upload(\@addresses);
ok($id, 'upload succeeded; returned job id');
exit unless defined $id and length $id;

while ($bulk->is_pending) {
    diag "job is pending - checking again in 30 seconds...";
    sleep 30;
}

my $data = $bulk->download;
ok($data and @$data, 'got results');
is($data->[0]{Address}{PostalCode}, 90272, 'Address 1: correct ZIP');
like($data->[1]{Address}{PostalCode}, qr/^90046/, 'Address 2: correct ZIP');
like($data->[2]{Address}{PostalCode}, qr/^90027/, 'Address 3: correct ZIP');
is($data->[3]{Address}{PostalCode}, 90028, 'Address 4: correct ZIP');
is($data->[4]{Address}{CountryRegion}, 'Germany', 'Address 5: latin1 bytes');
is($data->[5]{Address}{CountryRegion}, 'Germany', 'Address 6: utf-8 chars');
is($data->[6]{Address}{CountryRegion}, 'Germany', 'Address 7: utf-8 bytes');
is($data->[7]{Address}, undef, 'Address 8: invalid');

my $failed = $bulk->failed;
is($failed, undef, 'no failures');
