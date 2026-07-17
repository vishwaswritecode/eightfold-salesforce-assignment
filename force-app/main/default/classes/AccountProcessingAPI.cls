@RestResource(urlMapping='/account-processing/*')
global with sharing class AccountProcessingAPI {

    @HttpPost
    global static void processAccounts() {

        RestRequest request = RestContext.request;
        RestResponse response = RestContext.response;

        try {

            // Validate request body
            if (request.requestBody == null ||
                String.isBlank(request.requestBody.toString())) {

                response.statusCode = 400;
                response.responseBody =
                    Blob.valueOf('Request body cannot be empty.');

                return;
            }

            // Deserialize Account Ids
            List<Id> accountIds =
                (List<Id>)JSON.deserialize(
                    request.requestBody.toString(),
                    List<Id>.class
                );

            if (accountIds == null || accountIds.isEmpty()) {

                response.statusCode = 400;
                response.responseBody =
                    Blob.valueOf('No Account Ids supplied.');

                return;
            }

            // Submit Queueable Job
            Id jobId = System.enqueueJob(
                new AccountProcessingQueueable(accountIds)
            );

            // Success Response
            response.statusCode = 202;

            response.responseBody = Blob.valueOf(
                JSON.serialize(new APIResponse(
                    true,
                    'Processing started successfully.',
                    jobId
                ))
            );

        }
        catch (Exception ex) {

            response.statusCode = 500;

            response.responseBody = Blob.valueOf(
                JSON.serialize(new APIResponse(
                    false,
                    ex.getMessage(),
                    null
                ))
            );

        }

    }

    // Response Wrapper
    global class APIResponse {

        public Boolean success;
        public String message;
        public Id jobId;

        public APIResponse(
            Boolean success,
            String message,
            Id jobId
        ) {
            this.success = success;
            this.message = message;
            this.jobId = jobId;
        }
    }

}