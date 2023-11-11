/**************************************************************************
 * @description Contributes to import-ready csv for Wealth Engine wealth screenings
 * 
 * @date October, 2023
 **************************************************************************/

// Rules
Date minDate = Date.newInstance(2023, 3, 1);
Date fakeBirthday = Date.newInstance(1945, 1, 1);

// Adults in households with registrations or memberships
List<Contact> lstContacts = [
    SELECT Id,
           (SELECT TREX1__reg_Course_Session__r.Name, TREX1__Start_Date__c
              FROM TREX1__Registrations__r 
             WHERE Qualifying_Enrollments__c > 0)
      FROM Contact 
     WHERE TREX1__Age__c >= 18
       AND AccountId IN (SELECT TREX1__Account__c 
                           FROM TREX1__Registration__c 
                          WHERE TREX1__Start_Date__c >= :minDate
                            AND Qualifying_Enrollments__c > 0)
];

// Headers
String csvString = 'Id,Registrations\n';

Integer rowCount = 0;
for (Contact ct : lstContacts) {

    // Contact and account info
    csvString += ct.Id + ',';

    // Registrations
    if (!ct.TREX1__Registrations__r.isEmpty()) {
        List<String> lstRegs = new List<String>();
        for (TREX1__Registration__c reg : ct.TREX1__Registrations__r) {
            lstRegs.add(reg.TREX1__reg_Course_Session__r.Name + ' - ' + reg.TREX1__Start_Date__c.format());
        }
        csvString += String.join(lstRegs, '; ');
    } else {
        csvString += '';
    }

    rowCount++;
    if (rowCount < lstContacts.size()) {
        csvString += '\n';
    }
}


// Create csv file attachment
Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
attachment.setFileName('RegistrationHistory.csv');
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


