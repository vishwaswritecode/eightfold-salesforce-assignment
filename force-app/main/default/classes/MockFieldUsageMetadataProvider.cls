@IsTest
public class MockFieldUsageMetadataProvider
    implements FieldUsageMetadataProvider {

    public List<FieldUsageDTO.MetadataComponent> retrieveMetadata(
        String objectApiName,
        List<String> fieldApiNames
    ) {
        List<FieldUsageDTO.MetadataComponent> results =
            new List<FieldUsageDTO.MetadataComponent>();

        // Mock FlexiPage referencing Account.Industry
        results.add(
            new FieldUsageDTO.MetadataComponent(
                'FlexiPage',
                'Account_Record_Page',
                '{"sobjectType":"Account",' +
                '"fieldName":"Account.Industry"}'
            )
        );

        // Mock Report referencing Account.Industry
        results.add(
            new FieldUsageDTO.MetadataComponent(
                'Report',
                'Sales_Reports/Account_Industry_Report',
                '{"columns":[{"field":"Account.Industry"}]}'
            )
        );

        // Mock Report referencing Account.Name
        results.add(
            new FieldUsageDTO.MetadataComponent(
                'Report',
                'Sales_Reports/Account_Summary',
                '{"columns":[{"field":"Account.Name"}]}'
            )
        );

        // Unrelated metadata
        results.add(
            new FieldUsageDTO.MetadataComponent(
                'FlexiPage',
                'Contact_Record_Page',
                '{"sobjectType":"Contact",' +
                '"fieldName":"Contact.Email"}'
            )
        );

        return results;
    }
}