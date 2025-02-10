

List<Account> accounts = [
    select Id, Name,
    	   (select Id, StageName, CloseDate
              from Opportunities
             where Committed__c = true) 
      from Account 
     where Id IN (select AccountId 
                    from Contact 
                   where Include_in_Wealth_Screening__c = true) 
       and Id IN (select AccountId 
                    from Opportunity
                   where Committed__c = true)
];

Map<Id, Set<String>> mapAccountIdToOppYears = new Map<Id, Set<String>>();

for (Account acc : accounts) {
    Set<String> oppYears = new Set<String>();
    for (Opportunity opp : acc.Opportunities) {
        oppYears.add( String.valueOf(opp.CloseDate.year()) );
    }
    mapAccountIdToOppYears.put(acc.Id, oppYears);
}

String csvString = 'Account ID,Number of Years Giving\n';
Integer recordCount = 0;
for (Id accId : mapAccountIdToOppYears.keySet()) {
    csvString += accId + ',' + String.valueOf(mapAccountIdToOppYears.get(accId).size());
    recordCount++;
    if (recordCount < mapAccountIdToOppYears.size()) {
        csvString += '\n';
    }
}

// Create csv file attachment
Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
attachment.setFileName('AccountYearsGiving.csv');
attachment.setBody(Blob.valueOf(csvString));

// Create email with attachment
Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
email.setToAddresses(new List<String>{'sserkin@asphaltgreen.org'});
email.setSubject('Data for ya');
email.setSenderDisplayName('AG Data Factory');
email.setPlainTextBody('Here is some data. Please enjoy.');
email.setFileAttachments(new List<Messaging.EmailFileAttachment>{ 
    attachment 
});

Messaging.sendEmail(
    new List<Messaging.SingleEmailMessage>{ email }
);

