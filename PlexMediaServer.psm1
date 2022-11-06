<#
References:
https://www.plexopedia.com/plex-media-server/api/

# GET http://<plex-media-server-ip-or-host>:32400/[key]?X-Plex-Token=[PlexToken]

/actions
/activities
/butler
/applications
	/[APPLICATIONSPLUGINNAME]
		/
			/applications
				/[APPLICATIONSPLUGINNAME]
			/:
				/plugins
					/[APPLICATIONSPLUGINBUNDLEID]
/channels
	/all
		/
			/video
				/[VIDEOPLUGINNAME]
			/applications
				/[APPLICATIONSPLUGINNAME]
			/music
				/[MUSICPLUGINNAME]
	/recentlyViewed
		/
			/applications
				/[APPLICATIONSPLUGINNAME]
			/video
				/[VIDEOPLUGINNAME]
			/music
				/[MUSICPLUGINNAME]
/clients
/devices
/diagnostics
/hubs
/library
	/sections
		/[key]
			/all
				&id=[ratingKey]
				[PUT]
					&title.value=NEW TITLE FOR ITEM
					&collection.locked=1
					&title.locked=1
					&titleSort.locked=1
					&artist.id.value=150766
			/unwatched
			/newest
			/recentlyAdded
			/recentlyViewed
			/recentlyViewedShows
			/onDeck
			/folder
	/recentlyAdded
		/
			/library
				/metadata
					/[ratingKey]
						/children
	/metadata
		/[ratingKey]
	/onDeck
/livetv
	/dvrs
	/epg
	/sessions
/media
	/grabbers
	/providers
	/subscriptions
/metadata
	/movie
	/music
	/series
/music
	/[MUSICPLUGINNAME]
		/
			/music
				/[MUSICPLUGINNAME]
			/:
				/plugins
					/[MUSICPLUGINBUNDLEID]
/neighborhood
/playQueues
/player
/playlists
/resources
/search
/server
	/servers
/servers
/statistics
/system
	/library
	/plugins
/transcode
/updater
/user
/video
	/[VIDEOPLUGINNAME]
		/
			/video
				/[VIDEOPLUGINNAME]
			/:
				/plugins
					/[VIDEOPLUGINBUNDLEID]
#>
function Get-Token { # TODO: Skipping for now since working locally can be done without token.
	[CmdletBinding(DefaultParameterSetName = 'LocalServer')]
	param (
		# Get token from plex.tv instead of through local server.
		[Parameter(Mandatory = $false
				  ,ParameterSetName = 'OnlineServer'
				  ,HelpMessage = 'Get token from plex.tv instead of through local server.')]
		[switch]
		$Online
		,
		# Server address for the Plex Media Server. Defaults to app.plex.tv.
		[Parameter(Mandatory = $true
				  ,ParameterSetName = 'LocalServer'
				  ,HelpMessage = 'Server address for the Plex Media Server. Defaults to app.plex.tv.')]
		[Alias('Address')]
		[ValidateNotNullOrEmpty()]
		[string]
		$Server
		,
		# TCP port for the Plex Media Server. Defaults to 32400 if a server is specified, otherwise 443.
		[Parameter(Mandatory = $false
				  ,ParameterSetName = 'LocalServer'
				  ,HelpMessage = 'TCP port for the Plex Media Server. Defaults to 32400 if a server is specified, otherwise 443.')]
		[int]
		$Port
		,
		# Use plain http instead of https. Defaults to using https.
		[Parameter(Mandatory = $false
				  ,ParameterSetName = 'LocalServer'
				  ,HelpMessage = 'Use plain http instead of https. Defaults to using https.')]
		[switch]$NoSsl
		,
		# Credential object for logging into Plex Media Server.
		[Parameter(Mandatory = $false
				  ,HelpMessage = 'Credential object for logging into Plex Media Server.')]
		[ValidateNotNull()]
		[System.Management.Automation.PSCredential]
		[System.Management.Automation.Credential()]
		$Credential = [System.Management.Automation.PSCredential]::Empty
	)

	begin {
		$Protocol = 'https'
		if ($NoSsl)  { $Protocol = 'http' }
		if (!$Port)  { $Port = 32400 }

		if ($Online) {
			$Server = 'app.plex.tv'
			$Port = 443
		}

		$Uri = "$($Protocol)://$($Server):$($Port)"
	}

	process {
		Write-Host $Plex.server -ForegroundColor Magenta
		$Result = Invoke-WebRequest -Uri $Uri
		if ($Result.StatusCode -eq 200) {
			$PleXml = [xml]$Result.Content
		}
	}

	end {
		return $PleXml.MediaContainer
	}
}

function Get-Account { # TODO: Use some universal/global connection string rather than Uri.
	[CmdletBinding()]
	param (
		# Uri
		[Parameter(Mandatory = $true)]
		[uri]
		$Uri
	)
	
	begin {
		$RequestUri = "$($Uri.OriginalString)/accounts"
	}
	
	process {
		$Result = Invoke-WebRequest -Uri $RequestUri
		$PleXml = [xml]$Result.Content
	}
	
	end {
		return $PleXml.MediaContainer.Account
	}
}

function Get-Device { # TODO: Use some universal/global connection string rather than Uri.
	[CmdletBinding()]
	param (
		# Uri
		[Parameter(Mandatory = $true)]
		[uri]
		$Uri
	)
	
	begin {
		$RequestUri = "$($Uri.OriginalString)/devices"
	}
	
	process {
		$Result = Invoke-WebRequest -Uri $RequestUri
		$PleXml = [xml]$Result.Content
	}
	
	end {
		return $PleXml.MediaContainer.Device
	}
}

function Connect-Server { # TODO: Either replace New-Server, or figure out how to make it work a bit like Connect-PSSession
	[CmdletBinding()]
	param (
		
	)
	
	begin {}
	
	process {
		
	}
	
	end {}
}
function New-Server { # TODO: Figure out how to get it working something like New-PSSession, to be used in combination with Connect-Server, Disconnect-Server etc.
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true)]
		[Alias('Address')]
		[string]
		$Server
		,
		[Parameter(Mandatory = $false)]
		[Alias('PlexToken')]
		[string]
		$Token
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
			Token  = $Token
		}

		try {
			$Result = Invoke-WebRequest -Uri $Plex.Server
		}
		catch {
			throw "Server returned $($Result.StatusCode): $($Result.StatusDescription). Error: " + $_
		}
		$PleXml = [xml]$Result.Content
		$Capabilies = $PleXml.MediaContainer
	}

	end {
		return $Capabilies
	}
}

function Get-Library { # TODO: Maybe split into multiple functions for each library type.
	# GET http://[IP address]:32400/library/sections/?X-Plex-Token=[PlexToken]
	# GET http://[IP address]:32400/library/sections/[Movies Library ID]/all?X-Plex-Token=[PlexToken]
	# GET http://[IP address]:32400/library/sections/[TV Shows Library ID]/all?X-Plex-Token=[PlexToken]
	# GET http://[IP address]:32400/library/sections/[Music Library ID]/all?X-Plex-Token=[PlexToken]
	# GET http://[IP address]:32400/library/sections/[Photo Library ID]/all?X-Plex-Token=[PlexToken]
	# GET http://[IP address]:32400/library/sections/[Videos Library ID]/all?X-Plex-Token=[PlexToken]
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
