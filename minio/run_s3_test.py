#!/usr/bin/env python

"""
S3 verification tool
"""

import os
import sys
import boto3
import datetime


def run_s3_test():
    """run_s3_test

    Run the S3 verification test
    """
    access_key = os.getenv(
        'S3_ACCESS_KEY',
        'trexaccesskey')
    secret_key = os.getenv(
        'S3_SECRET_KEY',
        'trex123321')
    region_name = os.getenv(
        'S3_REGION_NAME'
        'us-east-1')
    service_address = os.getenv(
        'S3_ADDRESS',
        'minio-service:9000')
    filename = os.getenv(
        'S3_UPLOAD_FILE',
        'run-s3-test.txt')
    bucket_name = os.getenv(
        'S3_BUCKET',
        's3-verification-tests')
    bucket_key = os.getenv(
        'S3_BUCKET_KEY',
        's3-worked-on-{}'.format(
            datetime.datetime.utcnow().strftime('%Y-%m-%d-%H-%M-%S')))
    secure = bool(os.getenv(
        'S3_SECURE',
        '0') == '1')

    if len(sys.argv) > 1:
        service_address = sys.argv[1]

    endpoint_url = 'http://{}'.format(
        service_address)
    if secure:
        endpoint_url = 'https://{}'.format(
            service_address)

    download_filename = 'download-{}'.format(
        filename)
    key_contents = 'tested on: {}'.format(
        datetime.datetime.utcnow().strftime('%Y-%m-%d %H:%M:%S'))

    if not os.path.exists(filename):
        print((
            'creating test file: {}').format(
                filename))
        with open(filename, 'w') as key_file:
            key_file.write(key_contents)

    print((
        'connecting: {}').format(
            endpoint_url))
    s3 = boto3.resource(
        's3',
        endpoint_url=endpoint_url,
        aws_access_key_id=access_key,
        aws_secret_access_key=secret_key,
        region_name=region_name,
        config=boto3.session.Config(
            signature_version='s3v4')
    )

    # Once the client is created.

    try:
        print((
            'checking bucket={} exists').format(
                bucket_name))
        if s3.Bucket(bucket_name) not in s3.buckets.all():
            print((
                'creating bucket={}').format(
                    bucket_name))
            s3.create_bucket(
                Bucket=bucket_name)
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
            bucket_key))
    s3.Bucket(bucket_name).upload_file(filename, bucket_key)

    # Download the file from S3
    print((
        'upload_file({}, {}, {})').format(
            bucket_name,
            bucket_key,
            download_filename))
    s3.Bucket(bucket_name).download_file(bucket_key, download_filename)
    print((
        'download_filename={} contents: {}').format(
            download_filename,
            open(download_filename).read()))
# end of run_s3_test


if __name__ == "__main__":
    run_s3_test()
