use 5.006;    # our
use strict;
use warnings;

package Gentoo::App::PerlInfo;

our $VERSION = '0.17';

# ABSTRACT: gather systems perl info

# AUTHORITY

use Term::ANSIColor;
use PortageXS v0.3.0;
use Path::Tiny qw( path );
use Digest::SHA1 qw( sha1_hex );
use Config qw( %Config );

sub new {
    my ( $class, @args ) = @_;
    my $config = { ref $args[0] ? %{ $args[0] } : @args };
    my $self = bless $config, $class;
    $self->{config_vars} = [ $self->default_config_vars ]
      unless exists $self->{config_vars};
    $self->{_pxs} = PortageXS->new() unless exists $self->{_pxs};
    return $self;
}

sub new_with_args {
    my ( $class, @args ) = @_;

    # TODO: Handle options here.
    return $class->new();
}

sub default_config_vars {
    qw(osname osvers archname uname useposix usethreads use5005threads
      useithreads usemultiplicity useperlio uselargefiles usesocks use64bitint
      use64bitall uselongdouble usemymalloc bincompat5005 cc ccflags optimize
      cppflags ccversion gccversion gccosandver intsize longsize ptrsize doublesize
      byteorder d_longlong longlongsize d_longdbl longdblsize ivtype ivsize nvtype
      nvsize Off_t lseeksize alignbytes prototype ld ldflags libpth libs perllibs
      libc so useshrplib libperl gnulibc_version dlsrc dlext d_dlsymun ccdlflags
      cccdlflags lddlflags);
}

sub package_installed {
    my ( $self, $name ) = @_;
    my (@results) = $self->_pxs->searchInstalledPackage($name);
    if ( not @results ) {
        return 'not installed';
    }
    return sprintf q[%s %s], $results[0], $self->use_for( $results[0] );
}

sub use_for {
    my ( $self, $name ) = @_;
    my (@use) = $self->_pxs->getUseSettingsOfInstalledPackage($name);
    return sprintf q[USE="%s"], join q[ ], @use;
}

sub eclass_desc {
    my ( $self, $eclassName ) = @_;
    my $eclass = path( $self->_pxs->portdir(), "eclass", "$eclassName.eclass" );
    if ( !-e $eclass ) {
        return "does not exist";
    }
    my $content = $eclass->slurp();
    my @parts;
    if ( $content =~ /\A\s*#\s*Copyright\s*\d+-(\d+)\s*Gentoo\s*Foundation/ ) {
        push @parts, sprintf q[year: %4s], $1;
    }
    unshift @parts, sprintf q[sha1: %36s], sha1_hex($content);
    return join q[ ], @parts;
}

sub _pxs        { $_[0]->{_pxs} }
sub config_vars { $_[0]->{config_vars} }

sub perl_config {
    my @out;
    for my $var ( sort @{ $_[0]->config_vars } ) {
        if ( exists $Config{$var} and defined $Config{$var} ) {
            push @out, $var . '="' . $Config{$var} . '"';
        }
        elsif ( exists $Config{$var} ) {
            push @out, $var . '=undef';
        }
        else {
            push @out, $var . ': does not exist';
        }
    }
    return @out;
}
1;

__END__

=head1 NAME

Gentoo::App::PerlInfo - gather systems perl info

=head1 SYNOPSIS

perl-info

=head1 DESCRIPTION

perl-info shall help developers getting sufficient information about the
users perl installation when needed.

=head1 ARGUMENTS

perl-info does not have any arguments yet.

=head1 AUTHOR

Christian Hartmann <ian@gentoo.org>

=head1 LICENSE

This software is copyright (C) 2006, 2007  Christian Hartmann

This program is free software; you can redistribute it and/or modify
it under the terms of The GNU General Public License, Version 2,
or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA

=cut
