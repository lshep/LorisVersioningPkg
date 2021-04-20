## followed instructions at 
## https://github.com/Bioconductor/BiocHubServer
## setting up mysql database
## database: hubstesting
## user: hubuser
## used newer version of ruby 2.7.2
## sudo systemctl start mysql

################################################################################
##
## As recap for database creation and setup
##
##
###############################################################################

## start mysql server
sudo systemctl start mysql

##
## Start from scratch delete database and cache
##
cd /home/shepherd/.cache/R
rm -rf MyBiocHub
sudo mysql -u root -p
show databases;
DROP DATABASE hubstesting;
show databases.


##           
## In mysql
##

## Log into mysql
sudo mysql -u root -p

##create the database
CREATE DATABASE hubstesting;

## create any needed users with needed permission
CREATE USER hubuser;
GRANT ALL PRIVILEGES ON *.* TO 'hubuser'@'localhost' IDENTIFIED BY 'hubsrock';

## exit out of mysql
exit


##
## In BiocHubServer directory set up database tables and perform migration
##   including new migrations
## 

ruby schema_sequel.rb
sequel -m migrations/ mysql2://hubuser:hubsrock@localhost/hubstesting
ruby convert_db.rb



## In BiocHubServer start server
shotgun app.rb


http://127.0.0.1:9393/

#####################################################
##
## Create the Hubs class to access new hub database
##
#####################################################
library(AnnotationHub)
setClass("hubstesting", contains = "Hub")
MyHub <- function(...,
                  hub="http://127.0.0.1:9393",
                  cache="/home/shepherd/.cache/R/MyBiocHub",  
                  proxy=NULL,
                  localHub=FALSE,
                  ask=TRUE,
                  allVersions=FALSE){
    .Hub("hubstesting", url=hub, cache=cache, proxy=proxy, localHub=localHub, ask=ask, allVersions=allVersions, ...)
}

setMethod("cache", "hubstesting",
    function(x, ...) {
	callNextMethod(x,
		       cache.root="/home/shepherd/.cache/R/MyBiocHub",
		       proxy=NULL,
		       max.downloads=10)
    }
)


hub <- MyHub()




#########################################################
##
##  Adding resources
##
#########################################################

## Sample package
cd /home/shepherd/Projects/HubNotes/HubVersioning/SampleDataPackages
soffice LorisVersioningPkg/inst/extdata/metadata.csv



## library(AnnotationHubData) 
## options(AH_SERVER_POST_URL="http://127.0.0.1:9393/resource")
## options(ANNOTATION_HUB_URL="http://127.0.0.1:9393")
## url <- getOption("AH_SERVER_POST_URL")
## meta <- makeAnnotationHubMetadata(<pathToPackage>, <name of metadatafile>)
## pushMetadata(meta[[1]], url)


library(ExperimentHubData)
options(EXPERIMENT_HUB_SERVER_POST_URL="http://127.0.0.1:9393/resource")
options(EXPERIMENT_HUB_URL="http://127.0.0.1:9393")
url <- getOption("EXPERIMENT_HUB_SERVER_POST_URL")

meta = makeExperimentHubMetadata("SampleDataPackages/LorisVersioningPkg")
pushMetadata(meta, url)




## The data is now added
## IMPORTANT:
## In a new terminal, run `ruby convert_db.rb` in BiocHubServer
## this is necessary to see the new resources

ruby convert_db.rb

http://127.0.0.1:9393/
   
##################################################
##
## View resources 
##
###################################################

hub <- MyHub()
mcols(hub)[,c("title", "rdatapath", "version_id")]
length(hub)



###################################################
##
## Upload a new version
##
###################################################

https://s3.console.aws.amazon.com/s3/buckets/lori-test-version-conversion?region=us-east-1&tab=objects


cd /home/shepherd
## edit file 
aws s3 cp Justpkgs.txt s3://lori-test-version-conversion/Justpkgs.txt --acl public-read


## Sample package
cd /home/shepherd/Projects/HubNotes/HubVersioning/SampleDataPackages
soffice LorisVersioningPkg/inst/extdata/metadataV2.csv



## In R 

meta = makeExperimentHubMetadata("../SampleDataPackages/LorisVersioningPkg", "metadataV2.csv")
pushMetadata(meta, url)


## The data is now added
## IMPORTANT:
## In a new terminal, run `ruby convert_db.rb` in BiocHubServer
## this is necessary to see the new resources

ruby convert_db.rb

http://127.0.0.1:9393/


##################################################
##
## View resources 
##
###################################################

    
hub <- MyHub()
mcols(hub)[,c("title", "rdatapath", "version_id")]
length(hub)


allVersions(hub) <- TRUE

mcols(hub)[,c("title", "rdatapath", "version_id")]


hub["AH1"]
hub["AH1.0"]


getVersionsOfId(hub, "AH1")



temp1 = hub[["AH1"]]
readLines(temp1)

temp2 = hub[["AH1.0"]]
readLines(temp2)






###########################################
##
## Migrations
##
##########################################
##    -m, --migrate-directory DIR      run the migrations in directory
##    -M, --migrate-version VER        migrate the database to version given


## To apply all migrations:

sequel -m migrations/ mysql2://hubuser:hubsrock@localhost/hubstesting
ruby convert_db.rb

## To apply to a certain migration number / revert backwards use the -M #  option:

sequel -m migrations/ -M 10 mysql2://hubuser:hubsrock@localhost/hubstesting
ruby convert_db.rb



## to upload a new version
aws s3 cp Justpkgs.txt s3://lori-test-version-conversion/Justpkgs.txt --acl public-read

