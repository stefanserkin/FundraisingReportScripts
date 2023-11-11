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
    SELECT Id, AccountId, AG_ID__c, Salutation, FirstName, MiddleName, LastName, Suffix, 
           MailingStreet, MailingCity, MailingState, MailingCountry, MailingPostalCode
      FROM Contact 
     WHERE Include_in_Wealth_Screening__c = true
       AND TREX1__Age__c >= 18
];

/*
           (SELECT npe4__RelatedContact__c, npe4__RelatedContact__r.FirstName, npe4__RelatedContact__r.MiddleName, npe4__RelatedContact__r.LastName
              FROM npe4__Relationships__r
             WHERE npe4__Status__c = 'Current'
               AND npe4__Type__c = 'Spouse'
             LIMIT 1) */

// Headers
String csvString = 'Id,AccountId,AG_ID__c,User Supplied ID 2,Salutation,FirstName,MiddleName,LastName,Suffix,MailingStreet,MailingCity,MailingState,MailingCountry,MailingPostalCode';
// Spouses
// csvString += ',Spouse Contact ID,Spouse First Name,Spouse Middle Name,Spouse Last Name';
csvString += '\n';

Integer rowCount = 0;
for (Contact ct : lstContacts) {

    // Contact and account info
    csvString += ct.Id + ',' + ct.AccountId + ',' + ct.AG_ID__c + ',' + ct.Id + '-' + ct.AG_ID__c + ',' + ct.Salutation + ',' + ct.FirstName + ',' + ct.MiddleName + ',' + ct.LastName + ',' + ct.Suffix + ',' + ct.MailingStreet + ',' + ct.MailingCity + ',' + ct.MailingState + ',' + ct.MailingCountry + ',' + ct.MailingPostalCode;

    // Spouses
    /*
    if (!ct.npe4__Relationships__r.isEmpty()) {
        csvString += ct.npe4__Relationships__r[0].npe4__RelatedContact__c + ',' + ct.npe4__Relationships__r[0].npe4__RelatedContact__r.FirstName + ',' + ct.npe4__Relationships__r[0].npe4__RelatedContact__r.MiddleName + ',' + ct.npe4__Relationships__r[0].npe4__RelatedContact__r.LastName;
    } else {
        csvString += ',,,,';
    }
    */

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


