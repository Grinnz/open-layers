use strict;
use warnings;
use utf8;
use File::Temp;
use Test::More;

my $dir = File::Temp->newdir;

open my $test_utf8, '>:raw', "$dir/utf8.txt" or die "Failed to open $dir/utf8.txt for writing: $!";
print $test_utf8 "\xE2\x98\x83";
close $test_utf8;

open my $test_cp1252, '>:raw', "$dir/cp1252.txt" or die "Failed to open $dir/cp1252.txt for writing: $!";
print $test_cp1252 "\x80\x0D\x0A";
close $test_cp1252;

open my $test_utf16be, '>:raw', "$dir/utf16be.txt" or die "Failed to open $dir/utf16be.txt for writing: $!";
print $test_utf16be "\xD8\x34\xDD\x1E";
close $test_utf16be;

open my $test_utf16le, '>:raw', "$dir/utf16le.txt" or die "Failed to open $dir/utf16le.txt for writing: $!";
print $test_utf16le "\x03\x26\x0D\x00\x0A\x00";
close $test_utf16le;

{
  local $/;
  use open::layers r => ':encoding(UTF-8)';
  open my $read, '<', "$dir/utf8.txt" or die "Failed to open $dir/utf8.txt for reading: $!";
  is scalar(readline $read), '☃', 'read decodes from UTF-8';
  close $read;
  open my $write, '>', "$dir/utf8_out.txt" or die "Failed to open $dir/utf8_out.txt for writing: $!";
  print $write '°';
  close $write;
  open my $read_out, '<:raw', "$dir/utf8_out.txt" or die "Failed to open $dir/utf8_out.txt for reading: $!";
  is scalar(readline $read_out), "\xB0", 'write does not encode to UTf-8';
}

{
  local $/;
  use open::layers w => ':encoding(UTF-8)';
  open my $read, '<', "$dir/utf8.txt" or die "Failed to open $dir/utf8.txt for reading: $!";
  is scalar(readline $read), "\xE2\x98\x83", 'read does not decode from UTF-8';
  close $read;
  open my $write, '>', "$dir/utf8_out.txt" or die "Failed to open $dir/utf8_out.txt for writing: $!";
  print $write '°';
  close $write;
  open my $read_out, '<:raw', "$dir/utf8_out.txt" or die "Failed to open $dir/utf8_out.txt for reading: $!";
  is scalar(readline $read_out), "\xC2\xB0", 'write encodes to UTF-8';
}

{
  local $/;
  use open::layers r => ':encoding(UTF-8)', w => ':encoding(cp1252)';
  open my $read, '<', "$dir/utf8.txt" or die "Failed to open $dir/utf8.txt for reading: $!";
  is scalar(readline $read), '☃', 'read decodes from UTF-8';
  close $read;
  open my $write, '>', "$dir/cp1252_out.txt" or die "Failed to $dir/cp1252_out.txt for writing: $!";
  print $write '€';
  close $write;
  open my $read_out, '<:raw', "$dir/cp1252_out.txt" or die "Failed to open $dir/cp1252_out.txt for reading: $!";
  local $/;
  is scalar(readline $read_out), "\x80", 'write encodes to cp1252';
}

{
  local $/;
  use open::layers rw => ':encoding(UTF-16BE)';
  open my $read, '<', "$dir/utf16be.txt" or die "Failed to open $dir/utf16be.txt for reading: $!";
  is scalar(readline $read), "\N{U+1D11E}", 'read decodes from UTF-16BE';
  close $read;
  open my $write, '>', "$dir/utf16be_out.txt" or die "Failed to open $dir/utf16be_out.txt for writing: $!";
  print $write "\N{U+1D122}";
  close $write;
  open my $read_out, '<:raw', "$dir/utf16be_out.txt" or die "Failed to open $dir/utf16be_out.txt for reading: $!";
  is scalar(readline $read_out), "\xD8\x34\xDD\x22", 'write encodes to UTF-16BE';
}

{
  local $/;
  use open::layers rw => ':raw:encoding(cp1252)';
  open my $read, '<', "$dir/cp1252.txt" or die "Failed to open $dir/cp1252.txt for reading: $!";
  is scalar(readline $read), "€\r\n", 'read decodes from cp1252 (no CRLF)';
  close $read;
  open my $write, '>', "$dir/cp1252_out.txt" or die "Failed to open $dir/cp1252_out.txt for writing: $!";
  print $write "€\r\n";
  close $write;
  open my $read_out, '<:raw', "$dir/cp1252_out.txt" or die "Failed to open $dir/cp1252_out.txt for writing: $!";
  is scalar(readline $read_out), "\x80\x0D\x0A", 'write encodes to cp1252 (no CRLF)';
}

{
  local $/;
  use open::layers rw => ':raw:encoding(UTF-16LE):crlf';
  open my $read, '<', "$dir/utf16le.txt" or die "Failed to open $dir/utf16le.txt for reading: $!";
  is scalar(readline $read), "☃\n", 'read decodes from UTF-16LE and CRLF';
  close $read;
  open my $write, '>', "$dir/utf16le_out.txt" or die "Failed to open $dir/utf16le_out.txt for writing: $!";
  print $write "☃\n";
  close $write;
  open my $read_out, '<:raw', "$dir/utf16le_out.txt" or die "Failed to open $dir/utf16le_out.txt for writing: $!";
  is scalar(readline $read_out), "\x03\x26\x0D\x00\x0A\x00", 'write encodes to UTF-16LE and CRLF';
}

done_testing;
