# Eightfold Salesforce Assignment - High Volume Account Processing

## Overview

This solution processes high-volume Account records asynchronously using Queueable Apex.

## Features

- REST API endpoint to initiate processing
- Queueable Apex for asynchronous execution
- Bulkified implementation
- Service-oriented architecture
- Reusable constants
- Test class with coverage
- Error handling and logging

## Project Structure

```
force-app/main/default/classes/
├── AccountProcessingAPI.cls
├── AccountProcessingQueueable.cls
├── AccountProcessingService.cls
├── ScoreCalculationService.cls
├── Constants.cls
└── AccountProcessingQueueableTest.cls
```

## Processing Flow

1. Client invokes the REST API.
2. API validates the request.
3. Queueable Apex is enqueued.
4. Queueable processes account records in batches.
5. Score is calculated.
6. Accounts are updated asynchronously.

## Design Decisions

- Queueable Apex used for asynchronous processing.
- Business logic separated into service classes.
- Constants centralized for maintainability.
- Bulk-safe implementation following Salesforce best practices.

## Technologies

- Apex
- Queueable Apex
- REST API
- SOQL
- DML
- Salesforce Platform

## Author

Vishwas Kumar
