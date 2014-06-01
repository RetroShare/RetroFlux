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
use HTML::Template;
use CGI ('param');
use CGI::Session;
use URI::Escape;
use Data::Dumper;
use lib 'lib';
use Google::ProtocolBuffers;
use retrofunc;

Google::ProtocolBuffers->parsefile("proto/peers.proto", { include_dir => 'proto', create_accessors => 1 } );

my $cgi = CGI->new();
my $session = CGI::Session->new () or die CGI::Session->errstr;
my $template = HTML::Template->new(filename => 'template/peers.tmpl');
retrofunc::loadDefaultTemplateParams($template);
$template->param(SORTICONLINK => retroconfig::getSortIconlink());

my @loop_peers = ();
my $cnt_connectedpeers;
my $cnt_friendspeers;
my $cnt_listedpeers;
my $cnt_peers;
my $friendspeers;
my $connectedpeers;
my $listedpeers;

retrofunc::ssh2Connect();

if($cgi->param()) {
   my $action = $cgi->param('action');
   my $gpg_id = $cgi->param('gpgid');
   if($action && $gpg_id) {
     if($gpg_id =~ /\b[0-9A-F]{16}\b/) {
       if($action eq "addpeer") {
          retrofunc::addPeer($gpg_id);
       }
       if($action eq "removepeer") {
          retrofunc::removePeer($gpg_id);
       }
     }
   }
}

$friendspeers = retrofunc::getPeersList("FRIENDS");
$connectedpeers = retrofunc::getPeersList("CONNECTED");
$listedpeers = retrofunc::getPeersList("LISTED");
retrofunc::ssh2Disconnect();
listPeers();

#$template->param(CNTFRIENDSPEERS => $cnt_friendspeers);
$template->param(CNTCONNECTEDPEERS => $cnt_connectedpeers);
#$template->param(CNTLISTEDPEERS => $cnt_listedpeers);
$template->param(CNTPEERS => $cnt_peers);
$template->param(PEERS => \@loop_peers);

print retrofunc::getContentTypeString();
print $template->output;

sub listPeers {
    my %peers_hash;
    if($friendspeers->peers) {
     for my $resfripeer ( $friendspeers->peers ) {
       $cnt_friendspeers = scalar @$resfripeer;
       for my $fripeer ( @$resfripeer ) {
        $peers_hash{$fripeer->gpg_id}{'name'} = $fripeer->name;
        $peers_hash{$fripeer->gpg_id}{'relation'} = $fripeer->relation;
        $peers_hash{$fripeer->gpg_id}{'status'} = 'OFFLINE';
       }
     }
    }
    
    if ($connectedpeers->peers) {
     for my $resconpeer ( $connectedpeers->peers ) {
       $cnt_connectedpeers = scalar @$resconpeer;
       for my $conpeer ( @$resconpeer ) {
        $peers_hash{$conpeer->gpg_id}{'name'} = $conpeer->name;
        $peers_hash{$conpeer->gpg_id}{'relation'} = $conpeer->relation;
        $peers_hash{$conpeer->gpg_id}{'status'} = 'ONLINE';
       }
     }
    }
    
    if ($listedpeers->peers) {
     for my $reslispeer ( $listedpeers->peers ) {
       $cnt_listedpeers = scalar $reslispeer;
       for my $lispeer ( @$reslispeer ) {
        $peers_hash{$lispeer->gpg_id}{'name'} = $lispeer->name;
        $peers_hash{$lispeer->gpg_id}{'relation'} = $lispeer->relation;
        $peers_hash{$lispeer->gpg_id}{'status'} = 'ONLINE';
       }
     }
    }
    
    for my $respeer ( keys %peers_hash ) {
        my %row_data;
        $row_data{PEERNAME} = $peers_hash{$respeer}{'name'};
        $row_data{PEERGPG} = $respeer;
        $row_data{PEERREL} = $peers_hash{$respeer}{'relation'};
        $row_data{PEERSTAT} = $peers_hash{$respeer}{'status'};
        push(@loop_peers, \%row_data);
    }
    
    $cnt_peers = scalar @loop_peers;
}
