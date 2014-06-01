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
use CGI::Session;
use URI::Escape;
use XML::LibXML;
use Data::Dumper;
use CGI ('param');
use lib 'lib';
use retrofunc;
use retroconfig;

my $dtd = XML::LibXML::Dtd->new('RsCollection', retroconfig::getRSCSchemaFile());
#my $xml = XML::LibXML->new();
my $cgi = CGI->new();
my @loop_data = ();
my ($action, $dom, $rscfile, $rscdata, $filename, $filesize, $filehash, @fileparameter, $returnvalue, %data);

my $session = CGI::Session->new () or die CGI::Session->errstr;
my $template = HTML::Template->new(filename => 'template/collection.tmpl');
retrofunc::loadDefaultTemplateParams($template);
#$template->param(SEARCHDOWNBLUEICON => retroconfig::getSearchDownBluelink());
$template->param(SORTICONLINK => retroconfig::getSortIconlink());

if($cgi->param()) {
   $rscfile = $cgi->param('rscfile');
   if($rscfile) {
      while (<$rscfile>) {
         $rscdata .= $_;  
      }
      
      my $xml_node_rows = 0;
      my $tmp_str;
      
      eval { $dom = XML::LibXML->load_xml(string => $rscdata) };
      unless($@) {
        eval { $dom->validate($dtd) };
        unless($@) {
        #if ($dom->validate($dtd)) {  
          
          my $xml_root = $dom->getDocumentElement;
          $tmp_str = $xml_root;
          #$tmp_str = $dom->validate($dtd);
          
          for my $xml_node ($xml_root->findnodes('//*[@sha1]')) {
             my %row_data;
             #$tmp_str .= $xml_node."<br>";
             my $xml_file_name = $xml_node->getAttribute('name');
             my $xml_file_size = $xml_node->getAttribute('size');
             my $xml_file_hash = $xml_node->getAttribute('sha1');
             $row_data{RESNAME} = $xml_file_name;
             $row_data{RESESCNAME} = uri_escape($xml_file_name);
             #$row_data{RESLINK} = "retroshare://file?name=".$aname."&size=".$fsize."&hash=".$ergeb;
             $row_data{RESSIZE} = $xml_file_size;
             $row_data{RESFORMATSIZE} = format_bytes($xml_file_size);
             $row_data{RESHASH} = $xml_file_hash;
             push(@loop_data, \%row_data);
             $xml_node_rows += 1;
          }
        }
      }
      
      # Show Number of Results
      $template->param(ROWS => $xml_node_rows);
      $template->param(RSCFILENAME => $rscfile);
      $template->param(ERRORMSG => $@);
   }
}

$template->param(RESULTS => \@loop_data);

print retrofunc::getContentTypeString();
print $template->output;