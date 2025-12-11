#!/bin/bash

USERID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

LOGS_FOLDER="/var/log/shell-roboshop"
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"
MONGODB_HOST=mongodb.poguri.fun
MYSQL_HOST=mysql.poguri.fun
SCRIPT_DIR=$(pwd)

mkdir -p $LOGS_FOLDER
echo "script started executed at: (date)" | tee -a $LOG_FILE

if [ $USERID -ne 0 ]; then
    echo "ERROR:: please run these script with root privelege"
    exit 1 # failure is other than zero
fi

VALIDATE(){ # functions recieve input through args just like shell script args
    if [ $1 -ne 0 ]; then
        echo -e "$R Error:: Installing $2 is failure $N" | tee -a $LOG_FILE
        exit 1
    else
        echo -e "$G Installing $2 is Success $N" | tee -a $LOG_FILE
    fi
}

dnf install python3 gcc python3-devel -y &>>$LOG_FILE
VALIDATE $? "Installing Python Dependencies"

id roboshop &>>$LOG_FILE
if [ $? -ne 0 ]; then
   useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOG_FILE
   VALIDATE $? "creating system user"
else
   echo -e "user already exist ... $Y SKIPPING $N"

mkdir /app &>>$LOG_FILE
VALIDATE $? "creating app directory"

curl -L -o /tmp/payment.zip https://roboshop-artifacts.s3.amazonaws.com/payment-v3.zip >>$LOG_FILE
VALIDATE $? "downloading payment applications"&

cd /app  
VALIDATE $? "changing to app directory"

rm -rf /app/*
VALIDATE $? "removing the existing code"

unzip /tmp/payment.zip &>>$LOG_FILE
VALIDATE $? "unzip payment"

pip3 install -r requirements.txt &>>$LOG_FILE
VALIDATE $? "installing phthon requirements"

cp $SCRIPT_DIR/payment.service /etc/systemd/system/payment.service 
VALIDATE $? "copy systemctl service"

systemctl daemon-reload &>>$LOG_FILE
systemctl enable payment &>>$LOG_FILE
VALIDATE $? "enable payment"

systemctl start payment &>>$LOG_FILE
VALIDATE $? "restart payment"