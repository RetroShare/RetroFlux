package retrofunc;

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
use HTML::Template;
use URI::Escape;
use Number::Bytes::Human qw(format_bytes);
use Net::SSH2;
use Filesys::Df;
use Data::Dumper;
use lib 'lib';
#require Google::ProtocolBuffers;
use retroconfig;

my $host = retroconfig::getRetroShareHost();
my $port = retroconfig::getRetroSharePort();
my $user = retroconfig::getRetroShareUser();
my $pass = retroconfig::getRetroSharePass();
my $rsdwndir = retroconfig::getRetroShareDwnDir();
my $ssh2 = Net::SSH2->new();
my $chan = undef;
my $kMAGICID = retroconfig::getMagicId();
my $kHEADERSIZE = retroconfig::getHeadSize();
my $next_req_id = 1;

# Google::ProtocolBuffers->parsefile("proto/core.proto", { include_dir => 'proto', create_accessors => 1 } );
# Google::ProtocolBuffers->parsefile("proto/peers.proto", { include_dir => 'proto', create_accessors => 1 } );
# Google::ProtocolBuffers->parsefile("proto/files.proto", { include_dir => 'proto', create_accessors => 1 } );
# Google::ProtocolBuffers->parsefile("proto/system.proto", { include_dir => 'proto', create_accessors => 1 } );
# Google::ProtocolBuffers->parsefile("proto/stream.proto", { include_dir => 'proto', create_accessors => 1 } );
# Google::ProtocolBuffers->parsefile("proto/search.proto", { include_dir => 'proto', create_accessors => 1 } );
# Google::ProtocolBuffers->parsefile("proto/peers.proto", { include_dir => 'proto', create_accessors => 1 } );

sub getContentTypeString {
    return "Content-Type: text/html\n\n";
}

sub ssh2Connect {
    $ssh2->connect($host, $port) or die $!;
    if ($ssh2->auth_password($user,$pass)) {
        $chan = $ssh2->channel();
        #$chan->blocking(1);
        binmode($chan);
        $chan->shell();
    }
}

sub ssh2Disconnect {
    $chan->close();
    #print Dumper "wait-closed: " .$chan->wait_closed();
    #print Dumper "exit-status: " .$chan->exit_status();
    #print Dumper "send-eof:    " .$chan->send_eof();
    $ssh2->disconnect();
}

sub create_header {
    my ($req_id, $msg_type, $msg_size, $msg_body) = @_;  
    my $msgheader = pack('NNNN', $kMAGICID, $msg_type, $req_id, $msg_size);
    return $msgheader;
}

sub constructMsgId {
  my ($ext, $service, $submsg, $is_response) = @_;
  # enforce bit sizes.
  $ext &= 0xFF;
  $service &= 0xFFFF;
  $submsg &= 0xFF;
  
  if ($is_response) {
    $ext |= 0x01; # Set Bottom Bit.
  } else {
    $ext &= 0xFE; # Clear Bottom Bit.
  }
  
  my $msg_id = ($ext << 24) + ($service << 8) + ($submsg);
  return $msg_id;
}

sub gen_req_id {
    my $req_id = $next_req_id;
    $next_req_id += 1;
    return $req_id;
}

sub createreshash {
    my $RESRS = shift;
    my %RESHASH;
    
    for my $ERGEB (@$RESRS) {
      $RESHASH{$ERGEB->file->hash}{'name'} = $ERGEB->file->name;
      $RESHASH{$ERGEB->file->hash}{'size'} = $ERGEB->file->size;
      $RESHASH{$ERGEB->file->hash}{'sources'}++;
    }
    
    return %RESHASH;
}

######################################
# Read Response Massage
######################################
sub readResponseMessage {
    my ($BUFFER);
    $chan->read($BUFFER,$kHEADERSIZE);
    return unpack("NNNN", $BUFFER);
}

sub loadDefaultTemplateParams {
    my $template = shift;
    $template->param(PAGETITLE => retroconfig::getPagetitle());
    $template->param(PROGNAME => retroconfig::getProgName());
    $template->param(TIMEOUTPERIOD => retroconfig::getTimeOutPeriod());
    $template->param(STYLESHEETLINK => retroconfig::getStylesheetlink());
    $template->param(FAVICON => retroconfig::getFavIconlink());
    $template->param(SEARCHLOGOLINK => retroconfig::getSearchLogolink());
    $template->param(LOGOLINK => retroconfig::getLogolink());
    $template->param(JSAJAX => retroconfig::getJsAjax());
    $template->param(JSTEXTUTILS => retroconfig::getJsTextutils());
    $template->param(JSRFFUNC => retroconfig::getJsRfFunc());
    $template->param(JSJQUERY => retroconfig::getJsJQuerylink());
    $template->param(JSJQUERYTABSORTER => retroconfig::getJsJQueryTabsorterlink());
    $template->param(ERRORMSG => "");
     #$template->param(UPLOADICONLINK => retroconfig::getUploadLogolink());
     
}

sub getPeersList {
    my $setoptstr = shift;
    my $status_res;

    # setOptions OWNID = 1, LISTED = 2, CONNECTED = 3, FRIENDS = 4, VALID = 5, SIGNED = 6, ALL = 7
    if ($setoptstr eq "OWNID" || $setoptstr eq "LISTED" || $setoptstr eq "CONNECTED" || $setoptstr eq "FRIENDS" || $setoptstr eq "VALID" || $setoptstr eq "ALL") {
##      Google::ProtocolBuffers->parsefile("proto/peers.proto", { include_dir => 'proto', create_accessors => 1 } );
      #Google::ProtocolBuffers->parsefile("proto/peers.proto", { include_dir => 'proto' } );
      #my $reqpeers = Rsctrl::Peers::RequestPeers->new({ set => eval("Rsctrl::Peers::RequestPeers::SetOption::$setoptstr()"), info => Rsctrl::Peers::RequestPeers::InfoOption::BASIC()});
      my $reqpeers = Rsctrl::Peers::RequestPeers->new({ set => eval("Rsctrl::Peers::RequestPeers::SetOption::$setoptstr()"), info => Rsctrl::Peers::RequestPeers::InfoOption::BASIC()});
      my $pa_ext = 0;
      # service = (PEERS = 1) 
      my $pa_service = Rsctrl::Core::PackageId::PEERS();
      # submsg = 1;
      my $pa_submsg = Rsctrl::Peers::RequestMsgIds::MsgId_RequestPeers();
      my $pa_isresponse = 0;
    
      my $pa_msgid = constructMsgId($pa_ext, $pa_service, $pa_submsg, $pa_isresponse);
      my $pa_reqid = gen_req_id();
      my $pa_header = create_header($pa_reqid, $pa_msgid, length($reqpeers->encode));
    
      # [magicid][msgid][reqid][body size]
      my $pa_msg = $pa_header . $reqpeers->encode;
      $chan->write($pa_msg);
      my ($buf, $data);
      my ($res_magic_id, $res_msg_type, $res_req_id, $res_msg_size) = readResponseMessage();
      if($res_magic_id == $kMAGICID) {
         $chan->read($buf,$res_msg_size);
         $status_res = Rsctrl::Peers::ResponsePeerList->decode($buf);
      }
    }
    return $status_res;
}

sub getShareDirList {

    my $status_res;
##    Google::ProtocolBuffers->parsefile("proto/files.proto", { include_dir => 'proto', create_accessors => 1 } );
    # ListType { DIRQUERY_ROOT   = 1;  DIRQUERY_PERSON   = 2; DIRQUERY_FILE   = 3; DIRQUERY_DIR  = 4;   }
    my $reqpeers = Rsctrl::Files::RequestShareDirList->new({ ssl_id => '' , path => '' , list_type => Rsctrl::Files::ResponseShareDirList::ListType::DIRQUERY_DIR()});
    my $pa_ext = 0;
    # service = (FILES = 5) 
    my $pa_service = Rsctrl::Core::PackageId::FILES();
    # submsg = 3;
    my $pa_submsg = Rsctrl::Files::RequestMsgIds::MsgId_RequestShareDirList();
    my $pa_isresponse = 0;
  
    my $pa_msgid = constructMsgId($pa_ext, $pa_service, $pa_submsg, $pa_isresponse);
    my $pa_reqid = gen_req_id();
    my $pa_header = create_header($pa_reqid, $pa_msgid, length($reqpeers->encode));
  
    # [magicid][msgid][reqid][body size]
    my $pa_msg = $pa_header . $reqpeers->encode;
    $chan->write($pa_msg);
    my ($buf, $data);
    my ($res_magic_id, $res_msg_type, $res_req_id, $res_msg_size) = readResponseMessage();
    #print Dumper $res_magic_id, $res_msg_type, $res_req_id, $res_msg_size;
    if($res_magic_id == $kMAGICID) {
       $chan->read($buf,$res_msg_size);
       $status_res = Rsctrl::Files::ResponseShareDirList->decode($buf);
    }

    return $status_res;
}

##### DONT USE IT ######
sub getSystemAccount {
    
    my $status_res;
##    Google::ProtocolBuffers->parsefile("proto/system.proto", { include_dir => 'proto', create_accessors => 1 } );
    my $reqsys = Rsctrl::System::RequestSystemAccount->new({''});
    my $pa_ext = 0;
    # service = (SYSTEM = 2) 
    my $pa_service = Rsctrl::Core::PackageId::SYSTEM();
    # submsg = 4;
    #my $pa_submsg = Rsctrl::System::RequestMsgIds::MsgId_RequestSystemAccount();
    my $pa_submsg = 4;
    my $pa_isresponse = 0;
  
    my $pa_msgid = constructMsgId($pa_ext, $pa_service, $pa_submsg, $pa_isresponse);
    my $pa_reqid = gen_req_id();
    my $pa_header = create_header($pa_reqid, $pa_msgid, length($reqsys->encode));
  
    # [magicid][msgid][reqid][body size]
    my $pa_msg = $pa_header . $reqsys->encode;
    $chan->write($pa_msg);
    sleep(5);
    my ($buf, $data);
    my ($res_magic_id, $res_msg_type, $res_req_id, $res_msg_size) = readResponseMessage();
    print Dumper $res_magic_id, $res_msg_type, $res_req_id, $res_msg_size;
    if($res_magic_id == $kMAGICID) {
       print "$res_msg_size\n";
       $chan->read($buf,$res_msg_size);
       $status_res = Rsctrl::System::ResponseSystemAccount->decode($buf);
    }

    return $status_res;
}

##### DONT USE IT ######
sub getStartFileStream {
    my $status_res;
    my ($filename,$filesize,$filehash) = @_;
    
    if (defined($filename) || defined($filehash) || defined($filesize)) { 
##        Google::ProtocolBuffers->parsefile("proto/stream.proto", { include_dir => 'proto', create_accessors => 1 } );
        my $file   = Rsctrl::Core::File->new({name => $filename, hash => $filehash, size => $filesize});
        #print Dumper $file;
        my $reqsys = Rsctrl::Stream::RequestStartFileStream->new({file => $file, rate_kbs => 25});
        print Dumper $reqsys;
        my $pa_ext = 0;
        # service = (STREAM = 6) 
        my $pa_service = Rsctrl::Core::PackageId::STREAM();
        # MsgId_RequestListStreams = 3;
        #my $pa_submsg = Rsctl::Stream::RequestMsgIds::MsgId_RequestStartFileStream();
        my $pa_submsg = 1;
        my $pa_isresponse = 0;
      
        my $pa_msgid = constructMsgId($pa_ext, $pa_service, $pa_submsg, $pa_isresponse);
        my $pa_reqid = gen_req_id();
        my $pa_header = create_header($pa_reqid, $pa_msgid, length($reqsys->encode));
      
        # [magicid][msgid][reqid][body size]
        my $pa_msg = $pa_header . $reqsys->encode;
        $chan->write($pa_msg);
        my ($buf, $data);
        my ($res_magic_id, $res_msg_type, $res_req_id, $res_msg_size) = readResponseMessage();
        if($res_magic_id == $kMAGICID) {
           $chan->read($buf,$res_msg_size);
           $status_res = Rsctrl::Stream::ResponseStreamDetail->decode($buf);
           #$status_res = Rsctrl::Stream::ResponseStreamData->decode($buf);
        }
    }
    return $status_res;
}

sub getSystemStatus {
    my $status_res;

##	  Google::ProtocolBuffers->parsefile("proto/system.proto", { include_dir => 'proto', create_accessors => 1 } );
	  my $reqsys = Rsctrl::System::RequestSystemStatus->new({});
	  my $pa_ext = 0;
	  # service = (SYSTEM = 2) 
	  my $pa_service = Rsctrl::Core::PackageId::SYSTEM();
	  #my $pa_submsg = Rsctl::System::RequestMsgIds::MsgId_RequestSystemStatus();
	  my $pa_submsg = 1;
	  my $pa_isresponse = 0;
	
	  my $pa_msgid = constructMsgId($pa_ext, $pa_service, $pa_submsg, $pa_isresponse);
	  my $pa_reqid = gen_req_id();
	  my $pa_header = create_header($pa_reqid, $pa_msgid, length($reqsys->encode));
	
	  # [magicid][msgid][reqid][body size]
	  my $pa_msg = $pa_header . $reqsys->encode;
	  $chan->write($pa_msg);
    my ($buf, $data);
	  my ($res_magic_id, $res_msg_type, $res_req_id, $res_msg_size) = readResponseMessage();
	  if($res_magic_id == $kMAGICID) {
	     $chan->read($buf,$res_msg_size);
	     $status_res = Rsctrl::System::ResponseSystemStatus->decode($buf);
	  }	
    return $status_res;
}

sub getListStreams {
    my $status_res;

##    Google::ProtocolBuffers->parsefile("proto/stream.proto", { include_dir => 'proto', create_accessors => 1 } );
    my $reqsys = Rsctrl::Stream::RequestListStreams->new({request_type => Rsctrl::Stream::StreamType::STREAM_TYPE_FILES()});
    my $pa_ext = 0;
    # service = (STREAM = 6) 
    my $pa_service = Rsctrl::Core::PackageId::STREAM();
    # MsgId_RequestListStreams = 3;
    #my $pa_submsg = Rsctl::Stream::RequestMsgIds::MsgId_RequestListStreams();
    my $pa_submsg = 3;
    my $pa_isresponse = 0;
  
    my $pa_msgid = constructMsgId($pa_ext, $pa_service, $pa_submsg, $pa_isresponse);
    my $pa_reqid = gen_req_id();
    my $pa_header = create_header($pa_reqid, $pa_msgid, length($reqsys->encode));
  
    # [magicid][msgid][reqid][body size]
    my $pa_msg = $pa_header . $reqsys->encode;
    $chan->write($pa_msg);
    my ($buf, $data);
    my ($res_magic_id, $res_msg_type, $res_req_id, $res_msg_size) = readResponseMessage();
    if($res_magic_id == $kMAGICID) {
       $chan->read($buf,$res_msg_size);
       $status_res = Rsctrl::Stream::ResponseStreamData->decode($buf);
    } 
    return $status_res;
}

sub getFSDiscSpaceInfo {
    my %dsinfo = ();
    # get Array of Directories
    my @dirs = retroconfig::getFSDirectories();
    # disc space information
    foreach my $dir (@dirs) {
      my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks) = stat($dir);
      my $ref = df($dir, 1);
      $dsinfo{$dir} = $ref;
      #print Dumper %dsinfo;
      #print Dumper $dir, $ref;
    }
    return %dsinfo;
}

sub getDownloadList {
	  my @RESULT;
##		Google::ProtocolBuffers->parsefile("proto/files.proto", { include_dir => 'proto', create_accessors => 1 } );
		my $rtl = Rsctrl::Files::RequestTransferList->new({direction => Rsctrl::Files::Direction::DIRECTION_DOWNLOAD()});
		###########################################
    # MsgID = Corresponds to the format of the Body.
    # def constructMsgId(ext, service, submsg, is_response)
    # msg_id = pyrs.msgs.constructMsgId(core_pb2.CORE, core_pb2.SEARCH, search_pb2.MsgId_RequestBasicSearch, False);
    # ext (Requests = 0, Responses = 1)
    # service (CORE = 0, PEERS = 1, SYSTEM = 2, CHAT = 3, SEARCH = 4, FILES = 5, GXS = 1000)
    # 
    # ext = Requests (0)
    # service = FILES (5)
    # submsg = MsgId_RequestTransferList (1)
    # is_response = False (0) ???
    ###########################################
		my $pa_msgid = constructMsgId(0,5,1,0);
		my $pa_reqid = gen_req_id();
		my $pa_header = create_header($pa_reqid, $pa_msgid, length($rtl->encode));
		my $pa_msg = $pa_header . $rtl->encode;
		$chan->write($pa_msg);
   
		my ($len, $buf2); 
		my ($res_magic_id, $res_msg_type, $res_req_id, $res_msg_size) = readResponseMessage(); 

		if(defined $res_magic_id) { 
			if($res_magic_id == $kMAGICID) { 
				$chan->read($buf2,$res_msg_size); 
				my $rtlres = Rsctrl::Files::ResponseTransferList->decode($buf2);
				#print Dumper $rtlres;
				my (%tmpb);
				for my $tmpa ($rtlres->transfers) {
				    push(@RESULT,$tmpa);
					#for my $tmpb (@$tmpa) {
					#	print "file : ". $tmpb->file->name;
					#	print " size : ". $tmpb->file->size;
					#	print " rate in kb : ". sprintf("%.2f", $tmpb->rate_kBs);
					#	print " fraction : ". sprintf("%.2f %%", $tmpb->fraction*100);
					#	print "\n";
					#}
				}
			}
		}

	return @RESULT;
}

sub getUploadList {
  my @RESULT;

##    Google::ProtocolBuffers->parsefile("proto/files.proto", { include_dir => 'proto', create_accessors => 1 } );
    my $rtl = Rsctrl::Files::RequestTransferList->new({direction => Rsctrl::Files::Direction::DIRECTION_UPLOAD()});
    ########################################
    # service FILES = 5;
    # MsgId_RequestTransferList = 1;
    ########################################
    my $pa_msgid = constructMsgId(0,5,1,0);
    my $pa_reqid = gen_req_id();
    my $pa_header = create_header($pa_reqid, $pa_msgid, length($rtl->encode));
    my $pa_msg = $pa_header . $rtl->encode;
    $chan->write($pa_msg);
   
    my ($len, $buf2); 
    my ($res_magic_id, $res_msg_type, $res_req_id, $res_msg_size) = readResponseMessage(); 

    if(defined $res_magic_id) { 
      if($res_magic_id == $kMAGICID) { 
        $chan->read($buf2,$res_msg_size); 
        my $rtlres = Rsctrl::Files::ResponseTransferList->decode($buf2);
        #print Dumper $rtlres;
        my (%tmpb);
        for my $tmpa ($rtlres->transfers) {
            push(@RESULT,$tmpa);
        }
      }
    }

  return @RESULT;
}

#########################################################
# start search
#########################################################
sub startBasicSearchRequest {
    my @terms=@_;
    my $searchid;

##    Google::ProtocolBuffers->parsefile("proto/search.proto", { include_dir => 'proto', create_accessors => 1 } );
    my $rtl = Rsctrl::Search::RequestBasicSearch->new({terms => \@terms});
    ###########################################
    # MsgID = Corresponds to the format of the Body.
    # def constructMsgId(ext, service, submsg, is_response)
    # msg_id = pyrs.msgs.constructMsgId(core_pb2.CORE, core_pb2.SEARCH, search_pb2.MsgId_RequestBasicSearch, False);
    # ext (Requests = 0, Responses = 1)
    # service (CORE = 0, PEERS = 1, SYSTEM = 2, CHAT = 3, SEARCH = 4, FILES = 5, GXS = 1000)
    # 
    # ext = Requests (0)
    # service = SEARCH (4)
    # submsg = MsgId_RequestBasicSearch (1)
    # is_response = False (0) ???
    ###########################################
    my $pa_msgid = constructMsgId(0,4,1,0);
    my $pa_reqid = gen_req_id();
    my $pa_header = create_header($pa_reqid, $pa_msgid, length($rtl->encode));
    my $pa_msg = $pa_header . $rtl->encode;
    $chan->write($pa_msg);
 
    #sleep(1);
   
    my ($len, $buf2, $rtlres); 
    my ($res_magic_id, $res_msg_type, $res_req_id, $res_msg_size) = readResponseMessage(); 
    if($res_magic_id == $kMAGICID) { 
       $chan->read($buf2,$res_msg_size); 
       $rtlres = Rsctrl::Search::ResponseSearchIds->decode($buf2);
       #$searchid = @{$rtlres->search_id}[0];
       #print Dumper $searchid;
    }

    #return $searchid;
    return $rtlres;
}

sub startRequestListSearches {
    my @result_list_searches;
    
    my $reqList = Rsctrl::Search::RequestListSearches->new();
    my $msgidReqList = Rsctrl::Search::RequestMsgIds::MsgId_RequestListSearches();
    my $reqListHead = create_header(gen_req_id(),constructMsgId(0,4,$msgidReqList,0),length($reqList->encode));
    my $reqListMsg = $reqListHead . $reqList->encode;
    $chan->write($reqListMsg);
    
    my ($buf4);
    my ($req_magic_id, $req_msg_type, $req_req_id, $req_msg_size) = readResponseMessage();
    print Dumper ($req_magic_id, $req_msg_type, $req_req_id, $req_msg_size);
    if($req_magic_id == $kMAGICID) {
       $chan->read($buf4,$req_msg_size);
       my $ressres =  Rsctrl::Search::ResponseSearchResults->decode($buf4);
       print Dumper $ressres;
    
       #print "="x80, "\n";
       for my $tmpa ($ressres->searches) {
          #print Dumper $tmpa;
          for my $tmpb (@$tmpa) {
              for my $tmpc ($tmpb->hits) {
                  push(@result_list_searches,$tmpc);
                  #for my $tmpd (@$tmpc) {
                  #print Dumper $tmpd;
                  #print "hash : ". $tmpd->file->hash;
                  #print " file : ". $tmpd->file->name;
                  #print " size : ". $tmpd->file->size;
                  #print "\n";
                  #}
              }
          }
       }
    }

}

sub startSearchResultsRequest {
     my @searchids;
     push(@searchids,shift);
     my @search_results_request;
    
     #Google::ProtocolBuffers->parsefile("proto/search.proto", { include_dir => 'proto', create_accessors => 1 } );
     my $reqsres = Rsctrl::Search::RequestSearchResults->new({ result_limit => retroconfig::getResultLimit() });
     #my $reqsres = Rsctrl::Search::RequestSearchResults->new({search_ids => @SEARCHIDS});
     #my $reqsres = Rsctrl::Search::RequestSearchResults->new();
     # service = SEARCH (4)
     my $msgid_reqsres = Rsctrl::Search::RequestMsgIds::MsgId_RequestSearchResults(); # 5
     my $reqsres_head = create_header(gen_req_id(),constructMsgId(0,4,$msgid_reqsres,0),length($reqsres->encode));
     my $reqsres_msg = $reqsres_head . $reqsres->encode;
     $chan->write($reqsres_msg);
    
     sleep(3);
     
     my ($buf4);
     my ($req_magic_id, $req_msg_type, $req_req_id, $req_msg_size) = readResponseMessage();
     #print Dumper ($req_magic_id, $req_msg_type, $req_req_id, $req_msg_size);
     if($req_magic_id == $kMAGICID) {
        $chan->read($buf4,$req_msg_size);
        my $ressres =  Rsctrl::Search::ResponseSearchResults->decode($buf4);
        #print Dumper $ressres;
    
      #print "="x80, "\n";
      for my $tmpa ($ressres->searches) {
          #print Dumper $tmpa;
          for my $tmpb (@$tmpa) {
              for my $tmpc ($tmpb->hits) {
                  push(@search_results_request,$tmpc);
                  #for my $tmpd (@$tmpc) {
                  #print Dumper $tmpd;
                  #print "hash : ". $tmpd->file->hash;
                  #print " file : ". $tmpd->file->name;
                  #print " size : ". $tmpd->file->size;
                  #print "\n";
                  #}
                }
            }
        }
     }

    return @search_results_request;
}

##############################################################################
# Eine Suchanfrage schliessen
##############################################################################
sub stopSearchRequest {
    my $search_request_id = shift;

    #Google::ProtocolBuffers->parsefile("proto/search.proto", { include_dir => 'proto', create_accessors => 1 } );
    my $rtl = Rsctrl::Search::RequestCloseSearch->new({search_id => $search_request_id});
    ###########################################
    # MsgID = Corresponds to the format of the Body.
    # def constructMsgId(ext, service, submsg, is_response)
    # msg_id = pyrs.msgs.constructMsgId(core_pb2.CORE, core_pb2.SEARCH, search_pb2.MsgId_RequestBasicSearch, False);
    # ext (Requests = 0, Responses = 1)
    # service (CORE = 0, PEERS = 1, SYSTEM = 2, CHAT = 3, SEARCH = 4, FILES = 5, GXS = 1000)
    # 
    # ext = Requests (0)
    # service = SEARCH (4)
    # submsg = MsgId_RequestCloseSearch   = 3;
    # is_response = False (0) ???
    ###########################################
    my $pa_msgid = constructMsgId(0,4,3,0);
    my $pa_reqid = gen_req_id();
    my $pa_header = create_header($pa_reqid, $pa_msgid, length($rtl->encode));
    my $pa_msg = $pa_header . $rtl->encode;
    $chan->write($pa_msg);
 
    #sleep(1);
   
    my ($len, $buf2, $rtlres); 
    my ($res_magic_id, $res_msg_type, $res_req_id, $res_msg_size) = readResponseMessage(); 
    if($res_magic_id == $kMAGICID) { 
       $chan->read($buf2,$res_msg_size); 
       $rtlres = Rsctrl::Search::ResponseSearchIds->decode($buf2);
       #$search_request_id = @{$rtlres->search_id}[0];
       #print Dumper $search_request_id;
    }

    #return $search_request_id;
    return $rtlres;
}

##############################################################################
# start download
##############################################################################
sub startDownloadFile {
    my ($FILENAME,$FILESIZE,$FILEHASH) = @_;
    if (defined($FILENAME) || defined($FILEHASH) || defined($FILESIZE)) {
      #print Dumper ($FILENAME,$FILESIZE,$FILEHASH);
##      Google::ProtocolBuffers->parsefile("proto/files.proto", { include_dir => 'proto', create_accessors => 1 } );
      my $ACTION = Rsctrl::Files::RequestControlDownload::Action::ACTION_START();
      my $FILE   = Rsctrl::Core::File->new({name => $FILENAME, hash => $FILEHASH, size => $FILESIZE});
      my $REQDWN = Rsctrl::Files::RequestControlDownload->new({file => $FILE, action => $ACTION});
      # service FILES = 5;
      # MsgId_RequestControlDownload = 2;
      my $REQHEAD = create_header(gen_req_id(),constructMsgId(0,5,2,0),length($REQDWN->encode));
      my $REQMSG = $REQHEAD . $REQDWN->encode;
      $chan->write($REQMSG);
      return 1;   
    } else {
      return 0; 
    }
}

##############################################################################
# cancle download
##############################################################################
sub stopDownloadFile {
    my ($FILENAME,$FILESIZE,$FILEHASH) = @_;
    if (defined($FILENAME) || defined($FILEHASH) || defined($FILESIZE)) {
      #print Dumper ($FILENAME,$FILESIZE,$FILEHASH);
##      Google::ProtocolBuffers->parsefile("proto/files.proto", { include_dir => 'proto', create_accessors => 1 } );
      my $ACTION = Rsctrl::Files::RequestControlDownload::Action::ACTION_CANCEL();
      my $FILE   = Rsctrl::Core::File->new({name => $FILENAME, hash => $FILEHASH, size => $FILESIZE});
      # only hash
      #my $FILE   = Rsctrl::Core::File->new({hash => $FILEHASH});
      my $REQDWN = Rsctrl::Files::RequestControlDownload->new({file => $FILE, action => $ACTION});
      # service FILES = 5;
      # MsgId_RequestControlDownload = 2;
      my $REQHEAD = create_header(gen_req_id(),constructMsgId(0,5,2,0),length($REQDWN->encode));
      my $REQMSG = $REQHEAD . $REQDWN->encode;
      $chan->write($REQMSG);
      
      #my ($BUFSTOP);
      #my ($req_magic_id, $req_msg_type, $req_req_id, $req_msg_size) = readResponseMessage();
      #if($req_magic_id == $kMAGICID) {
      #   $chan->read($BUFSTOP,$req_msg_size);
      #   my $RESCONDWN =  Rsctrl::Files::ResponseControlDownload->decode($BUFSTOP);
      #   print Dumper $RESCONDWN;
      #   return $RESCONDWN+77;
      #}
      
      return 1;   
    } else {
      return 0; 
    }
}

##############################################################################
# pause download
##############################################################################
sub pauseDownloadFile {
    my ($FILENAME,$FILESIZE,$FILEHASH) = @_;
    if (defined($FILENAME) || defined($FILEHASH) || defined($FILESIZE)) {
      #print Dumper ($FILENAME,$FILESIZE,$FILEHASH);
##      Google::ProtocolBuffers->parsefile("proto/files.proto", { include_dir => 'proto', create_accessors => 1 } );
      my $ACTION = Rsctrl::Files::RequestControlDownload::Action::ACTION_PAUSE();
      my $FILE   = Rsctrl::Core::File->new({name => $FILENAME, hash => $FILEHASH, size => $FILESIZE});
      # only hash
      #my $FILE   = Rsctrl::Core::File->new({hash => $FILEHASH});
      my $REQDWN = Rsctrl::Files::RequestControlDownload->new({file => $FILE, action => $ACTION});
      # service FILES = 5;
      # MsgId_RequestControlDownload = 2;
      my $REQHEAD = create_header(gen_req_id(),constructMsgId(0,5,2,0),length($REQDWN->encode));
      my $REQMSG = $REQHEAD . $REQDWN->encode;
      $chan->write($REQMSG);
      return 1;   
    } else {
      return 0; 
    }
}

##############################################################################
# restart download
##############################################################################
sub restartDownloadFile {
    my ($FILENAME,$FILESIZE,$FILEHASH) = @_;
    if (defined($FILENAME) || defined($FILEHASH) || defined($FILESIZE)) {
      #print Dumper ($FILENAME,$FILESIZE,$FILEHASH);
##      Google::ProtocolBuffers->parsefile("proto/files.proto", { include_dir => 'proto', create_accessors => 1 } );
      my $ACTION = Rsctrl::Files::RequestControlDownload::Action::ACTION_RESTART();
      my $FILE   = Rsctrl::Core::File->new({name => $FILENAME, hash => $FILEHASH, size => $FILESIZE});
      # only hash
      #my $FILE   = Rsctrl::Core::File->new({hash => $FILEHASH});
      my $REQDWN = Rsctrl::Files::RequestControlDownload->new({file => $FILE, action => $ACTION});
      # service FILES = 5;
      # MsgId_RequestControlDownload = 2;
      my $REQHEAD = create_header(gen_req_id(),constructMsgId(0,5,2,0),length($REQDWN->encode));
      my $REQMSG = $REQHEAD . $REQDWN->encode;
      $chan->write($REQMSG);
      return 1;   
    } else {
      return 0; 
    }
}

##############################################################################
# read rscollection and start downloads
##############################################################################
sub readRSCollection {
    my $rscoll_file = shift;
    if (defined($rsdwndir) && defined($rscoll_file)) {
      print Dumper $rsdwndir.$rscoll_file;
      return 1;   
    } else {
      return 0; 
    }
}

############################################
# add peer
############################################
sub addPeer {
    my $peer_pgp = shift;
    
##    Google::ProtocolBuffers->parsefile("proto/peers.proto", { include_dir => 'proto', create_accessors => 1 } );
    my $rtl = Rsctrl::Peers::RequestAddPeer->new({cmd => Rsctrl::Peers::RequestAddPeer::AddCmd::ADD(), pgp_id => $peer_pgp});
    ###########################################
    # MsgID = Corresponds to the format of the Body.
    # def constructMsgId(ext, service, submsg, is_response)
    # msg_id = pyrs.msgs.constructMsgId(core_pb2.CORE, core_pb2.SEARCH, search_pb2.MsgId_RequestBasicSearch, False);
    # ext (Requests = 0, Responses = 1)
    # service (CORE = 0, PEERS = 1, SYSTEM = 2, CHAT = 3, SEARCH = 4, FILES = 5, GXS = 1000)
    # 
    # submsg = MsgId_RequestAddPeer (2)
    # is_response = False (0) ???
    ###########################################
    my $pa_msgid = constructMsgId(0,1,2,0);
    my $pa_reqid = gen_req_id();
    my $pa_header = create_header($pa_reqid, $pa_msgid, length($rtl->encode));
    my $pa_msg = $pa_header . $rtl->encode;
    $chan->write($pa_msg);
   
    my ($len, $buf2, $rtlres); 
    my ($res_magic_id, $res_msg_type, $res_req_id, $res_msg_size) = readResponseMessage(); 
    if($res_magic_id == $kMAGICID) { 
       $chan->read($buf2,$res_msg_size); 
       $rtlres = Rsctrl::Peers::ResponsePeerList->decode($buf2);
       #print Dumper $rtlres;
    }
    
    return $rtlres;
}

############################################
# remove peer
############################################
sub removePeer {
    my $peer_pgp = shift;
    
##    Google::ProtocolBuffers->parsefile("proto/peers.proto", { include_dir => 'proto', create_accessors => 1 } );
    my $rtl = Rsctrl::Peers::RequestAddPeer->new({cmd => Rsctrl::Peers::RequestAddPeer::AddCmd::REMOVE(), pgp_id => $peer_pgp});
    ###########################################
    # MsgID = Corresponds to the format of the Body.
    # def constructMsgId(ext, service, submsg, is_response)
    # msg_id = pyrs.msgs.constructMsgId(core_pb2.CORE, core_pb2.SEARCH, search_pb2.MsgId_RequestBasicSearch, False);
    # ext (Requests = 0, Responses = 1)
    # service (CORE = 0, PEERS = 1, SYSTEM = 2, CHAT = 3, SEARCH = 4, FILES = 5, GXS = 1000)
    # 
    # submsg = MsgId_RequestAddPeer (2)
    # is_response = False (0) ???
    ###########################################
    my $pa_msgid = constructMsgId(0,1,2,0);
    my $pa_reqid = gen_req_id();
    my $pa_header = create_header($pa_reqid, $pa_msgid, length($rtl->encode));
    my $pa_msg = $pa_header . $rtl->encode;
    $chan->write($pa_msg);
   
    my ($len, $buf2, $rtlres); 
    my ($res_magic_id, $res_msg_type, $res_req_id, $res_msg_size) = readResponseMessage(); 
    if($res_magic_id == $kMAGICID) { 
       $chan->read($buf2,$res_msg_size); 
       $rtlres = Rsctrl::Peers::ResponsePeerList->decode($buf2);
       #print Dumper $rtlres;
    }
    
    return $rtlres;
}

#################################################
# chat.proto
#################################################
sub getChatlobbies {
    # my @RESULT;
    my $rtlres;
    my $rtl = Rsctrl::Chat::RequestChatLobbies->new({lobby_set => Rsctrl::Chat::RequestChatLobbies::LobbySet::LOBBYSET_ALL()});
    # LOBBYSET_ALL, LOBBYSET_JOINED, LOBBYSET_INVITED, LOBBYSET_VISIBLE
    ########################################
    # service CHAT = 3;
    # MsgId_RequestChatLobbies = 1;
    ########################################
    my $pa_ext = 0;
    # service = (CHAT = 3) 
    my $pa_service = Rsctrl::Core::PackageId::CHAT();
    # submsg = 1;
    my $pa_submsg = Rsctrl::Chat::RequestMsgIds::MsgId_RequestChatLobbies();
    my $pa_isresponse = 0;
  
    my $pa_msgid = constructMsgId($pa_ext, $pa_service, $pa_submsg, $pa_isresponse);
    my $pa_reqid = gen_req_id();
    my $pa_header = create_header($pa_reqid, $pa_msgid, length($rtl->encode));
    my $pa_msg = $pa_header . $rtl->encode;
    $chan->write($pa_msg);
   
    my ($len, $buf2); 
    my ($res_magic_id, $res_msg_type, $res_req_id, $res_msg_size) = readResponseMessage(); 

    if(defined $res_magic_id) { 
      if($res_magic_id == $kMAGICID) { 
        $chan->read($buf2,$res_msg_size); 
        $rtlres = Rsctrl::Chat::ResponseChatLobbies->decode($buf2);
        # print Dumper $rtlres->lobbies;
        # for my $tmpa ($rtlres->lobbies) {
            # push(@RESULT,$tmpa);
        # }
      }
    }

  return $rtlres;
}

sub joinChatlobby {
    # my @RESULT;
    my $lobbyid = shift;
    my $rtlres;
    my $rtl = Rsctrl::Chat::RequestJoinOrLeaveLobby->new({lobby_id => $lobbyid, action => Rsctrl::Chat::RequestJoinOrLeaveLobby::LobbyAction::JOIN_OR_ACCEPT()});
    ########################################
    # service CHAT = 3;
    # MsgId_RequestJoinOrLeaveLobby = 3;
    ########################################
    my $pa_ext = 0;
    my $pa_service = Rsctrl::Core::PackageId::CHAT();
    my $pa_submsg = Rsctrl::Chat::RequestMsgIds::MsgId_RequestJoinOrLeaveLobby();
    my $pa_isresponse = 0;
  
    my $pa_msgid = constructMsgId($pa_ext, $pa_service, $pa_submsg, $pa_isresponse);
    my $pa_reqid = gen_req_id();
    my $pa_header = create_header($pa_reqid, $pa_msgid, length($rtl->encode));
    my $pa_msg = $pa_header . $rtl->encode;
    $chan->write($pa_msg);
   
    my ($len, $buf2); 
    my ($res_magic_id, $res_msg_type, $res_req_id, $res_msg_size) = readResponseMessage(); 

    if(defined $res_magic_id) { 
      if($res_magic_id == $kMAGICID) { 
        $chan->read($buf2,$res_msg_size); 
        $rtlres = Rsctrl::Chat::ResponseChatLobbies->decode($buf2);
        # print Dumper $rtlres->lobbies;
        # for my $tmpa ($rtlres->lobbies) {
            # push(@RESULT,$tmpa);
        # }
      }
    }

  return $rtlres;
}

sub leaveChatlobby {
    # my @RESULT;
    my $lobbyid = shift;
    my $rtlres;
    my $rtl = Rsctrl::Chat::RequestJoinOrLeaveLobby->new({lobby_id => $lobbyid, action => Rsctrl::Chat::RequestJoinOrLeaveLobby::LobbyAction::LEAVE_OR_DENY()});
    ########################################
    # service CHAT = 3;
    # MsgId_RequestJoinOrLeaveLobby = 3;
    ########################################
    my $pa_ext = 0;
    my $pa_service = Rsctrl::Core::PackageId::CHAT();
    my $pa_submsg = Rsctrl::Chat::RequestMsgIds::MsgId_RequestJoinOrLeaveLobby();
    my $pa_isresponse = 0;
  
    my $pa_msgid = constructMsgId($pa_ext, $pa_service, $pa_submsg, $pa_isresponse);
    my $pa_reqid = gen_req_id();
    my $pa_header = create_header($pa_reqid, $pa_msgid, length($rtl->encode));
    my $pa_msg = $pa_header . $rtl->encode;
    $chan->write($pa_msg);
   
    my ($len, $buf2); 
    my ($res_magic_id, $res_msg_type, $res_req_id, $res_msg_size) = readResponseMessage(); 

    if(defined $res_magic_id) { 
      if($res_magic_id == $kMAGICID) { 
        $chan->read($buf2,$res_msg_size); 
        $rtlres = Rsctrl::Chat::ResponseChatLobbies->decode($buf2);
        # print Dumper $rtlres->lobbies;
        # for my $tmpa ($rtlres->lobbies) {
            # push(@RESULT,$tmpa);
        # }
      }
    }

  return $rtlres;
}

1;