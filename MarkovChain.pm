package Algorithm::MarkovChain;
use Carp;
use strict;
require 5.005;

use vars qw($VERSION);
$VERSION = '0.03';

use fields qw(_chains _symbols _recover_symbols _longest);

=head1 NAME

Algorithm::MarkovChain - Object oriented Markov chain generator

=head1 SYNOPSIS

  use Algorithm::MarkovChain;

  my $chain = Algorithm::MarkovChain::->new();

  # learn about things from @symbols
  $chain->seed(symbols => \@symbols,
               longest => 6);

  # attempt to tell me something about the sky
  my @newness = $chain->spew(length   => 20,
                             complete => [ qw( the sky is ) ]);

=head1 DESCRIPTION

Algorithm::MarkovChain is an implementation of the Markov Chain
algorithm within an object container.

=head1 METHODS


=head2 Algorithm::MarkovChain::->new() or $obj->new()

Creates a new instance of the Algorithm::MarkovChain class.

Takes one optional parameter: C<recover_symbols>

C<recover_symbols> has meaning if your symbols differ from their true
values when stringifyed.  With this option enabled steps are taken to
ensure that the original values for symbols are returned by the
I<spew> method.

=cut

sub new {
    my $invocant = shift;
    my %args = @_;

    my Algorithm::MarkovChain $self;

    my $class = ref $invocant || $invocant;
    { # yikes, apprently this gets better around 5.6.0
        no strict 'refs';
        $self = bless [\%{"$class\::FIELDS"}], $class;
    }

    $self->{_longest} = 0;
    $self->{_chains} = {};
    $self->{_symbols} = {};
    $self->{_recover_symbols} = $args{recover_symbols};

    return $self;
}

=head2 $obj->seed()

Seeds the markov chains from an example symbol stream.

Takes two parameters, one required C<symbols>, one optional C<longest>

C<symbols> presents the symbols to seed from

C<longest> sets an upper limit on the longest chain to
construct. (defaults to 4)

=cut

sub seed {
    my Algorithm::MarkovChain $self = shift;
    my %args = @_;

    croak 'seed: no symbols'  unless $args{symbols};
    croak 'seed: bad symbols' unless ref($args{symbols}) eq 'ARRAY';

    my $longest = $args{longest} || 4;

    local @::symbols;
    *::symbols = $args{symbols};

    if ($self->{_recover_symbols}) {
        $self->{_symbols}{$_} = $_ for @::symbols;
    }

    my %tweaked;
    for my $length (1..$longest) {
        for (my $i = 0; ($i + $length) < @::symbols; $i++) {
            my $link = join($;, @::symbols[$i..$i + $length - 1]);
            $self->{_chains}{$link}{$::symbols[$i + $length]}{seen}++;
            $tweaked{$link} = 1;
        }
    }

    for my $redo (keys %tweaked) {
        my @tmp = split $;, $redo;
        my $length = scalar @tmp;
        $self->{_longest} = $length
          if $length > $self->{_longest};

        local %::foo;
        *::foo = $self->{_chains}{$redo};
        my $total;
        $total += $::foo{$_}{seen} for keys %::foo;
        ($::foo{$_}{prob} = $::foo{$_}{seen} / $total) for keys %::foo;
    }
}

=head2 $obj->spew()

Uses the constructed chains to produce symbol streams

Takes four optional parameters C<complete>, C<length>,
C<longest_subchain>, C<force_length> and C<stop_at_terminal>

C<complete> provides a starting point for the generation of output.
Note: the algorithm will discard elements of this list if it does not
find a starting chain that matches it, this is infinite-loop avoidance.

C<length> specifies the minimum number of symbols desired (default is 30)

C<stop_at_terminal> directs the spew to stop chaining at the first
terminal point reached

C<force_length> ensures you get exactly C<length> symbols returned
(note this overrides the behaviour of C<stop_at_terminal>)

=cut

sub spew {
    my Algorithm::MarkovChain $self = shift;
    my %args = @_;

    my @heads = keys %{ $self->{_chains} };
    croak "spew called without any chains seeded"
      unless @heads;

    my $length   = $args{length} || 30;
    my $subchain = $args{longest_subchain} || $length;

    my @fin; # final chain
    my @sub; # current sub-chain
    if ($args{complete} && ref $args{complete} eq 'ARRAY') {
        @sub = @{ $args{complete} };
    }

    while (@fin < $length) {
        if (@sub && ((!$self->{_chains}{$sub[-1]}) || (@sub > $subchain))) { # we've gone terminal
            push @fin, @sub;
            @sub = ();
            next if $args{force_length}; # ignore stop_at_terminal
            last if $args{stop_at_terminal};
        }

        @sub = split $;, $heads[ rand @heads ]
          unless @sub;

        my $consider = 1;
        if (@sub > 1) {
            $consider = int rand ($self->{_longest} - 1);
        }

        my $start = join($;, @sub[-$consider..-1]);

        next unless $self->{_chains}{$start}; # loop if we missed

        my $cprob;
        my $target = rand;

        for my $word (keys %{ $self->{_chains}{$start} }) {
            $cprob += $self->{_chains}{$start}{$word}{prob};
            if ($cprob >= $target) {
                push @sub, $word;
                last;
            }
        }
    }

    $#fin = $length
      if $args{force_length};

    @fin = map { $self->{_symbols}{$_} } @fin
      if $self->{_recover_symbols};

    return @fin;
}

1;
__END__


=head1 TODO

=over 4

=item Documentation

I need to explain Markov Chains, and flesh out the examples some more.

=item Serialization interface

Currently seeding the chain list is very intensive, and so there
should be a useful way to serialize objects of Algorithm::MarkovChain.

With the current implementation there are no private object variables,
so it's possible to cheat and just freeze the raw object, but I
wouldn't want for people to rely on that.

=item Fix bugs/respond to feature requests

Just email me <richardc@unixbeard.net> and we'll sort something out...

=back

=head1 BUGS

Hopefully not, though if they probably arise from my not understanding
Markov chaining as well as I thought I did when coding commenced.

That or they're jst stupid mistakes :)

=head1 AUTHOR

Richard Clamp <richardc@unixbeard.net>

=head1 SEE ALSO

perl(1).

=cut
