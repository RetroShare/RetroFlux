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
use CGI ('param');
use CGI::Session;
use lib 'lib';
use Google::ProtocolBuffers;
use retrofunc;

Google::ProtocolBuffers->parsefile("proto/files.proto", { include_dir => 'proto', create_accessors => 1 } );

my $cgi = CGI->new();
my $session = CGI::Session->new () or die CGI::Session->errstr;
my $action;
my $rscname;
my $filename;
my $filesize;
my $filehash;
my $returnvalue;
my %data;
my @fileparameter;

if($cgi->param()) {
   $action = $cgi->param('action');
   if($action) {
       if($action eq "startdownload") {
          $filename = $cgi->param('name');
          $filesize = $cgi->param('size');
          $filehash = $cgi->param('hash');
          if($filename && $filesize && $filehash) {
             @fileparameter = ($filename, $filesize, $filehash);
             retrofunc::ssh2Connect();
             $returnvalue = retrofunc::startDownloadFile(@fileparameter);
             retrofunc::ssh2Disconnect();
             %data = ('status' => $returnvalue, 'name' => $filename, 'size' => $filesize, 'hash' => $filehash);
          } else {
             %data = ('status' => 0, 'name' => $filename, 'size' => $filesize, 'hash' => $filehash);
          }
       } elsif ($action eq "startdownloadallfiles") {
         my $tmp_allfiles = $cgi->param('allfiles');
         my $allfiles_string = uri_unescape($tmp_allfiles);
         my $allfiles_string_tmp;
         my %hash_allfiles;
         my @array_allfiles = split(/downloadFile/, $allfiles_string);
         #$allfiles_string =~ /downloadFile\((.*)\)/g;
         foreach my $tmp_arrayallfile (@array_allfiles) {
             if($tmp_arrayallfile =~ /\((.+)\)/) {
                my ($allf_name, $allf_size, $allf_hash) = split(/,/,$1);
                $allf_name =~ s/^'|'$//g;
                $allf_size =~ s/^'|'$//g;
                $allf_hash =~ s/^'|'$//g;
                $hash_allfiles{$allf_hash}{'name'} = $allf_name;
                $hash_allfiles{$allf_hash}{'size'} = $allf_size;
             }
         }
         
         my @return_allfiles;
         retrofunc::ssh2Connect();
         for my $tmp_hashallf (keys %hash_allfiles) {
             my @tmp_arrayallf = ($hash_allfiles{$tmp_hashallf}{'name'}, $hash_allfiles{$tmp_hashallf}{'size'}, $tmp_hashallf);
             push(@return_allfiles, $tmp_hashallf);
             $returnvalue += retrofunc::startDownloadFile(@tmp_arrayallf);
         }
         retrofunc::ssh2Disconnect();
         
         #my $tmp_arrayallfiles = join('#', $allfiles_string);
         %data = ('status' => $returnvalue, 'hashes' => [ @return_allfiles ]); 
       } elsif ($action eq "stopdownload") {
          $filename = $cgi->param('name');
          $filesize = $cgi->param('size');
          $filehash = $cgi->param('hash');
          if($filename && $filesize && $filehash) {
            @fileparameter = ($filename, $filesize, $filehash);
            retrofunc::ssh2Connect();
            $returnvalue = retrofunc::stopDownloadFile(@fileparameter);
            retrofunc::ssh2Disconnect();
            %data = ('status' => $returnvalue, 'name' => $filename, 'size' => $filesize, 'hash' => $filehash);
          } else {
            %data = ('status' => 0, 'name' => $filename, 'size' => $filesize, 'hash' => $filehash);
          }
       } elsif ($action eq "pausedownload") {
          $filename = $cgi->param('name');
          $filesize = $cgi->param('size');
          $filehash = $cgi->param('hash');
          if($filename && $filesize && $filehash) {
            @fileparameter = ($filename, $filesize, $filehash);
            retrofunc::ssh2Connect();
            $returnvalue = retrofunc::pauseDownloadFile(@fileparameter);
            retrofunc::ssh2Disconnect();
            %data = ('status' => $returnvalue, 'name' => $filename, 'size' => $filesize, 'hash' => $filehash);
          } else {
            %data = ('status' => 0, 'name' => $filename, 'size' => $filesize, 'hash' => $filehash);
          }
       } elsif ($action eq "restartdownload") {
          $filename = $cgi->param('name');
          $filesize = $cgi->param('size');
          $filehash = $cgi->param('hash');
          if($filename && $filesize && $filehash) {
            @fileparameter = ($filename, $filesize, $filehash);
            retrofunc::ssh2Connect();
            $returnvalue = retrofunc::restartDownloadFile(@fileparameter);
            retrofunc::ssh2Disconnect();
            %data = ('status' => $returnvalue, 'name' => $filename, 'size' => $filesize, 'hash' => $filehash);
          } else {
            %data = ('status' => 0, 'name' => $filename, 'size' => $filesize, 'hash' => $filehash);
          }
       } else {
          %data = ('status' => 0, 'name' => $filename, 'size' => $filesize, 'hash' => $filehash);
       }
     
      my $json_text = to_json(\%data);
      print retrofunc::getContentTypeString();
      print $json_text;
   }
}