import subprocess
import yaml
import json
import sys
import os
import urllib


def getArtifactProperties(artifactPath):

    response = os.popen("curl --silent -u {}:{} -X GET \"https://{}/artifactory/api/storage/{}?properties\"".format(jfrogUsername,jfrogToken,hostUrl,artifactPath)).read()
    print(response)

    parsedResponse = json.loads(response)
    if "properties" in parsedResponse:
        return parsedResponse["properties"]
    return -1

def putArtifactProperties(artifactPath, artifactProperties):
    ENC_PIPE = "%7C"
    propertiesString = ""
    print(artifactProperties)
    for i in artifactProperties:
        propertiesString += "{}={}{}".format(
            i, (",".join(artifactProperties[i])), ENC_PIPE
        )
    propertiesString = propertiesString[0 : propertiesString.rfind(ENC_PIPE)]
    print(propertiesString)
    response = os.popen("curl --silent -u {}:{} -X PUT \"https://{}/artifactory/api/storage/{}?properties={}\"".format(jfrogUsername,jfrogToken,hostUrl,artifactPath,propertiesString)).read()
    print(response)
    
    '''outputs'''
    env_file = os.getenv("GITHUB_ENV")
    with open(env_file, "a") as myfile:
        myfile.write("artifactPath={}\n".format(artifactPath))
        myfile.write("properties={}".format(propertiesString))


""" Entry Point Inputs """

# Define global variable
repoName = sys.argv[1]
branch = sys.argv[2]
version = sys.argv[3]
hostUrl = sys.argv[4]
jfrogUsername = sys.argv[5]
jfrogToken = sys.argv[6]
jfrogRepoDir = sys.argv[7]
debug = ""
release = ""
deploymentArtifactPath = "{}/{}/{}/{}/{}.zip".format(jfrogRepoDir, repoName, branch, version, repoName)
# newProperties = {"debug": [debug], "release": [release]}

if branch != "master":
    debug = "true"
    release = "false"
else:
    debug = "false"
    release = "true"
newProperties = {"debug": [debug], "release": [release]}
currentProperties = getArtifactProperties(deploymentArtifactPath)
if currentProperties != -1:
    for i in currentProperties:
        if i in newProperties:
            newProperties[i] = set(newProperties[i])
            for j in currentProperties[i]:
                newProperties[i].add(j)

"""
type(deploymentArtifactPath) = str
type(newProperties) = dict
"""
putArtifactProperties(deploymentArtifactPath, newProperties)