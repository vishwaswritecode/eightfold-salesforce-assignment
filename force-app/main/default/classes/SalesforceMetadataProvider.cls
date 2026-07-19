public with sharing class SalesforceMetadataProvider
    implements FieldUsageMetadataProvider {

    private static final String NAMED_CREDENTIAL =
        'SalesforceMetadataAPI';

    private static final String API_VERSION =
        '65.0';


    // =========================================================
    // MAIN ENTRY POINT
    // =========================================================

    public List<FieldUsageDTO.MetadataComponent> retrieveMetadata(
        String objectApiName,
        List<String> fieldApiNames
    ) {

        if (String.isBlank(objectApiName)) {
            throw new MetadataProviderException(
                'Object API name is required.'
            );
        }

        if (
            fieldApiNames == null ||
            fieldApiNames.isEmpty()
        ) {
            return new List<FieldUsageDTO.MetadataComponent>();
        }

        System.debug(
            LoggingLevel.ERROR,
            '===== FIELD USAGE ANALYSIS START ====='
        );

        System.debug(
            LoggingLevel.ERROR,
            'Object = ' + objectApiName
        );

        System.debug(
            LoggingLevel.ERROR,
            'Fields = ' + fieldApiNames
        );


        // Validate Named Credential
        validateNamedCredential();


        List<FieldUsageDTO.MetadataComponent> results =
            new List<FieldUsageDTO.MetadataComponent>();


        // =====================================================
        // 1. METADATA COMPONENT DEPENDENCIES
        // =====================================================

        results.addAll(
            retrieveMetadataDependencies(
                objectApiName,
                fieldApiNames
            )
        );


        // =====================================================
        // 2. APEX CLASSES
        // =====================================================

        results.addAll(
            retrieveApexClasses(
                objectApiName,
                fieldApiNames
            )
        );


        // =====================================================
        // 3. APEX TRIGGERS
        // =====================================================

        results.addAll(
            retrieveApexTriggers(
                objectApiName,
                fieldApiNames
            )
        );


        // =====================================================
        // 4. LAYOUTS
        // =====================================================

        results.addAll(
            retrieveLayouts(
                objectApiName,
                fieldApiNames
            )
        );


        // =====================================================
        // 5. VALIDATION RULES
        // =====================================================

        results.addAll(
            retrieveValidationRules(
                objectApiName,
                fieldApiNames
            )
        );

        // =====================================================
        // 6. REPORTS
        // =====================================================

        results.addAll(
            retrieveReports(
                objectApiName,
                fieldApiNames
            )
        );


        // =====================================================
        // REMOVE DUPLICATES
        // =====================================================

        results =
            removeDuplicates(
                results
            );


        System.debug(
            LoggingLevel.ERROR,
            'TOTAL COMPONENTS = ' +
            results.size()
        );

        System.debug(
            LoggingLevel.ERROR,
            '===== FIELD USAGE ANALYSIS END ====='
        );


        return results;
    }


    // =========================================================
    // VALIDATE NAMED CREDENTIAL
    // =========================================================

    private static void validateNamedCredential() {

        HttpRequest request =
            new HttpRequest();

        request.setEndpoint(
            'callout:' +
            NAMED_CREDENTIAL +
            '/services/data/v' +
            API_VERSION +
            '/limits/'
        );

        request.setMethod('GET');

        request.setTimeout(120000);


        HttpResponse response;

        try {

            response =
                new Http().send(
                    request
                );

        } catch (Exception e) {

            throw new MetadataProviderException(
                'Unable to connect using Named Credential: ' +
                e.getMessage()
            );
        }


        System.debug(
            LoggingLevel.ERROR,
            'Named Credential Status = ' +
            response.getStatusCode()
        );


        if (
            response.getStatusCode() < 200 ||
            response.getStatusCode() >= 300
        ) {

            throw new MetadataProviderException(
                'Named Credential authentication failed. ' +
                'HTTP Status: ' +
                response.getStatusCode() +
                '. Response: ' +
                response.getBody()
            );
        }
    }


    // =========================================================
    // METADATA COMPONENT DEPENDENCIES
    // =========================================================

    private static List<FieldUsageDTO.MetadataComponent>
        retrieveMetadataDependencies(
            String objectApiName,
            List<String> fieldApiNames
        ) {

        List<FieldUsageDTO.MetadataComponent> results =
            new List<FieldUsageDTO.MetadataComponent>();


        String soql =
            'SELECT ' +
            'MetadataComponentId, ' +
            'MetadataComponentName, ' +
            'MetadataComponentType, ' +
            'RefMetadataComponentId, ' +
            'RefMetadataComponentName, ' +
            'RefMetadataComponentType ' +
            'FROM MetadataComponentDependency';


        String endpoint =
            buildToolingQueryEndpoint(
                soql
            );


        while (
            String.isNotBlank(
                endpoint
            )
        ) {

            HttpResponse response =
                executeGet(
                    endpoint
                );


            Map<String, Object> body =
                parseResponse(
                    response
                );


            List<Object> records =
                (List<Object>)
                body.get(
                    'records'
                );


            if (records != null) {

                for (
                    Object recordObject :
                    records
                ) {

                    Map<String, Object> record =
                        (Map<String, Object>)
                        recordObject;


                    String componentName =
                        getString(
                            record,
                            'MetadataComponentName'
                        );


                    String componentType =
                        getString(
                            record,
                            'MetadataComponentType'
                        );


                    String refName =
                        getString(
                            record,
                            'RefMetadataComponentName'
                        );


                    String refType =
                        getString(
                            record,
                            'RefMetadataComponentType'
                        );


                    if (
                        String.isBlank(componentName) ||
                        String.isBlank(componentType)
                    ) {
                        continue;
                    }


                    String searchableContent =
                        JSON.serialize(
                            record
                        );


                    if (
                        containsAnyFieldReference(
                            searchableContent,
                            objectApiName,
                            fieldApiNames
                        )
                    ) {

                        results.add(
                            new FieldUsageDTO.MetadataComponent(
                                normalizeMetadataType(
                                    componentType
                                ),
                                componentName,
                                searchableContent
                            )
                        );


                        System.debug(
                            LoggingLevel.ERROR,
                            'DEPENDENCY MATCH: ' +
                            componentType +
                            ' -> ' +
                            componentName +
                            ' -> ' +
                            refType +
                            ' -> ' +
                            refName
                        );
                    }
                }
            }


            endpoint =
                getNextEndpoint(
                    body
                );
        }


        return results;
    }


    // =========================================================
    // APEX CLASS SCANNING
    // =========================================================

    private static List<FieldUsageDTO.MetadataComponent>
        retrieveApexClasses(
            String objectApiName,
            List<String> fieldApiNames
        ) {

        List<FieldUsageDTO.MetadataComponent> results =
            new List<FieldUsageDTO.MetadataComponent>();


        String soql =
            'SELECT Id, Name, NamespacePrefix, Body ' +
            'FROM ApexClass';


        String endpoint =
            buildToolingQueryEndpoint(
                soql
            );


        while (
            String.isNotBlank(
                endpoint
            )
        ) {

            HttpResponse response =
                executeGet(
                    endpoint
                );


            Map<String, Object> body =
                parseResponse(
                    response
                );


            List<Object> records =
                (List<Object>)
                body.get(
                    'records'
                );


            if (records != null) {

                for (
                    Object recordObject :
                    records
                ) {

                    Map<String, Object> record =
                        (Map<String, Object>)
                        recordObject;


                    String className =
                        getString(
                            record,
                            'Name'
                        );


                    String apexBody =
                        getString(
                            record,
                            'Body'
                        );


                    if (
                        String.isBlank(className) ||
                        String.isBlank(apexBody)
                    ) {
                        continue;
                    }


                    if (
                        containsAnyFieldReference(
                            apexBody,
                            objectApiName,
                            fieldApiNames
                        )
                    ) {

                        results.add(
                            new FieldUsageDTO.MetadataComponent(
                                'ApexClass',
                                className,
                                apexBody
                            )
                        );


                        System.debug(
                            LoggingLevel.ERROR,
                            'APEX CLASS MATCH = ' +
                            className
                        );
                    }
                }
            }


            endpoint =
                getNextEndpoint(
                    body
                );
        }


        return results;
    }


    // =========================================================
    // APEX TRIGGER SCANNING
    // =========================================================

    private static List<FieldUsageDTO.MetadataComponent>
        retrieveApexTriggers(
            String objectApiName,
            List<String> fieldApiNames
        ) {

        List<FieldUsageDTO.MetadataComponent> results =
            new List<FieldUsageDTO.MetadataComponent>();


        String soql =
            'SELECT Id, Name, NamespacePrefix, Body ' +
            'FROM ApexTrigger';


        String endpoint =
            buildToolingQueryEndpoint(
                soql
            );


        while (
            String.isNotBlank(
                endpoint
            )
        ) {

            HttpResponse response =
                executeGet(
                    endpoint
                );


            Map<String, Object> body =
                parseResponse(
                    response
                );


            List<Object> records =
                (List<Object>)
                body.get(
                    'records'
                );


            if (records != null) {

                for (
                    Object recordObject :
                    records
                ) {

                    Map<String, Object> record =
                        (Map<String, Object>)
                        recordObject;


                    String triggerName =
                        getString(
                            record,
                            'Name'
                        );


                    String triggerBody =
                        getString(
                            record,
                            'Body'
                        );


                    if (
                        String.isBlank(triggerName) ||
                        String.isBlank(triggerBody)
                    ) {
                        continue;
                    }


                    if (
                        containsAnyFieldReference(
                            triggerBody,
                            objectApiName,
                            fieldApiNames
                        )
                    ) {

                        results.add(
                            new FieldUsageDTO.MetadataComponent(
                                'ApexTrigger',
                                triggerName,
                                triggerBody
                            )
                        );


                        System.debug(
                            LoggingLevel.ERROR,
                            'APEX TRIGGER MATCH = ' +
                            triggerName
                        );
                    }
                }
            }


            endpoint =
                getNextEndpoint(
                    body
                );
        }


        return results;
    }


    // =========================================================
    // LAYOUT SCANNING
    // =========================================================

    private static List<FieldUsageDTO.MetadataComponent>
        retrieveLayouts(
            String objectApiName,
            List<String> fieldApiNames
        ) {

        List<FieldUsageDTO.MetadataComponent> results =
            new List<FieldUsageDTO.MetadataComponent>();


        /*
         * First retrieve Layout IDs without Metadata.
         */
        String soql =
            'SELECT Id, Name, TableEnumOrId ' +
            'FROM Layout';


        String endpoint =
            buildToolingQueryEndpoint(
                soql
            );


        while (
            String.isNotBlank(
                endpoint
            )
        ) {

            HttpResponse response =
                executeGet(
                    endpoint
                );


            Map<String, Object> body =
                parseResponse(
                    response
                );


            List<Object> records =
                (List<Object>)
                body.get(
                    'records'
                );


            if (records != null) {

                for (
                    Object recordObject :
                    records
                ) {

                    Map<String, Object> record =
                        (Map<String, Object>)
                        recordObject;


                    String layoutId =
                        getString(
                            record,
                            'Id'
                        );


                    String layoutName =
                        getString(
                            record,
                            'Name'
                        );


                    String tableEnumOrId =
                        getString(
                            record,
                            'TableEnumOrId'
                        );


                    if (
                        String.isBlank(layoutId) ||
                        String.isBlank(layoutName)
                    ) {
                        continue;
                    }


                    /*
                     * Standard objects normally expose the
                     * object API name in TableEnumOrId.
                     *
                     * Custom objects may return an ID.
                     */
                    if (
                        String.isNotBlank(
                            tableEnumOrId
                        )
                        &&
                        !looksLikeSalesforceId(
                            tableEnumOrId
                        )
                        &&
                        !tableEnumOrId.equalsIgnoreCase(
                            objectApiName
                        )
                    ) {

                        continue;
                    }


                    /*
                     * Retrieve each Layout individually.
                     */
                    String layoutEndpoint =
                        'callout:' +
                        NAMED_CREDENTIAL +
                        '/services/data/v' +
                        API_VERSION +
                        '/tooling/sobjects/Layout/' +
                        layoutId;


                    HttpResponse layoutResponse;


                    try {

                        layoutResponse =
                            executeGet(
                                layoutEndpoint
                            );

                    } catch (Exception e) {

                        System.debug(
                            LoggingLevel.ERROR,
                            'Unable to retrieve Layout ' +
                            layoutName +
                            ': ' +
                            e.getMessage()
                        );

                        continue;
                    }


                    Map<String, Object> layoutRecord;


                    try {

                        layoutRecord =
                            (Map<String, Object>)
                            JSON.deserializeUntyped(
                                layoutResponse.getBody()
                            );

                    } catch (Exception e) {

                        System.debug(
                            LoggingLevel.ERROR,
                            'Unable to parse Layout ' +
                            layoutName +
                            ': ' +
                            e.getMessage()
                        );

                        continue;
                    }


                    Object metadata =
                        layoutRecord.get(
                            'Metadata'
                        );


                    if (metadata == null) {

                        System.debug(
                            LoggingLevel.DEBUG,
                            'No Metadata returned for Layout: ' +
                            layoutName
                        );

                        continue;
                    }


                    String metadataJson =
                        JSON.serialize(
                            metadata
                        );


                    if (
                        containsAnyFieldReference(
                            metadataJson,
                            objectApiName,
                            fieldApiNames
                        )
                    ) {

                        String displayName =
                            objectApiName +
                            ' - ' +
                            layoutName;


                        results.add(
                            new FieldUsageDTO.MetadataComponent(
                                'Layout',
                                displayName,
                                metadataJson
                            )
                        );


                        System.debug(
                            LoggingLevel.ERROR,
                            'LAYOUT MATCH = ' +
                            displayName
                        );
                    }
                }
            }


            endpoint =
                getNextEndpoint(
                    body
                );
        }


        return results;
    }


    // =========================================================
    // VALIDATION RULE SCANNING
    // =========================================================

    private static List<FieldUsageDTO.MetadataComponent>
        retrieveValidationRules(
            String objectApiName,
            List<String> fieldApiNames
        ) {

        List<FieldUsageDTO.MetadataComponent> results =
            new List<FieldUsageDTO.MetadataComponent>();


        /*
         * Query validation rules for the selected object.
         *
         * We first retrieve the ValidationRule IDs and names.
         * Then each rule is retrieved individually so its
         * metadata/formula can be inspected.
         */
        String escapedObjectName =
            String.escapeSingleQuotes(
                objectApiName
            );


        String soql =
            'SELECT Id, ValidationName, ' +
            'EntityDefinition.QualifiedApiName ' +
            'FROM ValidationRule ' +
            'WHERE EntityDefinition.QualifiedApiName = \'' +
            escapedObjectName +
            '\'';


        String endpoint =
            buildToolingQueryEndpoint(
                soql
            );


        while (
            String.isNotBlank(
                endpoint
            )
        ) {

            HttpResponse response;


            try {

                response =
                    executeGet(
                        endpoint
                    );

            } catch (Exception e) {

                /*
                 * Do not break existing functionality
                 * if ValidationRule querying is unavailable.
                 */
                System.debug(
                    LoggingLevel.ERROR,
                    'Unable to query Validation Rules: ' +
                    e.getMessage()
                );

                return results;
            }


            Map<String, Object> body =
                parseResponse(
                    response
                );


            List<Object> records =
                (List<Object>)
                body.get(
                    'records'
                );


            if (records != null) {

                for (
                    Object recordObject :
                    records
                ) {

                    Map<String, Object> record =
                        (Map<String, Object>)
                        recordObject;


                    String validationRuleId =
                        getString(
                            record,
                            'Id'
                        );


                    String validationRuleName =
                        getString(
                            record,
                            'ValidationName'
                        );


                    if (
                        String.isBlank(
                            validationRuleId
                        )
                        ||
                        String.isBlank(
                            validationRuleName
                        )
                    ) {

                        continue;
                    }


                    System.debug(
                        LoggingLevel.DEBUG,
                        'Checking Validation Rule = ' +
                        validationRuleName
                    );


                    /*
                     * Retrieve individual ValidationRule.
                     */
                    String validationRuleEndpoint =
                        'callout:' +
                        NAMED_CREDENTIAL +
                        '/services/data/v' +
                        API_VERSION +
                        '/tooling/sobjects/ValidationRule/' +
                        validationRuleId;


                    HttpResponse validationRuleResponse;


                    try {

                        validationRuleResponse =
                            executeGet(
                                validationRuleEndpoint
                            );

                    } catch (Exception e) {

                        System.debug(
                            LoggingLevel.ERROR,
                            'Unable to retrieve Validation Rule ' +
                            validationRuleName +
                            ': ' +
                            e.getMessage()
                        );

                        continue;
                    }


                    Map<String, Object> validationRuleRecord;


                    try {

                        validationRuleRecord =
                            (Map<String, Object>)
                            JSON.deserializeUntyped(
                                validationRuleResponse.getBody()
                            );

                    } catch (Exception e) {

                        System.debug(
                            LoggingLevel.ERROR,
                            'Unable to parse Validation Rule ' +
                            validationRuleName +
                            ': ' +
                            e.getMessage()
                        );

                        continue;
                    }


                    /*
                     * Serialize the entire record.
                     *
                     * This allows us to search both Metadata
                     * and any formula-related fields returned
                     * by the Tooling API.
                     */
                    String searchableContent =
                        JSON.serialize(
                            validationRuleRecord
                        );


                    if (
                        containsAnyFieldReference(
                            searchableContent,
                            objectApiName,
                            fieldApiNames
                        )
                    ) {

                        results.add(
                            new FieldUsageDTO.MetadataComponent(
                                'ValidationRule',
                                validationRuleName,
                                searchableContent
                            )
                        );


                        System.debug(
                            LoggingLevel.ERROR,
                            'VALIDATION RULE MATCH = ' +
                            validationRuleName
                        );
                    }
                }
            }


            endpoint =
                getNextEndpoint(
                    body
                );
        }


        return results;
    }

            // =========================================================
        // REPORT SCANNING
        // =========================================================

        private static List<FieldUsageDTO.MetadataComponent>
            retrieveReports(
                String objectApiName,
                List<String> fieldApiNames
            ) {

            List<FieldUsageDTO.MetadataComponent> results =
                new List<FieldUsageDTO.MetadataComponent>();


            /*
            * Step 1:
            * Query Reports available to the running user.
            */
            String soql =
                'SELECT Id, Name, DeveloperName ' +
                'FROM Report';


            String endpoint =
                'callout:' +
                NAMED_CREDENTIAL +
                '/services/data/v' +
                API_VERSION +
                '/query/?q=' +
                EncodingUtil.urlEncode(
                    soql,
                    'UTF-8'
                );


            while (
                String.isNotBlank(
                    endpoint
                )
            ) {

                HttpResponse response;


                try {

                    response =
                        executeGet(
                            endpoint
                        );

                } catch (Exception e) {

                    System.debug(
                        LoggingLevel.ERROR,
                        'Unable to query Reports: ' +
                        e.getMessage()
                    );

                    return results;
                }


                Map<String, Object> body =
                    parseResponse(
                        response
                    );


                List<Object> records =
                    (List<Object>)
                    body.get(
                        'records'
                    );


                if (records != null) {

                    for (
                        Object recordObject :
                        records
                    ) {

                        Map<String, Object> record =
                            (Map<String, Object>)
                            recordObject;


                        String reportId =
                            getString(
                                record,
                                'Id'
                            );


                        String reportName =
                            getString(
                                record,
                                'Name'
                            );


                        String developerName =
                            getString(
                                record,
                                'DeveloperName'
                            );


                        if (
                            String.isBlank(
                                reportId
                            )
                        ) {
                            continue;
                        }


                        if (
                            String.isBlank(
                                reportName
                            )
                        ) {
                            reportName =
                                developerName;
                        }


                        if (
                            String.isBlank(
                                reportName
                            )
                        ) {
                            reportName =
                                reportId;
                        }


                        /*
                        * Step 2:
                        * Use Analytics REST API to describe
                        * the individual Report.
                        */
                        String reportDescribeEndpoint =
                            'callout:' +
                            NAMED_CREDENTIAL +
                            '/services/data/v' +
                            API_VERSION +
                            '/analytics/reports/' +
                            reportId +
                            '/describe';


                        HttpResponse reportResponse;


                        try {

                            reportResponse =
                                executeGet(
                                    reportDescribeEndpoint
                                );

                        } catch (Exception e) {

                            System.debug(
                                LoggingLevel.ERROR,
                                'Unable to describe Report ' +
                                reportName +
                                ': ' +
                                e.getMessage()
                            );

                            continue;
                        }


                        Map<String, Object> reportDescribe;


                        try {

                            reportDescribe =
                                (Map<String, Object>)
                                JSON.deserializeUntyped(
                                    reportResponse.getBody()
                                );

                        } catch (Exception e) {

                            System.debug(
                                LoggingLevel.ERROR,
                                'Unable to parse Report ' +
                                reportName +
                                ': ' +
                                e.getMessage()
                            );

                            continue;
                        }


                        /*
                        * Step 3:
                        * Convert complete Report description
                        * to JSON so we can search its metadata.
                        */
                        String searchableContent =
                            JSON.serialize(
                                reportDescribe
                            );


                        /*
                        * Step 4:
                        * Check whether any selected field
                        * appears in the Report metadata.
                        */
                        if (
                            containsAnyFieldReference(
                                searchableContent,
                                objectApiName,
                                fieldApiNames
                            )
                        ) {

                            results.add(
                                new FieldUsageDTO.MetadataComponent(
                                    'Report',
                                    reportName,
                                    searchableContent
                                )
                            );


                            System.debug(
                                LoggingLevel.ERROR,
                                'REPORT MATCH = ' +
                                reportName
                            );
                        }
                    }
                }


                /*
                * Step 5:
                * Handle pagination.
                */
                Boolean done =
                    body.containsKey(
                        'done'
                    )
                    &&
                    (Boolean)
                    body.get(
                        'done'
                    );


                if (done) {

                    endpoint = null;

                } else {

                    String nextRecordsUrl =
                        (String)
                        body.get(
                            'nextRecordsUrl'
                        );


                    if (
                        String.isBlank(
                            nextRecordsUrl
                        )
                    ) {

                        endpoint = null;

                    } else {

                        endpoint =
                            'callout:' +
                            NAMED_CREDENTIAL +
                            nextRecordsUrl;
                    }
                }
            }


            return results;
        }


    // =========================================================
    // FIELD REFERENCE MATCHING
    // =========================================================

    private static Boolean containsAnyFieldReference(
        String content,
        String objectApiName,
        List<String> fieldApiNames
    ) {

        if (
            String.isBlank(content) ||
            fieldApiNames == null ||
            fieldApiNames.isEmpty()
        ) {

            return false;
        }


        String lowerContent =
            content.toLowerCase();


        for (
            String fieldApiName :
            fieldApiNames
        ) {

            if (
                String.isBlank(
                    fieldApiName
                )
            ) {
                continue;
            }


            String lowerField =
                fieldApiName.toLowerCase();


            String qualifiedField =
                (
                    objectApiName +
                    '.' +
                    fieldApiName
                ).toLowerCase();


            String dollarQualifiedField =
                (
                    objectApiName +
                    '$' +
                    fieldApiName
                ).toLowerCase();


            String colonQualifiedField =
                (
                    objectApiName +
                    ':' +
                    fieldApiName
                ).toLowerCase();


            if (
                lowerContent.contains(
                    qualifiedField
                )
                ||
                lowerContent.contains(
                    dollarQualifiedField
                )
                ||
                lowerContent.contains(
                    colonQualifiedField
                )
                ||
                lowerContent.contains(
                    lowerField
                )
            ) {

                return true;
            }
        }


        return false;
    }


    // =========================================================
    // BUILD TOOLING QUERY ENDPOINT
    // =========================================================

    private static String buildToolingQueryEndpoint(
        String soql
    ) {

        return
            'callout:' +
            NAMED_CREDENTIAL +
            '/services/data/v' +
            API_VERSION +
            '/tooling/query/?q=' +
            EncodingUtil.urlEncode(
                soql,
                'UTF-8'
            );
    }


    // =========================================================
    // EXECUTE GET
    // =========================================================

    private static HttpResponse executeGet(
        String endpoint
    ) {

        HttpRequest request =
            new HttpRequest();


        request.setEndpoint(
            endpoint
        );


        request.setMethod(
            'GET'
        );


        request.setHeader(
            'Accept',
            'application/json'
        );


        request.setTimeout(
            120000
        );


        HttpResponse response;


        try {

            response =
                new Http().send(
                    request
                );

        } catch (Exception e) {

            throw new MetadataProviderException(
                'Salesforce API callout failed: ' +
                e.getMessage()
            );
        }


        System.debug(
            LoggingLevel.DEBUG,
            'API Endpoint = ' +
            endpoint
        );


        System.debug(
            LoggingLevel.DEBUG,
            'API Status = ' +
            response.getStatusCode()
        );


        if (
            response.getStatusCode() < 200 ||
            response.getStatusCode() >= 300
        ) {

            System.debug(
                LoggingLevel.ERROR,
                'API ERROR ENDPOINT = ' +
                endpoint
            );


            System.debug(
                LoggingLevel.ERROR,
                'API ERROR STATUS = ' +
                response.getStatusCode()
            );


            System.debug(
                LoggingLevel.ERROR,
                'API ERROR BODY = ' +
                response.getBody()
            );


            throw new MetadataProviderException(
                'Salesforce API request failed. ' +
                'HTTP Status: ' +
                response.getStatusCode() +
                '. Response: ' +
                response.getBody()
            );
        }


        return response;
    }


    // =========================================================
    // PARSE RESPONSE
    // =========================================================

    private static Map<String, Object> parseResponse(
        HttpResponse response
    ) {

        if (
            response == null ||
            String.isBlank(
                response.getBody()
            )
        ) {

            return new Map<String, Object>();
        }


        return
            (Map<String, Object>)
            JSON.deserializeUntyped(
                response.getBody()
            );
    }


    // =========================================================
    // PAGINATION
    // =========================================================

    private static String getNextEndpoint(
        Map<String, Object> body
    ) {

        if (body == null) {
            return null;
        }


        Boolean done =
            body.containsKey(
                'done'
            )
            &&
            (Boolean)
            body.get(
                'done'
            );


        if (done) {
            return null;
        }


        String nextRecordsUrl =
            (String)
            body.get(
                'nextRecordsUrl'
            );


        if (
            String.isBlank(
                nextRecordsUrl
            )
        ) {

            return null;
        }


        return
            'callout:' +
            NAMED_CREDENTIAL +
            nextRecordsUrl;
    }


    // =========================================================
    // NORMALIZE METADATA TYPE
    // =========================================================

    private static String normalizeMetadataType(
        String componentType
    ) {

        if (
            String.isBlank(
                componentType
            )
        ) {

            return 'Metadata';
        }


        String lowerType =
            componentType.toLowerCase();


        if (
            lowerType.contains(
                'flexipage'
            )
        ) {

            return 'FlexiPage';
        }


        if (
            lowerType.contains(
                'report'
            )
        ) {

            return 'Report';
        }


        if (
            lowerType.contains(
                'apexclass'
            )
        ) {

            return 'ApexClass';
        }


        if (
            lowerType.contains(
                'apextrigger'
            )
        ) {

            return 'ApexTrigger';
        }


        if (
            lowerType.contains(
                'layout'
            )
        ) {

            return 'Layout';
        }


        if (
            lowerType.contains(
                'flow'
            )
        ) {

            return 'Flow';
        }


        if (
            lowerType.contains(
                'validationrule'
            )
        ) {

            return 'ValidationRule';
        }


        return componentType;
    }


    // =========================================================
    // REMOVE DUPLICATES
    // =========================================================

    private static List<FieldUsageDTO.MetadataComponent>
        removeDuplicates(
            List<FieldUsageDTO.MetadataComponent> components
        ) {

        List<FieldUsageDTO.MetadataComponent> results =
            new List<FieldUsageDTO.MetadataComponent>();


        Set<String> seen =
            new Set<String>();


        if (components == null) {

            return results;
        }


        for (
            FieldUsageDTO.MetadataComponent component :
            components
        ) {

            if (component == null) {

                continue;
            }


            String key =
                String.valueOf(
                    component.metadataType
                )
                +
                '|'
                +
                String.valueOf(
                    component.componentName
                );


            key =
                key.toLowerCase();


            if (
                seen.contains(
                    key
                )
            ) {

                continue;
            }


            seen.add(
                key
            );


            results.add(
                component
            );
        }


        return results;
    }


    // =========================================================
    // SALESFORCE ID CHECK
    // =========================================================

    private static Boolean looksLikeSalesforceId(
        String value
    ) {

        if (
            String.isBlank(
                value
            )
        ) {

            return false;
        }


        return
            value.length() == 15 ||
            value.length() == 18;
    }


    // =========================================================
    // STRING HELPER
    // =========================================================

    private static String getString(
        Map<String, Object> record,
        String key
    ) {

        if (
            record == null ||
            !record.containsKey(
                key
            ) ||
            record.get(
                key
            ) == null
        ) {

            return null;
        }


        return String.valueOf(
            record.get(
                key
            )
        );
    }


    // =========================================================
    // EXCEPTION
    // =========================================================

    public class MetadataProviderException
        extends Exception {
    }
}