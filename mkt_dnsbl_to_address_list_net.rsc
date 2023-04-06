#Define address list name
:local AddrListName "cts";
# Download the DNSBL
:local sourceurl "https://raw.githubusercontent.com/theAmberLion/YABL/main/testbl.txt";
:local filename "testbl.txt";

:execute [/tool fetch url="$sourceurl" mode=https];

delay 1s;

#Uncomment this if you want address list to be cleared before populating with new addresses. Otherwise, keep this commented and the script will check if the address is already there.
:execute [/ip firewall address-list remove [find where list="$AddrListName"]];


# Parse each row and generate address list.
# Mikrotik's command (file get contents) - has a known limitation of 4095 bytes (string variable limitation). So if the file you are trying to read is larger than that - it will fail!
# Look each row for newline and parse it to address-list

{
:local content [/file get [/file find name="$filename"] contents];
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

	:log info ("DNSBL: Processing [$line]. ");

		# resolve DNS name to IP address, and then convert IP host address to /24 network address. After that, add to address list, while using the dns name as comment.
		:local ResolvedIP [:resolve $line]
		
		:local FirstDot [:find $ResolvedIP "." 0];		
		:local SecondDot [:find $ResolvedIP "." ($FirstDot+1)];		
		:local ThirdDot [:find $ResolvedIP "." ($SecondDot+1)];
		
		#For debugging
		#:log info ("Result FDot: $FirstDot");
		#:log info ("Result SDot: $SecondDot");
		#:log info ("Result TDot: $ThirdDot");
		
		#This creates IP network address from first 3 octets.
		:local NetPrefix ([:pick $ResolvedIP 0 ($FirstDot)] . "." . [:pick $ResolvedIP ($FirstDot+1) ($SecondDot)] . "." . [:pick $ResolvedIP ($SecondDot+1) ($ThirdDot)]);
				
		#This adds ".0/24" suffix
		:local ResolvedNet "$NetPrefix.0/24";

		#For debugging
		#:log info ("Result netaddress : $ResolvedNet");

		# Check if address already present in address-list
		:if ([:len [/ip firewall address-list find where (address=$ResolvedNet)]]=0) do={
			/ip firewall address-list add list="cts" address=$ResolvedNet comment="DNSBL net $line";		
		} else={
		:log info ("Domain [$line] is part from $ResolvedNet and is already present.");
		}
	}
#For debugging 
#:log info ("DNSBL: Lineend: $lineEnd  Content length: $contentLen ");
}
}

#Clean-up
:log info ("DNSBL: Deleting downloaded file $filename.");
:execute [/file remove [/file find name="$filename"]];

:log info ("DNSBL: Script execution finished.");

# This code was inspired by user "skot" from Mikrotik forums: (https://forum.mikrotik.com/viewtopic.php?t=93050#p464218) and by (https://github.com/pwlgrzs/Mikrotik-Blacklist)
