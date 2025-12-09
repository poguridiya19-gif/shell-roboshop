#!/bin/bash

USERID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
LOGS_FOLDER="/var/log/shell-roboshop"
SCRIPT_NAME=$( echo $0 | cut -d "." -f1 )
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log" #/var/log/shell-script/16.logs.log
START_TIME=$(date +%s)
 
mkdir -p $LOGS_FOLDER
SCRIPT_DIR=$(pwd)
echo -e "script started executed at: $(date)" | tee $LOG_FILE

if [ $USERID -ne 0 ]; then
   echo -e "ERROR:: please run these script with root privelege"
   exit 1 #failure other than zero
fi

VALIDATE(){ # function input through args like shell scirpt args
    if [ $1 -ne 0 ]; then
      echo -e " $R ERROR:: installing $2 is failure $N" | tee -a $LOG_FILE
      exit 1
    else
      echo -e " $G installing $2 is success $N" | tee -a $LOG_FILE
    fi
}

cp $SCRIPT_DIR/rabbitmq.repo /etc/yum.repos.d/rabbitmq.repo &>>$LOG_FILE
VALIDATE $? "Adding RabbitMQ repo"

dnf install rabbitmq-server -y &>>$LOG_FILE
VALIDATE $? "Installing RabbitMQ Server"

systemctl enable rabbitmq-server &>>$LOG_FILE
VALIDATE $? "Enabling RabbitMQ Server"

systemctl start rabbitmq-server &>>$LOG_FILE
VALIDATE $? "Starting Rabbitmq Server"

rabbitmqctl add_user roboshop roboshop123 &>>$LOG_FILE
rabbitmqctl set_permissions -p / roboshop ".*" ".*" ".*" &>>$LOG_FILE
VALIDATE $? "Setting up Permissions"

END_TIME=$(date +%s)
TOTAL_TIME=$(( $END_TIME - $START_TIME ))
echo -e "script executed in: $Y $TOTAL_TIME Seconds $N"