public with sharing class FieldUsageController {

    @AuraEnabled(cacheable=true)
    public static List<FieldUsageDTO.ObjectOption> getObjects() {
        try {
            return FieldUsageService.getObjects();
        } catch (Exception e) {
            throw new AuraHandledException(
                'Unable to retrieve Salesforce objects: ' + e.getMessage()
            );
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<FieldUsageDTO.FieldOption> getFields(
        String objectApiName
    ) {
        try {
            if (String.isBlank(objectApiName)) {
                throw new AuraHandledException(
                    'Object API name is required.'
                );
            }

            return FieldUsageService.getFields(objectApiName);

        } catch (AuraHandledException e) {
            throw e;

        } catch (Exception e) {
            throw new AuraHandledException(
                'Unable to retrieve fields: ' + e.getMessage()
            );
        }
    }

    @AuraEnabled
    public static List<FieldUsageDTO.FieldUsageResult> analyzeFieldUsage(
        String objectApiName,
        List<String> fieldApiNames
    ) {
        try {
            if (String.isBlank(objectApiName)) {
                throw new AuraHandledException(
                    'Object API name is required.'
                );
            }

            if (fieldApiNames == null || fieldApiNames.isEmpty()) {
                throw new AuraHandledException(
                    'At least one field must be selected.'
                );
            }

            return FieldUsageService.analyzeFieldUsage(
                objectApiName,
                fieldApiNames
            );

        } catch (AuraHandledException e) {
            throw e;

        } catch (Exception e) {
            throw new AuraHandledException(
                'Unable to analyze field usage: ' + e.getMessage()
            );
        }
    }
}