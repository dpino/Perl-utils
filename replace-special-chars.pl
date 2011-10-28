#!/usr/bin/perl

# Copyright (C) 2011 Diego Pino García <dpino@igalia.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor,
# Boston, MA  02110-1301, USA.

# Replaces special characters (á, à, â, etc) for a simple form (a)

use strict;

if (scalar @ARGV == 0) {
    error("replace-special-chars <filename>");
}

my $filename = shift @ARGV;
if (!(-f $filename)) {
    error("$filename doesn't exist");
}

open FILE, "<$filename";
while (<FILE>) {
    print replace_special_chars($_);
}
close FILE;

sub replace_special_chars
{
    my($str) = @_;

    my %specials = (
        'á' => 'a', 'é' => 'e', 'í' => 'i', 'ó' => 'o', 'ú' => 'u', 'à' => 'a', 'è' => 'e', 'ì' => 'i', 'ò' => 'o', 'ù' => 'u', 'ä' => 'a', 'ë' => 'e', 'ï' => 'i', 'ö' => 'o', 'ü' => 'u', 'â' => 'a', 'ê' => 'e', 'î' => 'i', 'ô' => 'o', 'û' => 'u', 'Á' => 'A', 'É' => 'E', 'Í' => 'I', 'Ó' => 'O', 'Ú' => 'U', 'À' => 'A', 'È' => 'E', 'Ì' => 'I', 'Ò' => 'O', 'Ù' => 'U', 'Ä' => 'A', 'Ë' => 'E', 'Ï' => 'I', 'Ö' => 'O', 'Ü' => 'U', 'Â' => 'A', 'Ê' => 'E', 'Î' => 'I', 'Ô' => 'O', 'Û' => 'U', 'ñ' => 'n', 'Ñ' => 'N', 'ç' => 'c', 'Ç' => 'C', 'ã' => 'a',
    );

    while (my($key, $value) = each(%specials)) {
        $str =~ s/$key/$value/g; 
    }
    return $str;
}

sub error
{
    my($str) = @_;

    print "$str\n";
    exit();
}
