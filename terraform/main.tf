        
            terraform {
                required_providers {
                    tdh = {
                        source  = "svc-bot-mds/tdh"
                        version = "~>1.2.0" # only allow future patches in this minor release
                    }
                }
            }

            # Configure the TDH Provider

            provider "tdh" {
                host = "https://<tdmc_host>
                type = "user_creds"
                username = "<username>"
                password = "<pwd>"
                org_id = "<orgId>
            }

            locals {
                service_type        = "POSTGRES"
                provider            = "tkgs"
                policy_with_create  = ["open-to-all"]
                instance_type       = "XX-SMALL"
                region              = "tanzu"
                data_plane_id       = "xxx"
                version             = "postgres-15"
                storage_policy_name = "vsan-default-storage-policy" # Modify if required 
            }
            
            # Fetch Network Policies
            data "tdh_network_policies"  "create" {
                names = local.policy_with_create
            }
            data "tdh_network_ports" "all" {
            }  
            
            output "network_policies_data" {
                value = {
                    create = data.tdh_network_policies.create
                }
            }
            resource "tdh_network_policy" "network" {
            name         = "tf-pg-nw-policy"
            network_spec = {
                cidr             = "0.0.0.0/32",
                network_port_ids = [
                for port in data.tdh_network_ports.all.list : port.id if strcontains(port.id, "postgres")
                ]
            }
            } 
              
            # Create Cluster
            resource "tdh_cluster" "test" {
                name                = "mm-demo-terraform"
                service_type        = local.service_type
                provider_type       = local.provider
                instance_size       = local.instance_type
                region              = local.region
                data_plane_id       = local.data_plane_id
                network_policy_ids  = [tdh_network_policy.network.id]
                tags                = ["tdh-tf", "example", "new-tag"]
                version             = local.version
                storage_policy_name = local.storage_policy_name
                cluster_metadata = {
                    username = "my_pg_user"
                    password = "P4$$word"
                    database = "my_db"
                }
                # Non editable fields
                lifecycle {
                    ignore_changes = [instance_size, name, provider_type, region, service_type, version, storage_policy_name]
                }
            }
