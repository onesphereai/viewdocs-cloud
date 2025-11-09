# Business Statement
Build a cloud version of Viewdocs. Currently viewdocs runs on premise infrastructure. Viewdocs by its definition provides client users / internal users access to the documents which are stored in IES (On-premise archive), IESC (Cloud version of IES) and CMOD (IBM document archival solution).

## Primary Actor
FBDMS HelpDesk Users
FBDMS ECM Admins
FBDMS Internal consumers
Client Orgnisation Administrator
Client User
## Stakeholders and Interests
**FBDMS HelpDesk Users**: Want to be able to support clients or internal consumers
**FBDMS ECM Admins**: Want to be able to onboard viewdocs / IESC / IES / CMOD
**FBDMS Internal consumers**: Want to be able to use viewdocs / IESC / IES / CMODa
**Client Orgnisation Administrator**: Want to be able to manage users and assign documents
**Client User: Want to be able view documents using viewdocs.
## Pre-conditions
User is logged into FBDMS system
User has access to viewdocs & mailroom
User has access to the archive folder in viewdocs.
## Post-conditions
User is able to view the document, download documents.(Single and bulk).
User is able Send documents as email.
User is able to add comments.
User is able to search documents by index data. (IES / IESC / CMOD)
User is able to search documents by full text search (IESC)
User is able to do conversational search (IESC)

## Main Success Scenario
1. User logs into FBDMS system
2. User navigates to viewdocs.
3. User selects the folder.
4. User performs search either via index search / full text search.
5. User views document.
6. User can optionally download the document.
7. User can opt to send bulk download request.
8. User can add comments to the document.
9. User can send document as email.
## Extensions
- 3a. User does not have access to the folder
    - 1. Only folders with access are shown.
    - 2. User selects a different folder
    - 3. Return to step 3 of the main success scenario
- 5a. User does not have permissions to view the document (controlled via ACL)
    - 1. Show error message indicating lack of permissions
    - 2. User selects a different document
    - 3. Return to step 5 of the main success scenario
- 6a. Download fails due to network issues
    - 1. Show error message indicating download failure
    - 2. User retries download
    - 3. Return to step 6 of the main success scenario
- 7a. Bulk download request fails
    - 1. Show error message indicating failure
    - 2. User retries bulk download request
    - 3. Return to step 7 of the main success scenario
- 8a. User does not have permissions to add comments
    - 1. Show error message indicating lack of permissions
    - 2. User selects a different document
    - 3. Return to step 5 of the main success scenario
- 9a. Email sending fails
    - 1. Show error message indicating email sending failure    
    - 2. User retries sending email
    - 3. Return to step 9 of the main success scenario
## Alternative Scenarios
- User uses search options to filter documents based on specific criteria.

# Technical Statement
## Purpose


## Non-Functional Requirements
- The system must be highly available and scalable to handle varying loads.
- The system must comply with FBDMS security policies and data protection regulations.
- The system must integrate seamlessly with existing FBDMS systems (IESC, IES, CMOD, IDM,HUB, EMAIL Service)

## Frequency of Use
This feature is expected to be used frequently by FBDMS HelpDesk Users, ECM Admins
and Client Users as part of their daily operations.

# Technical Definitions / System definition
## System
- Identity Management System - IDM as IdP (deployed in AWS)
- Viewdocs as SP deployed on premise
- IESC (AWS) / IES as ECM
- Mailroom system (using Viewdocs) to document assignment to the users (Part of Viewdocs set of application suite)
- CIP (Cloud imaging platform) with AI pipelines

## Component Details
- IDM: Identity Management System developed by FBDMS, used for user authentication and authorization.
- Viewdocs: Document viewing system that integrates with IDM for user management and provides access to documents
- IESC / IES: Enterprise Content Management systems used for storing and managing documents.
- Mailroom System: System used for handling document assignments and notifications, integrated with Viewdocs for
    document access.
## Technical Requirements
- Integration with IDM for user authentication and authorization.
- Secure communication between Viewdocs and IDM using SAML 2.0 protocol.
- Access control mechanisms to ensure users can only access documents they are authorized to view.
- Logging and monitoring of user activities for auditing purposes.
- Scalability to handle increasing number of users and documents.
- Compliance with FBDMS security policies and data protection regulations.
- Backup and disaster recovery mechanisms to ensure data integrity and availability.
- Performance optimization to ensure fast document retrieval and viewing experience.
- User-friendly interface for easy navigation and document management.
- Support for various document formats and types.
- Integration with email services for sending documents as email.
- Implementation of search functionalities including index-based search, full-text search, and conversational search. (Supported by IESC for Full Text serach, Conversational Search, Index Search), IES ( Index Search), CMOD (Index Search)
- Bulk download capabilities with error handling and retry mechanisms.
- Commenting functionality with access control based on user permissions.
- Regular updates and maintenance to ensure system reliability and security.
- Training and support for users to effectively utilize the system features.
- Documentation of system architecture, components, and user guides for reference.
- Testing and quality assurance to ensure system functionality and performance meet requirements.
- Deployment and configuration management to ensure smooth rollout and updates of the system.
- Collaboration with FBDMS IT and security teams to ensure alignment with organizational standards and practices.
- Monitoring and alerting mechanisms to proactively identify and address system issues.
- Continuous improvement processes to gather user feedback and enhance system features over time.
- Compliance with relevant industry standards and regulations for data security and privacy.
- Integration with existing FBDMS systems and workflows to ensure seamless operations.
- Support for multi-factor authentication (MFA) for enhanced security.(Managed by IDP)
- Implementation of role-based access control (RBAC) to manage user permissions effectively.
- Regular security assessments and vulnerability scans to identify and mitigate potential risks.
- AWS Serverless Architecture with multitenany.
- HUB Events will be faciliated using flow below Viewdocs - FRS (MQ) - HUB (MQ).
- Email Service will be used to send emails. Viewdocs - FRS (MQ) - (IDM Email service) (For immediate need)
- Future Email Service - Using Email Platform. (Self Service via rest endpoint).
- DynamoDB for backend where Viewdocs configurations will be stored.