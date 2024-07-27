import json
import argparse
import xmltodict
from xml.dom.minidom import parseString

def read_xml(xml_file):
    with open(xml_file, 'r') as f:
        data = f.read()
    return parseString(data)

def append_repo_ids(elements, repository_ids):
    if not isinstance(elements, list): elements = [elements]
    for i in elements:
        if '.jfrog.io' in i['url']: 
            repository_ids.append(i['id'])

def parse_modules(module, repository_ids):
    pom_path = f'{module}/pom.xml'
    with open(pom_path) as xml_file:
        pom_text = xmltodict.parse(xml_file.read())
        pom_json = json.dumps(pom_text)
    pom_json= json.loads(pom_json)

    if 'repositories' in pom_json['project']:
        repositories = (pom_json['project'])['repositories']
        for repository in repositories: 
            append_repo_ids(repositories[repository], repository_ids)

def generate_settings(args):
    ''' Maven Setting Changes For JFrog Artifactory '''
    try:
        pom_path = 'pom.xml'
        repository_ids = []
        with open(pom_path) as xml_file:
            pom_text = xmltodict.parse(xml_file.read())
            pom_json = json.dumps(pom_text)
        pom_json= json.loads(pom_json)

    except Exception as e:
        print('pom.xml file issue. Possible error: pom file not in directory.')
        print('Exception: {}'.format(e))

    try:
        if 'repositories' in pom_json['project']:
            repositories = (pom_json['project'])['repositories']
            for repository in repositories: append_repo_ids(repositories[repository], repository_ids)
        else:
            print('No "repositories" key in JSON dump.')

    except Exception as e:
        print('Keys in pom_json not correct. Possible error: repositories not formatted correctly.')
        print('Exception: {}'.format(e))

    try:
        if 'modules' in pom_json['project']:
            modules = (pom_json['project'])['modules']
            if type(modules['module']) is list:
                for module in modules['module']: 
                    parse_modules(module, repository_ids)
            else:
                parse_modules(modules['module'], repository_ids)
        else:
            print('No "module" key in JSON dump.')
    except Exception as e: 
        print('Keys in pom_json not correct. Possible error: modules key not formatted correctly.')
        print('Exception: {}'.format(e))
        
    ''' Write to xml '''
    print(repository_ids)
    dom = read_xml(args.settings)
    servers = dom.getElementsByTagName('servers')[0]
    if len(repository_ids) > 0:
        for i in repository_ids:
            server = dom.createElement('server')
            repo_id = dom.createElement('id')
            username = dom.createElement('username')
            password = dom.createElement('password')
            repo_id.appendChild(dom.createTextNode(i))
            username.appendChild(dom.createTextNode(args.jfrog_user))
            password.appendChild(dom.createTextNode(args.jfrog_token))
            server.appendChild(repo_id)
            server.appendChild(username)
            server.appendChild(password)
            servers.appendChild(server)

    with open(f'{args.settings}','w') as f:
        f.write(dom.toprettyxml())

def parse_args():
    parser = argparse.ArgumentParser(formatter_class=argparse.ArgumentDefaultsHelpFormatter)
    parser.add_argument('--settings', help='Path to settings.xml', required=True)
    parser.add_argument('--jfrog_user', help='A jfrog username', required=True)
    parser.add_argument('--jfrog_token', help='A jfrog personal access token', required=True)
    return parser.parse_args()

def main():
    args = parse_args()
    generate_settings(args)

if __name__ == '__main__':
    main()