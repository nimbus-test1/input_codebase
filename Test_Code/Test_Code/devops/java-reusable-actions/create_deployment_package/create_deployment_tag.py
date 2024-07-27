import os
import yaml
import subprocess

def copy_command(path):
    return 'cp -r --parents {}/{} ./deployment/'.format(os.environ['buildInfo_basepath'], path)

def create_component(deployment_name, build_type, build_artifact):
    component = {}
    component['name'] = (deployment_name.replace(' ', '-')).lower()
    component['buildtype'] = build_type
    component['build_artifact'] = build_artifact
    return component

def parse_lambda_deployments(deployment_info, jfrog_path):
    build_type = 'lambda'
    build_artifact = (os.environ['buildInfo_jfrogbuildArtifact_lambda']).strip()
    if os.environ.get("buildInfo_lambda_names"):
        lambda_names = os.environ.get("buildInfo_lambda_names").lower().split(",")
        for deployment_name in lambda_names:
            build_artifact = f'{(os.environ["buildInfo_buildArtifact"]).strip()}/{jfrog_path}-{deployment_name}.zip'
            deployment_info['components'].append(create_component(deployment_name, build_type, build_artifact))
    else:
        deployment_name = '{}-{}'.format(os.environ['buildInfo_jobname'], os.environ['buildInfo_name'])
        build_artifact = (os.environ['buildInfo_jfrogbuildArtifact_lambda']).strip()
        deployment_info['components'].append(create_component(deployment_name, build_type, build_artifact))
    return deployment_info

def create_deployment_tag():
    job_name = os.environ['buildInfo_jobname']
    build_type = os.environ['buildInfo_buildtype']
    git_hash = os.environ['buildInfo_git_hash']
    branch_name = os.environ["buildInfo_branch"]
    build_version = os.environ['version']

    deployment_info = {'components': [], 'version': build_version, 'git_hash': git_hash}
    build_artifact = (os.environ['buildInfo_buildArtifact']).strip()
    deployment_name = job_name
    if 'buildInfo_name' in os.environ:
        deployment_name = os.environ['buildInfo_name']
    if build_type == 'docker':
        build_artifact = (os.environ['buildInfo_jfrogbuildArtifact_docker']).strip()
        deployment_info['components'].append(
            create_component(deployment_name, build_type, build_artifact)
        )
    elif build_type == 'lambda':
        jfrog_path = f'digital-lambdas/{job_name}/{branch_name}/{build_version}/{job_name}'
        deployment_info = parse_lambda_deployments(deployment_info, jfrog_path)
    else:
        print('Build type not supported!')
        build_artifact= (os.environ['buildInfo_buildArtifact']).strip()
        deployment_info['components'].append(
            create_component(deployment_name, build_type, build_artifact)
        )

    commands = [
        'mkdir deployment', 
        'cp deployment.yaml ./deployment'
    ]

    if os.path.exists("test.yaml"):
        commands.append(
            'cp test.yaml ./deployment;'
        )
    elif os.path.exists(f'{(os.environ["buildInfo_basepath"])}/test.yaml'):
        commands.append(
            f'cp {os.environ["buildInfo_basepath"]}/test.yaml ./deployment;'
        )
    else:
        print('test.YAML does not exist.')

    if (os.environ['buildInfo_deploymentFlag'] == 'true' and
            'terraform_path' in os.environ):
        deployment_info['terraform_path'] = os.environ['buildInfo_terraform_path']
        commands.append(copy_command(deployment_info['terraform_path']))
    
    if (os.environ['buildInfo_opentestFlag'] == 'true' and 
            'buildInfo_opentest_path' in os.environ):
        deployment_info['opentest_path'] = os.environ['buildInfo_opentest_path']
        commands.append(copy_command(deployment_info['opentest_path']))

    if (os.environ['buildInfo_jmeterFlag'] == 'true' and 
            'buildInfo_jmeter_path' in os.environ):
        deployment_info['jmeter_path'] = os.environ['buildInfo_jmeter_path']
        commands.append(copy_command(deployment_info['jmeter_path']))

    if os.environ['buildInfo_liquibaseFlag'] == 'true':
        if 'buildInfo_liquibase_path' in os.environ:
            deployment_info['liquibase_path'] = os.environ['buildInfo_liquibase_path']
            commands.append(copy_command(deployment_info['liquibase_path']))

        if 'buildInfo_liquibase_changelog' in os.environ:
            deployment_info['liquibase_changelog'] = os.environ['buildInfo_liquibase_changelog']
            commands.append(copy_command(deployment_info['liquibase_changelog']))  

    if (os.environ['buildInfo_postmanFlag'] == 'true' and 
            'buildInfo_postman_path' in os.environ):
        deployment_info['postman_path'] = os.environ['buildInfo_postman_path']
        commands.append(copy_command(deployment_info['postman_path']))

    if os.environ['buildInfo_flaggerFlag'] == 'true':
        deployment_info['flagger'] = os.environ['buildInfo_flaggerContent']

    print('deployment_info:\n{}'.format(yaml.dump(deployment_info)))
    with open('deployment.yaml', 'w') as outfile:
        yaml.dump(deployment_info, outfile, default_flow_style=False)

    commands.extend([ 
        'ls -lha ./deployment',
        'cd deployment && zip -9r ../{}.zip .'.format(job_name),
        'ls -lha'
    ])

    print(commands)
    for command in commands:
        print(command)
        output = subprocess.run(command, capture_output=True, shell=True)
        print(output.stdout.decode())

    tag = '{}-gha'.format(os.environ['buildInfo_version'])
    with open(os.getenv('GITHUB_ENV'), 'a') as myfile:
        myfile.write('TAG={}\n'.format(tag))
    with open(os.environ['GITHUB_OUTPUT'], 'a') as filename:
        print(f'TAG={tag}', file=filename)

if __name__ == '__main__':
    create_deployment_tag()