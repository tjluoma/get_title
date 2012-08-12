#!/bin/zsh
# Purpose: given an http(s) URL, get the <title> and output it to stdout

NAME="$0:t"

i="$@"

trap control_c SIGINT

	# run if user hits control-c
control_c()
{
	# if growlnotify is found, tell user we are exiting and clear 'sticky' growl alert
	(( $+commands[growlnotify] )) && growlnotify --appIcon "Terminal" --identifier "$NAME"  --message "Giving up $TITLE for $i" --title "$NAME"

	exit 1
}

	# if growlnotify is found, tell user we have started
(( $+commands[growlnotify] )) && growlnotify --sticky --appIcon "Terminal" --identifier "$NAME"  --message "Fetching <title> for $i" --title "$NAME"

	# takes input (which is assumed to be a URL) and dumps the HTML source to stdout (curl)
	# then removes all control characters such as new lines so we get one lone line of input (tr)
	# and then strips out everything after (and including) </title> and up to (and including) <title> (sed)
	# note that sed regex is case insensitive

TITLE=$(curl -sL "$i" | tr -d '[:cntrl:]' | sed 's#</[Tt][Ii][Tt][Ll][Ee]>.*##g ; s#.*<[Tt][Ii][Tt][Ll][Ee]>##g')

	# extra special processing for the NYTimes and its stupid login request
	# there may be other special cases, so I've left this as a 'case' statement to make it easier to add later

case "$TITLE" in
	"Log In - The New York Times")

			(( $+commands[growlnotify] )) && \
			growlnotify --sticky --appIcon "Terminal" --identifier "$NAME" --message "Rechecking NYTimes URL $TITLE for $i" --title "$NAME"

			TITLE=$(curl -sL "$i" | fgrep -i '<title' | sed 's#<title>##g ; s#</title>##g')
	;;

esac

	# if we didn't get any title, exit ugly.
[[ "$TITLE" == "" ]] && exit 1

	# IFF `titlecase` is installed, use it.
	# (for explanation, see
	# http://daringfireball.net/2008/05/title_case and
	# see http://daringfireball.net/2008/08/title_case_update and
	# http://plasmasturm.org/code/titlecase/ )
	#
	# if you use brew, it can be installed via `brew www titlecase`
if (( $+commands[titlecase] ))
then
		echo "$TITLE" | titlecase
else
		# if `titlecase` isn't found, just output the title as-is
		echo "$TITLE"
fi

	# if growlnotify is found, tell user what we found
(( $+commands[growlnotify] )) && growlnotify --appIcon "Terminal" --identifier "$NAME"  --message "Found $TITLE for $i" --title "$NAME"

exit 0


#
# NOTE: the below code is an earlier version which used `tidy` (which is installed in OS X by
# default) and `lynx` (which is not). It also changed colons and slashes to dashes, which is useful
# when creating TITLEs which will be used for filenames. Unfortunately this seemed to be much
# slower, so I changed it for the above.
#
# TITLE=$(curl -s -L "$@" |\
# 		tidy -utf8 -wrap 0 -q --force-output yes --show-errors 0 --show-warnings no --output-xhtml yes |\
# 			fgrep '<title>' |\
# 				sed 's#<title>##g; s#</title>##g' |\
# 					lynx -width=1000 -stdin -dump -nomargins -assume_charset=utf8 |\
# 						tr -s '/|:' '-' |\
# 							tr -d '[:cntrl:]')
#EOF
