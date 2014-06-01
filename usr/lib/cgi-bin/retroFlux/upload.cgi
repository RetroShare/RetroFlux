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
use CGI ('param');
use CGI::Session;
use Number::Bytes::Human qw(format_bytes);
use HTML::Template;
use URI::Escape;
use Data::Dumper;
use lib 'lib';
use Google::ProtocolBuffers;
use retrofunc;

Google::ProtocolBuffers->parsefile("proto/files.proto", { include_dir => 'proto', create_accessors => 1 } );

my @loop_data = ();
my $session = CGI::Session->new () or die CGI::Session->errstr;
my $template = HTML::Template->new(filename => 'template/upload.tmpl');
retrofunc::loadDefaultTemplateParams($template);
$template->param(SORTICONLINK => retroconfig::getSortIconlink());

retrofunc::ssh2Connect();
my @dwnlist = retrofunc::getUploadList();
retrofunc::ssh2Disconnect();
my $dwnarray = shift @dwnlist;
#print Dumper $dwnarray;
my %dwnhash;
    
for my $dwnerg (@$dwnarray) {
  $dwnhash{$dwnerg->file->hash}{'name'} = $dwnerg->file->name;
  $dwnhash{$dwnerg->file->hash}{'size'} = $dwnerg->file->size;
  $dwnhash{$dwnerg->file->hash}{'rate'} = $dwnerg->rate_kBs;
  $dwnhash{$dwnerg->file->hash}{'fraction'} = $dwnerg->fraction*100;
}

my $rows;
if (%dwnhash) {
    $rows = keys( %dwnhash );
} else {
    $rows = 0;
}

# Show Number of Results
$template->param(ROWS => $rows); 

# If Results found then go through, if not break
if($rows) {

   for my $ergeb (keys %dwnhash) {
          my %row_data;
          my $fname = $dwnhash{$ergeb}{'name'};
          my $aname = uri_escape($fname);
          my $fsize = $dwnhash{$ergeb}{'size'};
          my $frate = sprintf "%.2f", $dwnhash{$ergeb}{'rate'};
          my $ffrac = sprintf "%.2f", $dwnhash{$ergeb}{'fraction'};

          $row_data{RESNAME} = $fname;
          #$row_data{RESLINK} = "retroshare://file?name=".$aname."&size=".$fsize."&hash=".$ergeb; 
          #$row_data{RESSIZE} = $fsize;
          $row_data{RESFORMATSIZE} = format_bytes($fsize);
          $row_data{RESHASH} = $ergeb;
          $row_data{RESRATE} = $frate." KB/s";
          #$row_data{RESFRAC} = $ffrac." %";
          #$row_data{STOPGRAYLINK} = getShareStopGraylink();
          #$row_data{STOPBLUELINK} = getShareStopBluelink();
          
          push(@loop_data, \%row_data);
      }
}

$template->param(RESULTS => \@loop_data);

print retrofunc::getContentTypeString();
print $template->output;