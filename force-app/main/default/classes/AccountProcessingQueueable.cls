public with sharing class AccountProcessingQueueable implements Queueable {

    private List<Id> accountIds;
    private Integer startIndex;

    public AccountProcessingQueueable(List<Id> accountIds) {
        this(accountIds, 0);
    }

    public AccountProcessingQueueable(List<Id> accountIds,
                                      Integer startIndex) {

        this.accountIds = accountIds;
        this.startIndex = startIndex;
    }

    public void execute(QueueableContext context) {

        if(accountIds == null || accountIds.isEmpty()) {
            return;
        }

        Integer endIndex = Math.min(
            startIndex + Constants.CHUNK_SIZE,
            accountIds.size()
        );

        List<Id> chunk = new List<Id>();

        for(Integer i = startIndex; i < endIndex; i++) {
            chunk.add(accountIds[i]);
        }

        // Process only this chunk
        AccountProcessingService.processAccounts(chunk);

        // Chain next Queueable if records remain
        if(endIndex < accountIds.size()) {

            System.enqueueJob(
                new AccountProcessingQueueable(
                    accountIds,
                    endIndex
                )
            );

        }

    }

}