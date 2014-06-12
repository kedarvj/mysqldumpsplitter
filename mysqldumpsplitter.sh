#!/bin/sh
# http://kedar.nitty-witty.com
# Source: http://kedar.nitty-witty.com/blog/mydumpsplitter-extract-tables-from-mysql-dump-shell-script
#SPLIT DUMP FILE INTO INDIVIDUAL TABLE DUMPS
# Text color variables
txtund=$(tput sgr 0 1)    # Underline
txtbld=$(tput bold)       # Bold
txtred=$(tput setaf 1)    # Red
txtgrn=$(tput setaf 2)    # Green
txtylw=$(tput setaf 3)    # Yellow
txtblu=$(tput setaf 4)    # Blue
txtpur=$(tput setaf 5)    # Purple
txtcyn=$(tput setaf 6)    # Cyan
txtwht=$(tput setaf 7)    # White
txtrst=$(tput sgr0)       # Text reset

TARGET_DIR="."
DUMP_FILE=$1
TABLE_COUNT=0

if [ $# = 0 ]; then
        echo "${txtbld}${txtred}Usage: sh MyDumpSplitter.sh DUMP-FILE-NAME${txtrst} -- Extract all tables as a separate file from dump."
        echo "${txtbld}${txtred}       sh MyDumpSplitter.sh DUMP-FILE-NAME TABLE-NAME ${txtrst} -- Extract single table from dump."
        echo "${txtbld}${txtred}       sh MyDumpSplitter.sh DUMP-FILE-NAME -S TABLE-NAME-REGEXP ${txtrst} -- Extract tables from dump for specified regular expression."
        exit;
elif [ $# = 1 ]; then
        #Loop for each tablename found in provided dumpfile
        for tablename in $(grep "Table structure for table " $1 | awk -F"\`" {'print $2'})
        do
                #Extract table specific dump to tablename.sql
                sed -n "/^-- Table structure for table \`$tablename\`/,/^-- Table structure for table/p" $1 > $TARGET_DIR/$tablename.sql
                TABLE_COUNT=$((TABLE_COUNT+1))
        done;
elif [ $# = 2  ]; then
        for tablename in $(grep -E "Table structure for table \`$2\`" $1| awk -F"\`" {'print $2'})
        do
                echo "Extracting $tablename..."
                #Extract table specific dump to tablename.sql
                sed -n "/^-- Table structure for table \`$tablename\`/,/^-- Table structure for table/p" $1 > $TARGET_DIR/$tablename.sql
                TABLE_COUNT=$((TABLE_COUNT+1))
        done;
elif [ $# = 3  ]; then

        if [ $2 = "-S" ]; then
                for tablename in $(grep -E "Table structure for table \`$3" $1| awk -F"\`" {'print $2'})
                do
                        echo "Extracting $tablename..."
                        #Extract table specific dump to tablename.sql
                        sed -n "/^-- Table structure for table \`$tablename\`/,/^-- Table structure for table/p" $1 > $TARGET_DIR/$tablename.sql
                        TABLE_COUNT=$((TABLE_COUNT+1))
                done;
        else
                echo "${txtbld}${txtred} Please provide proper parameters. ${txtrst}";
        fi
fi

#Summary
echo "${txtbld}$TABLE_COUNT Table extracted from $DUMP_FILE at $TARGET_DIR${txtrst}"
                                                                