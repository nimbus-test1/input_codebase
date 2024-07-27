import subprocess
import hashlib
import argparse
import requests
from requests.auth import HTTPBasicAuth
import os

def run_commmand(command):
    process = subprocess.Popen(command, stdout=subprocess.PIPE, stderr=subprocess.PIPE, shell=True)
    stdout, stderr = process.communicate()
    print(stdout.decode() + stderr.decode())
    if (process.returncode != 0):
        raise SystemExit("Stopping workflow due to error")

def parse_args():
    parser = argparse.ArgumentParser(formatter_class=argparse.ArgumentDefaultsHelpFormatter)
    parser.add_argument('--lambda_artifact_url', help='The jfrog url and path for lambda artifacts', required=False)
    parser.add_argument('--artifact_index', help='The index for enumerated artifacts', required=False)
    parser.add_argument('--job_name', help='The job name', required=False)
    parser.add_argument('--branch_name', help='The branch name', required=False)
    parser.add_argument('--build_lang', help='The build language', required=False)
    parser.add_argument('--build_type', help='The build type', required=False)
    parser.add_argument('--build_version', help='The build version', required=False)
    parser.add_argument('--jfrog_url', help='The jfrog url', required=False)
    parser.add_argument('--jfrog_user', help='The jfrog username', required=False)
    parser.add_argument('--jfrog_token', help='The jfrog token', required=False)
    parser.add_argument('--jfrog_repo_dir', help='The jfrog repo directory', required=False)
    parser.add_argument('--info_path', help='The repo base path', required=False)
    return parser.parse_args()

def publish_artifact():
    args = parse_args()
    #Publish Artifact for docker
    if (args.build_type == 'docker'):
        if args.info_path:
          print("Changing Directory to: " + args.info_path)
          os.chdir(args.info_path)
        base_image_name ='{}/{}/{}:{}'.format(args.jfrog_url, args.jfrog_repo_dir, args.job_name, args.branch_name)
        commands = [
            'docker images',
            'docker push {}-latest'.format(base_image_name),
            'docker push {}-{}'.format(base_image_name, args.build_version),
            'echo "buildInfo_build_artifact={}-{}" >> $GITHUB_ENV'.format(base_image_name, args.build_version)
        ]

    # Publish Artifact for lambda
    if args.build_type == 'lambda' and (args.build_lang.startswith('java') or args.build_lang.startswith('dotnet')):
        print("Index is set to: " + args.artifact_index)
        if args.artifact_index != "NA":
          local_artifact_path = './{}-{}-{}.jar'.format(args.job_name, args.branch_name, args.artifact_index)
        else:
          local_artifact_path = './{}-{}.jar'.format(args.job_name, args.branch_name)
        print("local_artifact_path is set to: " + local_artifact_path)
        md5checksum = hashlib.md5(open(local_artifact_path, 'rb').read()).hexdigest()
        sha1checksum = hashlib.sha1(open(local_artifact_path, 'rb').read()).hexdigest()
        url = args.lambda_artifact_url
        headers = {
            'X-Checksum-MD5':'{}'.format(md5checksum),
            'X-Checksum-Sha1':'{}'.format(sha1checksum)
        }
        print('headers:{}'.format(headers))
        jfrog_auth = HTTPBasicAuth(args.jfrog_user, args.jfrog_token)
        response = requests.request('PUT', url, headers=headers, data=open(local_artifact_path, 'rb'), auth=jfrog_auth)
        response.raise_for_status()
        commands = [
            'echo "buildInfo_build_artifact={}" >> $GITHUB_ENV'.format(url)
        ]
        print('Artifact URL:{}'.format(url))

    for command in commands:
        run_commmand(command)

if __name__ == '__main__':
    publish_artifact()
