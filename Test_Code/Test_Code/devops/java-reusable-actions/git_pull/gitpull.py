import json
import os
import subprocess
import sys
import yaml

""" GITPULL """

def set_user_details():
    command = "git config --local user.email vet-infrastructure.uk@capgemini.com"
    subprocess.run(command, shell=True)
    command = "git config --local user.name VET-Jenkins"
    subprocess.run(command, shell=True)
    command = "git config --local credential.helper cache"
    subprocess.run(command, shell=True)


def create_tag_github():
    # TODO: Infrastructure needs implemented for new tagging process
    if builddata["jobname"] in specialRepoList:
        set_user_details()

        command = "git config --local -l"
        ret = subprocess.run(command, capture_output=True, shell=True)
        print((ret.stdout.decode()).strip())

        command = (
            "git tag --points-at HEAD |grep -v deploy | grep ^[0-9] |sort -n |tail -1"
        )
        ret = subprocess.run(command, capture_output=True, shell=True)
        latestTag = (ret.stdout.decode()).strip()

        if latestTag != "":
            print("Already tagged with version number= ", latestTag)
            return latestTag

        command = "git tag |grep -v deploy | grep ^[0-9] |sort -n |tail -1"
        ret = subprocess.run(command, capture_output=True, shell=True)
        gitTag = (ret.stdout.decode()).strip()

        newTag = 1 if gitTag == "" else int(gitTag) + 1
        print("Current tag = " + gitTag)
        print("New tag = " + str(newTag))

        command = (
            "git tag -a "
            + str(newTag)
            + " -m 'Creating Tag For Release "
            + str(newTag)
            + "'"
        )
        ret = subprocess.run(command, capture_output=True, shell=True)
        print(command)

        command = "git log -n 2 --graph --abbrev-commit --decorate --format=format:'%C(yellow)%ai%Creset %C(2)%h%Creset %C(5)%d%Creset %C(blue)%aN%Creset %n''%s'"
        ret = subprocess.run(command, capture_output=True, shell=True)
        print((ret.stdout.decode()).strip())

        # TODO: Uncomment this and possibly fix it, when testing with a real repository
        # command = "git push --follow-tags " + str(newTag)
        # ret = subprocess.run(command, capture_output=True, shell=True)
        # print((ret.stdout.decode()).strip())

        return str(newTag)
    else:
        print("Repo is not specified for new tag approach.")


def create_version_number_tag():
    version_number_tag = create_tag_github()

    if builddata["jobname"] in specialRepoList:
        print("Found repo in specialList=", builddata["jobname"])
        version_number_tag += "-" + tmpBuilddata["git_shorthash"]

    return version_number_tag


''' Entrypoint '''

# taking in inputs 
arr = sys.argv[1::]
payload_str = " ".join(map(str, arr))
github_context = json.loads(payload_str)

# Define global vars
builddata = {}
specialRepoList = [
    "service-registry-dashboard",
    "accounts-java-container-app-profile",
    "accounts-java-container-orchestration",
    "accounts-java-container-app-authentication",
    "accounts-java-container-app-authorization",
]

otr = [
    "capability-otr-dotnet-docker-mock",
    "otr-dotnetcore-container-orderms",
    "otr-dotnetcore-container-gmal-order-completed-event-processor",
    "otr-dotnetcore-container-gmal-order-state-event-processor",
    "otr-dotnetcore-container-gmal-orchestrator",
    "otr-dotnetcore-container-totalizems",
    "otr-dotnetcore-container-loyalt-integration-ms",
    "otr-dotnetcore-nuget-delivery-core",
    "otr-dotnetcore-container-deliveryms",
    "otr-dotnetcore-container-ue-deliveryms",
    "otr-dotnet-lambda-delivery",
    "otr-dotnetcore-container-fraudms",
    "otr-dotnetcore-container-paymentms",
    "otr-dotnetcore-container-pushnotificationms",
    "otr-dotnetcore-container-gma-payment-reversal-event-processor",
    "otr-dotnetcore-mesh-container-gma-digital-receipt-notification-processor",
]
payments = [
    "payments-dotnetcore-container-fraudms",
    "payments-dotnetcore-container-paymentms",
    "payments-dotnetcore-container-walletms",
    "payments-dotnetcore-container-pspnotificationms",
    "payments-dotnetcore-container-payment-product-gateway",
]

offers = [
    "offers-java-lambda-oas-new-customers-eligibility",
    "offers-java-lambda-oas-reporting",
    "offers-java-lambda-oas-batch-ingestion",
    "offers-java-container-offerassociation",
]

capabilityManagedRepoNames = [
    "accounts",
    "core",
    "delivery",
    "menu",
    "offers",
    "order",
    "otr",
    "payments",
    "pe",
]

# Repository metadata to dictionary conversion 
with open("build.yaml", "r") as file:
    tmpBuilddata = yaml.safe_load(file)


command = "git rev-parse HEAD"
ret = subprocess.run(command, capture_output=True, shell=True)
tmpBuilddata["git_hash"] = (ret.stdout.decode()).strip()

command = "git rev-parse --short=6 HEAD"
ret = subprocess.run(command, capture_output=True, shell=True)
tmpBuilddata["git_shorthash"] = (ret.stdout.decode()).strip()

buildVersion = str(tmpBuilddata["version"])
currentBuild_description = buildVersion + " - " + tmpBuilddata["git_shorthash"]


if len(tmpBuilddata["docker"]) > 0:
    buildflag = "docker"
elif len(tmpBuilddata["lambda"]) > 0:
    buildflag = "lambda"
else:
    buildflag = ""
    print("buildflag is not set.")

# Code for Opentest tag in build yaml file
if ("opentest" in tmpBuilddata) and (len(tmpBuilddata["opentest"]) > 0):
    opentestFlag = True
    if "opentest_path" in tmpBuilddata["opentest"]:
        opentest_path = (tmpBuilddata["opentest"])["opentest_path"]
else:
    opentestFlag = False

# Code for jmeter tag in build yaml file
if ("jmeter" in tmpBuilddata) and (len(tmpBuilddata["jmeter"]) > 0):
    jmeterFlag = True
    if "jmeter_path" in tmpBuilddata["jmeter"]:
        jmeter_path = (tmpBuilddata["jmeter"])["jmeter_path"]
else:
    jmeterFlag = False

# Code for liquibase tag in build yaml file
if ("liquibase" in tmpBuilddata) and (len(tmpBuilddata["liquibase"]) > 0):
    liquibaseFlag = True
    if "liquibase_path" in tmpBuilddata["liquibase"]:
        liquibase_path = (tmpBuilddata["liquibase"])["liquibase_path"]
    if "changelog" in tmpBuilddata["liquibase"]:
        changelog = (tmpBuilddata["liquibase"])["changelog"]
else:
    liquibaseFlag = False


# Code for postman tag in build yaml file
if ("postman" in tmpBuilddata) and (len(tmpBuilddata["postman"]) > 0):
    postmanFlag = True
    if "postman_path" in tmpBuilddata["postman"]:
        postman_path = (tmpBuilddata["postman_path"])["postman_path"]
else:
    postmanFlag = False

# Code for flagger tag in build yaml file
if "flagger" in tmpBuilddata:
    flaggerFlag = True
else:
    flaggerFlag = False


# Code for deployment tag in build yaml file
if "deployment" in tmpBuilddata:
    deploymentFlag = True
    if "terraform_path" in tmpBuilddata["deployment"]:
        terraform_path = (tmpBuilddata["deployment"])["terraform_path"]
else:
    deploymentFlag = False

for it in tmpBuilddata[buildflag]:
    print(it)
    currentWorkingDirectory = os.getcwd()
    it["basepath"] = currentWorkingDirectory
    if buildflag == "docker":
        pathBreakdown = it["path"].split("/")
        if len(pathBreakdown) == 1 and it["name"] == it["path"]:
            it["workingdir"] = currentWorkingDirectory + "/{}".format(it["name"])
        if pathBreakdown[-1] == it["name"]:
            it["workingdir"] = currentWorkingDirectory + "/{}/{}".format(
                pathBreakdown[0], it["name"]
            )
        else:
            it["workingdir"] = currentWorkingDirectory + "/{}/{}".format(
                it["path"], it["name"]
            )
    elif buildflag == "lambda":
        it["workingdir"] = currentWorkingDirectory
    else:
        it["workingdir"] = currentWorkingDirectory
    it["Proj"] = it["path"] + "/Project.groovy"
    it["branch"] = ((github_context["ref_name"]).replace("/", "-")).lower()
    it["rawbranch"] = github_context["ref_name"]
    it["jobname"] = (github_context["repository"].split("/"))[1]
    it["repoName"] = github_context["repository"]
    it["buildtype"] = buildflag
    it["git_shorthash"] = tmpBuilddata["git_shorthash"]
    it["version"] = f"{buildVersion}-{tmpBuilddata['git_shorthash']}-gha"
    it["buildVersion"] = buildVersion
    it["git_hash"] = tmpBuilddata["git_hash"]
    it[
        "docker_artifactory_sharedtools_host_url"
    ] = "artifactory.sharedtools.vet-tools.digitalecp..com"
    it["opentestFlag"] = opentestFlag
    it["jmeterFlag"] = jmeterFlag
    it["liquibaseFlag"] = liquibaseFlag
    it["postmanFlag"] = postmanFlag
    it["flaggerFlag"] = flaggerFlag
    it["deploymentFlag"] = deploymentFlag
    it[
        "buildArtifact"
    ] = "vet-docker.artifactory.sharedtools.vet-tools.digitalecp..com/{}:{}-{}".format(
        (github_context["repository"].split("/"))[1],
        (github_context["ref_name"]).replace("/", "-").lower(),
        (it["version"])
    )
    it[
        "jfrogbuildArtifact"
    ] = ".jfrog.io/digital-docker-{}/{}:{}-{}".format(
        (it["jobname"].split("-")[0]),
        (github_context["repository"].split("/"))[1],
        ((github_context["ref_name"]).replace("/", "-")).lower(),
        (it["version"])
    )
    it[
        "jfrogbuildArtifact_docker"
    ] = ".jfrog.io/digital-docker/{}:{}-{}".format(
        (github_context["repository"].split("/"))[1],
        ((github_context["ref_name"]).replace("/", "-")).lower(),
        (it["version"])
    )
    it[
        "jfrogbuildArtifact_lambda"
    ] = "https://.jfrog.io/artifactory/digital-lambdas/{}-{}/{}/{}/{}-{}.jar".format(
        (github_context["repository"].split("/"))[1],
        (it["name"].lower()).strip(),
        ((github_context["ref_name"]).replace("/", "-")).lower(),
        (it["version"]),
        (github_context["repository"].split("/"))[1],
        (it["name"].lower()).strip()
    )


    if opentestFlag == True:
        it["opentest_path"] = opentest_path
    if jmeterFlag == True:
        it["jmeter_path"] = jmeter_path
    if liquibaseFlag == True:
        it["liquibase_path"] = liquibase_path
        if changelog:
            it["changelog"] = changelog
    if postmanFlag == True:
        it["postman_path"] = postman_path

    if deploymentFlag == True:
        it["terraform_path"] = terraform_path

    if flaggerFlag == True:
        it["flaggerContent"] = tmpBuilddata["flagger"]

    if it["jobname"] in payments:
        it["testedServices"] = True
    elif it["jobname"] in offers:
        it["testedServices"] = True
    elif it["jobname"] in otr:
        it["testedServices"] = True
    elif "-forked" in it["jobname"]: # assume that -forked repos need to be unit tested
        it["testedServices"] = True
    else:
        it["testedServices"] = False

    if "java_distribution" in tmpBuilddata:
        it["java_distribution"] = tmpBuilddata["java_distribution"]

    if "java_version" in tmpBuilddata:
        it["java_version"] = tmpBuilddata["java_version"]

    if "mvn_version" in tmpBuilddata:
        it["mvn_version"] = tmpBuilddata["mvn_version"]

    if it["jobname"].split("-")[0] in capabilityManagedRepoNames:
        it["capability"] = it["jobname"].split("-")[0]
    else:
        it["capability"] = 'common'
    
    if it["buildtype"] == 'lambda':
        if it["capability"] == 'otr':
            it["artifactoryBuildRepo"] = 'digital-lambdas'
            it["artifactoryDeploymentsRepo"] = 'digital-deployments-orders'
        else:
            it["artifactoryBuildRepo"] = 'digital-lambdas'
            it["artifactoryDeploymentsRepo"] = 'digital-deployments-' + it["capability"]
    elif it["capability"] == 'pe':
        it["artifactoryBuildRepo"] = 'digital-pe-docker'
        it["artifactoryDeploymentsRepo"] = 'digital-pe-deployments'
    elif it["capability"] == 'otr':
        it["artifactoryBuildRepo"] = 'digital-docker-orders'
        it["artifactoryDeploymentsRepo"] = 'digital-deployments-orders'
    else:
        it["artifactoryBuildRepo"] = 'digital-docker-' + it["capability"]
        it["artifactoryDeploymentsRepo"] = 'digital-deployments-' + it["capability"]

    builddata.update(it)

if builddata["jobname"] in specialRepoList:
    newVersionTag = create_version_number_tag()
    print(newVersionTag)
    builddata.update({"version": newVersionTag})

if len(builddata) > 0:
    with open(os.environ["GITHUB_OUTPUT"], "a") as filename:
        print(f"buildInfo={json.dumps(builddata)}", file=filename)
