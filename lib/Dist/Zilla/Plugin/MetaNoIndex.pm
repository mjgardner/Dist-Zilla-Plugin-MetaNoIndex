package Dist::Zilla::Plugin::MetaNoIndex;

# ABSTRACT: Stop CPAN from indexing stuff

use English qw(-no_match_vars);
use Moose;
use Readonly;
use Moose::Autobox;
with 'Dist::Zilla::Role::MetaProvider';

Readonly my %ATTR_ALIAS => (
    directory => [qw(dir directories folder)],
    file      => ['files'],
    package   => [qw(class module packages)],
    namespace => ['namespaces'],
);

=encoding utf8

=for stopword JT

=begin Pod::Coverage

    mvp_aliases
    mvp_multivalue_args

=end Pod::Coverage

=cut

sub mvp_aliases {
    my %aliases;
    while ( my ( $attr, $aliases_ref ) = each %ATTR_ALIAS ) {
        %aliases = ( %aliases, map { $ARG => $attr } @{$aliases_ref} );
    }
    return \%aliases;
}

sub mvp_multivalue_args { return keys %ATTR_ALIAS }

=attr directory

Exclude folders and everything in them. Example: C<author.t>.
Aliases: C<folder>, C<dir>, C<directories>.

=attr file

Exclude a specific file. Example: C<lib/Foo.pm>.
Alias: C<files>.

=attr package

Exclude by package name. Example: C<My::Package>.
Aliases: C<class>, C<module>, C<packages>.

=attr namespace

Exclude everything under a specific namespace. Example: C<My::Package>. 
Alias: C<namespaces>.

B<NOTE:> This will not exclude the package C<My::Package>, only everything
under it like C<My::Package::Foo>.

=cut

for ( keys %ATTR_ALIAS ) {
    has $ARG => (
        is        => 'ro',
        isa       => 'ArrayRef[Str]',
        init_arg  => $ARG,
        predicate => "_has_$ARG",
    );
}

=method metadata

Returns a reference to a hash containing the distribution's no_index metadata.

=cut

sub metadata {
    my $self = shift;
    return {
        no_index => {
            map { $ARG => $self->$ARG }
                grep { my $method = "_has_$ARG"; $self->$method }
                keys %ATTR_ALIAS
        }
    };
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;

__END__

=head1 SYNOPSIS

In your F<dist.ini>:

  [MetaNoIndex]
  directory = author.t
  directory = examples
  file = lib/Foo.pm
  package = My::Module
  namespace = My::Module

=head1 DESCRIPTION

This plugin allows you to prevent PAUSE/CPAN from indexing files you don't
want indexed. This is useful if you build test classes or example classes
that are used for those purposes only, and are not part of the distribution.
It does this by adding a C<no_index> block to your F<META.yml> file in your
distribution.

=head1 SUPPORT

=over

=item Repository

L<http://github.com/rizen/Dist-Zilla-Plugin-MetaNoIndex>

=item Bug Reports

L<http://rt.cpan.org/Public/Dist/Display.html?Name=Dist-Zilla-Plugin-MetaNoIndex>

=back

=head1 SEE ALSO

L<Dist::Zilla>
