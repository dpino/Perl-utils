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

# Reads a .pot file and translates it (output is a .po file) using the Google Translate API
# Warning: You need a Google Translate API KEY_CODE in order to use this script

use Data::Dumper;
use LWP::Simple;
use Date::Format;
use JSON;

use utf8;

# Read parameters
my $API_KEY = "";
my $LANG_ORIG = "en";
my $LANG_DEST = "es";
my $FILENAME = "";
while (my $arg = shift @ARGV) {
    if ($arg eq "-o" || $arg eq "--orig") {
        $arg = shift @ARGV;
        $LANG_ORIG = $arg;
        next;
    }
    if ($arg eq "-d" || $arg eq "--dest") {
        $arg = shift @ARGV;
        $LANG_DEST= $arg;
        next;
    }
    if ($arg eq "-k" || $arg eq "--key") {
        $arg = shift @ARGV;
        $API_KEY = $arg;
        next;
    }
    if ($arg eq "-h" || $arg eq "--help") {
        help();
        exit();
    }
    $FILENAME = $arg;
}

if ($FILENAME eq "" || $API_KEY eq "") {
    help();
    exit();
}

# Read .po file and translate
if (!(-f $FILENAME)) {
    print "$FILENAME not found\n";
    exit();
}

my $URL = "https://www.googleapis.com/language/translate/v2?key=$API_KEY&ie=UTF8&q=###QUERY###&source=###LANG_ORIG###&target=###LANG_DEST###";
my $entries = {};

my $content = readfile($FILENAME);
insert_entries(split "\n", $content);
default_po_header();
translate_entries(values(%{$entries}));

# Print default PO header
sub default_po_header()
{
    my $creation_date = time2str("%Y-%m-%d %H:%M %z", time);

    # Create file
print qq#\# SOME DESCRIPTIVE TITLE.
\# Copyright (C) YEAR THE PACKAGE'S COPYRIGHT HOLDER
\# This file is distributed under the same license as the PACKAGE package.
\# FIRST AUTHOR <EMAIL\@ADDRESS>, YEAR.
\#

"Project-Id-Version: PACKAGE VERSION\\n"
"Report-Msgid-Bugs-To: \\n"
"POT-Creation-Date: $creation_date\\n"
"PO-Revision-Date: YEAR-MO-DA HO:MI+ZONE\\n"
"Last-Translator: FULL NAME <EMAIL\@ADDRESS>\\n"
"Language-Team: LANGUAGE <LL\@li.org>\\n"
"MIME-Version: 1.0\\n"
"Content-Type: text/plain; charset=CHARSET\\n"
"Content-Transfer-Encoding: 8bit\\n"
\n#;
}

# Read .pot file and insert keys (msgid, msgstr, comments) into a hash array
sub insert_entries {
    my(@lines) = @_;

    my $in_msgid = 0;
    foreach $line (@lines) {
        if ($line =~ /^#:/) {
            $comments .= $line."\n";             
            next;
        }
        if ($line =~ /^msgid\s+(.*)$/) {
            $msgid = $1;
            $in_msgid = 1;
            next;
        }
        if ($line =~ /^msgstr "(.*)"/) {
            $msgstr = $1;
            $entry = create_entry($msgid, $msgstr, $comments);
            insert_entry($entry);

            $comments = ""; 
            $msgid = "";
            $in_msgid = 0;
            next;
        }
        if ($in_msgid) {
            $msgid .= "\n".$line;
        }
    }

}

# Translate entries read from .pot file and print them
sub translate_entries
{
    my(@entries) = @_; 

    foreach my $entry (@entries) {
        $msgstr = translate(format_msgid($entry->{'msgid'}));
        print $entry->{'comments'};
        print "msgid ".$entry->{'msgid'}."\n";
        print "msgstr \"".$msgstr."\"\n";
        print "\n";
    }
}

sub translate
{
    my($query) = @_;
    my $url = $URL;

    $url =~ s/###QUERY###/$query/;
    $url =~ s/###LANG_ORIG###/$LANG_ORIG/;
    $url =~ s/###LANG_DEST###/$LANG_DEST/;

    my $content = get $url;
    my $result = from_json($content);
    my $translation = $result->{'data'}{'translations'}[0];
    my $translatedText = $translation->{'translatedText'};

    return $translatedText;
}

sub format_msgid
{
    my($msgid) = @_;

    $msgid =~ s/"\n"//g;   
    $msgid =~ s/^"//g;   
    $msgid =~ s/"$//g;   
    $msgid =~ s/\%/0x25/g;
    return $msgid;
}

sub help
{
    print "translate <filename> [-k|--key] GOOGLE_TRANSLATE_API_KEY [-o|--orig <orig_lang>] [-d|--dest <dest_lang>]\n";
    print "translate <filename> [-o|--orig <orig_lang>] [-d|--dest <dest_lang>]\n";
    print "\t-k|--key\tGoogle Translate API Key\n";
    print "\t-o|--orig\tOrigin lang ISO code\n";
    print "\t-d|--dest\tDestination lang ISO code\n\n";
    print "Example: translate -k API_KEY -o en -d es keys.pot\n\n";
}

sub create_entry
{
    my($msgid, $msgstr, $comments) = @_;

    my $entry = {};  
    $entry->{'msgid'} = $msgid;
    $entry->{'msgstr'} = $msgstr;
    $entry->{'comments'} = $comments;

    return $entry;
}

sub insert_entry
{
    my($entry) = @_;   

    my $msgid = $entry->{'msgid'};
    if ($entries->{$msgid} == undef) {
        $entries->{$msgid} = $entry;
    }
}

sub readfile
{
    my($filename) = @_;
    my $content = "";

    open FILE, "<$filename";
    while (<FILE>) {
        $content .= $_;
    }
    close FILE;

    return $content;
}
