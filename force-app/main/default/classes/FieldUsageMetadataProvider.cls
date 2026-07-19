public interface FieldUsageMetadataProvider {

    List<FieldUsageDTO.MetadataComponent> retrieveMetadata(
        String objectApiName,
        List<String> fieldApiNames
    );
}