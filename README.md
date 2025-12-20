# Enterprise Cloud Platform | Workload Pattern - Azure Virtual Desktop (AVD)

Modular Azure Virtual Desktop deployment using Terraform and Terragrunt with a layered architecture approach.

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

## Prerequisites

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
