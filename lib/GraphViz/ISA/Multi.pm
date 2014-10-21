
package GraphViz::ISA::Multi;
use strict;
use GraphViz;

BEGIN {
	use Exporter ();
	use vars qw ($VERSION @ISA);
	$VERSION     = 0.01;
}

sub new
{
	my ($class, %parameters) = @_;

	my $self = bless ({}, ref ($class) || $class);

	$self->{data} = {};
	$self->{ignore} = $parameters{ignore};
	return ($self);
}


sub graph 
{
    my $self = shift;

    if (not defined $self->{g}) {
	$self->{g} = GraphViz->new();
    }

    ### draw all nodes:
    foreach my $module (sort keys %{$self->{data}}) {
	$self->{g}->add_node($module);
	foreach my $nod (@{$self->{data}->{$module}}) {
	    $self->{g}->add_node($nod) ;
	}
    }

    ### draw the edges
    foreach my $module (sort keys %{$self->{data}}) {
	$self->{g}->add_edge($_, $module) for
	    @{$self->{data}->{$module}};
    }

    return $self->{g};
}


sub add
{
    my $self = shift;
    my @to_add = @_;

    foreach my $module (@to_add) {
	next if grep /$module/i, @{$self->{ignore}};
	my $filename = $module;
	$filename =~ s!::!/!g;
	$filename .= ".pm";

	eval { 
	    if (! defined $INC{$filename} ) {
	     require $filename; 
	    }
        }; 
	if ($@) {
	    return undef;
	}

	no strict 'refs';
	if (@{$module . "::ISA"} > 0) {
	    $self->{data}->{$module} = \@{$module."::ISA"};
	    foreach my $ign (@{$self->{ignore}}) {
		@{$self->{data}->{$module}} = grep $_ !~ /$ign/, @{$self->{data}->{$module}} ;
	    }
	    $self->add($_) foreach @{$module."::ISA"};
	}
    }
    return $self->{data};
}

sub AUTOLOAD
{
    no strict 'vars';
    my $self = shift;
    my $n = $AUTOLOAD;
    $n =~ s/.*:://g;

    return if $n =~ /DESTROY/;

    if ($n =~ /as_/) {
	$self->graph();
	### give it down to GraphViz:
    }
    $self->{g}->$n(@_);
}


1; #this line is important and will help the module return a true value
__END__


=head1 NAME

GraphViz::ISA::Multi - Display ISA relations between modules

=head1 SYNOPSIS

    use GraphViz::ISA::Multi;

    my $gnew= GraphViz::ISA::Multi->new(ignore => [ 'Exporter' ]);

    $gnew->add("Curses::UI::TextViewer" );
    $gnew->add("Curses::UI::Listbox" );

    print $gnew->as_png();


=head1 DESCRIPTION

GraphViz::ISA::Multi visualizes the ISA relations between multiple 
modules. It is a addition to GraphViz::ISA, which can only show
the ISA tree of one module.


=head1 USAGE

=over 4 


=item new( ignore => ARRAYREF )

    Creates a new GraphViz::ISA::Multi object. Takes as an 
    additional parameter the 'ignore' => [ 'Module' ] list,
    which tells the object to not display certain modules
    in the graphic.



=item add( MODULENAMELIST )

    Adds packages to the graphic. Takes a list of module names
    and returns the data structure used to display the graphic
    on success. On error it returns a false value (undef).



=item graph( )

    Used to create the actual GraphViz object and graphic. You
    usually don't call this directly as it is called when you
    call one of the as_* methods. You can override if it you
    subclass the class.
    It returns the GraphViz object on success.



=item as_png( )

    See GraphViz() for more details.



=back

=head1 AUTHOR

	Marcus Thiesen
        marcus@cpan.org
	http://perl.thiesenweb.de

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.


=head1 SEE ALSO

perl(1).

=cut
