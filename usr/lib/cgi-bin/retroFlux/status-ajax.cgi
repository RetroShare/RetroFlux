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
use JSON;
use CGI::Session;
use lib 'lib';
use Google::ProtocolBuffers;
use retrofunc;

Google::ProtocolBuffers->parsefile("proto/system.proto", { include_dir => 'proto', create_accessors => 1 } );

my $session = CGI::Session->new () or die CGI::Session->errstr;
retrofunc::ssh2Connect();
my $ressys = retrofunc::getSystemStatus();
retrofunc::ssh2Disconnect();
my $bawi = $ressys->bw_total;
my %data = ('peers' => $ressys->no_peers,
            'connected' => $ressys->no_connected,
            'netstatus' => $ressys->net_status,
            'download' => sprintf("%.2f",$bawi->down),
            'upload' => sprintf("%.2f",$bawi->up),
           );
my $json_text = to_json(\%data);

print retrofunc::getContentTypeString();
print $json_text;