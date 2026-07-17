public with sharing class AccountProcessingService {

    public static void processAccounts(List<Id> accountIds) {

        if (accountIds == null || accountIds.isEmpty()) {
            return;
        }

        // Query Accounts
        List<Account> accounts = [
            SELECT Id,
                   Name,
                   Priority__c,
                   Health_Score__c
            FROM Account
            WHERE Id IN :accountIds
        ];

        // Query Open Opportunities
        List<Opportunity> opportunities = [
            SELECT Id,
                   Name,
                   AccountId,
                   StageName,
                   CreatedDate,
                   Escalate__c,
                   CloseDate
            FROM Opportunity
            WHERE AccountId IN :accountIds
            AND IsClosed = FALSE
        ];

        // Group Opportunities by Account
        Map<Id, List<Opportunity>> accountOpportunityMap = new Map<Id, List<Opportunity>>();

        for (Opportunity opp : opportunities) {

            if (!accountOpportunityMap.containsKey(opp.AccountId)) {
                accountOpportunityMap.put(
                    opp.AccountId,
                    new List<Opportunity>()
                );
            }

            accountOpportunityMap.get(opp.AccountId).add(opp);
        }

        List<Account> accountsToUpdate = new List<Account>();
        List<Opportunity> opportunitiesToUpdate = new List<Opportunity>();
            

        // Process Accounts
        for (Account account : accounts) {

            List<Opportunity> accountOpps =
                accountOpportunityMap.containsKey(account.Id)
                ? accountOpportunityMap.get(account.Id)
                : new List<Opportunity>();

            // Escalation Logic
            if (account.Priority__c == Constants.HIGH_PRIORITY) {

                for (Opportunity opp : accountOpps) {

                    Integer daysOld = opp.CloseDate.daysBetween(System.today());
                    if (daysOld > Constants.OPPORTUNITY_AGE_LIMIT) {
                        opp.Escalate__c = true;
                        opportunitiesToUpdate.add(opp);

                    }

                }

            }

            // Score Calculation
            account.Health_Score__c =
                ScoreCalculationService.calculateScore(
                    account,
                    accountOpps
                );

            accountsToUpdate.add(account);

        }

        updateOpportunities(opportunitiesToUpdate);

        updateAccounts(accountsToUpdate);

    }

    /**
     * Update Opportunities using Partial Success
     */
    private static void updateOpportunities(
        List<Opportunity> opportunities
    ) {

        if (opportunities.isEmpty()) {
            return;
        }

        Database.SaveResult[] results =
            Database.update(opportunities, false);

        logErrors(results, opportunities);

    }

    /**
     * Update Accounts using Partial Success
     */
    private static void updateAccounts(
        List<Account> accounts
    ) {

        if (accounts.isEmpty()) {
            return;
        }

        Database.SaveResult[] results =
            Database.update(accounts, false);

        logErrors(results, accounts);

    }

    /**
     * Generic Error Logger
     */
    private static void logErrors(
        Database.SaveResult[] results,
        List<SObject> records
    ) {

        for (Integer i = 0; i < results.size(); i++) {

            if (!results[i].isSuccess()) {

                for (Database.Error error : results[i].getErrors()) {

                    System.debug(
                        LoggingLevel.ERROR,
                        'Record Id : ' +
                        records[i].Id +
                        ' Error : ' +
                        error.getMessage()
                    );

                }

            }

        }

    }

}