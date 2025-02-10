/**************************************************************************
 * @description Contributes to import-ready csv for Wealth Engine wealth screenings
 * 
 * @date October, 2023
 **************************************************************************/

List<Account> lstAccounts = [
    SELECT Id,
           (SELECT TREX1__Contact__r.FirstName, TREX1__Start_Date__c, TREX1__Status__c, Type_of_Membership__c, RecordType.DeveloperName, TREX1__memb_Type__r.Name, TREX1__Category_Name__c
              FROM TREX1__Memberships__r
             WHERE Type_of_Membership__c NOT IN ('Program Participant', 'Staff')
               AND TREX1__Category_Name__c NOT IN ('Complimentary Memberships','Complimentary Sessions')
               AND TREX1__Status__c IN ('Active', 'Complete', 'Pending Active', 'Pending Cancel', 'Pending Transfer', 'On Hold')
             ORDER BY TREX1__Start_Date__c DESC, TREX1__Contact__r.FirstName)
      FROM Account 
     WHERE Id IN (SELECT AccountId FROM Contact WHERE Include_in_Wealth_Screening__c = true)
];

// Headers
String csvString = 'Id,Memberships,Private Lessons\n';

Integer rowCount = 0;
for (Account acc : lstAccounts) {

    // Account id
    csvString += acc.Id + ',';

    // Memberships
    if (!acc.TREX1__Memberships__r.isEmpty()) {
        List<String> lstMems = new List<String>();
        List<String> lstPvts = new List<String>();
        for (TREX1__Membership__c mem : acc.TREX1__Memberships__r) {
            String memString = '';
            if (mem.Type_of_Membership__c != null) {
                memString += mem.Type_of_Membership__c;
            } else {
                memString += mem.TREX1__memb_Type__r.Name.replaceAll('"','""');
            }
            // memString += ' (Contact: ' + mem.TREX1__Contact__r.FirstName + ' | Status: ' + mem.TREX1__Status__c + ' | Start Date: ' + mem.TREX1__Start_Date__c.format() + ')';
            memString += ' (' + mem.TREX1__Contact__r.FirstName + ' | ' + mem.TREX1__Status__c + ' | ' + mem.TREX1__Start_Date__c.format() + ')';

            if (mem.RecordType.DeveloperName == 'Standard_Membership') {
                lstMems.add(memString);
            } else {
                lstPvts.add(memString);
            }
        }
        csvString += '"' + String.join(lstMems, '; ') + '"' + ',' + '"' + String.join(lstPvts, '; ') + '"';
    } else {
        csvString += ',';
    }

    rowCount++;
    if (rowCount < lstAccounts.size()) {
        csvString += '\n';
    }
}


// Create csv file attachment
Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
attachment.setFileName('MembershipHistory.csv');
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


