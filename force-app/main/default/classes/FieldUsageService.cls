public with sharing class FieldUsageService {

    /*
     * Metadata provider.
     *
     * @TestVisible allows unit tests to inject
     * MockFieldUsageMetadataProvider.
     */
    @TestVisible
    private static FieldUsageMetadataProvider metadataProvider;


    // =========================================================
    // GET OBJECTS
    // =========================================================

    /**
     * Dynamically retrieves all queryable Salesforce objects.
     */
    public static List<FieldUsageDTO.ObjectOption> getObjects() {

        List<FieldUsageDTO.ObjectOption> results =
            new List<FieldUsageDTO.ObjectOption>();

        Map<String, Schema.SObjectType> globalDescribe =
            Schema.getGlobalDescribe();


        for (String objectApiName : globalDescribe.keySet()) {

            Schema.DescribeSObjectResult describeResult =
                globalDescribe
                    .get(objectApiName)
                    .getDescribe();


            /*
             * Skip objects that cannot be queried.
             */
            if (!describeResult.isQueryable()) {
                continue;
            }


            results.add(
                new FieldUsageDTO.ObjectOption(
                    describeResult.getLabel(),
                    describeResult.getName()
                )
            );
        }


        /*
         * Sort objects alphabetically by label.
         */
        results.sort(
            new ObjectOptionComparator()
        );


        return results;
    }


    // =========================================================
    // GET FIELDS
    // =========================================================

    /**
     * Dynamically retrieves all standard and custom fields
     * for the selected Salesforce object.
     */
    public static List<FieldUsageDTO.FieldOption> getFields(
        String objectApiName
    ) {

        if (String.isBlank(objectApiName)) {

            throw new FieldUsageException(
                'Object API name is required.'
            );
        }


        Map<String, Schema.SObjectType> globalDescribe =
            Schema.getGlobalDescribe();


        /*
         * Validate object.
         */
        if (!globalDescribe.containsKey(objectApiName)) {

            throw new FieldUsageException(
                'Invalid Salesforce object: ' +
                objectApiName
            );
        }


        Schema.DescribeSObjectResult objectDescribe =
            globalDescribe
                .get(objectApiName)
                .getDescribe();


        Map<String, Schema.SObjectField> fieldMap =
            objectDescribe
                .fields
                .getMap();


        List<FieldUsageDTO.FieldOption> results =
            new List<FieldUsageDTO.FieldOption>();


        /*
         * Retrieve all standard + custom fields.
         */
        for (String fieldApiName : fieldMap.keySet()) {

            Schema.DescribeFieldResult fieldDescribe =
                fieldMap
                    .get(fieldApiName)
                    .getDescribe();


            results.add(
                new FieldUsageDTO.FieldOption(
                    fieldDescribe.getLabel(),
                    fieldDescribe.getName()
                )
            );
        }


        /*
         * Sort fields alphabetically.
         */
        results.sort(
            new FieldOptionComparator()
        );


        return results;
    }


    // =========================================================
    // ANALYZE FIELD USAGE
    // =========================================================

    /**
     * Main service method.
     *
     * Retrieves metadata using the configured provider
     * and checks selected fields against returned
     * metadata components.
     */
    public static List<FieldUsageDTO.FieldUsageResult>
        analyzeFieldUsage(
            String objectApiName,
            List<String> fieldApiNames
        ) {

        /*
         * Validate request.
         */
        validateObjectAndFields(
            objectApiName,
            fieldApiNames
        );


        /*
         * Get metadata provider.
         */
        FieldUsageMetadataProvider provider =
            getMetadataProvider();


        /*
         * Retrieve metadata for the selected
         * object and fields.
         *
         * IMPORTANT:
         * Store the returned list in components.
         */
        List<FieldUsageDTO.MetadataComponent> components =
            provider.retrieveMetadata(
                objectApiName,
                fieldApiNames
            );


        List<FieldUsageDTO.FieldUsageResult> results =
            new List<FieldUsageDTO.FieldUsageResult>();


        /*
         * Defensive null handling.
         */
        if (components == null) {
            return results;
        }


        Map<String, Schema.SObjectField> fields =
            Schema.getGlobalDescribe()
                .get(objectApiName)
                .getDescribe()
                .fields
                .getMap();


        /*
         * Analyze every selected field.
         */
        for (String fieldApiName : fieldApiNames) {

            Schema.DescribeFieldResult fieldDescribe =
                fields
                    .get(fieldApiName)
                    .getDescribe();


            /*
             * Check every metadata component.
             */
            for (
                FieldUsageDTO.MetadataComponent component :
                components
            ) {

                if (component == null) {
                    continue;
                }


                Boolean fieldReferenced =
                    containsFieldReference(
                        component.metadataContent,
                        objectApiName,
                        fieldApiName
                    );


                if (fieldReferenced) {

                    results.add(
                        new FieldUsageDTO.FieldUsageResult(
                            fieldDescribe.getLabel(),
                            fieldApiName,
                            component.metadataType,
                            component.componentName,
                            determineReferenceType(
                                component.metadataType
                            )
                        )
                    );
                }
            }
        }


        return results;
    }


    // =========================================================
    // METADATA PROVIDER
    // =========================================================

    /**
     * Returns the real metadata provider.
     *
     * During unit testing, metadataProvider can be replaced
     * with MockFieldUsageMetadataProvider.
     */
    private static FieldUsageMetadataProvider
        getMetadataProvider() {

        if (metadataProvider == null) {

            metadataProvider =
                new SalesforceMetadataProvider();
        }


        return metadataProvider;
    }


    // =========================================================
    // FIELD REFERENCE DETECTION
    // =========================================================

    /**
     * Determines whether serialized metadata contains
     * a reference to the selected Salesforce field.
     *
     * Supports:
     *
     * Industry
     *
     * Account.Industry
     *
     * Account$Industry
     *
     * Account:Industry
     */
    @TestVisible
    private static Boolean containsFieldReference(
        String metadataContent,
        String objectApiName,
        String fieldApiName
    ) {

        if (String.isBlank(metadataContent)) {
            return false;
        }


        String lowerContent =
            metadataContent.toLowerCase();


        String lowerObject =
            objectApiName.toLowerCase();


        String lowerField =
            fieldApiName.toLowerCase();


        /*
         * Common Salesforce metadata field formats.
         */
        String dotQualifiedField =
            lowerObject +
            '.' +
            lowerField;


        String dollarQualifiedField =
            lowerObject +
            '$' +
            lowerField;


        String colonQualifiedField =
            lowerObject +
            ':' +
            lowerField;


        /*
         * Check qualified field references first.
         */
        if (
            lowerContent.contains(
                dotQualifiedField
            )
            ||
            lowerContent.contains(
                dollarQualifiedField
            )
            ||
            lowerContent.contains(
                colonQualifiedField
            )
        ) {

            return true;
        }


        /*
         * Some metadata structures store only
         * the field API name.
         *
         * Examples:
         *
         * Escalate__c
         *
         * ReportColumn.field
         *
         * Apex source
         *
         * Layout metadata
         */
        return lowerContent.contains(
            lowerField
        );
    }


    // =========================================================
    // REFERENCE TYPE
    // =========================================================

    /**
     * Converts Salesforce metadata types into
     * user-friendly dependency categories.
     */
    private static String determineReferenceType(
        String metadataType
    ) {

        if (String.isBlank(metadataType)) {

            return 'Metadata Reference';
        }


        switch on metadataType {


            when 'FlexiPage' {

                return 'Lightning Page';
            }


            when 'Report' {

                return 'Report';
            }


            when 'Dashboard' {

                return 'Dashboard';
            }


            when 'Flow' {

                return 'Automation';
            }


            when 'ApexClass' {

                return 'Apex Code';
            }


            when 'ApexTrigger' {

                return 'Apex Trigger';
            }


            when 'Layout' {

                return 'Page Layout';
            }


            when 'LightningComponent' {

                return 'Lightning Component';
            }


            when 'LightningComponentBundle' {

                return 'Lightning Web Component';
            }


            when 'ValidationRule' {

                return 'Validation Rule';
            }


            when 'Workflow' {

                return 'Workflow';
            }


            when else {

                return 'Metadata Reference';
            }
        }
    }


    // =========================================================
    // VALIDATION
    // =========================================================

    /**
     * Validates selected object and fields.
     */
    private static void validateObjectAndFields(
        String objectApiName,
        List<String> fieldApiNames
    ) {

        if (String.isBlank(objectApiName)) {

            throw new FieldUsageException(
                'Object API name is required.'
            );
        }


        if (
            fieldApiNames == null
            ||
            fieldApiNames.isEmpty()
        ) {

            throw new FieldUsageException(
                'At least one field must be selected.'
            );
        }


        Map<String, Schema.SObjectType> globalDescribe =
            Schema.getGlobalDescribe();


        /*
         * Validate object.
         */
        if (
            !globalDescribe.containsKey(
                objectApiName
            )
        ) {

            throw new FieldUsageException(
                'Invalid object: ' +
                objectApiName
            );
        }


        Map<String, Schema.SObjectField> fields =
            globalDescribe
                .get(objectApiName)
                .getDescribe()
                .fields
                .getMap();


        /*
         * Validate every selected field.
         */
        for (
            String fieldApiName :
            fieldApiNames
        ) {

            if (
                String.isBlank(
                    fieldApiName
                )
            ) {

                throw new FieldUsageException(
                    'Field API name cannot be blank.'
                );
            }


            if (
                !fields.containsKey(
                    fieldApiName
                )
            ) {

                throw new FieldUsageException(
                    'Invalid field ' +
                    fieldApiName +
                    ' for object ' +
                    objectApiName
                );
            }
        }
    }


    // =========================================================
    // OBJECT SORT COMPARATOR
    // =========================================================

    /**
     * Sorts Salesforce objects alphabetically
     * by their labels.
     */
    private class ObjectOptionComparator
        implements Comparator<FieldUsageDTO.ObjectOption> {

        public Integer compare(
            FieldUsageDTO.ObjectOption a,
            FieldUsageDTO.ObjectOption b
        ) {

            String labelA =
                a == null ||
                a.label == null
                    ? ''
                    : a.label.toLowerCase();


            String labelB =
                b == null ||
                b.label == null
                    ? ''
                    : b.label.toLowerCase();


            return labelA.compareTo(
                labelB
            );
        }
    }


    // =========================================================
    // FIELD SORT COMPARATOR
    // =========================================================

    /**
     * Sorts Salesforce fields alphabetically
     * by their labels.
     */
    private class FieldOptionComparator
        implements Comparator<FieldUsageDTO.FieldOption> {

        public Integer compare(
            FieldUsageDTO.FieldOption a,
            FieldUsageDTO.FieldOption b
        ) {

            String labelA =
                a == null ||
                a.label == null
                    ? ''
                    : a.label.toLowerCase();


            String labelB =
                b == null ||
                b.label == null
                    ? ''
                    : b.label.toLowerCase();


            return labelA.compareTo(
                labelB
            );
        }
    }


    // =========================================================
    // CUSTOM EXCEPTION
    // =========================================================

    public class FieldUsageException
        extends Exception {
    }
}