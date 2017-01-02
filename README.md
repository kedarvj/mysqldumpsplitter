# mysqldumpsplitter - MySQL Dump splitter to split / extract databases, tables, list from mysqldump with plenty of more funtionality.


### Usage:

Download the utility from [website](http://kedar.nitty-witty.com/blog) or git repository.
<hr>
	************ Usage ************ 

sh mysqldumpsplitter.sh --source filename --desc --extract [DB|TABLE|DBTABLES|ALLDBS|ALLTABLES|REGEXP] --match_str string --compression [gzip|pigz|bzip2|none] --decompression [gzip|pigz|bzip2|none] --output_dir [path to output dir] [--config /path/to/config] 
                                                    
<h4>Options:</h4>
                                                    
	--source: mysqldump filename to process. It could be a compressed or regular file.
	--desc: This option will list out all databases and tables.
	--extract: Specify what to extract. Possible values DB, TABLE, ALLDBS, ALLTABLES, REGEXP
	--match_str: Specify match string for extract command option.
	--compression: gzip/pigz/bzip2/none (default: gzip). Extracted file will be of this compression.
	--decompression: gzip/pigz/bzip2/none (default: gzip). This will be used against input file.
	--output_dir: path to output dir. (default: ./out/)
	--config: path to config file. You may use --config option to specify the config file that includes following variables.
		SOURCE=
		EXTRACT=
		COMPRESSION=
		DECOMPRESSION=
		OUTPUT_DIR=
		MATCH_STR=

                                                    
Ver. 5.0
<hr>


### mysqldumpsplitter recipe:

1) Extract single database from mysqldump:

`sh mysqldumpsplitter.sh --source filename --extract DB --match_str database-name`

Above command will create sql for specified database from specified "filename" sql file and store it in compressed format to database-name.sql.gz. 

2) Extract single table from mysqldump:

`sh mysqldumpsplitter.sh --source filename --extract TABLE --match_str table-name`

Above command will create sql for specified table from specified "filename" mysqldump file and store it in compressed format to database-name.sql.gz.
 

3) Extract tables matching regular expression from mysqldump:

`sh mysqldumpsplitter.sh --source filename --extract REGEXP --match_str regular-expression`

Above command will create sqls for tables matching specified regular expression from specified "filename" mysqldump file and store it in compressed format to individual table-name.sql.gz.


4) Extract all databases from mysqldump:

`sh mysqldumpsplitter.sh --source filename --extract ALLDBS`

Above command will extract all databases from specified "filename" mysqldump file and store it in compressed format to individual database-name.sql.gz.


5) Extract all table from mysqldump:

`sh mysqldumpsplitter.sh --source filename --extract ALLTABLES`

Above command will extract all tables from specified "filename" mysqldump file and store it in compressed format to individual table-name.sql.gz.


6) Extract list of tables from mysqldump:

`sh mysqldumpsplitter.sh --source filename --extract REGEXP --match_str '(table1|table2|table3)'`

Above command will extract tables from the specified "filename" mysqldump  file and store them in compressed format to individual table-name.sql.gz.

7) Extract a database from compressed mysqldump:

`sh mysqldumpsplitter.sh --source filename.sql.gz --extract DB --match_str 'dbname' --decompression gzip`

Above command will decompress filename.sql.gz using gzip, extract database named "dbname" from "filename.sql.gz" & store it as out/dbname.sql.gz


8) Extract a database from compressed mysqldump in an uncompressed format:

`sh mysqldumpsplitter.sh --source filename.sql.gz --extract DB --match_str 'dbname' --decompression gzip --compression none`

Above command will decompress filename.sql.gz using gzip and extract database named "dbname" from "filename.sql.gz" & store it as plain sql out/dbname.sql


9) Extract alltables from mysqldump in different folder:

`sh mysqldumpsplitter.sh --source filename --extract ALLTABLES --output_dir /path/to/extracts/`

Above command will extract all tables from specified "filename" mysqldump file and extracts tables in compressed format to individual files, table-name.sql.gz stored under /path/to/extracts/.
The script will create the folder /path/to/extracts/ if not exists.


10) Extract one or more tables from one database in a full-dump:

Consider you have a full dump with multiple databases and you want to extract few tables from one database.

	Extract single database:
	`sh mysqldumpsplitter.sh --source filename --extract DB --match_str DBNAME --compression none`

	Extract all tables
	`sh mysqldumpsplitter.sh --source out/DBNAME.sql --extract REGEXP --match_str "(tbl1|tbl2)"`

though we can use another option to do this in single command as follows:

`sh mysqldumpsplitter.sh --source filename --extract DBTABLE --match_str "DBNAME.(tbl1|tbl2)" --compression none`

Above command will extract both tbl1 and tbl2 from DBNAME database in sql format under folder "out" in current directory.

You can extract single table as follows:

`sh mysqldumpsplitter.sh --source filename --extract DBTABLE --match_str "DBNAME.(tbl1)" --compression none`
 
11) Extract all tables from specific database:

`mysqldumpsplitter.sh --source filename --extract DBTABLE --match_str "DBNAME.*" --compression none`

Above command will extract all tables from DBNAME database in sql format and store it under "out" directory.


12) List content of the mysqldump file

`mysqldumpsplitter.sh --source filename --desc`

Above command will list databases and tables from the dump file.
--
