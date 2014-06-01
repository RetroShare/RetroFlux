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
use HTML::Template::Expr;
use CGI ('param');
use CGI::Session;
use URI::Escape;
use Data::Dumper;
use lib 'lib';
use Google::ProtocolBuffers;
use retrofunc;

Google::ProtocolBuffers->parsefile("proto/chat.proto", { include_dir => 'proto', create_accessors => 1 } );

my $cgi = CGI->new();
my $session = CGI::Session->new () or die CGI::Session->errstr;
my $template = HTML::Template::Expr->new(filename => 'template/chatlobby.tmpl');
retrofunc::loadDefaultTemplateParams($template);
$template->param(SORTICONLINK => retroconfig::getSortIconlink());

my @loop_chatlobbies = ();
my $chatlobbies;
my $cnt_chatlobby;
my $cnt_chatlobbies;

retrofunc::ssh2Connect();
$chatlobbies = retrofunc::getChatlobbies();
# print Dumper $chatlobbies;
retrofunc::ssh2Disconnect();
createChatLobbyList();
$template->param(CNTCHATS => $cnt_chatlobbies);
$template->param(CHATLOBBIES => \@loop_chatlobbies);

print retrofunc::getContentTypeString();
print $template->output;

sub createChatLobbyList {
    my %chatlobby_hash;
    if($chatlobbies->lobbies) {
     for my $reschatlobby ( $chatlobbies->lobbies ) {
       $cnt_chatlobby = scalar @$reschatlobby;
       for my $chatlobby ( @$reschatlobby ) {
        $chatlobby_hash{$chatlobby->lobby_id}{'name'} = $chatlobby->lobby_name;
        $chatlobby_hash{$chatlobby->lobby_id}{'topic'} = $chatlobby->lobby_topic;
        $chatlobby_hash{$chatlobby->lobby_id}{'nopeers'} = $chatlobby->no_peers;
        $chatlobby_hash{$chatlobby->lobby_id}{'state'} = $chatlobby->lobby_state;
       }
     }
    }
    
    for my $reschatlobby ( keys %chatlobby_hash ) {
        my %row_data;
        $row_data{CHATLOBBYID} = $reschatlobby;
        $row_data{CHATLOBBYNAME} = $chatlobby_hash{$reschatlobby}{'name'};
        $row_data{CHATLOBBYNOPEERS} = $chatlobby_hash{$reschatlobby}{'nopeers'};
        $row_data{CHATLOBBYTOPIC} = $chatlobby_hash{$reschatlobby}{'topic'};
        $row_data{CHATLOBBYSTATE} = $chatlobby_hash{$reschatlobby}{'state'};
        push(@loop_chatlobbies, \%row_data);
    }
    
    $cnt_chatlobbies = scalar @loop_chatlobbies;
}
