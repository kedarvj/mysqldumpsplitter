#!/bin/sh

# Current Version: 6.1
# Extracts database, table, all databases, all tables or tables matching on regular expression from the mysqldump.
# Includes output compression options.
# By: Kedar Vaijanapurkar
# Website: http://kedar.nitty-witty.com/blog
# Original Blog Post: http://kedar.nitty-witty.com/blog/mydumpsplitter-extract-tables-from-mysql-dump-shell-script
# Follow GIT: https://github.com/kedarvj/mysqldumpsplitter/

## Version Info:
# Ver. 1.0: Feb 11, 2010
# ... Initial version extract table(s) based on name, regexp or all of them from database-dump.
# Ver. 2.0: Feb, 2015
# ... Added database extract and compression
# Ver. 3.0: March, 2015
# ... Complete rewrite.
# ... Extract all databases.
# Ver. 4.0: March, 2015
# ... More validations and bug fixes.
# ... Support for config file.
# ... Detecting source dump types (compressed/sql).
# ... Support for compressed backup and bz2 format.
# Credit: Andrzej Wroblewski (andrzej.wroblewski@packetstorm.pl) for his inputs on compressed backup & bz2 support.
# Ver. 5.0: Apr, 2015
# ... Describing the dump, listing all databases and tables
# ... Extracting one or more tables from single database
# Ver. 6.1: Oct, 2015
# ... Bug fixing in REGEXP extraction functionlity
# ... Bug fixing in describe functionality
# ... Preserving time_zone & charset env settings in extracted sqls.
# Credit: @PeterTheDBA helped understanding the possible issues with environment variable settings included in first 17 lines of mysqldump.
##

# ToDo: Work with straming input
## Formating Colour
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

## Variable Declaration
SOURCE='';
MATCH_STR='';
EXTRACT='';
OUTPUT_DIR='out';
EXT="sql.gz";
TABLE_NAME='';
DB_NAME='';
COMPRESSION='gzip';
DECOMPRESSION='cat';
VERSION=6.1

## Usage Description
usage()
{
        echo "\n\t\t\t\t\t\t\t${txtgrn}${txtund}************ Usage ************ \n"${txtrst};
        echo "${txtgrn}sh mysqldumpsplitter.sh --source filename --extract [DB|TABLE|DBTABLES|ALLDBS|ALLTABLES|REGEXP] --match_str string --compression [gzip|pigz|bzip2|xz|pxz|none] --decompression [gzip|pigz|bzip2|xz|pxz|none] --output_dir [path to output dir] [--config /path/to/config] ${txtrst}"
        echo "${txtund}                                                    ${txtrst}"
        echo "OPTIONS:"
        echo "${txtund}                                                    ${txtrst}"
        echo "  --source: mysqldump filename to process. It could be a compressed or regular file."
        echo "  --desc: This option will list out all databases and tables."
        echo "  --extract: Specify what to extract. Possible values DB, TABLE, ALLDBS, ALLTABLES, REGEXP"
        echo "  --match_str: Specify match string for extract command option."
        echo "  --compression: gzip/pigz/bzip2/xz/pxz/none (default: gzip). Extracted file will be of this compression."
        echo "  --decompression: gzip/pigz/bzip2/xz/pxz/none (default: gzip). This will be used against input file."
        echo "  --output_dir: path to output dir. (default: ./out/)"
        echo "  --config: path to config file. You may use --config option to specify the config file that includes following variables."
        echo "\t\tSOURCE=
\t\tEXTRACT=
\t\tCOMPRESSION=
\t\tDECOMPRESSION=
\t\tOUTPUT_DIR=
\t\tMATCH_STR=
"
        echo "${txtund}                                                    ${txtrst}"
        echo "Ver. $VERSION"
        exit 0;
}

## Parsing and processing input
parse_result()
{


        ## Validate SOURCE is provided and exists
        if [ -z $SOURCE ]; then
            echo "${txtred}ERROR: Source file not specified or does not exist. (Entered: $SOURCE)${txtrst}"
            echo "${txtgrn}* Make sure --source is first argument. ${txtrst}";
            exit 2;
        elif [ ! -f $SOURCE ]; then
            echo "${txtred}ERROR: Source file does not exist. (Entered: $SOURCE)${txtrst}"
            exit 2;
        fi

        ## Parse Extract Operation
        case $EXTRACT in
                ALLDBS|ALLTABLES|DESCRIBE )
                        if [ "$MATCH_STR" != '' ]; then
                            echo "${txtylw}Ignoring option --match_string.${txtrst}"
                        fi;
                         ;;
                DB|TABLE|REGEXP|DBTABLE)
                        if [ "$MATCH_STR" = '' ]; then
                            echo "${txtred}ERROR: Expecting input for option --match_string.${txtrst}"
                            exit 1;
                        fi;
                        ;;
                * )     echo "${txtred}ERROR: Please specify correct option for --extract.${txtrst}"
                        usage;
        esac;

        ## Parse compression
        if [ "$COMPRESSION" = 'none' ]; then
                COMPRESSION='cat';
                EXT="sql"
                echo "${txtgrn}Setting no compression.${txtrst}";
        elif [ "$COMPRESSION" = 'pigz' ]; then
                which $COMPRESSION &>/dev/null
                if [ $? -ne 0 ]; then
                        echo "${txtred}WARNING:$COMPRESSION appears having issues, using default gzip.${txtrst}";
                        COMPRESSION="gzip";
                fi;
                echo "${txtgrn}Setting compression as $COMPRESSION.${txtrst}";
                EXT="sql.gz"
        elif [ "$COMPRESSION" = 'bzip2' ]; then
                which $COMPRESSION &>/dev/null
                if [ $? -ne 0 ]; then
                        echo "${txtred}WARNING:$COMPRESSION appears having issues, using default gzip.${txtrst}";
                        COMPRESSION="gzip";
                fi;
                echo "${txtgrn}Setting compression as $COMPRESSION.${txtrst}";
                EXT="sql.bz2";
        elif [ "$COMPRESSION" = 'xz' ]; then
                which $COMPRESSION &>/dev/null
                if [ $? -ne 0 ]; then
                        echo "${txtred}WARNING:$COMPRESSION appears having issues, using default gzip.${txtrst}";
                        COMPRESSION="gzip";
                fi;
                echo "${txtgrn}Setting compression as $COMPRESSION.${txtrst}";
                EXT="sql.xz";
        elif [ "$COMPRESSION" = 'pxz' ]; then
                which $COMPRESSION &>/dev/null
                if [ $? -ne 0 ]; then
                        echo "${txtred}WARNING:$COMPRESSION appears having issues, using default gzip.${txtrst}";
                        COMPRESSION="gzip";
                fi;
                echo "${txtgrn}Setting compression as $COMPRESSION.${txtrst}";
                EXT="sql.xz";
        else
                COMPRESSION='gzip';
                echo "${txtgrn}Setting compression $COMPRESSION (default).${txtrst}";
                EXT="sql.gz"
        fi;


        ## Parse  decompression
        if [ "$DECOMPRESSION" = 'none' ]; then
                DECOMPRESSION='cat';
                echo "${txtgrn}Setting no decompression.${txtrst}";
        elif [ "$DECOMPRESSION" = 'pigz' ]; then
                which $DECOMPRESSION &>/dev/null
                if [ $? -ne 0 ]; then
                        echo "${txtred}WARNING:$DECOMPRESSION appears having issues, using default gzip.${txtrst}";
                        DECOMPRESSION="gzip -d -c";
                else
                        DECOMPRESSION="pigz -d -c";
                fi;
                echo "${txtgrn}Setting decompression as $DECOMPRESSION.${txtrst}";
       elif [ "$DECOMPRESSION" = 'bzip2' ]; then
                which $DECOMPRESSION &>/dev/null
                if [ $? -ne 0 ]; then
                        echo "${txtred}WARNING:$DECOMPRESSION appears having issues, using default gzip.${txtrst}";
                        DECOMPRESSION="gzip -d -c";
                else
                        DECOMPRESSION="bzip2 -d -c";
                fi;
                echo "${txtgrn}Setting decompression as $DECOMPRESSION.${txtrst}";
       elif [ "$DECOMPRESSION" = 'xz' ]; then
                which $DECOMPRESSION &>/dev/null
                if [ $? -ne 0 ]; then
                        echo "${txtred}WARNING:$DECOMPRESSION appears having issues, using default gzip.${txtrst}";
                        DECOMPRESSION="gzip -d -c";
                else
                        DECOMPRESSION="xz -d -c";
                fi;
                echo "${txtgrn}Setting decompression as $DECOMPRESSION.${txtrst}";
       elif [ "$DECOMPRESSION" = 'pxz' ]; then
                which $DECOMPRESSION &>/dev/null
                if [ $? -ne 0 ]; then
                        echo "${txtred}WARNING:$DECOMPRESSION appears having issues, using default gzip.${txtrst}";
                        DECOMPRESSION="gzip -d -c";
                else
                        DECOMPRESSION="pxz -d -c";
                fi;
                echo "${txtgrn}Setting decompression as $DECOMPRESSION.${txtrst}";
        else
                DECOMPRESSION="gzip -d -c";
                echo "${txtgrn}Setting decompression $DECOMPRESSION (default).${txtrst}";
        fi;


        ## Verify file type:
        filecommand=`file $SOURCE`
        echo $filecommand | grep "compressed"  1>/dev/null
        if [ `echo $?` -eq 0 ]
        then
                echo "${txtylw}File $SOURCE is a compressed dump.${txtrst}"
                if [ "$DECOMPRESSION" = 'cat' ]; then
                        echo "${txtred} The input file $SOURCE appears to be a compressed dump. \n While the decompression is set to none.\n Please specify ${txtund}--decompression [gzip|bzip2|pigz|xz|pxz]${txtrst}${txtred} argument.${txtrst}";
                        exit 1;
                fi;
        else
                echo "${txtylw}File $SOURCE is a regular dump.${txtrst}"
                if [ "$DECOMPRESSION" != 'cat' ]; then
                        echo "${txtred} Default decompression method for source is gzip. \n The input file $SOURCE does not appear a compressed dump. \n ${txtylw}We will try using no decompression. Please consider specifying ${txtund}--decompression none${txtrst}${txtylw} argument.${txtrst}";
                        DECOMPRESSION='cat'; ## Auto correct decompression to none for regular files.
                fi;
        fi;


        # Output directory
        if [ "$OUTPUT_DIR" = "" ]; then
                OUTPUT_DIR="out";
        fi;
        mkdir -p $OUTPUT_DIR
        if [ $? -eq 0 ]; then
                echo "${txtgrn}Setting output directory: $OUTPUT_DIR.${txtrst}";
        else
                echo "${txtred}ERROR:Issue while checking output directory: $OUTPUT_DIR.${txtrst}";
                exit 2;
        fi;

echo "${txtylw}Processing: Extract $EXTRACT $MATCH_STR from $SOURCE with compression option as $COMPRESSION and output location as $OUTPUT_DIR${txtrst}";

}

# Include first 17 lines of full mysqldump - preserve time_zone/charset/environment variables.
include_dump_info()
{
        if [ $1 = "" ]; then
                echo "${txtred}Couldn't find out-put file while preserving time_zone/charset settings!${txtrst}"
                exit;
        fi;
        OUTPUT_FILE=$1

        echo "Including environment settings from mysqldump."
        $DECOMPRESSION $SOURCE | head -17 | $COMPRESSION > $OUTPUT_DIR/$OUTPUT_FILE.$EXT
        echo "" | $COMPRESSION >> $OUTPUT_DIR/$MATCH_STR.$EXT
        echo "/* -- Splitted with mysqldumpsplitter (http://goo.gl/WIWj6d) -- */" | $COMPRESSION >> $OUTPUT_DIR/$OUTPUT_FILE.$EXT
        echo "" | $COMPRESSION >> $OUTPUT_DIR/$MATCH_STR.$EXT
}

## Actual dump splitting
dump_splitter()
{
        case $EXTRACT in
                DB)
                        # Include first 17 lines of standard mysqldump to preserve time_zone and charset.
                        include_dump_info $MATCH_STR

                        echo "Extracting Database: $MATCH_STR";
                        $DECOMPRESSION $SOURCE | sed -n "/^-- Current Database: \`$MATCH_STR\`/,/^-- Current Database: /p" | $COMPRESSION >> $OUTPUT_DIR/$MATCH_STR.$EXT
                        echo "${txtbld} Database $MATCH_STR  extracted from $SOURCE at $OUTPUT_DIR${txtrst}"
                        ;;

                TABLE)
                        # Include first 17 lines of standard mysqldump to preserve time_zone and charset.
                        include_dump_info $MATCH_STR

                        #Loop for each tablename found in provided dumpfile
                        echo "Extracting $MATCH_STR."
                        #Extract table specific dump to tablename.sql
                        $DECOMPRESSION  $SOURCE | sed -n "/^-- Table structure for table \`$MATCH_STR\`/,/^-- Table structure for table/p" | $COMPRESSION >> $OUTPUT_DIR/$MATCH_STR.$EXT
                        echo "${txtbld} Table $MATCH_STR  extracted from $SOURCE at $OUTPUT_DIR${txtrst}"
                        ;;

                ALLDBS)
                        for dbname in $($DECOMPRESSION $SOURCE | grep -E "^-- Current Database: " | awk -F"\`" {'print $2'})
                        do
                         # Include first 17 lines of standard mysqldump to preserve time_zone and charset.
                         include_dump_info $dbname

                                echo "Extracting Database $dbname..."
                                #Extract database specific dump to database.sql.gz
                                $DECOMPRESSION $SOURCE | sed -n "/^-- Current Database: \`$dbname\`/,/^-- Current Database: /p" | $COMPRESSION >> $OUTPUT_DIR/$dbname.$EXT
                                DB_COUNT=$((DB_COUNT+1))
                         echo "${txtbld}Database $dbname extracted from $SOURCE at $OUTPUT_DIR/$dbname.$EXT${txtrst}"
                        done;
                        echo "${txtbld}Total $DB_COUNT databases extracted.${txtrst}"
                        ;;

                ALLTABLES)

                        for tablename in $($DECOMPRESSION $SOURCE | grep "Table structure for table " | awk -F"\`" {'print $2'})
                        do
                         # Include first 17 lines of standard mysqldump to preserve time_zone and charset.
                         include_dump_info $tablename

                         #Extract table specific dump to tablename.sql
                         $DECOMPRESSION $SOURCE | sed -n "/^-- Table structure for table \`$tablename\`/,/^-- Table structure for table/p" | $COMPRESSION >> $OUTPUT_DIR/$tablename.$EXT
                         TABLE_COUNT=$((TABLE_COUNT+1))
                         echo "${txtbld}Table $tablename extracted from $DUMP_FILE at $OUTPUT_DIR/$tablename.$EXT${txtrst}"
                        done;
                         echo "${txtbld}Total $TABLE_COUNT tables extracted.${txtrst}"
                        ;;
                REGEXP)

                        TABLE_COUNT=0;
                        for tablename in $($DECOMPRESSION $SOURCE | grep -E "Table structure for table \`$MATCH_STR" | awk -F"\`" {'print $2'})
                        do
                         # Include first 17 lines of standard mysqldump to preserve time_zone and charset.
                         include_dump_info $tablename

                         echo "Extracting $tablename..."
                                #Extract table specific dump to tablename.sql
                                $DECOMPRESSION $SOURCE | sed -n "/^-- Table structure for table \`$tablename\`/,/^-- Table structure for table/p" | $COMPRESSION >> $OUTPUT_DIR/$tablename.$EXT
                         echo "${txtbld}Table $tablename extracted from $DUMP_FILE at $OUTPUT_DIR/$tablename.$EXT${txtrst}"
                                TABLE_COUNT=$((TABLE_COUNT+1))
                        done;
                        echo "${txtbld}Total $TABLE_COUNT tables extracted.${txtrst}"
                        ;;

                DBTABLE)

                        MATCH_DB=`echo $MATCH_STR | awk -F "." {'print $1'}`
                        MATCH_TBLS=`echo $MATCH_STR | awk -F "." {'print $2'}`
                        if [ "$MATCH_TBLS" = "*" ]; then
                         MATCH_TBLS='';
                        fi;
                        TABLE_COUNT=0;

                        for tablename in $( $DECOMPRESSION $SOURCE | sed -n "/^-- Current Database: \`$MATCH_DB\`/,/^-- Current Database: /p" | grep -E "^-- Table structure for table \`$MATCH_TBLS" | awk -F '\`' {'print $2'} )
                        do
                                echo "Extracting $tablename..."
                                #Extract table specific dump to tablename.sql
                         # Include first 17 lines of standard mysqldump to preserve time_zone and charset.
                         include_dump_info $tablename

                                $DECOMPRESSION $SOURCE | sed -n "/^-- Current Database: \`$MATCH_DB\`/,/^-- Current Database: /p" | sed -n "/^-- Table structure for table \`$tablename\`/,/^-- Table structure for table/p" | $COMPRESSION >> $OUTPUT_DIR/$tablename.$EXT
                         echo "${txtbld}Table $tablename extracted from $DUMP_FILE at $OUTPUT_DIR/$tablename.$EXT${txtrst}"
                                TABLE_COUNT=$((TABLE_COUNT+1))
                        done;
                        echo "${txtbld}Total $TABLE_COUNT tables extracted from $MATCH_DB.${txtrst}"
                        ;;

                *)      echo "Wrong option, exiting.";
                        usage;
                        exit 1;;
        esac
}

missing_arg()
{
        echo "${txtred}ERROR:Missing argument $1.${txtrst}"
        exit 1;
}

if [ "$#" -eq 0 ]; then
        usage;
        exit 1;
fi

# Accepts Parameters
while [ "$1" != "" ]; do
    case $1 in
        --source|-S  )   shift
                if [ -z $1 ]; then
                        missing_arg --source
                fi;
                SOURCE=$1 ;;

        --extract|-E  )   shift
                if [ -z $1 ]; then
                        missing_arg --extract
                fi;
                EXTRACT=$1 ;;
        --compression|-C  )   shift
                if [ -z $1 ]; then
                        missing_arg --compression
                fi;
                COMPRESSION=$1 ;;
        --decompression|-D) shift
                if [ -z $1 ]; then
                        missing_arg --decompression
                fi;
                DECOMPRESSION=$1 ;;
        --output_dir|-O  ) shift
                if [ -z $1 ]; then
                        missing_arg --output_dir
                fi;
                OUTPUT_DIR=$1 ;;
        --match_str|-M ) shift
                if [ -z $1 ]; then
                        missing_arg --match_str
                fi;
                MATCH_STR=$1 ;;
        --desc  )
                        EXTRACT="DESCRIBE"
                        parse_result
                        echo "-------------------------------";
                        echo "Database\t\tTables";
                        echo "-------------------------------";
                        $DECOMPRESSION $SOURCE | grep -E "(^-- Current Database:|^-- Table structure for table)" | sed  's/-- Current Database: /-------------------------------\n/' | sed 's/-- Table structure for table /\t\t/'| sed 's/`//g' ;
                        echo "-------------------------------";
                        exit 0;
                ;;

        --config        ) shift;
                if [ -z $1 ]; then
                        missing_arg --config
                fi;
                if [ ! -f $1 ]; then
                    echo "${txtred}ERROR: Config file $1 does not exist.${txtrst}"
                    exit 2;
                fi;
. ./$1 ;;
        -h  )   usage
                exit ;;
        * )     echo "";
                usage
                exit 1
    esac
    shift
done

parse_result
dump_splitter
exit 0;
