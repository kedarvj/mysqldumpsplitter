#!/bin/bash

# Current Version: 8
# Extracts database, table, all databases, all tables or tables matching on regular expression from the mysqldump.
# Includes output compression options.
# By: Kedar Vaijanapurkar
# Website: http://kedar.nitty-witty.com/blog
# Original Blog Post: http://kedar.nitty-witty.com/blog/mydumpsplitter-extract-tables-from-mysql-dump-shell-script
# Follow GIT: https://github.com/kedarvj/mysqldumpsplitter/

## Version Info:
# Ver. 8: Apr 30, 2023
# ... Faster mysqldumpsplitter
# IMPORTANT
# This is still ongoing work and not all the functionalities are in place. Aim is to optimize the existing mysqldumpsplitter flow.
# 

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


# Create a directory to store the extracted databases and tables
mkdir -p extracted_data

# Initialize variables to hold the current database and table names
current_db=""
current_table=""
ignore_db_filter=1 # if only specific database needs to be downloaded
ignore_db_table_filter=1 # database and table need to be extracted
dump_splitter()
{
# Loop through each line in the dump file
cat  $SOURCE | while read -r line; do
    # Check if the current line defines a new database
    if echo "$line" | grep -Eqwi "^-- Current Database"; then
        # Extract the database name from the line
        db=$(echo $line | sed -E "s/.*\`(.+)\`.*/\1/")

        # Update the current database name
        current_db=$db

        # Reset to OFF
        ignore_db_table_filter=1
        ignore_db_filter=1


        echo "${txtwht}Current Database $current_db ${txtrst}"
        echo "---------------------------------------"

        if [[ $EXTRACT == 'DB' ]]; then
          if [[ $db != $MATCH_STR ]]; then
            echo "${txtred}Ignoring Database $db ${txtrst}"
            ignore_db_filter=1
            continue;
          else
            echo "${txtgrn}Extracting Database $db ${txtrst}"
            ignore_db_filter=0
          fi
        # If this database needs to be ignored, continue to next line
        [[ $ignore_db_filter == 1 ]] && continue;
        fi
    fi


    # Check if the current line defines a new table
    if echo "$line" | grep -Eqwi "^-- Table structure for table"; then
        # Extract the table name from the line
        table=$(echo $line | sed -E "s/-- Table structure for table.*\`(.+)\`.*/\1/")

        # Set the current table name
        current_table=$table

        if [[ $EXTRACT == 'DBTABLE' ]]; then
          MATCH_DB=`echo $MATCH_STR | awk -F "." {'print $1'}`
          MATCH_TBLS=`echo $MATCH_STR | awk -F "." {'print $2'}`
          if [[ $db != $MATCH_DB ]]; then
             ignore_db_filter=1
             ignore_db_table_filter=1
             echo "${txtred} Ignoring Table $db.$table ${txtrst} --- db=$ignore_db_filter  dbtbl=$ignore_db_table_filter "
             continue;
          else
             # Create a directory for the current database
             mkdir -p extracted_data/$db
             if [[ $table != $MATCH_TBLS ]]; then
                ignore_db_table_filter=1
                ignore_db_filter=1
                echo "${txtred}Ignoring Table $db.$table ${txtrst} --- db=$ignore_db_filter  dbtbl=$ignore_db_table_filter"
              else
                ignore_db_filter=0
                ignore_db_table_filter=0
                echo "${txtgrn}Extracting Table $db.$table ${txtrst}--- db=$ignore_db_filter  dbtbl=$ignore_db_table_filter"
              fi
          fi
        fi
    fi

    # Ignore if for DB, ignore_db_filter is ON (1)
    [[ $ignore_db_filter == 1 && $EXTRACT == 'DB' ]] && continue;

    # Ignore if for DB, ignore_db_table_filter is ON (1)
    [[ $ignore_db_table_filter == 1 && $EXTRACT == 'DBTABLE' ]] && continue;

    # Write the current line to the SQL file for the current database and table
    echo "$line" >> extracted_data/$current_db/$current_table.sql
    continue

done
}


##

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
        echo "/* -- Split with mysqldumpsplitter (http://goo.gl/WIWj6d) -- */" | $COMPRESSION >> $OUTPUT_DIR/$OUTPUT_FILE.$EXT
        echo "" | $COMPRESSION >> $OUTPUT_DIR/$MATCH_STR.$EXT
}


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
        echo -e "\t\tSOURCE=
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
                        $DECOMPRESSION $SOURCE | grep -aE "(^-- Current Database:|^-- Table structure for table)" | sed  "s/-- Current Database: /-------------------------------\n/" | sed 's/-- Table structure for table /\t\t/' | sed 's/`//g' ;
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

dump_splitter
