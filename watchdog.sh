#!/bin.bash

# Mention @stupot & @devs
echo "# Cloud Watchdog - <@U4ZSTKBPA> <!subteam^S0DL8PF0A>\n\n"

#
# AWS
#
echo "## AWS\n"

AWS_REGIONS=$(aws ec2 describe-regions --no-all-regions --query 'Regions[*].RegionName' --output text)

# Loop through regions 

for region in $AWS_REGIONS ; do 
    ## Identify running instances *without* tag
    INSTANCES=$(aws --region $region ec2 describe-instances --filters Name=instance-state-name,Values=running --query 'Reservations[*].Instances[?!not_null(Tags[?Key == `WatchdogIgnore`])] | [].InstanceId' --output text)
  
    ## Shutdown Instances
    for instance in $INSTANCES ; do
        info=$(aws --region $region ec2 describe-instances --instance-id $instance --output yaml)
        NAME=$(echo "$info" |grep 'Key: Name' -A 1 |grep Value |sed 's/.*: //g')

        if [[ -z $NAME ]] ; then
            NAME="No Name"
        fi

        ## Identify user from RunInstances cloudtrail log message
        USER=$(aws --region $region cloudtrail lookup-events --lookup-attributes AttributeKey=ResourceName,AttributeValue=$instance --query 'Events[*].{event:EventName,user:Username}' --output yaml |grep RunInstances -A 1 |grep user |sed 's/.*: //g')

        ## If user empty then figure it out from whatever users recently performed actions on resources
        if [[ -z $USER ]] ; then 
            USER=$(aws --region $region cloudtrail lookup-events --lookup-attributes AttributeKey=ResourceName,AttributeValue=$instance |grep Username |sort |uniq |sed 's/.*: //g' |tr '\n' ' ')
        fi

        echo "Shutting down ${USER}'s instance in $region ($instance - $NAME)\n" 
        aws --region $region ec2 stop-instances --instance-ids $instance 
    done 
done

#
# Azure
#

echo "\n## Azure\n"

# Loop through regions 

## Identify running instances *without* tag
INSTANCES=$(az vm list -d --query "[?powerState=='VM running' && tags.WatchdogIgnore != 'true'].id" -o tsv)

## Shutdown Instances
for instance in $INSTANCES ; do
    LOCATION=$(az vm show --ids $instance --query "location" -o tsv)
    USER=$(az monitor activity-log list --resource-id $instance --offset 90d --query "[?operationName.value=='Microsoft.Compute/virtualMachines/write'].claims.name" -o tsv |sort |uniq)
    echo "Shutting down ${USER}'s instance in $LOCATION ($instance)\n" 
    az vm deallocate --ids $instance --no-wait
done 

