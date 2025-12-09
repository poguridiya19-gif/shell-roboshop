#!/bin/bash

USERID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

LOGS_FOLDER="/var/log/shell-roboshop"
SCRIPT_NAME=$( echo $0 | cut -d "." -f1 )
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log" #/var/log/shell-roboshop/16.logs.log
START_TIME=$(date +%s)
mkdir -p $LOGS_FOLDER
echo  "script started executed at: $(date)" | tee -a $LOG_FILE

if [ $USERID -ne 0 ]; then
   echo  "ERROR:: please run these script with root privilege"
   exit 1 #failure other than zero"
fi

VALIDATE(){ # functions recieve input through args like shell script args"
    if [ $1 -ne 0 ]; then
       echo -e "$R ERROR:: Installing $2 is Failure $N " | tee -a $LOG_FILE
       exit 1
    else 
       echo -e "$G Installing $2 is Success $N " | tee -a $LOG_FILE
    fi
}

dnf install mysql-server -y &>>$LOG_FILE
VALIDATE $? "Installing MySQl Server"

systemctl enable mysqld &>>$LOG_FILE
VALIDATE $? "Enabling MySQl Server"

systemctl start mysqld &>>$LOG_FILE
VALIDATE $? "Starting MySQl Server"

mysql_secure_installation --set-root-pass RoboShop@1 &>>$LOG_FILE
VALIDATE $? "Setting up Root Password"

END_TIME=$(date +%s)
TOTAL_TIME=$(( $END_TIME - $START_TIME ))
echo -e "script executed in: $Y $TOTAL_TIME Seconds"