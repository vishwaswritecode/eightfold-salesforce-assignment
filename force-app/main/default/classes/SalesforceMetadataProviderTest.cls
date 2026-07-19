@IsTest
private class SalesforceMetadataProviderTest {

    // =========================================================
    // SUCCESS TEST
    // =========================================================

    @IsTest
    static void testRetrieveMetadataSuccess() {

        Test.setMock(
            HttpCalloutMock.class,
            new SalesforceMetadataHttpMock()
        );

        SalesforceMetadataProvider provider =
            new SalesforceMetadataProvider();

        Test.startTest();

        List<FieldUsageDTO.MetadataComponent> results =
            provider.retrieveMetadata(
                'Account',
                new List<String>{
                    'Industry'
                }
            );

        Test.stopTest();

        System.assertNotEquals(
            null,
            results,
            'Results should not be null.'
        );

        System.assert(
            !results.isEmpty(),
            'Mock metadata should return field references.'
        );


        Set<String> metadataTypes =
            new Set<String>();

        for (
            FieldUsageDTO.MetadataComponent component :
            results
        ) {

            metadataTypes.add(
                component.metadataType
            );
        }


        System.assert(
            metadataTypes.contains('ApexClass'),
            'ApexClass reference should be detected.'
        );

        System.assert(
            metadataTypes.contains('ApexTrigger'),
            'ApexTrigger reference should be detected.'
        );

        System.assert(
            metadataTypes.contains('Layout'),
            'Layout reference should be detected.'
        );

        System.assert(
            metadataTypes.contains('ValidationRule'),
            'ValidationRule reference should be detected.'
        );

        System.assert(
            metadataTypes.contains('Report'),
            'Report reference should be detected.'
        );
    }


    // =========================================================
    // EMPTY FIELD LIST
    // =========================================================

    @IsTest
    static void testEmptyFieldList() {

        SalesforceMetadataProvider provider =
            new SalesforceMetadataProvider();

        Test.startTest();

        List<FieldUsageDTO.MetadataComponent> results =
            provider.retrieveMetadata(
                'Account',
                new List<String>()
            );

        Test.stopTest();

        System.assertEquals(
            0,
            results.size(),
            'Empty field list should return empty results.'
        );
    }


    // =========================================================
    // NULL FIELD LIST
    // =========================================================

    @IsTest
    static void testNullFieldList() {

        SalesforceMetadataProvider provider =
            new SalesforceMetadataProvider();

        Test.startTest();

        List<FieldUsageDTO.MetadataComponent> results =
            provider.retrieveMetadata(
                'Account',
                null
            );

        Test.stopTest();

        System.assertEquals(
            0,
            results.size(),
            'Null field list should return empty results.'
        );
    }


    // =========================================================
    // BLANK OBJECT
    // =========================================================

    @IsTest
    static void testBlankObject() {

        SalesforceMetadataProvider provider =
            new SalesforceMetadataProvider();

        try {

            provider.retrieveMetadata(
                null,
                new List<String>{
                    'Industry'
                }
            );

            System.assert(
                false,
                'Exception should have been thrown.'
            );

        } catch (
            SalesforceMetadataProvider.MetadataProviderException e
        ) {

            System.assert(
                e.getMessage().contains(
                    'Object API name is required'
                )
            );
        }
    }


    // =========================================================
    // NAMED CREDENTIAL FAILURE
    // =========================================================

    @IsTest
    static void testNamedCredentialFailure() {

        Test.setMock(
            HttpCalloutMock.class,
            new NamedCredentialFailureMock()
        );

        SalesforceMetadataProvider provider =
            new SalesforceMetadataProvider();

        try {

            Test.startTest();

            provider.retrieveMetadata(
                'Account',
                new List<String>{
                    'Industry'
                }
            );

            Test.stopTest();

            System.assert(
                false,
                'Exception should have been thrown.'
            );

        } catch (
            SalesforceMetadataProvider.MetadataProviderException e
        ) {

            System.assert(
                e.getMessage().contains(
                    'Named Credential authentication failed'
                )
            );
        }
    }


    // =========================================================
    // MAIN HTTP MOCK
    // =========================================================

    private class SalesforceMetadataHttpMock
        implements HttpCalloutMock {

        public HttpResponse respond(
            HttpRequest request
        ) {

            HttpResponse response =
                new HttpResponse();

            response.setStatusCode(200);

            String endpoint =
                request.getEndpoint();


            // =================================================
            // NAMED CREDENTIAL VALIDATION
            // =================================================

            if (
                endpoint.contains('/limits/')
            ) {

                response.setBody(
                    '{"DailyApiRequests":' +
                    '{"Max":15000,"Remaining":14999}}'
                );

                return response;
            }


            // =================================================
            // METADATA COMPONENT DEPENDENCY
            // =================================================

            if (
                endpoint.contains('/tooling/query/') &&
                endpoint.contains(
                    'MetadataComponentDependency'
                )
            ) {

                response.setBody(
                    '{' +
                        '"done":true,' +
                        '"records":[' +
                            '{' +
                                '"MetadataComponentId":"01p000000000001",' +
                                '"MetadataComponentName":"AccountController",' +
                                '"MetadataComponentType":"ApexClass",' +
                                '"RefMetadataComponentId":"00N000000000001",' +
                                '"RefMetadataComponentName":"Industry",' +
                                '"RefMetadataComponentType":"CustomField",' +
                                '"fieldReference":"Account.Industry"' +
                            '}' +
                        ']' +
                    '}'
                );

                return response;
            }


            // =================================================
            // APEX CLASS QUERY
            // =================================================

            if (
                endpoint.contains('/tooling/query/') &&
                endpoint.contains('ApexClass')
            ) {

                response.setBody(
                    '{' +
                        '"done":true,' +
                        '"records":[' +
                            '{' +
                                '"Id":"01p000000000002",' +
                                '"Name":"AccountIndustryController",' +
                                '"NamespacePrefix":null,' +
                                '"Body":"public class AccountIndustryController {' +
                                    ' String fieldName = \'Account.Industry\';' +
                                ' }"' +
                            '}' +
                        ']' +
                    '}'
                );

                return response;
            }


            // =================================================
            // APEX TRIGGER QUERY
            // =================================================

            if (
                endpoint.contains('/tooling/query/') &&
                endpoint.contains('ApexTrigger')
            ) {

                response.setBody(
                    '{' +
                        '"done":true,' +
                        '"records":[' +
                            '{' +
                                '"Id":"01q000000000001",' +
                                '"Name":"AccountIndustryTrigger",' +
                                '"NamespacePrefix":null,' +
                                '"Body":"trigger AccountIndustryTrigger ' +
                                    'on Account (before update) {' +
                                    ' String value = Trigger.new[0].Industry;' +
                                ' }"' +
                            '}' +
                        ']' +
                    '}'
                );

                return response;
            }


            // =================================================
            // LAYOUT LIST QUERY
            // =================================================

            if (
                endpoint.contains('/tooling/query/') &&
                endpoint.contains('FROM+Layout')
            ) {

                response.setBody(
                    '{' +
                        '"done":true,' +
                        '"records":[' +
                            '{' +
                                '"Id":"00h000000000001",' +
                                '"Name":"Account Layout",' +
                                '"TableEnumOrId":"Account"' +
                            '}' +
                        ']' +
                    '}'
                );

                return response;
            }


            // =================================================
            // INDIVIDUAL LAYOUT
            // =================================================

            if (
                endpoint.contains(
                    '/tooling/sobjects/Layout/'
                )
            ) {

                response.setBody(
                    '{' +
                        '"Id":"00h000000000001",' +
                        '"Name":"Account Layout",' +
                        '"Metadata":{' +
                            '"layoutSections":[' +
                                '{' +
                                    '"label":"Account Information",' +
                                    '"layoutColumns":[' +
                                        '{' +
                                            '"layoutItems":[' +
                                                '{' +
                                                    '"field":"Industry"' +
                                                '}' +
                                            ']' +
                                        '}' +
                                    ']' +
                                '}' +
                            ']' +
                        '}' +
                    '}'
                );

                return response;
            }


            // =================================================
            // VALIDATION RULE LIST QUERY
            // =================================================

            if (
                endpoint.contains('/tooling/query/') &&
                endpoint.contains('ValidationRule')
            ) {

                response.setBody(
                    '{' +
                        '"done":true,' +
                        '"records":[' +
                            '{' +
                                '"Id":"03d000000000001",' +
                                '"ValidationName":"IndustryRequired"' +
                            '}' +
                        ']' +
                    '}'
                );

                return response;
            }


            // =================================================
            // INDIVIDUAL VALIDATION RULE
            // =================================================

            if (
                endpoint.contains(
                    '/tooling/sobjects/ValidationRule/'
                )
            ) {

                response.setBody(
                    '{' +
                        '"Id":"03d000000000001",' +
                        '"ValidationName":"IndustryRequired",' +
                        '"Metadata":{' +
                            '"active":true,' +
                            '"errorConditionFormula":' +
                            '"ISBLANK(Account.Industry)",' +
                            '"errorMessage":"Industry is required"' +
                        '}' +
                    '}'
                );

                return response;
            }


            // =================================================
            // REPORT QUERY
            // =================================================

            if (
                endpoint.contains('/query/') &&
                !endpoint.contains('/tooling/query/')
            ) {

                response.setBody(
                    '{' +
                        '"done":true,' +
                        '"records":[' +
                            '{' +
                                '"Id":"00O000000000001",' +
                                '"Name":"Account Industry Report",' +
                                '"DeveloperName":"Account_Industry_Report"' +
                            '}' +
                        ']' +
                    '}'
                );

                return response;
            }


            // =================================================
            // REPORT DESCRIBE
            // =================================================

            if (
                endpoint.contains(
                    '/analytics/reports/'
                )
            ) {

                response.setBody(
                    '{' +
                        '"reportMetadata":{' +
                            '"detailColumns":[' +
                                '"Account.Name",' +
                                '"Account.Industry"' +
                            ']' +
                        '}' +
                    '}'
                );

                return response;
            }


            // =================================================
            // DEFAULT
            // =================================================

            response.setBody(
                '{"done":true,"records":[]}'
            );

            return response;
        }
    }


    // =========================================================
    // NAMED CREDENTIAL FAILURE MOCK
    // =========================================================

    private class NamedCredentialFailureMock
        implements HttpCalloutMock {

        public HttpResponse respond(
            HttpRequest request
        ) {

            HttpResponse response =
                new HttpResponse();

            response.setStatusCode(401);

            response.setBody(
                '{"message":"Unauthorized"}'
            );

            return response;
        }
    }
}