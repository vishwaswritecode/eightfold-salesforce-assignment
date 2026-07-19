# Eightfold Salesforce Assignment

This repository contains Salesforce solutions for the Eightfold Salesforce technical assignments.

The project includes:

1. Assignment 1 - High-Volume Account Processing
2. Assignment 2 - Field Usage Analyzer / Where Is This Used

---

## Assignment 1 - High-Volume Account Processing

### Overview

This solution processes high-volume Account records asynchronously using Queueable Apex.

### Features

- REST API endpoint to initiate Account processing
- Queueable Apex for asynchronous execution
- Bulkified processing
- Service-oriented architecture
- Error handling and logging
- Separation of API, Queueable, and business logic
- Apex test coverage

### Processing Flow

1. Client invokes the REST API.
2. The API validates the incoming request.
3. A Queueable Apex job is enqueued.
4. Account records are processed asynchronously.
5. Business logic is applied to the records.
6. Account records are updated using bulk-safe DML operations.

### Design Decisions

- Queueable Apex is used for scalable asynchronous processing.
- Business logic is separated into service classes.
- The implementation follows bulkification best practices.
- Error handling and logging are separated from the core processing logic.

---

## Assignment 2 - Field Usage Analyzer

### Overview

The Field Usage Analyzer is a Salesforce Lightning Web Component that allows users to select a Salesforce object and one or more fields and identify where those fields are referenced across Salesforce metadata.

The solution combines Salesforce Schema Describe information with Salesforce Metadata and Tooling API analysis.

### Features

- Select a Salesforce object
- Dynamically retrieve fields for the selected object
- Select one or multiple fields
- Analyze field usage across Salesforce metadata
- Display metadata type and component name
- Detect field references in supported metadata components
- Metadata provider abstraction for testability
- Mock metadata provider for Apex unit tests
- HTTP callout mocking for Metadata API tests
- LWC Jest test support

### Supported Metadata Analysis

The analyzer searches supported metadata sources such as:

- Apex Classes
- Apex Triggers
- Lightning Record Pages / FlexiPages
- Page Layouts
- Validation Rules
- Reports
- Metadata Component Dependencies

The exact results depend on metadata availability and Salesforce API support.

### Architecture

The solution follows a layered architecture:

```text
Lightning Web Component
        |
        v
FieldUsageController
        |
        v
FieldUsageService
        |
        v
FieldUsageMetadataProvider
        |
        v
SalesforceMetadataProvider
        |
        v
Salesforce REST / Tooling / Metadata APIs

force-app/main/default/classes/

FieldUsageController.cls
FieldUsageControllerTest.cls

FieldUsageService.cls
FieldUsageServiceTest.cls

FieldUsageDTO.cls

FieldUsageMetadataProvider.cls
MockFieldUsageMetadataProvider.cls

SalesforceMetadataProvider.cls
SalesforceMetadataProviderTest.cls

force-app/main/default/lwc/fieldUsageAnalyzer/

fieldUsageAnalyzer.html
fieldUsageAnalyzer.js
fieldUsageAnalyzer.css
fieldUsageAnalyzer.js-meta.xml

__tests__/
fieldUsageAnalyzer.test.js

Field Usage Analysis Flow
The user opens the Field Usage Analyzer LWC.
The component retrieves available Salesforce objects.
The user selects an object.
The component retrieves fields for that object.
The user selects one or more fields.
The LWC calls the Apex controller.
The controller delegates processing to FieldUsageService.
The service validates the selected object and fields.
SalesforceMetadataProvider retrieves supported metadata information.
The service analyzes metadata for field references.
Matching references are returned to the LWC.
The results are displayed to the user.
