# Enterprise Cloud Platform | Workload Pattern - Azure Virtual Desktop (AVD)

A state-of-the-art, modular Azure Virtual Desktop deployment using Terraform and Terragrunt with a layered architecture approach.

## Table of Contents

- [Overview](#overview)
- [Enterprise Cloud Platform Integration](#enterprise-cloud-platform-integration)
- [Architecture](#architecture)
- [Project Structure](#project-structure)
- [Deployment Levels](#deployment-levels)
- [Multi-Environment Support](#multi-environment-support)
- [Prerequisites](#prerequisites)
- [Getting Started](#getting-started)
- [Design Principles](#design-principles)

## Overview

This project is a **Workload Pattern** for the Enterprise Cloud Platform (ECP) offering, providing a production-ready, scalable Azure Virtual Desktop (AVD) infrastructure deployment using Infrastructure as Code (IaC).

As an ECP Workload Pattern, this solution builds on top of the foundational services provided by Enterprise Cloud Platform, leveraging existing networking, monitoring, and storage infrastructure while adding AVD-specific capabilities. The solution is designed with modularity, reusability, and multi-environment support as core principles, and is fully compatible with Enterprise Cloud Platform standards and practices.

## Enterprise Cloud Platform Integration

This AVD Workload Pattern is designed to seamlessly integrate with and extend the Enterprise Cloud Platform. It leverages the following ECP-provided infrastructure:

### ECP-Provided Foundation Services

The following services are **provided by Enterprise Cloud Platform** and do not need to be deployed as part of this workload pattern:

- **Networking Infrastructure**: Virtual Networks, Subnets, Network Security Groups, Route Tables, Azure Firewall
- **Log Analytics Workspace**: Centralized logging and monitoring infrastructure
- **Terraform State Storage**: Azure Storage Account with blob containers for remote state management
- **Private DNS Zones**: DNS infrastructure for private endpoint resolution
- **Key Vault** (optional): Centralized secrets management
- **Azure Bastion** (optional): Secure VM access infrastructure

### Workload Pattern Scope

This AVD Workload Pattern focuses on deploying:

- **AVD-Specific Storage**: Storage accounts for FSLogix profiles and MSIX app attach
- **Compute Gallery & Image Builder**: Custom image management for AVD session hosts
- **AVD Management Plane**: Workspaces, host pools, and application groups
- **AVD Session Hosts**: Virtual machines and associated configurations
- **AVD-Specific Configurations**: FSLogix, scaling plans, and application deployment

### Integration Points

The workload pattern integrates with ECP through:

- **Network Peering/Integration**: AVD resources are deployed into ECP-provided subnets
- **Centralized Logging**: All AVD resources send diagnostics to ECP Log Analytics workspace
- **State Management**: Terraform state is stored in ECP-provided storage accounts
- **DNS Integration**: AVD resources utilize ECP Private DNS zones
- **Security Integration**: Leverages ECP network security controls and policies

### Key Features

- **Layered Architecture**: Clear separation of concerns across infrastructure levels
- **Multi-Environment**: Support for dev, test, staging, and production environments
- **DRY Principle**: Terragrunt configuration to avoid code duplication
- **Security First**: Built-in security best practices and compliance standards
- **Scalability**: Designed to scale from pilot to enterprise-wide deployments
- **Observability**: Integrated monitoring and logging from the ground up

## Architecture

The deployment is structured into distinct levels, building on top of Enterprise Cloud Platform foundation services:

```
╔═══════════════════════════════════════════════════════════════════════════╗
║                                                                           ║
║                  ENTERPRISE CLOUD PLATFORM (ECP)                          ║
║                         Foundation Services                               ║
║                                                                           ║
╠═══════════════════════════════════════════════════════════════════════════╣
║                                                                           ║
║  Virtual Networks & Subnets  │  Network Security Groups & Azure Firewall  ║
║  Log Analytics Workspace     │  Terraform State Storage Account           ║
║  Private DNS Zones           │  Key Vault & Azure Bastion (optional)      ║
║                                                                           ║
╚═══════════════════════════════════════════════════════════════════════════╝
                                     │
                                     │ Builds Upon
                                     ▼
╔═══════════════════════════════════════════════════════════════════════════╗
║                  AVD WORKLOAD PATTERN DEPLOYMENT LEVELS                   ║
╚═══════════════════════════════════════════════════════════════════════════╝

┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃ Level 0: AVD Foundation Infrastructure                                ┃
┣━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┫
┃                                                                       ┃
┃  ▸ Storage Accounts (FSLogix Profiles, MSIX)                          ┃
┃  ▸ Azure Compute Gallery                                              ┃
┃  ▸ Azure Image Builder Infrastructure                                 ┃
┃  ▸ Private Endpoints (for AVD storage)                                ┃
┃                                                                       ┃
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
                                     │
                                     │ Depends On
                                     ▼
┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃ Level 1: AVD Management Plane                                         ┃
┣━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┫
┃                                                                       ┃
┃  ▸ AVD Workspaces                                                     ┃
┃  ▸ Host Pools (Pooled & Personal)                                     ┃
┃  ▸ Application Groups (Desktop & RemoteApp)                           ┃
┃  ▸ Workspace Application Assignments                                  ┃
┃  ▸ Scaling Plans & Start VM on Connect                                ┃
┃                                                                       ┃
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
                                     │
                                     │ Depends On
                                     ▼
┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃ Level 2: AVD Session Hosts                                            ┃
┣━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┫
┃                                                                       ┃
┃  ▸ Session Host Virtual Machines                                      ┃
┃  ▸ Domain Join (Azure AD or AD DS)                                    ┃
┃  ▸ AVD Agent Registration                                             ┃
┃  ▸ Managed Identities                                                 ┃
┃  ▸ Custom Extensions & Scripts                                        ┃
┃  ▸ Monitoring Agents (Azure Monitor, Defender)                        ┃
┃                                                                       ┃
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
                                     │
                                     │ Depends On
                                     ▼
┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃ Level 3: Configuration & Customization                                ┃
┣━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┫
┃                                                                       ┃
┃  ▸ Custom Images (via Image Builder)                                  ┃
┃  ▸ FSLogix Profile Management                                         ┃
┃  ▸ MSIX App Attach                                                    ┃
┃  ▸ Application Installation Automation                                ┃
┃  ▸ GPO/Intune Policy Configurations                                   ┃
┃                                                                       ┃
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
```

## Project Structure

```
enterprise-cloud-platform-wp-avd/
├── README.md
├── .gitignore
├── environments/                    # Environment-specific configurations
│   ├── dev/
│   │   ├── terragrunt.hcl          # Environment-level Terragrunt config
│   │   ├── ecp-config.hcl          # ECP foundation service references
│   │   ├── level0/
│   │   │   ├── storage/
│   │   │   │   └── terragrunt.hcl  # Module-specific values
│   │   │   ├── compute-gallery/
│   │   │   │   └── terragrunt.hcl
│   │   │   └── image-builder/
│   │   │       └── terragrunt.hcl
│   │   ├── level1/
│   │   │   ├── workspace/
│   │   │   │   └── terragrunt.hcl
│   │   │   ├── host-pool-pooled/
│   │   │   │   └── terragrunt.hcl
│   │   │   ├── host-pool-personal/
│   │   │   │   └── terragrunt.hcl
│   │   │   └── application-groups/
│   │   │       └── terragrunt.hcl
│   │   ├── level2/
│   │   │   ├── session-hosts-pooled/
│   │   │   │   └── terragrunt.hcl
│   │   │   └── session-hosts-personal/
│   │   │       └── terragrunt.hcl
│   │   └── level3/
│   │       ├── custom-images/
│   │       │   └── terragrunt.hcl
│   │       └── fslogix/
│   │           └── terragrunt.hcl
│   ├── test/
│   │   └── [same structure as dev]
│   ├── staging/
│   │   └── [same structure as dev]
│   ├── prod/
│   │   └── [same structure as dev]
│   └── common.hcl                   # Shared configuration across environments
│
├── src/                             # Terraform modules
│   ├── level0/
│   │   ├── storage/
│   │   │   ├── main.tf
│   │   │   ├── variables.tf
│   │   │   ├── outputs.tf
│   │   │   └── README.md
│   │   ├── compute-gallery/
│   │   │   ├── main.tf
│   │   │   ├── variables.tf
│   │   │   ├── outputs.tf
│   │   │   └── README.md
│   │   └── image-builder/
│   │       ├── main.tf
│   │       ├── variables.tf
│   │       ├── outputs.tf
│   │       └── README.md
│   ├── level1/
│   │   ├── workspace/
│   │   │   ├── main.tf
│   │   │   ├── variables.tf
│   │   │   ├── outputs.tf
│   │   │   └── README.md
│   │   ├── host-pool/
│   │   │   ├── main.tf
│   │   │   ├── variables.tf
│   │   │   ├── outputs.tf
│   │   │   └── README.md
│   │   └── application-group/
│   │       ├── main.tf
│   │       ├── variables.tf
│   │       ├── outputs.tf
│   │       └── README.md
│   ├── level2/
│   │   └── session-hosts/
│   │       ├── main.tf
│   │       ├── variables.tf
│   │       ├── outputs.tf
│   │       └── README.md
│   ├── level3/
│   │   ├── custom-image/
│   │   │   ├── main.tf
│   │   │   ├── variables.tf
│   │   │   ├── outputs.tf
│   │   │   └── README.md
│   │   └── fslogix/
│   │       ├── main.tf
│   │       ├── variables.tf
│   │       ├── outputs.tf
│   │       └── README.md
│   └── modules/                     # Shared/common modules
│       ├── naming/
│       ├── tagging/
│       └── monitoring/
│
├── scripts/                         # Helper scripts
│   ├── deploy.sh
│   ├── destroy.sh
│   ├── validate.sh
│   └── image-builder/
│       └── customization-scripts/
│
├── docs/                            # Additional documentation
│   ├── architecture/
│   ├── deployment-guide.md
│   ├── troubleshooting.md
│   └── security-compliance.md
│
└── terragrunt.hcl                   # Root Terragrunt configuration
```

## Deployment Levels

### Level 0: AVD Foundation Infrastructure

**Purpose**: Establish AVD-specific storage and image management infrastructure on top of ECP foundation services.

**Components**:
- **Storage Module**: Storage accounts for FSLogix profiles and MSIX app attach with private endpoints
- **Compute Gallery Module**: Azure Compute Gallery for custom AVD images
- **Image Builder Module**: Azure Image Builder infrastructure and templates for session host images

**ECP Dependencies**:
- Virtual Network and Subnets (from ECP)
- Log Analytics Workspace (from ECP)
- Private DNS Zones (from ECP)

**Deployment Order**: Deploy first (after ECP foundation is available)

### Level 1: AVD Management Plane

**Purpose**: Deploy AVD control plane resources that define the virtual desktop experience.

**Components**:
- **Workspace Module**: AVD workspaces for user access
- **Host Pool Module**:
  - Pooled host pools (multi-session)
  - Personal host pools (single-session)
  - Scaling plans and schedules
- **Application Group Module**:
  - Desktop application groups
  - RemoteApp application groups
  - Application assignments

**Dependencies**:
- Level 0 (AVD storage, compute gallery)
- ECP foundation services (networking, logging)

**Deployment Order**: Deploy after Level 0

### Level 2: AVD Session Hosts

**Purpose**: Deploy and configure the actual virtual machines that users connect to.

**Components**:
- **Session Hosts Module**:
  - VM deployment (Windows 10/11 Multi-session or Enterprise)
  - Domain join (Azure AD Join or Hybrid Azure AD Join)
  - AVD agent installation and registration
  - Managed identities
  - VM extensions (monitoring, anti-malware, custom scripts)
  - Auto-scaling configuration

**Dependencies**:
- Level 0 (AVD storage for profiles)
- Level 1 (host pools for registration)
- ECP foundation services (network subnets, logging)

**Deployment Order**: Deploy after Level 1

### Level 3: Configuration & Customization

**Purpose**: Apply custom configurations, images, and applications to the environment.

**Components**:
- **Custom Image Module**: Image Builder templates and image creation
- **FSLogix Module**: FSLogix configuration, profile containers setup
- **MSIX App Attach**: Application package management
- **Application Installation**: Automated app deployment scripts

**Dependencies**: All previous levels

**Deployment Order**: Deploy after Level 2 or run as needed for updates

## Multi-Environment Support

### Environment Configuration Strategy

Each environment (dev, test, staging, prod) has its own configuration under `environments/{env}/`:

- **Size Variations**: Different VM SKUs, number of session hosts
- **Network Isolation**: Separate VNets per environment or shared hub
- **Cost Optimization**: Auto-shutdown in dev/test, scaling plans
- **Security Posture**: Progressive security controls (least strict in dev, most strict in prod)

### Terragrunt Configuration

**Root `terragrunt.hcl`**:
- Remote state configuration (Azure Storage)
- Provider configuration
- Common variables and functions

**Environment-level `terragrunt.hcl`**:
- Environment-specific settings (subscription ID, location, tags)
- Environment naming conventions

**Module-level `terragrunt.hcl`**:
- Module source path
- Module-specific input variables
- Dependencies between modules

### State Management

- **Remote State**: Uses ECP-provided Azure Storage Account with blob containers per environment
- **State Locking**: Azure Blob lease-based locking (provided by ECP)
- **State Structure**: `avd-workload/{environment}/{level}/{module}/terraform.tfstate`
- **Integration**: State backend configuration references ECP storage account via `ecp-config.hcl`

## Prerequisites

### Enterprise Cloud Platform Requirements

This workload pattern requires an existing Enterprise Cloud Platform deployment with the following services:

- **ECP Foundation Deployment**: Active ECP environment (dev/test/staging/prod)
- **Networking**: Virtual Networks with dedicated subnets for AVD workloads
- **Logging**: Log Analytics Workspace for centralized monitoring
- **State Storage**: Azure Storage Account for Terraform remote state
- **DNS**: Private DNS Zones for private endpoint resolution

### Required Tools

- Terraform >= 1.6.0
- Terragrunt >= 0.54.0
- Azure CLI >= 2.50.0
- Git >= 2.30.0

### Azure Requirements

- Azure Subscription with Owner or Contributor + User Access Administrator roles
- Service Principal or Managed Identity for Terraform (may be provided by ECP)
- Azure AD permissions for user/group assignments
- Access to ECP-provided foundation resources

### Permissions

- `Microsoft.DesktopVirtualization/*` - AVD resources
- `Microsoft.Compute/*` - VMs, images
- `Microsoft.Storage/*` - Storage accounts (for AVD-specific storage)
- Reader access to ECP-provided resources (VNet, Log Analytics, DNS)

## Getting Started

### Initial Setup

1. **Verify ECP Foundation**: Ensure your Enterprise Cloud Platform environment is deployed and obtain the following information:
   - VNet name and resource group
   - Subnet IDs for AVD session hosts
   - Log Analytics Workspace ID
   - Terraform state storage account details
   - Private DNS Zone names

2. **Clone the repository**:
   ```bash
   git clone <repository-url>
   cd enterprise-cloud-platform-wp-avd
   ```

3. **Configure Azure authentication**:
   ```bash
   az login
   az account set --subscription <subscription-id>
   ```

4. **Configure ECP integration**:
   ```bash
   cp environments/dev/ecp-config.hcl.example environments/dev/ecp-config.hcl
   # Edit with ECP-provided resource IDs and names
   ```

5. **Configure environment variables**:
   ```bash
   cp environments/dev/terragrunt.hcl.example environments/dev/terragrunt.hcl
   # Edit with your AVD-specific values
   ```

### Deployment

Deploy an environment in order:

```bash
# Deploy Level 0 - Foundation
cd environments/dev/level0
terragrunt run-all plan
terragrunt run-all apply

# Deploy Level 1 - AVD Management Plane
cd ../level1
terragrunt run-all plan
terragrunt run-all apply

# Deploy Level 2 - Session Hosts
cd ../level2
terragrunt run-all plan
terragrunt run-all apply

# Deploy Level 3 - Customization (as needed)
cd ../level3
terragrunt run-all plan
terragrunt run-all apply
```

### Single Module Deployment

```bash
cd environments/dev/level1/host-pool-pooled
terragrunt plan
terragrunt apply
```

## Design Principles

### 1. ECP-Native Architecture
This workload pattern is designed as a native extension of Enterprise Cloud Platform, leveraging ECP foundation services rather than duplicating infrastructure.

### 2. Separation of Concerns
Each level has distinct responsibilities and can be managed independently while respecting dependencies on both ECP services and previous deployment levels.

### 3. Infrastructure as Code
All infrastructure is defined as code with version control, enabling repeatable deployments and audit trails consistent with ECP standards.

### 4. DRY (Don't Repeat Yourself)
Terragrunt eliminates configuration duplication across environments while maintaining flexibility. ECP integration ensures no duplication of foundation services.

### 5. Security by Default
- Leverages ECP network security controls and policies
- Private endpoints for AVD-specific storage
- Managed identities over service principals where possible
- Encryption at rest and in transit
- Integration with ECP-provided Key Vault

### 6. Observability
- Centralized logging to ECP Log Analytics workspace
- Diagnostic settings on all AVD resources
- Azure Monitor integration through ECP
- Performance monitoring and alerting
- Consistent monitoring strategy across ECP and workload

### 7. Scalability
- Modular design allows adding new host pools or session hosts easily
- Supports horizontal scaling via auto-scaling plans
- Can be extended to multiple regions leveraging ECP multi-region capabilities
- Independent scaling of AVD resources without impacting ECP foundation

### 8. Cost Optimization
- Leverages shared ECP infrastructure (networking, logging, DNS)
- Auto-start/stop schedules for session hosts
- Right-sized VMs per environment
- Scaling plans to match user demand
- Storage tiering for profiles
- No duplication of foundation services reduces overall cost

## Next Steps

1. **Coordinate with ECP Team**: Obtain necessary information about ECP foundation resources (VNet, subnets, Log Analytics, state storage)
2. **Configure ECP Integration**: Update `ecp-config.hcl` with ECP-provided resource references
3. **Review Environment Configurations**: Customize AVD-specific settings per environment
4. **Define Image Strategy**: Decide between marketplace images vs custom images via Azure Image Builder
5. **Plan Identity Integration**: Set up Azure AD groups and user assignments for AVD access
6. **Configure Monitoring**: Define AVD-specific monitoring and alerting thresholds (integrates with ECP Log Analytics)
7. **Plan Deployment Schedule**: Coordinate deployment schedule per environment with ECP team

## Contributing

Please read CONTRIBUTING.md for details on our code of conduct and the process for submitting pull requests.

## License

[Your License Here]

## Support

For issues and questions, please open an issue in the repository or contact the platform team.
