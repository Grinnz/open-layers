package open::layers;

use strict;
use warnings;
use Carp ();
use open ();

our $VERSION = '0.001';

sub import {
  my $class = shift;
  while (@_) {
    my $arg = shift;
    if (ref $arg or ref \$arg eq 'GLOB') {
      Carp::croak "open::layers: No layer provided for handle $arg" unless @_;
      my $layer = shift;
      Carp::croak "open::layers: Invalid layer specification $layer" unless $layer =~ m/\A\s*(?::[^\s:]+\s*)+\z/;
      binmode $arg, $layer or Carp::croak "open::layers: binmode $arg failed: $!";
    } elsif ($arg =~ m/\ASTD(IN|OUT|ERR|IO)\z/) {
      my $which = $1;
      Carp::croak "open::layers: No layer provided for handle $arg" unless @_;
      my $layer = shift;
      Carp::croak "open::layers: Invalid layer specification $layer" unless $layer =~ m/\A\s*(?::[^\s:]+\s*)+\z/;
      my @handles = $which eq 'IN' ? \*STDIN
        : $which eq 'OUT' ? \*STDOUT
        : $which eq 'ERR' ? \*STDERR
        : (\*STDIN, \*STDOUT, \*STDERR);
      binmode $_, $layer or Carp::croak "open::layers: binmode $_ failed: $!" for @handles;
    } elsif ($arg =~ m/\A(rw|r|w)\z/) {
      my $which = $1;
      Carp::croak "open::layers: No layer provided for $arg handles" unless @_;
      my $layer = shift;
      Carp::croak "open::layers: Invalid layer specification $layer" unless $layer =~ m/\A\s*(?::[^\s:]+\s*)+\z/;
      my @layers = $layer =~ m/(:[^\s:]+)/g;
      my $open_type = $which eq 'r' ? 'IN' : $which eq 'w' ? 'OUT' : 'IO';
      'open'->import($open_type => join ' ', @layers);
    } else {
      Carp::croak "open::layers: Unknown flag $arg";
    }
  }
}

1;

=head1 NAME

open::layers - Set default PerlIO layers

=head1 SYNOPSIS

  # set default for open() in this lexical scope
  use open::layers r => ':raw'; # no CRLF translation on read
  use open::layers r => ':encoding(cp1252)', w => ':encoding(UTF-8)';
  use open::layers rw => ':encoding(UTF-8)'; # all opened handles

  # set layers on the standard handles (not lexical)
  use open::layers STDIN => ':encoding(UTF-8)';
  use open::layers STDOUT => ':encoding(UTF-8)', STDERR => ':encoding(UTF-8)';
  use open::layers STDIO => ':encoding(UTF-8)'; # shortcut for all of above

=head1 DESCRIPTION

This pragma is a reimagination of the core L<open> pragma, which either sets
L<PerlIO> layers on the global standard handles, or sets default L<PerlIO>
layers for handles opened in the current lexical scope. The interface is
redesigned to be more explicit and intuitive. See L</"COMPARISON TO open.pm">
for details.

A three-argument L<open()|perlfunc/open> call that specifies layers will ignore
any lexical defaults from this module or the L<open> pragma. A single C<:>
(colon) also does this, without applying any further layers.

  use open::layers rw => ':encoding(UTF-8)';
  open my $fh, '>:unix', $file; # ignores UTF-8 layer and applies :unix
  open my $fh, '<:', $file; # ignores UTF-8 layer

=head1 ARGUMENTS

Each operation is specified in a pair of arguments. The first argument, the
flag, specifies the target of the operation, which may be one of:

=over

=item STDIN, STDOUT, STDERR, STDIO

These strings indicate to set the layer(s) on the associated standard handle,
affecting usage of that handle globally. C<STDIO> is a shortcut to operate on
all three.

Note that this will also affect reading from C<STDIN> via L<ARGV|perlvar/ARGV>
(empty C<< <> >>, C<<< <<>> >>>, or L<readline()|perlfunc/readline>).

=item $handle

An arbitrary filehandle will have layer(s) set on it directly, affecting all
usage of that handle similarly to the operation on standard handles. Handles
must be passed as a glob or reference to a glob, B<not> a bareword. This is
equivalent to calling L<binmode()|perlfunc/binmode> on the handle in a C<BEGIN>
block.

Note that the handle must be opened in the compile phase (such as in a
preceding C<BEGIN> block) in order to be available for this pragma to operate
on it.

=item r, w, rw

These strings indicate to set the default layer(s) for handles opened in the
current lexical scope: C<r> for handles opened for reading, C<w> for handles
opened for writing, and C<rw> for all handles.

Note that this will also affect implicitly opened read handles such as files
opened by L<ARGV|perlvar/ARGV> (empty C<< <> >>, C<<< <<>> >>>, or
L<readline()|perlfunc/readline>), but B<not> C<STDIN> via C<ARGV>, or
L<DATA|perldata/"Special Literals">.

=back

The second argument is the layer or layers to set. Multiple layers can be
specified like C<:foo:bar>, as in L<open()|perlfunc/open> or
L<binmode()|perlfunc/binmode>.

=head1 COMPARISON TO open.pm

=over

=item *

Unlike L<open>, C<open::layers> requires that the target of the operation is
always specified so as to not confuse global and lexical operations.

=item *

Unlike L<open>, C<open::layers> can set layers on the standard handles without
affecting handles opened in the lexical scope.

=item *

Unlike L<open>, multiple layers are not required to be space separated.

=item *

Unlike L<open>, duplicate existing encoding layers are not removed from the
standard handles. Either ensure that nothing else is setting encoding layers on
these handles, or use the C<:raw> pseudo-layer to "reset" the layers to a
binary stream before applying text translation layers.

  use open::layers STDIO => ':raw:encoding(UTF-16BE)';
  use open::layers STDIO => ':raw:encoding(UTF-16BE):crlf'; # on Windows 5.14+

=item *

Unlike L<open>, the C<:locale> pseudo-layer is not (yet) implemented.

=back

=head1 CAVEATS

The L<PerlIO> layers and L<open> pragma have experienced several issues over
the years, most of which can't be worked around by this module. It's
recommended to use a recent Perl if you will be using complex layers; for
compatibility with old Perls, stick to L<binmode()|perlfunc/binmode> (either
with no layers for a binary stream, or with a single C<:encoding> layer). Here
are some selected issues:

=item *

Before Perl 5.8.8, L<open()|perlfunc/open> called with three arguments would
ignore L<${^OPEN}|perlvar/${^OPEN}> and thus any lexical default layers.
L<[perl #8168]|https://github.com/Perl/perl5/issues/8168>

=item *

Before Perl 5.8.9, the C<:crlf> layer did not preserve the C<:utf8> flag from
an earlier encoding layer, resulting in an improper translation of the bytes.
This can be worked around by adding the C<:utf8> layer after C<:crlf> (even if
it is not a UTF-8 encoding).

=item *

Before Perl 5.14, the C<:crlf> layer does not properly apply on top of another
layer, such as an encoding layer, if it had also been applied earlier in the
stack such as is default on Windows. Thus you could not usefully use a layer
like C<:encoding(UTF-16BE)> with a following C<:crlf>.
L<[perl #8325]|https://github.com/Perl/perl5/issues/8325>

=item *

Before Perl 5.14, the C<:pop>, C<:utf8>, or C<:bytes> layers did not allow
stacking further layers, like C<:pop:crlf>.
L<[perl #11054]|https://github.com/perl/perl5/issues/11054>

=item *

Before Perl 5.14, the C<:raw> layer reset the handle to an unbuffered state,
rather than just removing text translation layers.
L<[perl #10904]|https://github.com/perl/perl5/issues/10904>

=item *

Before Perl 5.14, the C<:raw> layer did not work properly with in-memory scalar
handles.

=item *

Before Perl 5.16, L<use|perlfunc/use> and L<require()|perlfunc/require> are
affected by lexical default layers when loading the source file, leading to
unexpected results. L<[perl #11541]|https://github.com/perl/perl5/issues/11541>

=back

=head1 BUGS

Report any issues on the public bugtracker.

=head1 AUTHOR

Dan Book <dbook@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2020 by Dan Book.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=head1 SEE ALSO

L<open>, L<PerlIO>
