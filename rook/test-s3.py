#!/usr/bin/env python

import os
import boto3
import datetime

# If bucket is private
AWS_ACCESS_KEY = os.getenv(
    'AWS_ACCESS_KEY',
    'your access key')
AWS_SECRET_KEY = os.getenv(
    'AWS_SECRET_KEY',
    'your secret key')
AWS_REGION = os.getenv(
    'AWS_REGION',
    'your region')

bucket_name = 'test-bucket'
filename = 'hello-test.txt'
download_filename = 'download-{}'.format(
    filename)
key_name = filename
key_contents = 'hello tested on: {}'.format(
    datetime.datetime.utcnow().strftime('%Y-%m-%d %H:%M:%S'))

print((
    'creating test file: {}').format(
        filename))
with open(filename, 'w') as key_file:
    key_file.write(key_contents)

print('connecting')
session = boto3.session.Session(
    aws_access_key_id=AWS_ACCESS_KEY,
    aws_secret_access_key=AWS_SECRET_KEY,
    region_name=AWS_REGION
)
print('getting s3 client')
s3_client = session.client('s3')

# If the bucket is public
# s3_client = boto3.client('s3')

# Once the client is created.

try:
    print((
        'creating bucket={}').format(
            bucket_name))
    bucket = s3_client.create_bucket(Bucket=bucket_name)
except Exception as e:
    print((
        'failed creating bucket={} with ex={}').format(
            bucket_name,
            e))
# end of try/ex for creating bucket


# Upload the file to S3
print((
    'upload_file({}, {}, {})').format(
        filename,
        bucket_name,
        key_name))
s3_client.upload_file(filename, bucket_name, key_name)

# Download the file from S3
print((
    'upload_file({}, {}, {})').format(
        bucket_name,
        key_name,
        download_filename))
s3_client.download_file(bucket_name, key_name, download_filename)
print((
    'download_filename={} contents: {}').format(
        download_filename,
        open(download_filename).read()))
