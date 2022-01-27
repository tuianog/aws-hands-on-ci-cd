from chalice import Chalice, Response
import os, boto3, json, hmac, hashlib, shutil, base64
from zipfile import ZipFile
import git

app = Chalice(app_name='webhook_test')

config = {
    "s3ReleaseBucket": os.getenv("RELEASE_BUCKET"),
    "s3ReleaseBucketKmsKeyId": os.getenv("RELEASE_BUCKET_KMS_KEY_ID"),
    "secretName": os.getenv("SECRET_NAME"),
    "knownHostsB64": os.getenv("KNOWN_HOSTS_B64")
}

session = boto3.session.Session()

def get_return_response(body = 'Ok', status_code=200):
    try:
        body = json.dumps(body)
    except TypeError as error:
        return Response(
            body='Error: '+str(error),
            status_code=500,
        )
    return Response(
        body=body,
        status_code=status_code,
    )

def get_secrets_from_secrets_manager(secret_name):
    client = session.client(
        service_name='secretsmanager',
    )
    get_secret_value_response = client.get_secret_value(
        SecretId=secret_name
    )
    text_secret_data = get_secret_value_response['SecretString']
    return json.loads(text_secret_data)


@app.route("/webhook", methods=['POST'])
def handler_post():
    print('POST webhook handler')
    try:
        headers = app.current_request.headers
        print('POST handler: headers {}'.format(headers))
        event_body = app.current_request.json_body
        print('POST handler: body {}'.format(event_body))
        if app.current_request.headers.get('x-event-key') == "diagnostics:ping":
            return get_return_response(body='Test connection with success', status_code=200)
        event_key = headers.get('x-event-key')
        if event_key != 'repo:push':
            raise ValueError('Invalid push payload')
        secret = get_secrets_from_secrets_manager(config['secretName'])
        #verify_signature_header(event_body, secret)
        perform_clone_and_zip(event_body, secret)
        return get_return_response(status_code=200)
    except Exception as error:
        print('Exception {}'.format(str(error)))
        return get_return_response(body=str(error), status_code=500)


# Used if configured Webhook with secret
def verify_signature_header(event_body, secret):
    header_signature = app.current_request.headers.get('x-hub-signature')
    if not header_signature:
        raise ValueError("No x-hub-signature header.")

    digest_header_split = header_signature.split('=')
    if len(digest_header_split) == 2:
        algorithm, signature_digest = digest_header_split
    else:
        raise ValueError("Invalid x-hub-signature header: expecting <algorithm>=<hash>")

    if algorithm != 'sha256':
        raise ValueError('Unsupported digest algorithm {}.'.format(algorithm))

    body_digest = hmac.new(key = secret["webhookSecret"].encode('utf-8'),
                           msg = event_body.encode('utf-8'),
                           digestmod = hashlib.sha256
                           ).hexdigest()

    if not signature_digest == body_digest:
        raise ValueError('Expected digest did not match provided HTTP signature header digest')


def get_git_metadata(body):
    branch_name = body.get('push').get('changes')[0].get('new').get('name')
    committer_user = body.get('actor').get('username')
    project_name = body.get('repository').get('slug')
    repository_full_name = body.get('repository').get('fullName')
    git_project_url = f"ssh://git@git.bmwgroup.net:7999/{repository_full_name}.git"
    return {
        "branchName": branch_name,
        "gitProjectUrl": git_project_url,
        "committerUser": committer_user,
        "projectName": project_name
    }


def perform_clone_and_zip(event_body, secret):
    setup_ssh_private_key(secret)
    git_metadata = get_git_metadata(event_body)
    branch_name = git_metadata['branchName']
    repo_dir = '/tmp/repository'
    if os.path.isdir(repo_dir):
        shutil.rmtree(repo_dir)
    repo = git.repo.base.Repo.clone_from(git_metadata['gitProjectUrl'], repo_dir, branch=branch_name, depth=1)
    print(f"Cloned repo {git_metadata['projectName']} with success for branch {branch_name}")
    git_files = get_git_repo_files(repo)
    zip_file = f"/tmp/package.zip"
    build_zip_file(git_files, zip_file)
    upload_to_s3(git_metadata, zip_file)
    print('Done')


def setup_ssh_private_key(secret):
    ssh_dir = '/tmp/.ssh'
    ssh_private_key_file = f"{ssh_dir}/id_rsa"
    ssh_private_key = base64.b64decode(secret['privateKey'])
    if not os.path.isdir(ssh_dir):
        os.mkdir(ssh_dir)
    with open(ssh_private_key_file, "wb") as file:
        file.write(ssh_private_key)
    os.chmod(ssh_private_key_file, 0o600)
    hosts_file = '/tmp/.ssh/known_hosts'
    with open(hosts_file, "wb") as file:
        file.write(base64.b64decode(config['knownHostsB64']))
    os.environ["GIT_SSH_COMMAND"] = f"ssh -i {ssh_private_key_file} -o UserKnownHostsFile={hosts_file}"
    print('Git env:', os.getenv('GIT_SSH_COMMAND'))


def get_git_repo_files(repo):
    git_root = os.path.abspath("%s/.." % repo.git_dir)
    git_files = git.Git(git_root).ls_files().split("\n")
    return [os.path.abspath("%s/%s" % (git_root, file)) for file in git_files]


def build_zip_file(files, zip_file):
    common_prefix = os.path.commonprefix(files)
    zip = ZipFile(zip_file, 'w')
    for file in files:
        zip.write(
            filename=file,
            arcname=os.path.relpath(file, common_prefix)
        )
    zip.close()


def upload_to_s3(git_metadata, zip_file):
    s3_client = session.client("s3")
    s3_target_key = f"{git_metadata['projectName']}/{git_metadata['branchName']}.zip"
    with open(zip_file, "rb") as zip_file_content:
        s3_client.put_object(
            Body=zip_file_content,
            Bucket=config['s3ReleaseBucket'],
            Key=s3_target_key,
            ServerSideEncryption="aws:kms",
            SSEKMSKeyId=config['s3ReleaseBucketKmsKeyId']
        )