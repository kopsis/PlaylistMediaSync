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
property NSFileManager : class "NSFileManager"
property NSDirectoryEnumerator : class "NSDirectoryEnumerator"
property PathConverter : class "PathConverter"
property NSMutableSet : class "NSMutableSet"

script AppDelegate
	property parent : class "NSObject"
    
    property playlistName : missing value
    property playlistSelection: missing value
    property mediaPath : missing value
    property mediaPathValue : missing value
    property progressText : missing value
    property progressIndicator : missing value
    property errorTextView : missing value
    property errorWindow : missing value
    property nil : missing value
    
    property simulate : false
	
    on awakeFromNib()
        tell me to log "in awakeFromNib"
        tell current application's NSUserDefaults to set defaults to standardUserDefaults()
        tell defaults to registerDefaults_({selectedPlaylist:"Playlist"})
        tell defaults to registerDefaults_({selectedPath:"/"})
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
        progressIndicator's stopAnimation_(me)
        
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
        tell current application's NSFileManager to set fileMan to defaultManager()

        -- Get the selected playlist and path
        set selectedPlaylist to playlistName's titleOfSelectedItem() as Unicode text
        tell me to log "Syncing playlist: " & selectedPlaylist
        set selectedPath to |path|() of mediaPath's |URL|()
        tell me to log "Syncing to: " & selectedPath
        
        -- Start progress
        progressText's setStringValue_("Scanning playlist ...")
        progressText's displayIfNeeded()
        progressIndicator's setIndeterminate_(true)
        progressIndicator's displayIfNeeded()
        progressIndicator's startAnimation_(me)

        -- Get all tracks from selected playlist
        set trackList to {}
        tell application "iTunes"
            repeat with aTrack in tracks of user playlist selectedPlaylist
                set theFile to get location of aTrack as text
                -- tell me to log theFile
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
        progressText's displayIfNeeded()
        progressIndicator's setIndeterminate_(false)
        progressIndicator's displayIfNeeded()
        progressIndicator's setDoubleValue_(1.0)
        
        -- Copy tracks to target
        set failures to {}
        set writtenFileSet to NSMutableSet's alloc()'s initWithCapacity_(count of trackList)
        set trackCount to count of trackList
        set i to 0.0
        repeat with aTrack in trackList
            set i to i + 1.0
            progressText's setStringValue_(tname of aTrack)
            progressText's displayIfNeeded()
            progressIndicator's setDoubleValue_((i * 100.0)/trackCount)
            progressIndicator's displayIfNeeded()
            
            -- set the root of the destination path
            set pathString to selectedPath as Unicode text
            
            -- sanitize and set the artist portion of the destination path
            copy my sanitize(tartist of aTrack as Unicode text) to artistString
            set artistPath to pathString & "/" & artistString
            
            -- sanitize and set the album portion of the destination path
            copy my sanitize(talbum of aTrack as Unicode text) to albumString
            set albumPath to artistPath & "/" & albumString
            
            -- sanitize and set the full destination path
            copy my sanitize(tname of aTrack as Unicode text) to trackString
            set trackFile to (tnum of aTrack as Unicode text) & " " & trackString & ".mp3"
            set destinationPath to albumPath & "/" & trackFile
            
            -- set the source path
            set sourcePath to tfile of aTrack
            set sourcePathPosix to PathConverter's createPosixFromHFS_(sourcePath)

            -- create folder as needed
            if simulate is false
                set status to fileMan's createDirectoryAtPath_withIntermediateDirectories_attributes_error_(albumPath, true, nil, nil)
            else
                set status to true
            end if
            if status is false then
                tell me to log "Error creating directory: " & albumPath
            end if
            if status is true then
                -- Determine if identical file already exists at destination
                set skipCopy to false
                set destinationExists to fileMan's fileExistsAtPath_(destinationPath)
                if destinationExists is true
                    -- Are size and date the same?
                    set destinationAttributes to fileMan's attributesOfItemAtPath_error_(destinationPath, nil)
                    set sourceAttributes to fileMan's attributesOfItemAtPath_error_(sourcePathPosix, nil)
                    if sourceAttributes's fileSize() equals destinationAttributes's fileSize() then
                        if sourceAttributes's fileCreationDate() equals destinationAttributes's fileCreationDate() then
                            -- files match
                            tell me to log "Up to date: " & sourcePathPosix
                            set skipCopy to true
                        else
                            tell me to log "Creation date mismatch"
                        end if
                    else
                        tell me to log "File size mismatch"
                    end if
                    if skipCopy is false
                        -- Delete the destination file
                        set status to fileMan's removeItemAtPath_error_(destinationPath, missing value)
                        if status is false
                            -- Delete failed so skip copy
                            set skipCopy to true
                            tell me to log "Failed deleting old target: " & destinationPath
                        end if
                    end if
                end if
                -- Copy file if needed
                if skipCopy is false
                    tell me to log "Copying " & sourcePathPosix & " to " & destinationPath
                    if simulate is false
                        set status to fileMan's copyItemAtPath_toPath_error_(sourcePathPosix, destinationPath, nil)
                    else
                        set status to true
                    end if
                    -- Did copy work?
                    if status is false then
                        tell me to log "Copy failed: " & sourcePathPosix
                        set failures to failures & {sourcePathPosix}
                    else
                        -- Add to copied files set (so we can look for orphans later)
                        writtenFileSet's addObject_(destinationPath)
                    end if
                else
                    -- Add skipped files to copied files set (they are not orphans)
                    writtenFileSet's addObject_(destinationPath)
                end if
            end if
        end repeat

        -- End progress
        progressText's setStringValue_("Cleaning up ...")
        progressIndicator's setIndeterminate_(true)
        progressIndicator's startAnimation_(me)
        delay 2
        
        -- Delete orphans on target
        tell me to log "Copied files: " & writtenFileSet's |count|()
        -- Create set with full paths of all files/dirs in destination path
        set destinationFileSet to NSMutableSet's alloc()'s init()
        set dirIterator to fileMan's enumeratorAtPath_(pathString)
        set allFiles to dirIterator's allObjects()
        repeat with aFile in allFiles
            destinationFileSet's addObject_(pathString & "/" & aFile)
        end repeat
        -- Subtract the set of written files to get the list of dirs and orphans
        destinationFileSet's minusSet_(writtenFileSet)
        tell me to log "Orphaned files: " & destinationFileSet's |count|()
        -- Iterate over what remains looking for files
        set setIterator to destinationFileSet's objectEnumerator()
        set aFile to setIterator's nextObject()
        repeat while aFile /= missing value
            -- is this a file?
            set {status, isDir} to fileMan's fileExistsAtPath_isDirectory_(aFile, reference)
            if isDir is false then
                tell me to log "Delete file: " & aFile
                if simulate is false
                    set status to fileMan's removeItemAtPath_error_(aFile, missing value)
                else
                    set status to true
                end if
                -- Remove from the set
                destinationFileSet's removeObject_(aFile)
            end if
            set aFile to setIterator's nextObject()
        end repeat
        -- Iterate repeatedly, deleting the first empty directory we find on each iteration
        set deadlocked to false
        set lastCount to destinationFileSet's |count|()
        repeat while lastCount is greater than 0 and deadlocked is false
            -- Iterate until we find an empty directory
            set setIterator to destinationFileSet's objectEnumerator()
            set aFile to setIterator's nextObject()
            repeat while aFile /= missing value
                -- tell me to log "Checking for empty dir: " & aFile
                -- Is directory empty?
                set dirContents to fileMan's contentsOfDirectoryAtPath_error_(aFile, missing value)
                if dirContents is missing value then
                    set contentsCount to 0
                else
                    set contentsCount to dirContents's |count|()
                end if
                if contentsCount is 0 then
                    -- Directory is empty so delete it
                    tell me to log "Deleting dir: " & aFile
                    if simulate is false
                        set status to fileMan's removeItemAtPath_error_(aFile, missing value)
                    end if
                    -- Remove from the set. We do this unconditionally because even if the delete failed, we don't want to try this one again.
                    destinationFileSet's removeObject_(aFile)
                    -- We've mutated the set, so bail out of the inner loop
                    exit
                end if
                set aFile to setIterator's nextObject()
            end repeat
            -- If the set size hasn't changed, we couldn't find anything to delete - stop iterating
            set thisCount to destinationFileSet's |count|()
            if thisCount = lastCount then
                set deadlocked to true
                tell me to log "Deadlocked, bailing out of orphan cleanup"
            else
                set lastCount to thisCount
            end if
        end repeat

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
        -- tell me to log "Running python script: " & pythonscript & args
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