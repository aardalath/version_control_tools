#!/bin/bash
##############################################################################
# ingestGitCommitsIntoSvn.sh
#
# Creates patches from Git repository (starting at a date) and appies them
# to an SVN repository
#
# Copyright (C) 2018 by J C Gonzalez - All rights reserved
##############################################################################

if [ $# -lt 2 ]; then
    echo "Usage:  $0 <svn-workcopy> <start-date>"
    exit 1
fi

SVN_DIR=$1
START_DATE=$2

echo "Ingesting commit in Git repository from ${START_DATE} on, "
echo "into SVN working copy located at ${SVN_DIR}."

fld=/tmp/$$.dir
mkdir -p $fld

echo "Retrieving log information from Git repository . . ."

git log --since "$START_DATE"  --date=local > $fld/1.last_commits
grep '^commit' $fld/1.last_commits | sed '1!G;h;$!d' > $fld/2.last_commit_nums

git_dir=$(pwd)

k=1

echo "Applying commits . . ."

while read key id ; do

    pf=$(printf "%03d" $k)

    echo " - Applying commit #$k - $id . . ."
    
    git show --pretty $id | \
    tee $fld/3.patch.$pf | \
    awk '(NR == 5){print $0;}' | \
    sed -e 's/ *//' > $fld/3.patch.$pf.log
    msg=$(cat $fld/3.patch.$pf.log)

    cd ${SVN_DIR}
    svn patch $fld/3.patch.$pf
    svn commit -m "$msg"
    cd ${git_dir}
    
    k=$((k + 1))

done < $fld/2.last_commit_nums

echo "Cleanning up . . ."

rm -rf $fld

echo "Done."

exit 0

