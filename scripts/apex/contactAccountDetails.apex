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
           MailingStreet, MailingCity, MailingState, MailingCountry, MailingPostalCode,
           Account.npo02__TotalOppAmount__c, Account.npo02__NumberOfClosedOpps__c, Account.npo02__LastOppAmount__c, 
           Account.npo02__LastCloseDate__c, Account.npo02__Best_Gift_Year_Total__c, Account.npo02__Best_Gift_Year__c, 
           Birthdate, TREX1__Age__c, MobilePhone, HomePhone, npe01__WorkPhone__c, OtherPhone,
           (SELECT npe4__RelatedContact__c, npe4__RelatedContact__r.AG_ID__c, 
                   npe4__RelatedContact__r.AccountId, npe4__RelatedContact__r.FirstName, 
                   npe4__RelatedContact__r.MiddleName, npe4__RelatedContact__r.LastName
              FROM npe4__Relationships__r
             WHERE npe4__Status__c = 'Current'
               AND npe4__Type__c = 'Spouse'
             LIMIT 1)
      FROM Contact 
     WHERE Include_in_Wealth_Screening__c = true
       AND TREX1__Age__c >= 18
];

// Headers
String csvString = 'Id,AccountId,AG_ID__c,User Supplied ID 2,Salutation,FirstName,MiddleName,LastName,Suffix,MailingStreet,MailingCity,MailingState,MailingCountry,MailingPostalCode,Account.npo02__TotalOppAmount__c,Account.npo02__NumberOfClosedOpps__c,Account.npo02__LastOppAmount__c,Account.npo02__LastCloseDate__c,Account.npo02__Best_Gift_Year_Total__c,Account.npo02__Best_Gift_Year__c,Birthdate,TREX1__Age__c,MobilePhone,HomePhone,npe01__WorkPhone__c,OtherPhone,';
// Spouses
csvString += 'Spouse Contact ID,User Supplied Spouse ID,User Supplied Spouse ID 2,Spouse First Name,Spouse Middle Name,Spouse Last Name';
csvString += '\n';

Integer rowCount = 0;
for (Contact ct : lstContacts) {

    // Contact and account info
    csvString += ct.Id + ',' + ct.AccountId + ',' + ct.AG_ID__c + ',' + ct.Id + '-' + ct.AG_ID__c + ',';
    csvString += ct.Salutation != null ? ct.Salutation + ',' : ',';
    csvString += ct.FirstName + ',';
    csvString += ct.MiddleName != null ? ct.MiddleName + ',' : ',';
    csvString += ct.LastName + ',';
    csvString += ct.Suffix != null ? ct.Suffix + ',' : ',';
    csvString += '"' + ct.MailingStreet.replaceAll('"','""') + '",';
    csvString += ct.MailingCity + ',' + ct.MailingState + ',' + ct.MailingCountry + ',' + ct.MailingPostalCode + ',';
    csvString += ct.Account.npo02__TotalOppAmount__c != null && ct.Account.npo02__TotalOppAmount__c > 0 ? ct.Account.npo02__TotalOppAmount__c + ',' : ',';
    csvString += ct.Account.npo02__NumberOfClosedOpps__c != null && ct.Account.npo02__NumberOfClosedOpps__c > 0 ? ct.Account.npo02__NumberOfClosedOpps__c + ',' : ',';
    csvString += ct.Account.npo02__LastOppAmount__c != null && ct.Account.npo02__LastOppAmount__c > 0 ? ct.Account.npo02__LastOppAmount__c + ',' : ',';
    csvString += ct.Account.npo02__LastCloseDate__c != null ? ct.Account.npo02__LastCloseDate__c + ',' : ',';
    csvString += ct.Account.npo02__Best_Gift_Year_Total__c != null && ct.Account.npo02__Best_Gift_Year_Total__c > 0 ? ct.Account.npo02__Best_Gift_Year_Total__c + ',' : ',';
    csvString += ct.Account.npo02__Best_Gift_Year__c != null ? ct.Account.npo02__Best_Gift_Year__c + ',' : ',';
    csvString += ct.Account.npo02__TotalOppAmount__c != null && ct.Account.npo02__TotalOppAmount__c > 0 ? ct.Account.npo02__TotalOppAmount__c + ',' : ',';
    
    if (ct.Birthdate != null && ct.Birthdate != fakeBirthday) {
        csvString += ct.Birthdate + ',' + ct.TREX1__Age__c + ',';
    } else {
        csvString += ',,';
    }

    csvString += ct.MobilePhone != null ? ct.MobilePhone + ',' : ',';
    csvString += ct.HomePhone != null ? ct.HomePhone + ',' : ',';
    csvString += ct.npe01__WorkPhone__c != null ? ct.npe01__WorkPhone__c + ',' : ',';
    csvString += ct.OtherPhone != null ? ct.OtherPhone + ',' : ',';

    // Spouses
    if (!ct.npe4__Relationships__r.isEmpty()) {
        // Contact Id
        csvString += ct.npe4__Relationships__r[0].npe4__RelatedContact__c + ',';
        // User Supplied Spouse Id (account id)
        csvString += ct.npe4__Relationships__r[0].npe4__RelatedContact__r.AccountId + ',';
        // User Supplied Spouse Id 2 (contact id & ag id)
        csvString += ct.npe4__Relationships__r[0].npe4__RelatedContact__c + '-' + ct.npe4__Relationships__r[0].npe4__RelatedContact__r.AG_ID__c + ',';
        // Spouse details
        csvString += ct.npe4__Relationships__r[0].npe4__RelatedContact__r.FirstName + ',' + ct.npe4__Relationships__r[0].npe4__RelatedContact__r.MiddleName + ',' + ct.npe4__Relationships__r[0].npe4__RelatedContact__r.LastName;
    } else {
        csvString += ',,,,,,';
    }

    rowCount++;
    if (rowCount < lstContacts.size()) {
        csvString += '\n';
    }
}


// Create csv file attachment
Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
attachment.setFileName('ContactAccountDetails.csv');
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


