#!/usr/bin/perl


#script to recieve orders
#written by chris@katipo.co.nz 24/2/2000

# Copyright 2000-2002 Katipo Communications
#
# This file is part of Koha.
#
# Koha is free software; you can redistribute it and/or modify it under the
# terms of the GNU General Public License as published by the Free Software
# Foundation; either version 2 of the License, or (at your option) any later
# version.
#
# Koha is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE.  See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Koha; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

=head1 NAME

orderreceive.pl

=head1 DESCRIPTION

This script shows all order already receive and all pendings orders.
It permit to write a new order as 'received'.

=head1 CGI PARAMETERS

=over 4

=item booksellerid

to know on what supplier this script has to display receive order.

=item receive

=item invoice

the number of this invoice.

=item freight

=item biblio

The biblionumber of this order.

=item datereceived

=item catview

=item gst

=back

=cut

use strict;
use warnings;

use CGI;
use C4::Context;
use C4::Koha;   # GetKohaAuthorisedValues GetItemTypes
use C4::Acquisition;
use C4::Auth;
use C4::Output;
use C4::Dates qw/format_date/;
use C4::Bookseller qw/ GetBookSellerFromId /;
use C4::Budgets qw/ GetBudget /;
use C4::Members;
use C4::Branch;    # GetBranches
use C4::Items;
use C4::Biblio;
use C4::Suggestions;


my $input      = new CGI;

my $dbh          = C4::Context->dbh;
my $booksellerid = $input->param('booksellerid');
my $ordernumber  = $input->param('ordernumber');
my $search       = $input->param('receive');
my $invoice      = $input->param('invoice');
my $freight      = $input->param('freight');
my $datereceived = $input->param('datereceived');


$datereceived = $datereceived ? C4::Dates->new($datereceived, 'iso') : C4::Dates->new();

my $bookseller = GetBookSellerFromId($booksellerid);
my $input_gst = ($input->param('gst') eq '' ? undef : $input->param('gst'));
my $gst= $input_gst // $bookseller->{gstrate} // C4::Context->preference("gist") // 0;
my $results = SearchOrder($ordernumber,$search);

my ( $template, $loggedinuser, $cookie ) = get_template_and_user(
    {
        template_name   => "acqui/orderreceive.tmpl",
        query           => $input,
        type            => "intranet",
        authnotrequired => 0,
        flagsrequired   => {acquisition => 'order_receive'},
        debug           => 1,
    }
);

my $count = scalar @$results;
# prepare the form for receiving
if ( $count == 1 ) {
    my $order = $results->[0];

    # Check if ACQ framework exists
    my $acq_fw = GetMarcStructure(1, 'ACQ');
    unless($acq_fw) {
        $template->param('NoACQframework' => 1);
    }

    my $AcqCreateItem = C4::Context->preference('AcqCreateItem');
    if ($AcqCreateItem eq 'receiving') {
        $template->param(
            AcqCreateItemReceiving => 1,
            UniqueItemFields => C4::Context->preference('UniqueItemFields'),
        );
    } elsif ($AcqCreateItem eq 'ordering') {
        my $fw = ($acq_fw) ? 'ACQ' : '';
        my @itemnumbers = GetItemnumbersFromOrder($order->{ordernumber});
        my @items;
        foreach (@itemnumbers) {
            my $item = GetItem($_);
            if($item->{homebranch}) {
                $item->{homebranchname} = GetBranchName($item->{homebranch});
            }
            if($item->{holdingbranch}) {
                $item->{holdingbranchname} = GetBranchName($item->{holdingbranch});
            }
            if(my $code = GetAuthValCode("items.notforloan", $fw)) {
                $item->{notforloan} = GetKohaAuthorisedValueLib($code, $item->{notforloan});
            }
            if(my $code = GetAuthValCode("items.restricted", $fw)) {
                $item->{restricted} = GetKohaAuthorisedValueLib($code, $item->{restricted});
            }
            if(my $code = GetAuthValCode("items.location", $fw)) {
                $item->{location} = GetKohaAuthorisedValueLib($code, $item->{location});
            }
            if(my $code = GetAuthValCode("items.ccode", $fw)) {
                $item->{collection} = GetKohaAuthorisedValueLib($code, $item->{ccode});
            }
            if(my $code = GetAuthValCode("items.materials", $fw)) {
                $item->{materials} = GetKohaAuthorisedValueLib($code, $item->{materials});
            }
            my $itemtype = getitemtypeinfo($item->{itype});
            $item->{itemtype} = $itemtype->{description};
            push @items, $item;
        }
        $template->param(items => \@items);
    }

    if ( $order->{'unitprice'} == 0 ) {
        $order->{'unitprice'} = '';
    }

    my $suggestion   = GetSuggestionInfoFromBiblionumber($order->{'biblionumber'});

    my $authorisedby = $order->{'authorisedby'};
    my $member = GetMember( borrowernumber => $authorisedby );

    my $budget = GetBudget( $order->{'budget_id'} );

    $template->param(
        AcqCreateItem         => $AcqCreateItem,
        count                 => 1,
        biblionumber          => $order->{'biblionumber'},
        ordernumber           => $order->{'ordernumber'},
        biblioitemnumber      => $order->{'biblioitemnumber'},
        booksellerid          => $order->{'booksellerid'},
        freight               => $freight,
        gst                   => $gst,
        name                  => $bookseller->{'name'},
        date                  => format_date($order->{entrydate}),
        title                 => $order->{'title'},
        author                => $order->{'author'},
        copyrightdate         => $order->{'copyrightdate'},
        isbn                  => $order->{'isbn'},
        seriestitle           => $order->{'seriestitle'},
        bookfund              => $budget->{budget_name},
        quantity              => $order->{'quantity'},
        quantityreceivedplus1 => $order->{'quantityreceived'} + 1,
        quantityreceived      => $order->{'quantityreceived'},
        rrp                   => $order->{'rrp'},
        ecost                 => sprintf( "%.2f",$order->{'ecost'}),
        unitprice             => sprintf( "%.2f",$order->{'unitprice'}),
        memberfirstname       => $member->{firstname} || "",
        membersurname         => $member->{surname} || "",
        invoice               => $invoice,
        datereceived          => $datereceived->output(),
        datereceived_iso      => $datereceived->output('iso'),
        notes                 => $order->{notes},
        suggestionid          => $suggestion->{suggestionid},
        surnamesuggestedby    => $suggestion->{surnamesuggestedby},
        firstnamesuggestedby  => $suggestion->{firstnamesuggestedby},
    );
}
else {
    my @loop;
    for ( my $i = 0 ; $i < $count ; $i++ ) {
        my %line = %{ @$results[$i] };

        $line{invoice}      = $invoice;
        $line{datereceived} = $datereceived->output();
        $line{freight}      = $freight;
        $line{gst}          = $gst;
        $line{title}        = @$results[$i]->{'title'};
        $line{author}       = @$results[$i]->{'author'};
        $line{booksellerid}   = $booksellerid;
        push @loop, \%line;
    }

    $template->param(
        loop         => \@loop,
        booksellerid   => $booksellerid,
    );
}
my $op = $input->param('op');
if ($op and $op eq 'edit'){
    $template->param(edit   =>   1);
}
output_html_with_http_headers $input, $cookie, $template->output;
