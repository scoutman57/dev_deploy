# deploy.sh
# $Id: $
#
# Deploys 'mysite' to 192.167.1.172
#

# create a version file...
# This could be a temp file : version=`date +%Y%b%d-%T`-$$-version
# but I think we'll call it VERSION instead, to draw attention to
# it on the remote install site.
version='./VERSION'

# Put the time of deployment into it...
echo "Deployed at `date +%Y%b%d-%T`" > $version
echo >> $version

# Add svn info
echo "The subversion information for this deployment is as follows: " >> $version
svn info >> $version
echo >> $version
echo "NOTE: if this is an archive in /tmp, the date of the file name is " >> $version
echo "the date that the old VERSION file was copied to /tmp  " >> $version
echo >> $version

# Archive old version file in /tmp
# we need a name for it, so we create one
my_date=`date +%Y%b%d-%k.%M.%S`

# strip any empty spaces (such as occur when the hour is a single digit)
my_date=`echo $my_date | sed 's/ //g'`

# create a file
version_tmp="/tmp/VERSION.mysite.${my_date}"

# For each argument...
#for host in  $@ 
#do
host='192.168.1.172'
echo "Installing on $host:/var/www/html ..."
	
# Copy the old version to /tmp
ssh -lroot $host "cd /var/www/html && cp ./VERSION $version_tmp"
	
# rsync the files to the /opt/RUO directory
rsync -avze ssh --exclude=.svn --exclude=deploy.sh --exclude=dev_deploy.sh --delete ./* root@${host}:/var/www/html/
	
# cd into that directory and recursively change ownership to apache:apache
ssh -lroot $host "cd /var/www/html/ && chown -R apache:apache *"
#done

# Remove version file 
rm $version

