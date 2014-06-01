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
use URI::Escape;
use Data::Dumper;
use CGI ('param');
use CGI::Session;
use lib 'lib';
use Google::ProtocolBuffers;
use retrofunc;

Google::ProtocolBuffers->parsefile("proto/peers.proto", { include_dir => 'proto', create_accessors => 1 } );

my $cgi = CGI->new();
my $session = CGI::Session->new () or die CGI::Session->errstr;
my $action;
my $rscname;
my $gpgid;
my $returnvalue;
my %data;

if($cgi->param()) {
   my $action = $cgi->param('action');
   my $gpg_id = $cgi->param('gpgid');
   if($action && $gpg_id) {
     if($gpg_id =~ /\b[0-9A-F]{16}\b/) {
       if($action eq "removepeer") {
          retrofunc::ssh2Connect();
          $returnvalue = retrofunc::removePeer($gpg_id);
          #print Dumper $returnvalue->status->code;
          retrofunc::ssh2Disconnect();
          %data = ('status' => $returnvalue->status->code, 'gpgid' => $gpg_id);
       } else {
         %data = ('status' => 0, 'gpgid' => $gpg_id);
       }
       my $json_text = to_json(\%data);
       print retrofunc::getContentTypeString();
       print $json_text;
     }
   }
}