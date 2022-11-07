# polling2

Usage Documentation for ./mac-to-poll.sh.
The following command line switches indicate the environment
-p  --Sets Production
-q  --Sets QA
-d  --Sets Development *Default
Required parameters
-a  --Sets the application name
-f  --Sets the file name.  Repeatable for multiple files
-s  --Sets the store list, comma delimited or filename with comma delimted
Optional parameters
-x  --Expires, integer, number of days from today
-t  --Run After Date, date format YYYY-MM-DD.
-r  --Prerequisite
-e  --Request to fix works with Fix Option
-o  --Fix Option: rescind, replace, prereq, equivalent_to
------------------------------------------------------------------
-help  --Displays this help                                          
Example : ./mac-to-poll.sh -q -a SYSCTL -f updt-sysctl.xml -s 9959,9953
