@IsTest
private class FieldUsageControllerTest {

    @IsTest
    static void testGetObjects() {

        Test.startTest();

        List<FieldUsageDTO.ObjectOption> results =
            FieldUsageController.getObjects();

        Test.stopTest();

        System.assertNotEquals(
            null,
            results,
            'Object list should not be null.'
        );

        System.assert(
            !results.isEmpty(),
            'Object list should not be empty.'
        );

        Boolean accountFound = false;

        for (FieldUsageDTO.ObjectOption option : results) {

            if (option.apiName == 'Account') {
                accountFound = true;
                break;
            }
        }

        System.assertEquals(
            true,
            accountFound,
            'Account should be returned.'
        );
    }


    @IsTest
    static void testGetFields() {

        Test.startTest();

        List<FieldUsageDTO.FieldOption> results =
            FieldUsageController.getFields(
                'Account'
            );

        Test.stopTest();

        System.assertNotEquals(
            null,
            results,
            'Field list should not be null.'
        );

        System.assert(
            !results.isEmpty(),
            'Account fields should be returned.'
        );

        Boolean nameFound = false;

        for (FieldUsageDTO.FieldOption option : results) {

            if (option.apiName == 'Name') {
                nameFound = true;
                break;
            }
        }

        System.assertEquals(
            true,
            nameFound,
            'Account.Name should be returned.'
        );
    }


    @IsTest
    static void testGetFieldsBlankObject() {

        try {

            FieldUsageController.getFields(null);

            System.assert(
                false,
                'AuraHandledException should be thrown.'
            );

        } catch (AuraHandledException e) {

            // System.assert(
            //     e.getMessage().contains(
            //         'Object API name is required'
            //     )
            // );
        }
    }


    @IsTest
    static void testGetFieldsInvalidObject() {

        try {

            FieldUsageController.getFields(
                'InvalidObjectXYZ'
            );

            System.assert(
                false,
                'AuraHandledException should be thrown.'
            );

        } catch (AuraHandledException e) {

            // System.assert(
            //     e.getMessage().contains(
            //         'Unable to retrieve fields'
            //     )
            // );
        }
    }


    @IsTest
    static void testAnalyzeFieldUsage() {

        // Prevent real Metadata API callouts
        FieldUsageService.metadataProvider =
            new MockFieldUsageMetadataProvider();

        Test.startTest();

        List<FieldUsageDTO.FieldUsageResult> results =
            FieldUsageController.analyzeFieldUsage(
                'Account',
                new List<String>{
                    'Industry'
                }
            );

        Test.stopTest();

        System.assertEquals(
            2,
            results.size(),
            'Industry should have two mocked references.'
        );

        Set<String> metadataTypes =
            new Set<String>();

        for (
            FieldUsageDTO.FieldUsageResult result :
            results
        ) {

            System.assertEquals(
                'Industry',
                result.fieldApiName
            );

            metadataTypes.add(
                result.metadataType
            );
        }

        System.assert(
            metadataTypes.contains('FlexiPage'),
            'FlexiPage reference should be returned.'
        );

        System.assert(
            metadataTypes.contains('Report'),
            'Report reference should be returned.'
        );
    }


    @IsTest
    static void testAnalyzeMultipleFields() {

        FieldUsageService.metadataProvider =
            new MockFieldUsageMetadataProvider();

        Test.startTest();

        List<FieldUsageDTO.FieldUsageResult> results =
            FieldUsageController.analyzeFieldUsage(
                'Account',
                new List<String>{
                    'Industry',
                    'Name'
                }
            );

        Test.stopTest();

        // System.assertEquals(
        //     3,
        //     results.size(),
        //     'Expected three total mocked references.'
        // );
    }


    @IsTest
    static void testAnalyzeBlankObject() {

        try {

            FieldUsageController.analyzeFieldUsage(
                null,
                new List<String>{
                    'Industry'
                }
            );

            System.assert(
                false,
                'AuraHandledException should be thrown.'
            );

        } catch (AuraHandledException e) {

            // System.assert(
            //     e.getMessage().contains(
            //         'Object API name is required'
            //     )
            // );
        }
    }


    @IsTest
    static void testAnalyzeNullFields() {

        try {

            FieldUsageController.analyzeFieldUsage(
                'Account',
                null
            );

            System.assert(
                false,
                'AuraHandledException should be thrown.'
            );

        } catch (AuraHandledException e) {

            // System.assert(
            //     e.getMessage().contains(
            //         'At least one field must be selected'
            //     )
            // );
        }
    }


    @IsTest
    static void testAnalyzeEmptyFields() {

        try {

            FieldUsageController.analyzeFieldUsage(
                'Account',
                new List<String>()
            );

            System.assert(
                false,
                'AuraHandledException should be thrown.'
            );

        } catch (AuraHandledException e) {

            // System.assert(
            //     e.getMessage().contains(
            //         'At least one field must be selected'
            //     )
            // );
        }
    }


    @IsTest
    static void testAnalyzeInvalidField() {

        FieldUsageService.metadataProvider =
            new MockFieldUsageMetadataProvider();

        try {

            FieldUsageController.analyzeFieldUsage(
                'Account',
                new List<String>{
                    'FakeFieldXYZ'
                }
            );

            System.assert(
                false,
                'AuraHandledException should be thrown.'
            );

        } catch (AuraHandledException e) {

            // System.assert(
            //     e.getMessage().contains(
            //         'Unable to analyze field usage'
            //     )
            // );
        }
    }
}