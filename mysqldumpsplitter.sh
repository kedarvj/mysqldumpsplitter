#!/bin/sh

# Current Version: 3.0
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
SOURCE_DUMP='';
OBJECT_NAME='';
EXTRACT='';
OUT_DIR='out';
EXT="sql.gz";
TABLE_NAME='';
DB_NAME='';


## Usage Description
usage()
{
	echo "${txtgrn}${txtund}************ Usage ************ "${txtrst};
	echo "${txtgrn}sh mysqldumpsplitter.sh --source filename --extract [DB|TABLE|ALLDBS|ALLTABLES|REGEXP] --match_str string --compression=[gzip|pigz|none] --output_dir=[path to output dir] ${txtrst}" 
	echo "${txtund}                                                    ${txtrst}"	
	echo "OPTIONS:"
	echo "${txtund}                                                    ${txtrst}"	
	echo "	--source: mysqldump filename (with path) to process"
	echo "	--extract: Specify what to extract. Possible values DB, TABLE, ALLDBS, ALLTABLES, REGEXP"
	echo "	--match_str: Specify match string for extract command option."
	echo "	--compression: gzip/pigz/no_compression (default: gzip) "
	echo "	--output_dir: path to output dir. (default: ./out/)"
	echo ""
	echo "${txtund}                                                    ${txtrst}"	
	exit 0;
}

## Parsing and processing input
parse_result()
{

	## Validate SOURCE_DUMP is provided and exists
	if [ -z $SOURCE_DUMP ]; then
	    echo "${txtred}ERROR: Source file not specified or does not exist. (Entered: $SOURCE_DUMP)${txtrst}"
	elif [ ! -f $SOURCE_DUMP ]; then
	    echo "${txtred}ERROR: Source file does not exist. (Entered: $SOURCE_DUMP)${txtrst}"
	    exit 2;
	fi

	## Parse Extract Operation
	case $EXTRACT in
		DB|TABLE|ALLDBS|ALLTABLES|REGEXP ) ;;
		* ) 	echo "${txtred}ERROR:Wrong option for --extract.${txtrst}"
			usage;
	esac;

	## Parse compression
	if [ "$COMPRESSION" = 'none' ]; then
		COMPRESSION='cat';
		EXT="sql"
		echo "${txtgrn}Setting no compression.${txtrst}";
	elif [ "$COMPRESSION" = 'pigz' ]; then
		which $COMPRESSION
		if [ $? -ne 0 ]; then 
			echo "${txtred}WARNING:$COMPRESSION appears having issues, using default gzip.${txtrst}";
			COMPRESSION="gzip";
		fi;
		echo "${txtgrn}Setting compression as $COMPRESSION.${txtrst}";
		EXT="sql.gz"
	else
		COMPRESSION='gzip';
		echo "${txtgrn}Using default compression $COMPRESSION.${txtrst}";
		EXT="sql.gz"
	fi;

	# Output directory
	mkdir -p $OUT_DIR
	if [ $? -eq 0 ]; then
		echo "${txtgrn}Settingup output directory: $OUT_DIR.${txtrst}";
	else
		echo "${txtred}ERROR:Issue while checking output directory: $OUT_DIR.${txtrst}";
		exit 2;
	fi;

echo "${txtylw}Processing: Extract $OBJECT_NAME from $SOURCE_DUMP with compression option as $COMPRESSION and output location as $OUT_DIR${txtrst}";

}

## Actual dump splitting
dump_splitter()
{
	case $EXTRACT in
		DB) 
			echo "Extracting Database: $OBJECT_NAME";
			sed -n "/^-- Current Database: \`$OBJECT_NAME\`/,/^-- Current Database: /p" $SOURCE_DUMP | $COMPRESSION > $OUT_DIR/$OBJECT_NAME.$EXT
			echo "${txtbld} Database $OBJECT_NAME  extracted from $SOURCE_DUMP at $OUTFILE${txtrst}"
			;;

		TABLE) 
			#Loop for each tablename found in provided dumpfile
		        echo "Extracting $OBJECT_NAME."
		        #Extract table specific dump to tablename.sql
		        sed -n "/^-- Table structure for table \`$OBJECT_NAME\`/,/^-- Table structure for table/p" $SOURCE_DUMP | $COMPRESSION > $OUT_DIR/$OBJECT_NAME.$EXT
			echo "${txtbld} Table $OBJECT_NAME  extracted from $SOURCE_DUMP at $OUTFILE${txtrst}"
		 	;;

		ALLDBS) 
		        for dbname in $(grep -E "^-- Current Database: " $SOURCE_DUMP| awk -F"\`" {'print $2'})
		        do
		                echo "Extracting Database $dbname..."
		                #Extract database specific dump to database.sql.gz
		                sed -n "/^-- Current Database: \`$dbname\`/,/^-- Current Database: /p" $SOURCE_DUMP | $COMPRESSION > $OUT_DIR/$dbname.$EXT
		                DB_COUNT=$((DB_COUNT+1))
				echo "${txtbld}Database $dbname extracted from $DUMP_FILE at $OUT_DIR/$dbname.$EXT${txtrst}"
		        done;
			echo "${txtbld}Total $DB_COUNT databases extracted.${txtrst}"
			;;

		ALLTABLES) 
			for tablename in $(grep "Table structure for table " $SOURCE_DUMP | awk -F"\`" {'print $2'})
			do
				#Extract table specific dump to tablename.sql
				sed -n "/^-- Table structure for table \`$tablename\`/,/^-- Table structure for table/p" $SOURCE_DUMP | $COMPRESSION > $OUT_DIR/$tablename.$EXT
				TABLE_COUNT=$((TABLE_COUNT+1))
				echo "${txtbld}Table $tablename extracted from $DUMP_FILE at $OUT_DIR/$tablename.$EXT${txtrst}"
			done;
				echo "${txtbld}Total $TABLE_COUNT tables extracted.${txtrst}"
			;;
		REGEXP) 
			TABLE_COUNT=0;
		        for tablename in $(grep -E "Table structure for table \`$OBJECT_NAME" $SOURCE_DUMP| awk -F"\`" {'print $2'})
		        do
		                echo "Extracting $tablename..."
		                #Extract table specific dump to tablename.sql
		                sed -n "/^-- Table structure for table \`$tablename\`/,/^-- Table structure for table/p" $SOURCE_DUMP | $COMPRESSION > $OUT_DIR/$tablename.$EXT
				echo "${txtbld}Table $tablename extracted from $DUMP_FILE at $OUT_DIR/$tablename.$EXT${txtrst}"
		                TABLE_COUNT=$((TABLE_COUNT+1))
		        done;
			echo "${txtbld}Total $TABLE_COUNT tables extracted.${txtrst}"
			;;

		*) echo "Wrong option, exiting.";;
	esac
}

# Accepts Parameters
while [ "$1" != "" ]; do
    case $1 in
        --source|-S  )   shift	
		SOURCE_DUMP=$1 ;;
        --extract|-E  )   shift	
		EXTRACT=$1 ;;
        --compression|-C  )   shift
		COMPRESSION=$1 ;;
	--output_dir|-O  ) shift
		OUT_DIR=$1 ;;
	--match_str|-M ) shift
		OBJECT_NAME=$1 ;;
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

