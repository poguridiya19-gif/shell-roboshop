#!/bin/bash

USERID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

LOGS_FOLDER="/var/log/shell-roboshop"
SCRIPT_NAME=$(echo $0|cut -d "." -f1)
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"
SCRIPT_DIR=$PWD

mkdir -p $LOGS_FOLDER
echo "script started executed at : $(date)" | tee -a $LOG_FILE

if [ $USERID -ne 0 ]; then
   echo -e "ERROR:: please run these script with root privilege"
   exit 1
fi

VALIDATE(){
    if [ $1 -ne 0 ]; then
       echo -e "$R installing $2 is failure $N"
       exit 1
    else 
       echo -e "$G installing $2 is success $N"
    fi
}

dnf module disable nginx -y &>>$LOG_FILE
VALIDATE $? "disabling default nginx module"
dnf module enable nginx:1.24 -y &>>$LOG_FILE
VALIDATE $? "enablimg nginx module 1.24"
dnf install nginx -y &>>$LOG_FILE
VALIDATE $? "installing nginx"

systemctl enable nginx &>>$LOG_FILE
systemctl start nginx &>>$LOG_FILE
VALIDATE $? "starting nginx"

rm -rf /usr/share/nginx/html/* 
VALIDATE $? "cleaning nginx html directory"

curl -o /tmp/frontend.zip https://roboshop-artifacts.s3.amazonaws.com/frontend-v3.zip &>>$LOG_FILE
VALIDATE $? "downloading frontend applications"

cd /usr/share/nginx/html
VALIDATE $? "changing directory to nginx html root"

unzip /tmp/frontend.zip &>>$LOG_FILE
VALIDATE $? "unzip frontend"

cp $SCRIPT_DIR/nginx.conf /etc/nginx/nginx.conf 
VALIDATE $? "copying nginx.conf"

systemctl restart nginx 
VALIDATE $? "restarting nginx"