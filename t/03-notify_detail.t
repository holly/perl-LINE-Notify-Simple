#!/usr/bin/env perl
use 5.006;
use strict;
use warnings;
use Test::More;

if ( !exists $ENV{LINE_ACCESS_TOKEN} ) {
    plan( skip_all => "LINE_ACCESS_TOKEN environtment not required for installation" );
}


require_ok( 'LINE::Notify::Simple' ) || print "Bail out!\n";

my $access_token = $ENV{LINE_ACCESS_TOKEN};
my $line = LINE::Notify::Simple->new({ access_token => $access_token });

my $data = {
      message          => "\nvalid token and notify_detail method test.",
      stickerPackageId => 11539,
      stickerId        => 52114110
};

my $res = $line->notify_detail($data);

ok($res->is_success == 1, "valid token and notify_detail method test");

done_testing;
