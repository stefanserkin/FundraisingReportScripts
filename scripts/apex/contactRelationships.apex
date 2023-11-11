/**************************************************************************
 * @description Produces a csv that is import-ready for Wealth Engine wealth screenings
 * 
 * @date October, 2023
 **************************************************************************/

// Rules
Date minDate = Date.newInstance(2023, 3, 1);
Date fakeBirthday = Date.newInstance(1945, 1, 1);

// Adults in households with registrations or memberships
List<Contact> lstContacts = [
    SELECT Id,
           (SELECT npe4__RelatedContact__c, npe4__RelatedContact__r.AccountId, npe4__RelatedContact__r.AG_ID__c, npe4__RelatedContact__r.FirstName, npe4__RelatedContact__r.MiddleName, npe4__RelatedContact__r.LastName
              FROM npe4__Relationships__r
             WHERE npe4__Status__c = 'Current'
               AND npe4__Type__c = 'Spouse'
             LIMIT 1)
      FROM Contact 
     WHERE Include_in_Wealth_Screening__c = true
       AND TREX1__Age__c >= 18
];

// Headers
String csvString = 'Id';
// Spouses
csvString += ',Spouse Contact ID,Spouse AG ID,Spouse Account ID,Spouse First Name,Spouse Middle Name,Spouse Last Name';
csvString += '\n';

Integer rowCount = 0;
for (Contact ct : lstContacts) {
    if (ct.npe4__Relationships__r.isEmpty()) continue;

    // Contact id
    csvString += ct.Id + ',';
    csvString += ct.npe4__Relationships__r[0].npe4__RelatedContact__c + ',' + ct.npe4__Relationships__r[0].npe4__RelatedContact__r.AG_ID__c + ',' + ct.npe4__Relationships__r[0].npe4__RelatedContact__r.AccountId + ',' + ct.npe4__Relationships__r[0].npe4__RelatedContact__r.FirstName + ',' + ct.npe4__Relationships__r[0].npe4__RelatedContact__r.MiddleName + ',' + ct.npe4__Relationships__r[0].npe4__RelatedContact__r.LastName;

    rowCount++;
    if (rowCount < lstContacts.size()) {
        csvString += '\n';
    }
}

// Create csv file attachment
Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
attachment.setFileName('ParticipantGroupUpdates.csv');
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


