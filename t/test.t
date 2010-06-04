#!perl

use Cwd;
use Dist::Zilla::Tester 4.101550;
use Data::PowerSet 'powerset';
use English '-no_match_vars';
use File::Temp;
use Modern::Perl;
use Path::Class qw(dir file);
use Test::Most;
use Test::Moose;
use Text::Template;
use Readonly;

our $MODULE;
my $tests = 3;

Readonly my %TEST_ATTR => (
    file => {
        values  => [qw(My/Module.pm My/Module2.pm)],
        aliases => ['files'],
    },
    directory => {
        values  => [qw(My/Private My/Private2)],
        aliases => [qw(dir directories folder)],
    },
    package => {
        values  => [qw(My::Module::Stuff My::Module::Things)],
        aliases => [qw(class module packages)],
    },
    namespace => {
        values  => [qw(My::Module::Stuff My::Module::Things)],
        aliases => ['namespaces'],
    },
);

BEGIN {
    Readonly our $MODULE => 'Dist::Zilla::Plugin::MetaNoIndex';
    use_ok($MODULE);
}
isa_ok( $MODULE, 'Moose::Object', $MODULE );
can_ok( $MODULE, 'metadata' );

for ( keys %TEST_ATTR ) {
    has_attribute_ok( $MODULE, $ARG, "has $ARG attribute" );
}
$tests += keys %TEST_ATTR;

my $dist_dir = File::Temp->newdir();
my $ini_template
    = Text::Template->new( type => 'string', source => <<'END_INI');
name     = test
author   = test user
abstract = test release
license  = BSD
version  = 1.0
copyright_holder = test holder

[MetaNoIndex]
{$ini_lines}
END_INI

my ( @test_sets, %attr_for );
while ( my ( $attr, $info ) = each %TEST_ATTR ) {
    push @test_sets, { $attr => $info->{values} }, map {
        { $ARG => $info->{values} }
    } @{ $info->{aliases} };

    %attr_for = ( %attr_for, map { $ARG => $attr } @{ $info->{aliases} } );
}
@test_sets = @{ powerset(@test_sets) };
$tests += @test_sets;

for my $set_ref (@test_sets) {
    my $ini_lines;
    for my $line ( @{$set_ref} ) {
        for ( values %{$line} ) {
            for my $value ( @{$ARG} ) {
                $ini_lines .= ( keys %{$line} )[0] . " = $value\n";
            }
        }
    }

    my $zilla = Dist::Zilla::Tester->from_config(
        { dist_root => "$dist_dir" },
        {   add_files => {
                'source/dist.ini' => $ini_template->fill_in(
                    hash => { ini_lines => $ini_lines },
                ),
            },
        },
    );
    lives_and(
        sub {
            my %expected;
            for ( @{$set_ref} ) {
                my $key = ( keys %{$ARG} )[0];
                if ( exists $attr_for{$key} ) {
                    $key = $attr_for{$key};
                }
                push @{ $expected{$key} }, @{ ( values %{$ARG} )[0] };
            }
            eq_or_diff( $zilla->distmeta->{no_index}, \%expected );
        },
        join q{, },
        map { ( keys %{$ARG} )[0] } @{$set_ref}
    );
}
done_testing($tests);
