public class ScoreCalculationService {

    public static Decimal calculateScore(Account account,
                                         List<Opportunity> opportunities) {

        Integer score = Constants.BASE_SCORE;

        if(account.Priority__c == Constants.HIGH_PRIORITY){
            score += Constants.HIGH_PRIORITY_BONUS;
        }

        Integer oldOpportunityCount = 0;

        for(Opportunity opp : opportunities){

            if (opp.CloseDate.daysBetween(System.today()) >
                Constants.OPPORTUNITY_AGE_LIMIT) {

                oldOpportunityCount++;
            }
        }

        if(oldOpportunityCount > 0){
            score -= oldOpportunityCount *
                     Constants.OLD_OPPORTUNITY_PENALTY;
        }
        else{
            score += Constants.NO_OLD_OPPORTUNITY_BONUS;
        }

        score = Math.max(Constants.MIN_SCORE, score);
        score = Math.min(Constants.MAX_SCORE, score);

        return score;
    }

}