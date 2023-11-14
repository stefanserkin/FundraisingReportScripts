/**************************************************************************
 * @description Contributes to import-ready csv for Wealth Engine wealth screenings
 * 
 * @date October, 2023
 **************************************************************************/

// Rules
Date minDate = Date.newInstance(2023, 3, 1);
Date fakeBirthday = Date.newInstance(1945, 1, 1);

// Adults in households with memberships since the minimum date
List<Contact> lstContacts = [
    SELECT Id,
           (SELECT TREX1__Status__c, Type_of_Membership__c, RecordType.DeveloperName, TREX1__memb_Type__r.Name, TREX1__Category_Name__c
              FROM TREX1__Memberships__r
             WHERE Type_of_Membership__c != 'Program Participant'
               AND TREX1__Status__c IN ('Active', 'Complete', 'Pending Active', 'Pending Cancel', 'Pending Transfer', 'On Hold'))
      FROM Contact 
     WHERE TREX1__Age__c >= 18
       AND AccountId IN (SELECT TREX1__Account__c 
                           FROM TREX1__Membership__c 
                          WHERE Type_of_Membership__c != 'Program Participant'
                            AND TREX1__Status__c in ('Active', 'Complete', 'Pending Active', 'Pending Cancel', 'Pending Transfer', 'On Hold')
                            AND TREX1__Start_Date__c >= :minDate)
];

// Headers
String csvString = 'Id,Memberships,Private Lessons\n';

Integer rowCount = 0;
for (Contact ct : lstContacts) {

    // Contact and account info
    csvString += ct.Id + ',';

    // Memberships
    if (!ct.TREX1__Memberships__r.isEmpty()) {
        List<String> lstMems = new List<String>();
        List<String> lstPvts = new List<String>();
        for (TREX1__Membership__c mem : ct.TREX1__Memberships__r) {
            if (mem.RecordType.DeveloperName == 'Standard_Membership') {
                lstMems.add(mem.Type_of_Membership__c + ' (' + mem.TREX1__Status__c + ')');
            } else {
                // lstPvts.add(mem.TREX1__Category_Name__c + ' (' + mem.TREX1__Status__c + ')');
                lstPvts.add(mem.TREX1__memb_Type__r.Name + ' (' + mem.TREX1__Status__c + ')');
            }
        }
        csvString += String.join(lstMems, '; ') + ',' + String.join(lstPvts, '; ');
    } else {
        csvString += ',';
    }

    rowCount++;
    if (rowCount < lstContacts.size()) {
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


