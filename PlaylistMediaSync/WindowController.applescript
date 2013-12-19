
(*
 WindowController.applescript
 Windows and Panels
 
 Created by Red Menace on 06/15/13, last updated/reviewed on 07/06/13
 Copyright (c) 2013 Menace Enterprises,  red_menace[at]menace-enterprises[dot]com
 
 This class provides for multiple window instances.
 Note that the controller loads its nib lazily - the window isn't loaded from the nib until it is shown.
 *)

##################################################
# MARK: -
# MARK: Application Properties
#
property Cocoa : current application -- just a shortcut


script WindowController
	
	
	##################################################
	# MARK: -
	# MARK: Script Properties
	#
	property parent : class "NSWindowController"
	
	
	##################################################
	# MARK: -
	# MARK: Interface Editor Bindings
	# these properties are bound to and synchronized with various UI attributes
	#
	# the following WindowController items allow access before showing the window
	property windowTitle : missing value
	property labelContents : missing value
	property textFieldContents : missing value
	
	
	##################################################
	# MARK: -
	# MARK: Delegate Handlers
	#
	on windowWillLoad() -- initialize before showing window
		log "windowWillLoad ...  " & quoted form of (windowTitle as text)
		# whatever
	end windowWillLoad
	
	
	on windowWillClose_(notification)
        # just pass on the notification - note that we need to use the AppDelegate instance, not the class
        --current application's NSApp's delegate's windowWillClose_(notification)
	end windowWillClose_
	
	
	##################################################
	# MARK: -
	# MARK: Class Handlers
	#
	on init() -- default init
		continue initWithWindowNibName_("WindowTemplate") -- name of window xib
		return result
	end init
	
	
end script

