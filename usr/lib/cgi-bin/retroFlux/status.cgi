#!/usr/bin/perl

###############################################################################
# RetroFlux 0.6.1      
# http://sourceforge.net/projects/retroflux/
#                   
# Copyright 2013 bolek 
#
# This file is part of RetroFlux.
#
# RetroFlux is free software: you can redistribute it and/or modify
# it under the terms of the GNU Lesser General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# RetroFlux is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public License
# along with RetroFlux.  If not, see <http://www.gnu.org/licenses/>.
#
# Diese Datei ist Teil von RetroFlux.
#
# RetroFlux ist Freie Software: Sie können es unter den Bedingungen
# der GNU Lesser General Public License, wie von der Free Software Foundation,
# Version 3 der Lizenz oder (nach Ihrer Wahl) jeder späteren
# veröffentlichten Version, weiterverbreiten und/oder modifizieren.
#
# RetroFlux wird in der Hoffnung, dass es nützlich sein wird, aber
# OHNE JEDE GEWÄHELEISTUNG, bereitgestellt; sogar ohne die implizite
# Gewährleistung der MARKTFÄHIGKEIT oder EIGNUNG FÜR EINEN BESTIMMTEN ZWECK.
# Siehe die GNU Lesser General Public License für weitere Details.
#
# Sie sollten eine Kopie der GNU Lesser General Public License zusammen mit diesem
# Programm erhalten haben. Wenn nicht, siehe <http://www.gnu.org/licenses/>.
###############################################################################

use strict;
#use warnings;
use utf8;
use Number::Bytes::Human qw(format_bytes);
use CGI::Session;
use HTML::Template;
use URI::Escape;
use Data::Dumper;
use lib 'lib';
use Google::ProtocolBuffers;
use retrofunc;

Google::ProtocolBuffers->parsefile("proto/system.proto", { include_dir => 'proto', create_accessors => 1 } );

my $session = CGI::Session->new () or die CGI::Session->errstr;
my $template = HTML::Template->new(filename => 'template/status.tmpl');
retrofunc::loadDefaultTemplateParams($template);

retrofunc::ssh2Connect();
my $ressys = retrofunc::getSystemStatus();
my %resfs  = retrofunc::getFSDiscSpaceInfo();
my @loop_fsdata;

#print Dumper @loop_fsdata;
retrofunc::ssh2Disconnect();
# Bandwidth
my $bawi = $ressys->bw_total;

for my $dirpath (keys %resfs) {
    my %row_data;
    $row_data{FSPATH} = $dirpath;
    $row_data{FSFREE} = format_bytes($resfs{$dirpath}{'bfree'});
    $row_data{FSUSED} = format_bytes($resfs{$dirpath}{'used'});
    $row_data{FSTOTAL} = format_bytes($resfs{$dirpath}{'blocks'});
    $row_data{FSPERCENT} = $resfs{$dirpath}{'per'}." %";
    push(@loop_fsdata, \%row_data);
}

$template->param(PEERS => $ressys->no_peers);
$template->param(CONNECTED => $ressys->no_connected);
$template->param(NETSTATUS => $ressys->net_status);
$template->param(BANDWDWN => sprintf("%.2f",$bawi->down));
$template->param(BANDWUP => sprintf("%.2f",$bawi->up));
$template->param(FSDISCSPACE => \@loop_fsdata);

print retrofunc::getContentTypeString();
print $template->output;