package retroconfig;

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
use utf8;

open (configfile, "<config.cgi") || die $!;
my @cfg_file = <configfile>;
chomp @cfg_file;
close (configfile);
my %cfg_data;

foreach (@cfg_file) {
   unless(/^#/) {
     my ($cfg_key,$cfg_value) = split(/=/, $_);
     $cfg_data{$cfg_key} = $cfg_value;
   }
}

my @rs_fsdirectories = split(/;/, $cfg_data{fsdirs});
chomp @rs_fsdirectories;

my $rs_host = $cfg_data{rshost};
my $rs_port = $cfg_data{rsport};
my $rs_user = $cfg_data{rsuser};
my $rs_pass = $cfg_data{rspass};
my $rs_dwndir = $cfg_data{rsdwndir} =~ /\/$/ ? $cfg_data{rsdwndir} : $cfg_data{rsdwndir}."/";

my $rs_magicid = 0x137F0001;
my $rs_headsize = 16;
my $rf_pagetitle = "RetroFlux";
my $rf_version = "0.6.1";
my $rf_progname = "RETRO<span class='bold'>FLUX<span> ".$rf_version;
my $rf_timeoutperiod = 10000;
my $rf_resultlimit = 1000;
my $rf_webdir = "../../retroFlux";
my $rf_stylesheetlink = $rf_webdir."/css/layout.css";
my $rf_jsajax = $rf_webdir."/js/ajax.js";
my $rf_jstextutils = $rf_webdir."/js/text-utils.js";
my $rf_jsrffunc = $rf_webdir."/js/rf-func.js";
my $rf_jsqueue = $rf_webdir."/js/Queue.js";
my $rf_jsjquerytabsorterlink = $rf_webdir."/js/jquery/jquery.tablesorter.js";
my $rf_jsjquerylink = $rf_webdir."/js/jquery/jquery-latest.js";
my $rf_faviconlink = $rf_webdir."/images/rf-favicon-32px.ico";
my $rf_logolink = $rf_webdir."/images/rf-logo-20px.png";
my $rf_searchlogolink = $rf_webdir."/images/rf-search-17px.png";
my $rf_uploadlink = $rf_webdir."/images/rf-upload-17px.png";
my $rf_sharestopgraylink = $rf_webdir."/images/rf-share-stop-gray-18px.png";
my $rf_sharestopbluelink = $rf_webdir."/images/rf-share-stop-blue-18px.png";
my $rf_sharepausegraylink = $rf_webdir."/images/rf-share-pause-gray-18px.png";
my $rf_sharepausebluelink = $rf_webdir."/images/rf-share-pause-blue-18px.png";
my $rf_sharerestartgraylink = $rf_webdir."/images/rf-share-restart-gray-18px.png";
my $rf_sharerestartbluelink = $rf_webdir."/images/rf-share-restart-blue-18px.png";
my $rf_searchdowngraylink = $rf_webdir."/images/rf-search-down-gray-18px.png";
my $rf_searchdownbluelink = $rf_webdir."/images/rf-search-down-blue-18px.png";
my $rf_sorticonlink = $rf_webdir."/images/rf-sort-14px.png";
my $rf_rscsdtdfile = "schema/rscollection.dtd";
my $rf_chatminusbluelink = $rf_webdir."/images/rf-chat-minus-blue-18px.png";
my $rf_chatminusgraylink = $rf_webdir."/images/rf-chat-minus-gray-18px.png";
my $rf_chatplusbluelink = $rf_webdir."/images/rf-chat-plus-blue-18px.png";
my $rf_chatplusgraylink = $rf_webdir."/images/rf-chat-plus-gray-18px.png";

sub getMagicId               { return $rs_magicid; }
sub getHeadSize              { return $rs_headsize; }
sub getTimeOutPeriod         { return $rf_timeoutperiod; }
sub getResultLimit           { return $rf_resultlimit; }
sub getRetroShareHost        { return $rs_host; }
sub getRetroSharePort        { return $rs_port; }
sub getRetroShareUser        { return $rs_user; }
sub getRetroSharePass        { return $rs_pass; }
sub getRetroShareDwnDir      { return $rs_dwndir; }
sub getFSDirectories         { return @rs_fsdirectories; }
sub getPagetitle             { return $rf_pagetitle; }
sub getProgName              { return $rf_progname; }
sub getStylesheetlink        { return $rf_stylesheetlink; }
sub getJsJQuerylink          { return $rf_jsjquerylink; }
sub getJsJQueryTabsorterlink { return $rf_jsjquerytabsorterlink; }
sub getFavIconlink           { return $rf_faviconlink; }
sub getSearchLogolink        { return $rf_searchlogolink; }
sub getUploadLogolink        { return $rf_uploadlink; }
sub getJsAjax                { return $rf_jsajax; }
sub getJsQueue               { return $rf_jsqueue; }
sub getJsTextutils           { return $rf_jstextutils; }
sub getJsRfFunc              { return $rf_jsrffunc; }
sub getLogolink              { return $rf_logolink; }
sub getShareStopGraylink     { return $rf_sharestopgraylink; }
sub getShareStopBluelink     { return $rf_sharestopbluelink; }
sub getSharePauseGraylink    { return $rf_sharepausegraylink; }
sub getSharePauseBluelink    { return $rf_sharepausebluelink; }
sub getShareRestartGraylink  { return $rf_sharerestartgraylink; }
sub getShareRestartBluelink  { return $rf_sharerestartbluelink; }
sub getSearchDownGraylink    { return $rf_searchdowngraylink; }
sub getSearchDownBluelink    { return $rf_searchdownbluelink; }
sub getSortIconlink          { return $rf_sorticonlink; }
sub getRSCSchemaFile         { return $rf_rscsdtdfile; }
sub getChatMinusBluelink     { return $rf_chatminusbluelink; }
sub getChatMinusGraylink     { return $rf_chatminusgraylink; }
sub getChatPlusBluelink      { return $rf_chatplusbluelink; }
sub getChatPlusGraylink      { return $rf_chatplusgraylink; }

1