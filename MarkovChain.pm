package Algorithm::MarkovChain;
use Carp;
use strict;
require 5.005;

use vars qw($VERSION);
$VERSION = '0.01';

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
    $self->{_longest} = $longest if $longest > $self->{_longest};

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
        local %::foo;
        *::foo = $self->{_chains}{$redo};
        my $total;
        $total += $::foo{$_}{seen} for keys %::foo;
        ($::foo{$_}{prob} = $::foo{$_}{seen} / $total) for keys %::foo;
    }
}

=head2 $obj->spew()

Uses the constructed chains to produce symbol streams

Takes two optional parameters C<length> and C<complete>

C<length> specifies the number of symbols to produce (default is 30)

C<complete> provides a starting point for the generation of output.
Note: the algorithm will discard elements of this list if it does not
find a starting chain that matches it, this is infinite-loop avoidance.

=cut

sub spew {
    my Algorithm::MarkovChain $self = shift;
    my %args = @_;

    my $length = $args{length} || 30;

    my @prev;
    if ($args{complete} && ref $args{complete} eq 'ARRAY') {
        @prev = @{ $args{complete} };
        for (;;) {
            my $start = join $;, @prev;
            last if $self->{_chains}{$start};
            last unless @prev;
            shift @prev;
        }
    }

    if (!@prev) { # pull a random chain from those we've already picked
        my @heads = keys %{ $self->{_chains} };
        @prev = split $;, $heads[ rand @heads ];
    }

    while (@prev < $length) {
        my $consider = 1;
        if (@prev > 1) {
            $consider = rand ($self->{_longest} - 1);
        }

        my $start = join($;, @prev[-$consider..-1]);
        next unless $self->{_chains}{$start};

        my $cprob;
        my $target = rand;

        for my $word (keys %{ $self->{_chains}{$start} }) {
            $cprob += $self->{_chains}{$start}{$word}{prob};
            if ($cprob >= $target) {
                push @prev, $word;
                last;
            }
        }
    }

    @prev = map { $self->{_symbols}{$_} } @prev
      if $self->{_recover_symbols};

    return @prev;
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
