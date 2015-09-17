Feature: Reuse block storage with cloudify 2
  # Tested features with this scenario:
  #   - Block storage
  #   - Reuse of an existing block storage
  #   - Usage of multiple block storage on the same compute
  Scenario: Deploying a compute with multiple (types of) storages attached should work
    Given I am authenticated with "ADMIN" role
    And I have already created a cloud image with name "Ubuntu Trusty", architecture "x86_64", type "linux", distribution "Ubuntu" and version "14.04.1"

    # Archives
    And I checkout the git archive from url "https://github.com/alien4cloud/tosca-normative-types.git" branch "master"
    And I upload the git archive "tosca-normative-types"
    And I checkout the git archive from url "https://github.com/alien4cloud/alien4cloud-extended-types.git" branch "master"
    And I upload the git archive "alien4cloud-extended-types/alien-base-types-1.0-SNAPSHOT"
    And I upload the git archive "alien4cloud-extended-types/alien-extended-storage-types-1.0-SNAPSHOT"
    And I upload the local archive "csars/test-int-types-1.0-SNAPSHOT"
    #Maybe a specific step for topo upload?
    And I upload the local archive "topologies/multi_storages.yml" 

    # Cloudify 2
    And I upload a plugin from maven artifact "alien4cloud:alien4cloud-cloudify2-provider"
#    And I upload a plugin from "../alien4cloud-cloudify2-provider"
    And I create a cloud with name "Cloudify 2" from cloudify 2 PaaS provider
    And I update cloudify 2 manager's url to the OpenStack's jenkins management server for cloud with name "Cloudify 2"
    And I enable the cloud "Cloudify 2"
    And I add the cloud image "Ubuntu Trusty" to the cloud "Cloudify 2" and match it to paaS image "RegionOne/c3fcd822-0693-4fac-b8bb-c0f268225800"
    And I add the flavor with name "small", number of CPUs 2, disk size 34359738368 and memory size 2147483648 to the cloud "Cloudify 2" and match it to paaS flavor "RegionOne/2"
    And I add the storage with id "SmallBlock" and device "/dev/vdb" and size 1073741824 to the cloud "Cloudify 2"
    And I match the storage with name "SmallBlock" of the cloud "Cloudify 2" to the PaaS resource "SMALL_BLOCK"

    And I create a new application with name "multi-storage-cfy2" and description "compute with multi Storage with CFY 2" based on the template with name "multi_storage"
    And I assign the cloud with name "Cloudify 2" for the application

    When I deploy it
    Then I should receive a RestResponse with no error
    And The application's deployment must succeed after 15 minutes
    
    When I upload to a node's remote path the local file with the keypair "keys/cfy2.pem" and user "root"
    	| Compute | /var/myTestVolume/block_storage_test_file.txt								| data/block_storage_test_file.txt |
#    	| Compute | /var/CustomStorageWithVolumeId/block_storage_test_file.txt	| data/block_storage_test_file.txt |
    	| Compute | /blockstorage1_data/block_storage_test_file.txt							| data/block_storage_test_file.txt |
    And I re-deploy the application
    Then The application's deployment must succeed after 15 minutes

		When I download the remote file "/var/myTestVolume/block_storage_test_file.txt" from the node "Compute" with the keypair "keys/cfy2.pem" and user "root"
    Then The downloaded file should have the same content as the local file "data/block_storage_test_file.txt"
    
#    When I download the remote file "/var/CustomStorageWithVolumeId/block_storage_test_file.txt" from the node "Compute" with the keypair "keys/cfy2.pem" and user "root"
#    Then The downloaded file should have the same content as the local file "data/block_storage_test_file.txt"
    
    When I download the remote file "/blockstorage1_data/block_storage_test_file.txt" from the node "Compute" with the keypair "keys/cfy2.pem" and user "root"
    Then The downloaded file should have the same content as the local file "data/block_storage_test_file.txt"

    When I undeploy it
    Then I should have a volume on OpenStack with id defined in property "volume_id" of the node "Blockstorage1"
    And I should have a volume on OpenStack with id defined in property "volume_id" of the node "ConfigurableBlockStorage"
    And I should have a volume on OpenStack with id defined in property "volume_id" of the node "CustomStorageWithVolumeId"
    # Delete the volume so do not have any leaks
    Then I should wait for 60 seconds before continuing the test
    Then I delete the volume on OpenStack with id defined in property "volume_id" of the node "Blockstorage1"
    And I delete the volume on OpenStack with id defined in property "volume_id" of the node "ConfigurableBlockStorage"