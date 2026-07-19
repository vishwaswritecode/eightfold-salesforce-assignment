public class FieldUsageDTO {

    public class ObjectOption {

        @AuraEnabled
        public String label { get; set; }

        @AuraEnabled
        public String apiName { get; set; }

        public ObjectOption(
            String label,
            String apiName
        ) {
            this.label = label;
            this.apiName = apiName;
        }
    }


    public class FieldOption {

        @AuraEnabled
        public String label { get; set; }

        @AuraEnabled
        public String apiName { get; set; }

        public FieldOption(
            String label,
            String apiName
        ) {
            this.label = label;
            this.apiName = apiName;
        }
    }


    public class FieldUsageResult {

        @AuraEnabled
        public String fieldLabel { get; set; }

        @AuraEnabled
        public String fieldApiName { get; set; }

        @AuraEnabled
        public String metadataType { get; set; }

        @AuraEnabled
        public String componentName { get; set; }

        @AuraEnabled
        public String referenceType { get; set; }


        public FieldUsageResult() {
        }


        public FieldUsageResult(
            String fieldLabel,
            String fieldApiName,
            String metadataType,
            String componentName,
            String referenceType
        ) {
            this.fieldLabel = fieldLabel;
            this.fieldApiName = fieldApiName;
            this.metadataType = metadataType;
            this.componentName = componentName;
            this.referenceType = referenceType;
        }
    }


    public class MetadataComponent {

        public String metadataType;

        public String componentName;

        public String metadataContent;


        public MetadataComponent(
            String metadataType,
            String componentName,
            String metadataContent
        ) {
            this.metadataType = metadataType;
            this.componentName = componentName;
            this.metadataContent = metadataContent;
        }
    }
}