use strict;
use warnings;
use utf8;
use Test::More;

{
  use open::layers r => ':encoding(UTF-8)';
  my $buffer = "\xE2\x98\x83";
  open my $read, '<', \$buffer or die "Failed to open buffer for reading: $!";
  is scalar(readline $read), '☃', 'read decodes from UTF-8';
  close $read;
  open my $write, '>', \$buffer or die "Failed to open buffer for writing: $!";
  print $write '°';
  close $write;
  is $buffer, "\xB0", 'write does not encode to UTF-8';
}

{
  use open::layers w => ':encoding(UTF-8)';
  my $buffer = "\xC2\xB0";
  open my $read, '<', \$buffer or die "Failed to open buffer for reading: $!";
  is scalar(readline $read), 'Â°', 'read does not decode from UTF-8';
  close $read;
  open my $write, '>', \$buffer or die "Failed to open buffer for writing: $!";
  print $write '°';
  close $write;
  is $buffer, "\xC2\xB0", 'write encodes to UTF-8';
}

{
  use open::layers r => ':encoding(UTF-8)', w => ':encoding(cp1252)';
  my $buffer = "\xE2\x82\xAC";
  open my $read, '<', \$buffer or die "Failed to open buffer for reading: $!";
  is scalar(readline $read), '€', 'read decodes from UTF-8';
  close $read;
  open my $write, '>', \$buffer or die "Failed to open buffer for writing: $!";
  print $write '€';
  close $write;
  is $buffer, "\x80", 'write encodes to cp1252';
}

{
  use open::layers rw => ':encoding(UTF-16BE)';
  my $buffer = "\xD8\x34\xDD\x1E";
  open my $read, '<', \$buffer or die "Failed to open buffer for reading: $!";
  is scalar(readline $read), "\N{U+1D11E}", 'read decodes from UTF-16BE';
  close $read;
  open my $write, '>', \$buffer or die "Failed to open buffer for writing: $!";
  print $write "\N{U+1D122}";
  close $write;
  is $buffer, "\xD8\x34\xDD\x22", 'write encodes to UTF-16BE';
}

{
  use open::layers rw => ':raw:encoding(UTF-16LE):crlf';
  my $buffer = "\x03\x26\x0D\x00\x0A\x00";
  open my $read, '<', \$buffer or die "Failed to open buffer for reading: $!";
  is scalar(readline $read), "☃\n", 'read decodes from UTF-16LE and CRLF';
  close $read;
  open my $write, '>', \$buffer or die "Failed to open buffer for writing: $!";
  print $write "☃\n";
  close $write;
  is $buffer, "\x03\x26\x0D\x00\x0A\x00", 'write encodes to UTF-16LE and CRLF';
}

done_testing;
