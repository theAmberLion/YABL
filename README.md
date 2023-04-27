# YABL
Yet Another Block List


Just a DNSBL for personal use. 

There are scripts I made, which parses and resolves DNSBL list into MikroTik address-lists. One to resolve host IP address, the other one to ban entire /24 subnet. 

ToDo:

- Make host script perform checks for entries already present in address-list
- Make scripts perform several resolvings to identify dns names with always-changing/load-balancer ip addresses.
