/**************************************************************************
 * @description Produces a csv that is import-ready for Wealth Engine wealth screenings
 * Name, middle initial, and address
 * Address is mandatory
 * Search for giving to other organizations
 * No staff screened
 * 
 * For child data - include ALL records in household
 * 
 * @date October, 2023
 **************************************************************************/

// Rules
Date minDate = Date.newInstance(2023, 3, 1);
Date fakeBirthday = Date.newInstance(1945, 1, 1);

List<Contact> lstRegCts = [
    SELECT Id 
      FROM Contact
     WHERE AccountId IN (SELECT TREX1__Account__c 
                           FROM TREX1__Registration__c 
                          WHERE TREX1__Start_Date__c >= :minDate
                            AND Qualifying_Enrollments__c > 0)
];

List<Contact> lstMemCts = [
    SELECT Id 
      FROM Contact
     WHERE AccountId IN (SELECT TREX1__Account__c 
                           FROM TREX1__Membership__c 
                          WHERE TREX1__Status__c in ('Active', 'Complete', 'Pending Active', 'Pending Cancel', 'Pending Transfer', 'On Hold')
                            AND TREX1__Start_Date__c >= :minDate)
];

// Adults in households with registrations or memberships
List<Contact> lstContacts = [
    SELECT Id, AccountId, AG_ID__c, Salutation, FirstName, MiddleName, LastName, Suffix, 
           MailingStreet, MailingCity, MailingState, MailingCountry, MailingPostalCode, 
           Account.npo02__TotalOppAmount__c, Account.npo02__NumberOfClosedOpps__c, Account.npo02__LastOppAmount__c, 
           Account.npo02__LastCloseDate__c, Account.npo02__Best_Gift_Year_Total__c, Account.npo02__Best_Gift_Year__c, 
           Birthdate, TREX1__Age__c, MobilePhone, HomePhone, npe01__WorkPhone__c, OtherPhone,
           (SELECT TREX1__reg_Course_Session__r.Name, TREX1__Start_Date__c
              FROM TREX1__Registrations__r 
             WHERE Qualifying_Enrollments__c > 0),
           (SELECT TREX1__Status__c, Type_of_Membership__c 
              FROM TREX1__Memberships__r
             WHERE TREX1__Status__c IN ('Active', 'Complete', 'Pending Active', 'Pending Cancel', 'Pending Transfer', 'On Hold')),
           (SELECT npe4__RelatedContact__c, npe4__RelatedContact__r.FirstName, npe4__RelatedContact__r.MiddleName, npe4__RelatedContact__r.LastName
              FROM npe4__Relationships__r
             WHERE npe4__Status__c = 'Current'
               AND npe4__Type__c = 'Spouse'
             LIMIT 1)
      FROM Contact 
     WHERE TREX1__Age__c >= 18
       AND (Id IN :lstRegCts OR Id IN :lstMemCts)
];

// Headers
String csvString = 'Id,AccountId,AG_ID__c,User Supplied ID 2,Salutation,FirstName,MiddleName,LastName,Suffix,MailingStreet,MailingCity,MailingState,MailingCountry,MailingPostalCode,Account.npo02__TotalOppAmount__c,Account.npo02__NumberOfClosedOpps__c,Account.npo02__LastOppAmount__c,Account.npo02__LastCloseDate__c,Account.npo02__Best_Gift_Year_Total__c,Account.npo02__Best_Gift_Year__c,Birthdate,TREX1__Age__c,MobilePhone,HomePhone,npe01__WorkPhone__c,OtherPhone,';
// Spouses
csvString += 'Spouse Contact ID,Spouse First Name,Spouse Middle Name,Spouse Last Name,';
// Memberships
csvString += 'Memberships,';
// Registrations
csvString += 'Registrations';
csvString += '\n';

Integer rowCount = 0;
for (Contact ct : lstContacts) {

    // Filter out youth
    if (ct.TREX1__Age__c < 18) continue;

    // Clear fake birthdates
    if (ct.Birthdate == fakeBirthday) ct.Birthdate = null;

    // Contact and account info
    csvString += ct.Id + ',' + ct.AccountId + ',' + ct.AG_ID__c + ',' + ct.Id + '-' + ct.AG_ID__c + ',' + ct.Salutation + ',' + ct.FirstName + ',' + ct.MiddleName + ',' + ct.LastName + ',' + ct.Suffix + ',' + ct.MailingStreet + ',' + ct.MailingCity + ',' + ct.MailingState + ',' + ct.MailingCountry + ',' + ct.MailingPostalCode + ',' + ct.Account.npo02__TotalOppAmount__c + ',' + ct.Account.npo02__NumberOfClosedOpps__c + ',' + ct.Account.npo02__LastOppAmount__c + ',' + ct.Account.npo02__LastCloseDate__c + ',' + ct.Account.npo02__Best_Gift_Year_Total__c + ',' + ct.Account.npo02__Best_Gift_Year__c + ',' + ct.Birthdate + ',' + ct.TREX1__Age__c + ',' + ct.MobilePhone + ',' + ct.HomePhone + ',' + ct.npe01__WorkPhone__c + ',' + ct.OtherPhone;

    // Spouses
    if (!ct.npe4__Relationships__r.isEmpty()) {
        csvString += ct.npe4__Relationships__r[0].npe4__RelatedContact__c + ',' + ct.npe4__Relationships__r[0].npe4__RelatedContact__r.FirstName + ',' + ct.npe4__Relationships__r[0].npe4__RelatedContact__r.MiddleName + ',' + ct.npe4__Relationships__r[0].npe4__RelatedContact__r.LastName;
    } else {
        csvString += ',,,,';
    }

    // Memberships
    if (!ct.TREX1__Memberships__r.isEmpty()) {
        List<String> lstMems = new List<String>();
        for (TREX1__Membership__c mem : ct.TREX1__Memberships__r) {
            lstMems.add(mem.Type_of_Membership__c + ' (' + mem.TREX1__Status__c + ')');
        }
        csvString += String.join(lstMems, '; ');
    } else {
        csvString += ',';
    }

    // Registrations
    if (!ct.TREX1__Registrations__r.isEmpty()) {
        List<String> lstRegs = new List<String>();
        for (TREX1__Registration__c reg : ct.TREX1__Registrations__r) {
        lstRegs.add(reg.TREX1__reg_Course_Session__r.Name + ' - ' + reg.TREX1__Start_Date__c.format());
    }
        csvString += String.join(lstRegs, '; ');
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


