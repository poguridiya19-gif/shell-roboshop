#!/bin/bash

USERID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

LOGS_FOLDER="/var/log/shell-roboshop"
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"
SCRIPT_DIR=$(pwd)

mkdir -p $LOGS_FOLDER
echo "script started executed at: $(date)" | tee -a $LOG_FILE

if [ $USERID -ne 0 ]; then
    echo "ERROR:: please run these script with root privelege"
    exit 1 # failure is other than zero
fi

VALIDATE(){ # functions recieve input through args just like shell script args
    if [ $1 -ne 0 ]; then
        echo -e "$G Error:: Installing $2 is failure $N" | tee -a $LOG_FILE
        exit 1
    else
        echo -e "$G Installing $2 is Success $N" | tee -a $LOG_FILE
    fi
}

dnf module disable nodejs -y &>>$LOG_FILE
VALIDATE $? "Disabling default Nodejs"

dnf module enable nodejs:20 -y &>>$LOG_FILE
VALIDATE $? "Enabling Nodejs"

dnf install nodejs -y &>>$LOG_FILE
VALIDATE $? "Installing Nodejs"

id roboshop &>>$LOG_FILE
if [$?-ne 0]; then
   useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
   VALIDATE $? "Creating System User"
else
   echo -e "user already exist... $G SKIPPING $Y"
fi

mkdir -p /app &>>$LOG_FILE
VALIDATE $? "Creating App Directory"

curl -L -o /tmp/cart.zip https://roboshop-artifacts.s3.amazonaws.com/cart-v3.zip &>>$LOG_FILE
VALIDATE $? "Downloading Cart Application"

cd /app &>>$LOG_FILE
VALIDATE $? "Changing App Directory"

rm -rf /app/* &>>$LOG_FILE
VALIDATE $? "Removing  Existing Code"

unzip /tmp/cart.zip &>>$LOG_FILE
VALIDATE $? "Unzip cart"

npm install &>>$LOG_FILE
VALIDATE $? "Install dependencies"

cp $SCRIPT_DIR/cart.service /etc/systemd/system/cart.service &>>$LOG_FILE
VALIDATE $? "copy systemctl service"

systemctl daemon-reload &>>$LOG_FILE
systemctl enable cart &>>$LOG_FILE
VALIDATE $? "enable cart"

systemctl restart cart &>>$LOG_FILE
VALIDATE $? "restarted cart"