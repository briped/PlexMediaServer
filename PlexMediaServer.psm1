function New-Server { # TODO: Everything
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[Alias('Address')]
		[string]
		$Server
		,
		[Parameter(Mandatory = $true)]
		[Alias('Token')]
		[string]
		$PlexToken
		,
		[Parameter(Mandatory = $false)]
		[int]
		$Port = 32400
		,
		[Parameter(Mandatory = $false)]
		[switch]$NoSsl
	)
	
	begin {
		$Protocol = 'https'
		if ($NoSsl)  { $Protocol = 'http' }
	}
	
	process {
		$Plex = New-Object -TypeName PSCustomObject -ArgumentList @{
			Server = "$($Protocol)://$($Server):$($Port)"
			Token  = $PlexToken
		}
	}
	
	end {
		return $Plex
	}
}
function Get-Library { # TODO: Split into multiple functions for each library type.
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $false
			,ParameterSetName = "ByName")]
		[Alias('Name')]
		[string[]]
		$Title
		,
		[Parameter(Mandatory = $false
			,ParameterSetName = "ById")]
		[Alias('Id')]
		[int[]]
		$Key
		,
		[Parameter(Mandatory = $false
			,ParameterSetName = "ByType")]
		[ValidateSet('movie'
			,'show'
			,'music'
			,'artist')]
		[string[]]
		$Type
		,
		[Parameter(Mandatory = $false
			,ParameterSetName = "All")]
		[switch]$All
		,
		[Parameter(Mandatory = $false)]
		[Alias('Token')]
		[string]
		$PlexToken
		,
		[Parameter(Mandatory = $false)]
		[Alias('Address')]
		[string]
		$Server
		,
		[Parameter(Mandatory = $false)]
		[int]
		$Port = 32400
		,
		[Parameter(Mandatory = $false)]
		[switch]$Ssl
	)
	
	begin {
		if (!$All) {
			if ($Key)   { $QueryBy = 'Key' }
			if ($Title) { $QueryBy = 'Title' }
			if ($Type)  {
				$QueryBy = 'Type'
				if ($Type -eq 'music') { $Type = 'artist' }
			}
		}

		$Protocol = 'http'
		if ($Ssl)  { $Protocol = 'https' }

		$Uri = "$($Protocol)://$($Server):$($Port)/library/sections/?X-Plex-Token=$($PlexToken)"
		$Results = @()
	}
	
	process {
		if ($All) {
			$Result = Invoke-WebRequest -Uri $Uri
			if ($Result.StatusCode -eq 200) {
				$Results = ([xml]$Result.Content).MediaContainer.Directory
			}
		}
		else {
			foreach ($Q in (Get-Variable -ValueOnly -Name $QueryBy)) {
				$Result = Invoke-WebRequest -Uri $Uri
				if ($Result.StatusCode -eq 200) {
					$Results += ([xml]$Result.Content).MediaContainer.Directory | Where-Object {
						$_."$($QueryBy.ToLower())" -eq $Q
					}
				}
			}
		}
	}
	
	end {
		return $Results
	}
}

function Get-LibraryItem { # TODO: Everything
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[Alias('Id')]
		[int]
		$Library
		,
		[Parameter(Mandatory = $false)]
		[Alias('Token')]
		[string]
		$PlexToken
		,
		[Parameter(Mandatory = $false)]
		[Alias('Address')]
		[string]
		$Server
		,
		[Parameter(Mandatory = $false)]
		[int]
		$Port = 32400
		,
		[Parameter(Mandatory = $false)]
		[switch]$Ssl
	)
	
	begin {
		$Protocol = 'http'
		if ($Ssl)  { $Protocol = 'https' }
		<# artist
		key            title
		---            -----
		all            All Artists
		albums         By Album
		genre          By Genre
		decade         By Decade
		year           By Year
		collection     By Collection
		recentlyAdded  Recently Added
		folder         By Folder
		search?type=8  Search Artists...
		search?type=9  Search Albums...
		search?type=10 Search Tracks...
		#>
		$Type = 'search'
		$Query = 'Man from Earth'
		$ArgumentsTable = @{
			'type'         = 9
			'query'        = $Query
			'X-Plex-Token' = $PlexToken
		}
		$ArgumentsArray = @()
		foreach ($Key in $ArgumentsTable.Keys) {
			$ArgumentsArray += "$($Key)=$($ArgumentsTable[$Key])"
		}
		$Arguments = $ArgumentsArray -join '&'
		$Uri = "$($Protocol)://$($Server):$($Port)/library/sections/$($Library)/$($Type)?$($Arguments)"
		$Uri
	}
	
	process {
		$Result = Invoke-WebRequest -Uri $Uri
		if ($Result.StatusCode -eq 200) {
			$Results = ([xml]$Result.Content).MediaContainer.Directory
		}
	}
	
	end {
		return $Results
	}
}

<#
GET
https://PLEXSERVER:32400
/library
/metadata
/213279


PUT
https://PLEXSERVER:32400
/library
/sections
/16
/all
?type=9
&id=151291
&includeExternalMedia=1
&title.value=NEW TITLE FOR ITEM
&collection.locked=1
&title.locked=1
&titleSort.locked=1
&artist.id.value=150766
#>