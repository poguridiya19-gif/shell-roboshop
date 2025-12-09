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
        echo -e "$G Error:: Installing $2 is failure $N" | tee -a $LOG_FILE
        exit 1
    else
        echo -e "$G Installing $2 is Success $N" | tee -a $LOG_FILE
    fi
}

dnf install maven -y &>>$LOG_FILE
VALIDATE $? "Installing maven"

id roboshop &>>$LOG_FILE
if [$?-ne 0]; then
   useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
   VALIDATE $? "Creating System User"
else
   echo -e "user  already exist... $G SKIPPING $Y"
fi

mkdir /app &>>$LOG_FILE
VALIDATE $? "creating app directory"

curl -L -o /tmp/shipping.zip https://roboshop-artifacts.s3.amazonaws.com/shipping-v3.zip &>>$LOG_FILE
VALIDATE $? "Downloading shipping application"

cd /app &>>$LOG_FILE
VALIDATE $? "Changing app directory"

rm -rf/app/*  &>>$LOG_FILE
VALIDATE $? "Removing exist code"

unzip /tmp/shipping.zip  &>>$LOG_FILE
VALIDATE $? "unzip shipping"

mvn clean package &>>$LOG_FILE
VALIDATE $? "Building Maven Project"

mv target/shipping-1.0.jar shipping.jar &>>$LOG_FILE
VALIDATE $? "Renaming Jar File"

cp $SCRIPT_DIR/shipping.service /etc/systemd/system/shipping.service &>>$LOG_FILE
VALIDATE $? "copy systemctl service"

systemctl daemon-reload &>>$LOG_FILE
systemctl enable shipping &>>$LOG_FILE
VALIDATE $? "Enable shipping"

dnf install mysql -y &>>$LOG_FILE
VALIDATE $? "Installing mysql"

mysql -h $MYSQL_HOST -uroot -proboshop@1 -e "use cities" &>>$LOG_FILE
if [$? -ne 0]; then
   mysql -h <MYSQL-SERVER-IPADDRESS> -uroot -pRoboShop@1 < /app/db/schema.sql &>>$LOG_FILE
   VALIDATE $? "Loading schema"

   mysql -h <MYSQL-SERVER-IPADDRESS> -uroot -pRoboShop@1 < /app/db/app-user.sql &>>$LOG_FILE
   VALIDATE $? "loading app user"

   mysql -h <MYSQL-SERVER-IPADDRESS> -uroot -pRoboShop@1 < /app/db/master-data.sql &>>$LOG_FILE
   VALIDATE $? "loading master data"
else
    echo -e "Shipping data already loaded... $Y SKIPPING $N"
fi

systemctl start shipping &>>$LOG_FILE
VALIDATE $? "Restart shipping"