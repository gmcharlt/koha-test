
<h1 id="logo"><a href="/cgi-bin/koha/mainpage.pl">[% LibraryName %]</a></h1><!-- Begin Patrons Admin Resident Search Box -->

<div id="header_search">
	<div id="contract_description_search" class="residentsearch">
	<p class="tip">Search by contract name or/and description:</p>
	<form action="[% script_name %]" method="post">
		<input type="text" name="searchfield" size="40" value="[% searchfield %]" />
		<input type="submit" class="submit" name="search" value="Search" />
	</form>	
	</div>

    [% INCLUDE 'patron-search-box.inc' %]

	[% IF ( CAN_user_catalogue ) %]
    <div id="catalog_search" class="residentsearch">
	<p class="tip">Enter search keywords:</p>
		<form action="/cgi-bin/koha/catalogue/search.pl"  method="get" id="cat-search-block">
			 <input type="text" name="q" id="search-form" size="40" value="" title="Enter the terms you wish to search for." class="form-text" />
				<input type="submit" value="Submit"  class="submit" />
		</form>
	</div>[% END %]
			<ul>
            <li><a href="#contract_description_search">Search contracts</a></li>
            [% IF ( CAN_user_circulate ) %]<li><a href="#circ_search">Check out</a></li>[% END %]
            [% IF ( CAN_user_catalogue ) %]<li><a href="#catalog_search">Search the catalog</a></li>[% END %]
			</ul>	
</div>
<!-- End Patrons Admin Resident Search Box -->
