#!/usr/bin/env python

import argparse
import logging
import os
import json
import boto3
import urllib
import datetime

from cryptography.hazmat.backends import default_backend
from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.primitives import serialization
from cryptography.hazmat.primitives.asymmetric import padding
from botocore.signers import CloudFrontSigner
from botocore.exceptions import ClientError
from urllib.parse import urlparse

# Create a logger
logging.basicConfig(format='%(name)s - %(asctime)s %(levelname)s: %(message)s')
logger = logging.getLogger(__file__)
logger.setLevel(logging.INFO)

def generate_signed_url(domain_name, url_path, key_id, pem, expired_in,
                        has_content_disposition=True):
    """
    https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/cloudfront.html#id57
    """
    ###
    # Helper function - RSA signer
    ###
    def rsa_signer(message):
        with open(pem, 'rb') as key_file:
            private_key = serialization.load_pem_private_key(
                    key_file.read(),
                    password=None,
                    backend=default_backend()
            )
        return private_key.sign(message, padding.PKCS1v15(), hashes.SHA1())

    ###
    # Form CloudFront URL
    ###
    filename = os.path.basename(url_path)
    path_encoded = urllib.parse.quote_plus(url_path, safe='/')
    params = {
        "response-content-disposition": "attachment; filename=%s" % filename
        }
    if has_content_disposition:
        url = "{}?{}".format(os.path.join(domain_name, path_encoded),
                             urllib.parse.urlencode(params))
    else:
        url = os.path.join(domain_name, path_encoded)

    ###
    # Generate signed URL
    ###
    expire_date = datetime.datetime.now() + datetime.timedelta(days=expired_in)

    cloudfront_signer = CloudFrontSigner(key_id, rsa_signer)

    # Create a signed url that will be valid until the specfic expiry date
    # provided using a canned policy.
    try:
        signed_url = cloudfront_signer.generate_presigned_url(
            url, date_less_than=expire_date)
        if signed_url.startswith(domain_name):
            return signed_url
        else:
            logger.error("Generated URL does not have correct domain name!")
            return False
    except ClientError as e:
        logger.error(e)
        return False

# Copied from Boto 3 doc
def upload_file(file_name, bucket, object_name=None):
    """Upload a file to an S3 bucket

    :param file_name: File to upload
    :param bucket: Bucket to upload to
    :param object_name: S3 object name. If not specified then file_name is used
    :return: True if file was uploaded, else False
    """

    # If S3 object_name was not specified, use file_name
    if object_name is None:
        object_name = file_name

    # Upload the file
    s3_client = boto3.client('s3')
    try:
        response = s3_client.upload_file(file_name, bucket, object_name)
    except ClientError as e:
        logger.error(e)
        return False
    return True

def create_download_links(locations, duration, outdir, cloudFrontBaseDir,
    cloudFrontDomainName, cloudFrontPrivateKeyID, cloudFrontPrivateKey):
    
    """
    Generate download links for result files.
    Generate a file with all links for batch download.
    Generate a JSON file with all the links and file names for MultiQC download_data module.

    :param locations: a file containing locations of files on S3
    :param duration: time in days for the presigned URLs to remain valid
    :param outdir: where to store the outputs
    :param cloudFrontBaseDir: the base dir for cloudFront
    :param cloudFrontDomainName: the domain name for cloudFront
    :param cloudFrontPrivateKeyID: the private key ID for cloudFront
    :param cloudFrontPrivateKey: the private key file associated with the private key ID for cloudFront
    """
    
    # Set file names and prepare
    json_name = "download_links.json"
    script_name = "download_links.ps1"
    if not outdir.startswith(cloudFrontBaseDir):
        logger.error("Output location NOT starting with {}".format(cloudFrontBaseDir))
        return
    
    # Generate URLs for all files in the input 
    links = dict()
    with open(locations, "r") as rfh, open(script_name, "w") as wfh:
        for location in rfh:
            location = location.strip()
            # Skip empty lines
            if not location:
                continue
            # Check if location is compatible with cloudFrontBaseDir
            if not location.startswith(cloudFrontBaseDir):
                logger.error("File location NOT starting with {}".format(cloudFrontBaseDir))
                return
            # Generate the signed-URL
            relative_url = os.path.relpath(location, cloudFrontBaseDir)
            filename = os.path.basename(location)
            response = generate_signed_url(domain_name=cloudFrontDomainName,
                                           url_path = relative_url,
                                           key_id = cloudFrontPrivateKeyID,
                                           pem = cloudFrontPrivateKey,
                                           expired_in = duration)
            # Write a curl command to the download script
            if response:
                links[filename] = response
                wfh.write("curl -o {} '{}'\n".format(filename, response))
            else:
                return
    
    # Upload the download script to S3
    script_url = os.path.join(outdir, script_name)
    parsed_url = urlparse(script_url)
    response = upload_file(script_name, parsed_url.netloc, parsed_url.path.lstrip('/'))
    if not response:
        logger.error("Unable to upload file {} to {}".format(script_name, outdir))
        return
    
    # Generate URL for the download script
    relative_url = os.path.relpath(script_url, cloudFrontBaseDir)
    response = generate_signed_url(domain_name=cloudFrontDomainName,
                                   url_path = relative_url,
                                   key_id = cloudFrontPrivateKeyID,
                                   pem = cloudFrontPrivateKey,
                                   expired_in = duration)
    if response:
        links[script_name] = response
    else:
        return
    
    # Write everything to a JSON file
    with open(json_name, "w") as fh:
        json.dump(links, fh, indent=4)
    # Upload the JSON file
    json_url = os.path.join(outdir, json_name)
    parsed_url = urlparse(json_url)
    response = upload_file(json_name, parsed_url.netloc, parsed_url.path.lstrip('/'))
    if not response:
        logger.error("Unable to upload file {} to {}".format(json_name, outdir))
        return

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="""Generate download links for output files on S3""")
    parser.add_argument("locations", type=str, help="File with all the locations of files on S3")
    parser.add_argument("-o", "--output_dir", dest="outdir", required=True, help="The location to save the download script on S3")
    parser.add_argument("-d", "--duration", dest="duration", default=60, type=int, help="Number of days the links are active")
    parser.add_argument("-b", "--cloudFrontBaseBir", dest="cloudFrontBaseDir", type=str, required=True, help="The base dir for CloudFront")
    parser.add_argument("--domainName", dest="cloudFrontDomainName", type=str, required=True, help="The domain name for CloudFront")
    parser.add_argument("--privateKeyID", dest="cloudFrontPrivateKeyID", type=str, required=True, help="The private key ID for CloudFront")
    parser.add_argument("--privateKey", dest="cloudFrontPrivateKey", type=str, required=True, help="The private key file for CloudFront")
    args = parser.parse_args()
    create_download_links(args.locations, args.duration, args.outdir, args.cloudFrontBaseDir, 
                          args.cloudFrontDomainName, args.cloudFrontPrivateKeyID, args.cloudFrontPrivateKey)
