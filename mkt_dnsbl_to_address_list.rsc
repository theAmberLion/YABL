# THe command file get contents - has a known limitation of 4095 bytes. So if the file you are trying to read is larger than that - it will fail!

:local content [/file get [/file find name=yabl_dnsbl.txt] contents] ;
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
# don't process blank lines
	:if ($line != "\r") do={
		/ip firewall address-list add list=yabl_dnsbl address=[:resolve $line] comment=$line
	}
} 
