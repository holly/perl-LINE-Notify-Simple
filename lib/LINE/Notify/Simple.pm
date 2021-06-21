package LINE::Notify::Simple;

use strict;
use warnings;
use utf8;
use feature qw(say);
use parent qw(Class::Accessor);
use JSON;
use Encode;
use Encode::Guess qw(euc-jp shiftjis 7bit-jis);
use LWP::UserAgent;
use HTTP::Request;
use URI::Escape;
use LINE::Notify::Simple::Response;

__PACKAGE__->mk_accessors(qw(access_token));

our $LINE_NOTIFY_URL    = 'https://notify-api.line.me/api/notify';
our $VERSION            = '1.01';

sub notify {

	my($self, $message) = @_;

	my $data = { message => $message };
	return $self->notify_detail($data);
}

sub notify_detail {

	my($self, $data) = @_;

	my $headers = [
			'Content-Type', 'application/x-www-form-urlencoded',
			'Authorization', sprintf('Bearer %s', $self->access_token)
		];

	my $content = $self->make_query($data);

	my $ua  = LWP::UserAgent->new;
	my $req = HTTP::Request->new("POST", $LINE_NOTIFY_URL, $headers, $content);
	my $res = $ua->request($req);

	my $rate_limit_headers = {};
	my @names = $res->header_field_names;
	foreach my $name (@names) {
		if ($name =~ /^X\-.*/) {
			$rate_limit_headers->{lc($name)} = $res->header($name);
		}
	}

	my $ref = JSON->new->decode($res->content);

	return LINE::Notify::Simple::Response->new({ rate_limit_headers => $rate_limit_headers, status => $ref->{status}, message => $ref->{message}, status_line => $res->status_line });
}


sub make_query {

	my($self, $data) = @_;

	my @pairs;
	foreach my $key(keys %{$data}) {

		my $val = $data->{$key};
		if (utf8::is_utf8($val)) {
			my $enc   = guess_encoding($val);
			my $guess = ref($enc) ? $enc->name : "UTF-8";
			$val = Encode::encode($guess, $val);
		}
		push @pairs, sprintf("%s=%s", $key, uri_escape($val));
	}
	return join("&", @pairs);
}

1;

__END__

=pod

=head1 NAME

LINE::Notify::Simple

=head1 VERSION

1.01

=head1 SYNOPSIS

  #!/usr/bin/env perl
  
  use strict;
  use warnings;
  use utf8;
  use feature qw(say);
  use LINE::Notify::Simple;
  
  my $access_token = 'your line access token';
  my $message = "\nThis is test message.";
  my $line = LINE::Notify->new({access_token => $access_token});
  
  my $res = $line->notify($message);
  if ($res->is_success) {
      say $res->message;
  } else {
      say $res->status_line . ". ". $res->message;
  }
  
  exit;

=head1 DESCRIPTION

L<LINE Notify API|https://notify-api.line.me/api/notify> simple & easy POST request module.

=head1 METHOD

=head2 notify

POST https://notify-api.line.me/api/notify.
Return LINE::Notify::Simple::Response.

  my $message = "\nThis is test message.";
  my $res = $line->notify($message);
  if ($res->is_success) {
      say $res->message;
  } else {
      say $res->status_line . ". ". $res->message;
  }

=over

=item *

message(required)

=back

=head2 notify_detail

Hashref keys are message, stickerPackageId, stickerId, notificationDisabled

  # see https://developers.line.biz/ja/docs/messaging-api/sticker-list/
  my $data = {
      message          => "\nThis is test message.",
      stickerPackageId => 11539,
      stickerId        => 52114110
  };
  my $res = $line->notify_detail($data);
  if ($res->is_success) {
      say $res->message;
  } else {
      say $res->status_line . ". ". $res->message;
  }

=over 4

=item *

message(required)

=item *

stickerPackageId(optional)

=item *

stickerId(optional)

=item *

notificationDisabled(optional).

=item *

imageThumbnail(not supported)

=item *

imageFullsize(not supported)

=back

=head1 AUTHOR

Akira Horimoto E<lt>emperor.kurt _at_ gmail.comE<gt>

=head1 SEE ALSO

L<https://notify-bot.line.me/doc/ja/>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

