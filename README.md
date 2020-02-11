# CIFv3 API PowerShell Wrapper

Collective Intelligence Framework (CIF) is a threat intelligence framework. This project is a CIFv3 client for PowerShell.

<https://csirtgadgets.com/collective-intelligence-framework>

<https://github.com/csirtgadgets/bearded-avenger>

## Getting Started

Install the module:

```powershell
Install-Module CIF3
```

Load the module:

```powershell
Import-Module CIF3
```

See what functions are available:

```powershell
Get-Command -Module CIF3
```

If you have an existing .cif.yml in your $env:HOME dir, its contents will be read and used automatically. If you've never setup your config file (.cif.yml) before, do so now. At a minimum you must set the Uri and Token parameters.

```powershell
Set-CIF3Config -Uri https://feeds.cif.domain.com -Token aaaabbbbccccdddd
```

## Using the Module

### CIF Instance Configuration

Retrieve your CIFv3 config settings:

```powershell
Get-CIF3Config
```

Set the URI and authorization token to communicate with the desired CIF instance:

```powershell
Set-CIF3Config -Uri 'https://cif.domain.local:5000' -Token 'd81830def81a871f2adbf00c5000000'
```

Test the connection to your configured CIF instance URI (returns $true if working, $false otherwise):

```powershell
Test-CIF3Auth
```

### Tokens

Tokens in CIF are like API keys, used for authenticating and authorizing a user to perform various actions.

List all tokens on the CIF instance:

```powershell
Get-CIF3Token
```

Find a token with username = 'user1@domain.local'

```powershell
Get-CIF3Token -Name user1@domain.local
```

Create a new token called 'writeonly' on the CIF instance. It will have write permissions but no read permissions:

```powershell
New-CIF3Token -Name 'writeonly' -Permission 'Write'
```

Remove the specified token from the CIF instance:

```powershell
Remove-CIF3Token -Id 'abcdef9999888855553333'
```

Update token to be in groups 'everyone' and 'admins':

```powershell
Set-CIF3TokenGroup -Id 'abcdef9999888855553333' -Group everyone, admins
```

### Indicators

Get a list of all indicators (default ResultSize is 100, so 100 will be returned):

```powershell
Get-CIF3Indicator
```

Get up to 500 indicator results that have a `Confidence` of 8 or greater:

```powershell
Get-CIF3Indicator -Confidence 8 -ResultSet 500
```

Get all fqdn indicators reported in the last week that have a 'malware' or 'botnet' tag:

```powershell
Get-CIF3Indicator -IType fqdn -StartTime (Get-Date).AddDays(-7) -EndTime (Get-Date) -Tag malware, botnet
```

Add an indicator for 'baddomain.xyz' at a confidence of 7, a yellow TLP, and tagged as 'malware'

```powershell
Add-CIF3Indicator -Indicator baddomain.xyz -Confidence 7 -Tag malware -TLP yellow
```

### Feeds

Feeds are aggregated and filtered datasets that have had whitelists applied before being returned. Indicator type is the only mandatory parameter when generating a feed.

Get a feed of all fqdn indicators with a confidence of 7.5 or greater:

```powershell
Get-CIF3Feed -IType fqdn -Confidence 7.5
```

# Acknowledgments

* Warren Frame's [PSSlack](https://github.com/RamblingCookieMonster/PSSlack) pwsh module for powershell framework ideas.
* The official csirtgadgets' [CIFv3 Python SDK](https://github.com/csirtgadgets/cifsdk-py-v3) for reference.
