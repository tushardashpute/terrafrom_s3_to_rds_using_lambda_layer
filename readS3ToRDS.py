import json
import csv
import boto3
import mysql.connector

s3client=boto3.client('s3')
def lambda_handler(event, context):
    bucket = event['Records'][0]['s3']['bucket']['name']
    csv_file = event['Records'][0]['s3']['object']['key']
    response = s3client.get_object(Bucket=bucket, Key=csv_file)
    lines = response['Body'].read().decode('utf-8').split()
    results = []
    for row in csv.DictReader(lines):
        results.append(row.values())
    print(results)
    
    connection = mysql.connector.connect(host='database-1.cnjee8l3jrmb.us-east-1.rds.amazonaws.com',
                                         database='empdb',
                                         port='3306',
                                         user='admin',
                                         passwd='admin123')
    
    mysql_insert = "insert into employee(empid,ename,salary) values(%s,%s,%s)"
    
    cursor = connection.cursor()
    cursor.executemany(mysql_insert, results)
    connection.commit() 

    return {
        'statusCode': 200,
        'body': json.dumps('Hello from Lambda!')
    }