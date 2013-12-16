--
--  AppDelegate.applescript
--  PlaylistMediaSync
--
--  Created by David Kessler on 12/16/13.
--  Copyright (c) 2013 Kopsis. All rights reserved.
--

property NSURL : class "NSURL"
property NSUserDefaults : class "NSUserDefaults"
property NSBundle : class "NSBundle"

script AppDelegate
	property parent : class "NSObject"
    
    property playlistName : missing value
    property playlistSelection: missing value
    property mediaPath : missing value
    property progressText : missing value
    property progressIndicator : missing value
	
    on awakeFromNib()
        tell me to log "in awakeFromNib"
        tell current application's NSUserDefaults to set defaults to standardUserDefaults()
        tell defaults to registerDefaults_({selectedPlaylist:"Playlist"})
        tell defaults to registerDefaults_({selectedPath:"/Volumes/Music/"})
    end awakeFromNib
    
	on applicationWillFinishLaunching_(aNotification)
		-- Insert code here to initialize your application before any files are opened
        tell current application's NSUserDefaults to set defaults to standardUserDefaults()
        
        tell me to log "in applicationWillFinishLaunching"

        -- Get list of user playlists from iTunes
        set all_userps to {}
        tell application "iTunes"
            set all_userps to (get name of every user playlist whose smart is false and special kind is none)
        end tell
        
        -- Populate pop up button with playlist names
        playlistName's removeAllItems()
        playlistName's addItemsWithTitles_(all_userps)
        
        -- Set playlist selection from defaults
        tell defaults to set selectedPlaylist to objectForKey_("selectedPlaylist")
        tell me to log "playlist from defaults: " & selectedPlaylist
        set selectedPlaylistIdx to playlistName's indexOfItemWithTitle_(selectedPlaylist)
        if selectedPlaylistIdx >= 0 then
            playlistName's selectItemAtIndex_(selectedPlaylistIdx)
        else
            tell me to log "No playlist named " & selectedPlaylist
        end if
        
        -- Clear progress
        progressText's setStringValue_("")
        progressIndicator's setDoubleValue_(0.0)
        progressIndicator's stopAnimation()
        
        -- Set path from defaults
        tell defaults to set selectedPath to objectForKey_("selectedPath") as Unicode text
        helperSetMediaPath_(selectedPath)
	end applicationWillFinishLaunching_
	
    on applicationShouldTerminateAfterLastWindowClosed_(theApplication)
        return YES
    end applicationShouldTerminateAfterLastWindowClosed_
    
	on applicationShouldTerminate_(sender)
		-- Insert code here to do any housekeeping before your application quits
        -- Save playlist selection as default
        tell current application's NSUserDefaults to set defaults to standardUserDefaults()
        if playlistSelection /= missing value then
            tell me to log "Selected playlist: " & playlistSelection
            tell defaults to setObject_forKey_(playlistSelection, "selectedPlaylist")
		end if
        return current application's NSTerminateNow
	end applicationShouldTerminate_

    on helperSetMediaPath_(pathText)
        -- Set the path control to the selected folder
        tell me to log "Setting media path to " & pathText
        set newURL to NSURL's alloc()'s initFileURLWithPath_(pathText)
        mediaPath's setURL_(newURL)
        -- Save as default
        tell current application's NSUserDefaults to set defaults to standardUserDefaults()
        tell defaults to setObject_forKey_(pathText, "selectedPath")
    end helperSetMediaPath_
    
    on changePath_(sender)
        -- When path control is clicked ...
        
        -- Prompt user to choose a folder
        set folderName to POSIX path of (choose folder with prompt "Select destination media")
        helperSetMediaPath_(folderName)
    end changePath_
    
    on doSync_(sender)
        -- When Sync button is clicked ...
        tell me to log "Sync Button clicked"
        -- Get the selected playlist and path
        set selectedPlaylist to playlistName's titleOfSelectedItem() as Unicode text
        tell me to log selectedPlaylist
        set selectedPath to |path|() of mediaPath's |URL|()
        tell me to log selectedPath
        
        -- Start progress
        progressText's setStringValue_("Scanning playlist ...")
        progressIndicator's setIndeterminate_(true)
        progressIndicator's startAnimation_(me)
        
        -- Get all tracks from selected playlist
        set trackList to {}
        tell application "iTunes"
            repeat with aTrack in tracks of user playlist selectedPlaylist
                set theFile to get location of aTrack
                set theArtist to get artist of aTrack
                set theAlbum to get album of aTrack
                set theName to get name of aTrack
                set theNumber to get track number of aTrack
                set fmtNumber to my add_leading_zeros(theNumber, 1)
                set trackList to trackList & {{tfile:theFile, tartist:theArtist, talbum:theAlbum, tname:theName, tnum:fmtNumber}}
            end repeat
        end tell
        
        -- Start progress
        progressIndicator's stopAnimation_(me)
        progressText's setStringValue_("Copying files ...")
        progressIndicator's setIndeterminate_(false)
        progressIndicator's setDoubleValue_(1.0)
        
        -- Copy tracks to target
        set trackCount to count of trackList
        set i to 0.0
        repeat with aTrack in trackList
            set i to i + 1.0
            progressText's setStringValue_(tname of aTrack)
            progressIndicator's setDoubleValue_((i * 100.0)/trackCount)
            
            -- set artistPath to rootDir & tartist of aTrack
            set pathString to selectedPath as Unicode text
            tell me to log pathString
            set pathString to pathString & "/" & tartist of aTrack as Unicode text
            tell me to log pathString
            copy my sanitize(pathString) to artistPath
            tell me to log artistPath
            set artistPathAlias to POSIX file artistPath
            set albumPath to artistPath & "/" & talbum of aTrack
            set albumPathAlias to POSIX file albumPath
            set trackFile to tnum of aTrack & " " & tname of aTrack & ".mp3"

            tell application "Finder"
                -- check for Artist folder
                if not (exists artistPathAlias) then
                    -- create folder
                    --make new folder at selectedPath as POSIX file with properties {name:tartist of aTrack}
                end if
                -- check for Album folder
                if not (exists albumPathAlias) then
                    -- create folder
                    --make new folder at artistPathAlias with properties {name:talbum of aTrack}
                end if
                --set theDupe to duplicate tfile of aTrack to folder albumPathAlias with replacing
                --set name of theDupe to trackFile
                --log (trackFile)
            end tell
            
            delay 0.1
        end repeat

        -- End progress
        progressText's setStringValue_("Cleaning up ...")
        progressIndicator's setIndeterminate_(true)
        progressIndicator's startAnimation_(me)
        delay 5
        
        -- Delete orphans on target

        -- Clear progress
        progressIndicator's stopAnimation_(me)
        progressIndicator's setIndeterminate_(false)
        progressText's setStringValue_("")
        progressIndicator's setDoubleValue_(0.0)
        
        tell me to log "Sync Done - " & count of trackList & " items"
    end doSync_

    on sanitize(theText)
        if theText = "" then
            return theText
        else
            return python("sanitize.py", {theText})
        end if
    end sanitize
    
    on python(pythonscript, arglist)
        set args to ""
        repeat with arg in arglist
            set args to args & " " & quoted form of arg
        end repeat
        tell me to log "Running python script: " & pythonscript & args
        set theFolder to current application's NSBundle's mainBundle()'s bundlePath() as text
        set pythonscript to quoted form of POSIX path of (theFolder & "/Contents/Resources/" & pythonscript as string)
        tell me to return do shell script "/usr/bin/python " & pythonscript & args
    end python
    
    on tcl(tclscript, arglist)
        set args to ""
        repeat with arg in arglist
            set args to args & " " & quoted form of arg
        end repeat
        if debugging then log "Running tcl script: " & tclscript & args
        set tclscript to quoted form of POSIX path of ((path to me) & "/Contents/Resources/" & tclscript as string)
        tell me to return do shell script "/usr/bin/tclsh " & tclscript & args
    end tcl
    
    on shellcmd(cmd)
        if debugging then log "Running shell command: " & cmd
        tell me to return do shell script cmd
    end shellcmd
    
    on add_leading_zeros(this_number, max_leading_zeros)
        -- Add leading zeros to a number
        set the threshold_number to (10 ^ max_leading_zeros) as integer
        if this_number is less than the threshold_number then
            set the leading_zeros to ""
            set the digit_count to the length of ((this_number div 1) as string)
            set the character_count to (max_leading_zeros + 1) - digit_count
            repeat character_count times
                set the leading_zeros to (the leading_zeros & "0") as string
            end repeat
            return (leading_zeros & (this_number as text)) as string
            else
            return this_number as text
        end if
    end add_leading_zeros
end script