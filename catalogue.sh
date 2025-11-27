#! bin bash

USERID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

LOGS_FOLDER="var/log/shell-roboshop"
SCRIPT_NAME=$(echo $0 | cut -d "." f1)
SCRIPT_DIR=$pwd
MONGODB_HOST=mongodb.poguri.fun
LOG_FILE="$LOG_FOLDER/$SCRIPT_NAME.log" #var/log/shell-script/16.logs.log

mkdir -p $LOGS_FOLDER
echo "script started executed at :$(date)" | tee -a $LOG_FILE

if [ $USERID -ne 0 ]; then
   echo "ERROR:: please run these script with root privelege"
   exit 1

VALIDATE(){
    if [ $1 -ne 0 ]; then
       echo -e "$R ERROR:Installing $2 is failure $N"
       exit 1
    else 
       echo -e "$R Installing $2 is success $N"
fi
}

#### NodeJs ####
dnf module disable nodejs -y &>>$LOG_FILE
VALIDATE $? "disabling node js"

dnf module enable nodejs:20 -y &>>$LOG_FILE
VALIDATE $? "Enabling node js"

dnf install nodejs -y &>>$LOG_FILE
VALIDATE $? "INSTALLING nodejs"

id roboshop &>>$LOG_FILE
if [ $? -ne 0 ]; then
   useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOG_FILE
   VALIDATE $? "creating system user"
else
   echo -e "user already exist ... $Y SKIPPING $N"
fi

mkdir -p /app
VALIDATE $? "creating app directory"
curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip &>>$LOG_FILE
VALIDATE $? "downloading catalogue application"
cd /app 
VALIDATE $? "changing  to app directory"

rm -rf /app*
VALIDATE $? "removing existing code"

unzip /tmp/catalogue.zip &>>$LOG_FILE
VALIDATE $? "unzip catalogue"

npm install &>>$LOG_FILE
VALIDATE $? "install dependencies"

cp $SCRIPT_DIR/catalogue.service /etc/systemd/system/catalogue.service
VALIDATE $? "copy systemctl service"

systemctl daemon-reload
systemctl enable catalogue &>>$LOG_FILE
VALIDATE $? "enable catalogue" 

cp $SCRIPT_DIR/mongo.repo /etc/yum.repos.d/mongo.repo
VALIDATE $? "copy mongo repo"

dnf install mongodb-mongosh -y &>>$LOG_FILE
VALIDATE $? "install mongo client"

INDEX=$(mongosh mongodb.poguri.fun --quiet --eval "db.get Mongo().get Db names(). index of ('catalogue')")
if [ $? -le 0 ]; then
   mongosh --host $MONGODB_HOST </app/db/master-data.js &>>$LOG_FILE
   VALIDATE $? "load catalogue products"
else
   echo -e "Catalogue products already exist ... $Y SKIPPING $N"
fi

systemctl restart catalogue
VALIDATE $? "restarted catalogue"

fi