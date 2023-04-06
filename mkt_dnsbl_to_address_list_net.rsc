# Download the DNSBL
:local sourceurl "https://raw.githubusercontent.com/theAmberLion/YABL/main/yabl_dnsbl_ru_propaganda.txt"
/tool fetch url="$sourceurl" mode=https

delay 1s;

# Parse each row and generate address list.
# Mikrotik's command (file get contents) - has a known limitation of 4095 bytes (string variable limitation). So if the file you are trying to read is larger than that - it will fail!
# Look each row for newline and parse it to address-list

{
:local content [/file get [/file find name="yabl_dnsbl_ru_propaganda.txt"] contents];
:local contentLen [:len $content];

:local lineEnd 0;
:local line "";
:local lastEnd 0;

:while ($lineEnd < $contentLen) do={
# depending on file type (linux/windows), "\n" might need to be "\r\n"
	:set lineEnd [:find $content "\n" $lastEnd];
# if there are no more line breaks, set this to be the last one
	:if ([:len $lineEnd] = 0) do={
		:set lineEnd $contentLen;
	}
# get the current line based on the last line break and next one
	:set line [:pick $content $lastEnd $lineEnd];
# depending on "\n" or "\r\n", this will be 1 or 2 accordingly
	:set lastEnd ($lineEnd + 1);
# don't process blank or invalid lines
	:if ([:put [:len $line]] > 3 ) do={
:log info ("DNSBL: Processing $line. ");
# Check if address already present in address-list
		:if ([:len [/ip firewall address-list find where (address=[:resolve $line])]]=0) do={
		# resolve DNS name to IP address, and then convert IP host address to /24 network address. After that, add to address list, while using the dns name as comment.
		:local ResolvedIP [:resolve $line]
		
		:local FirstDot  [:find $ResolvedIP "." 0];
		:log info ("Result FDot: $FirstDot");
		:local SecondDot [:find $ResolvedIP "." ($FirstDot+1)];
		:log info ("Result SDot: $SecondDot");
		:local ThirdDot [:find $ResolvedIP "." ($SecondDot+1)];
		:log info ("Result TDot: $ThirdDot");

		:local NetPrefix ([:pick $ResolvedIP 0 ($FirstDot)] . "." . [:pick $ResolvedIP ($FirstDot+1) ($SecondDot)] . "." . [:pick $ResolvedIP ($SecondDot+1) ($ThirdDot)]);
		:log info ("Result prefix : $NetPrefix");

		:local ResolvedNet "$NetPrefix.0/24";

		/ip firewall address-list add list="cts" address=$ResolvedNet comment="DNSBL net $line";		
		}
	}
#for debugging purposes
#:log info ("DNSBL: Lineend: $lineEnd  Content length: $contentLen ");
}
}

#Clean-up
:log info ("DNSBL: Deleting downloaded file.");
:execute [/file remove [/file find name="yabl_dnsbl_ru_propaganda.txt"]];

:log info ("DNSBL: Script execution finished.");

# This code was inspired by user "skot" from Mikrotik forums: (https://forum.mikrotik.com/viewtopic.php?t=93050#p464218) and by (https://github.com/pwlgrzs/Mikrotik-Blacklist)
