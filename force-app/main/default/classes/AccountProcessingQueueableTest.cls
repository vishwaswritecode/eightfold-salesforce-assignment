@IsTest
private class AccountProcessingQueueableTest {

    @TestSetup
    static void setupData() {

        List<Account> accounts = new List<Account>();

        for (Integer i = 1; i <= 5; i++) {
            accounts.add(new Account(
                Name = 'Test Account ' + i,
                Priority__c = (Math.mod(i, 2) == 0) ? Constants.HIGH_PRIORITY : 'Low Priority'
            ));
        }

        insert accounts;

        List<Opportunity> opps = new List<Opportunity>();

        for (Account acc : accounts) {

            // Old Opportunity
            opps.add(new Opportunity(
                Name = 'Old Opp ' + acc.Name,
                AccountId = acc.Id,
                StageName = 'Prospecting',
                CloseDate = System.today().addDays(-60),
                Escalate__c = false
            ));

            // Recent Opportunity
            opps.add(new Opportunity(
                Name = 'Recent Opp ' + acc.Name,
                AccountId = acc.Id,
                StageName = 'Prospecting',
                CloseDate = System.today().addDays(20),
                Escalate__c = false
            ));
        }

        insert opps;
    }

    @IsTest
    static void testQueueableProcessing() {

        List<Id> accountIds = new List<Id>();

        for (Account acc : [
            SELECT Id
            FROM Account
        ]) {
            accountIds.add(acc.Id);
        }

        Test.startTest();

        System.enqueueJob(
            new AccountProcessingQueueable(accountIds)
        );

        Test.stopTest();

        for (Account acc : [
            SELECT Priority__c,
                   Health_Score__c
            FROM Account
        ]) {

            System.assertNotEquals(
                null,
                acc.Health_Score__c
            );
        }

        for (Opportunity opp : [
            SELECT Escalate__c,
                   Account.Priority__c,
                   CloseDate
            FROM Opportunity
        ]) {

            if (opp.Account.Priority__c == Constants.HIGH_PRIORITY &&
                opp.CloseDate.daysBetween(System.today()) >
                Constants.OPPORTUNITY_AGE_LIMIT) {

                System.assertEquals(
                    true,
                    opp.Escalate__c
                );
            }
        }
    }

    @IsTest
    static void testRestApiSuccess() {

        List<Account> accounts = [
            SELECT Id
            FROM Account
            LIMIT 2
        ];

        List<Id> ids = new List<Id>();

        for(Account a : accounts){
            ids.add(a.Id);
        }

        RestRequest req = new RestRequest();
        req.httpMethod = 'POST';
        req.requestUri = '/services/apexrest/account-processing';
        req.requestBody =
            Blob.valueOf(JSON.serialize(ids));

        RestResponse res = new RestResponse();

        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();

        AccountProcessingAPI.processAccounts();

        Test.stopTest();

        System.assertEquals(
            202,
            RestContext.response.statusCode
        );
    }

    @IsTest
    static void testRestApiEmptyBody() {

        RestRequest req = new RestRequest();
        req.httpMethod = 'POST';
        req.requestUri = '/services/apexrest/account-processing';

        RestResponse res = new RestResponse();

        RestContext.request = req;
        RestContext.response = res;

        AccountProcessingAPI.processAccounts();

        System.assertEquals(
            400,
            RestContext.response.statusCode
        );
    }

    @IsTest
    static void testRestApiEmptyAccountList() {

        RestRequest req = new RestRequest();
        req.httpMethod = 'POST';
        req.requestUri = '/services/apexrest/account-processing';
        req.requestBody =
            Blob.valueOf('[]');

        RestResponse res = new RestResponse();

        RestContext.request = req;
        RestContext.response = res;

        AccountProcessingAPI.processAccounts();

        System.assertEquals(
            400,
            RestContext.response.statusCode
        );
    }

    @IsTest
    static void testScoreCalculationService() {

        Account acc = new Account(
            Priority__c = Constants.HIGH_PRIORITY
        );

        List<Opportunity> opps = new List<Opportunity>();

        opps.add(new Opportunity(
            CloseDate = System.today().addDays(-60)
        ));

        Decimal score =
            ScoreCalculationService.calculateScore(
                acc,
                opps
            );

        System.assertEquals(
            70,
            score
        );
    }
}