# terrafrom_s3_to_rds_using_lambda_layer
terrafrom_s3_to_rds_using_lambda_layer

sudo yum install -y https://dev.mysql.com/get/mysql57-community-release-el7-11.noarch.rpm
 sudo yum install -y mysql-community-client


mysql -h database-1.cnjee8l3jrmb.us-east-1.rds.amazonaws.com -u admin -padmin123

create database empdb;
 use empdb;
create table employee (empid int, empname varchar(40), salary int);
select * from employee;
desc employee;
