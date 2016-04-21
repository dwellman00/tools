#!/bin/sh
#
# *** MANAGED BY PUPPET - DO NOT EDIT DIRECTLY! ***
#
# Dale Wellman
# 10/18/2014
# 
# Backup local files to central area for netbackup to copy to tape

source /data/tools/backup.conf

DEBUG=

# Mysql Backup
if [ $MYSQL ]; then
  /bin/mkdir -p `/usr/bin/dirname ${MYSQLOUT}`
  if [ $DEBUG ]; then
    $DEBUG "/usr/bin/mysqldump -u root -p${MYSQLPASS} --all-databases --events --ignore-table=mysql.event ${MYSQLARGS} | /bin/gzip > ${MYSQLOUT}"
  else
    /usr/bin/mysqldump -u root -p${MYSQLPASS} --all-databases --events --ignore-table=mysql.event ${MYSQLARGS} | /bin/gzip > ${MYSQLOUT}
  fi
fi

# Misc Files
/bin/mkdir -p `/usr/bin/dirname ${FILELISTOUT}`
if [ $DEBUG ]; then
  $DEBUG "(cd /; /bin/tar cf - ${FILELIST} | gzip > ${FILELISTOUT} ) "
else
  (cd /; /bin/tar cf - ${FILELIST} | gzip > ${FILELISTOUT} ) 
fi

# Clean up old backups
/usr/bin/find /data/backup/ -mtime +14 -type f -exec /bin/rm \{} \;

