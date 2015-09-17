Feature: Usage of deployment artifacts with cloudify 3
  # Tested features with this scenario:
  #   - Deployment artifact as a file and directory for nodes and relationships
  #   - Override deployment artifact in Alien
  Scenario: Usage of deployment artifacts with cloudify 3
    Given I am authenticated with "ADMIN" role
    And I have already created a cloud image with name "Ubuntu Trusty", architecture "x86_64", type "linux", distribution "Ubuntu" and version "14.04.1"

    # Archives
    And I checkout the git archive from url "https://github.com/alien4cloud/tosca-normative-types.git" branch "master"
    And I upload the git archive "tosca-normative-types"
    And I checkout the git archive from url "https://github.com/alien4cloud/alien4cloud-extended-types.git" branch "master"
    And I upload the local archive "csars/artifact-test"
    And I upload the local archive "topologies/artifact_test.yaml"

    # Cloudify 3
    And I upload a plugin from maven artifact "alien4cloud:alien4cloud-cloudify3-provider"
#    And I upload a plugin from "../alien4cloud-cloudify3-provider"
    And I create a cloud with name "Cloudify 3" from cloudify 3 PaaS provider
    And I update cloudify 3 manager's url to the OpenStack's jenkins management server for cloud with name "Cloudify 3"
    And I enable the cloud "Cloudify 3"
    And I add the cloud image "Ubuntu Trusty" to the cloud "Cloudify 3" and match it to paaS image "02ddfcbb-9534-44d7-974d-5cfd36dfbcab"
    And I add the flavor with name "small", number of CPUs 2, disk size 34359738368 and memory size 2147483648 to the cloud "Cloudify 3" and match it to paaS flavor "2"
    And I add the storage with id "SmallBlock" and device "/dev/vdb" and size 1073741824 to the cloud "Cloudify 3"
    And I add the public network with name "public" to the cloud "Cloudify 3" and match it to paaS network "net-pub"

    And I create a new application with name "artifact-test-cfy3" and description "Artifact test with CFY 3" based on the template with name "artifact_test"
    And I update the node template "Artifacts"'s artifact "to_be_overridden" with file at path "src/test/resources/data/toOverride.txt"
    And I assign the cloud with name "Cloudify 3" for the application

    When I deploy it
    Then I should receive a RestResponse with no error
    And The application's deployment must succeed after 15 minutes
    When I download the remote file "/home/ubuntu/toBeOverridden.txt" from the node "Compute" with the keypair "keys/cfy3.pem" and user "ubuntu"
    Then The downloaded file should have the same content as the local file "data/toOverride.txt"
    When I download the remote file "/home/ubuntu/toBePreserved.txt" from the node "Compute" with the keypair "keys/cfy3.pem" and user "ubuntu"
    Then The downloaded file should have the same content as the local file "csars/artifact-test/toBePreserved.txt"