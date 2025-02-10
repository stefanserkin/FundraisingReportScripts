/**************************************************************************
 * @description Contributes to import-ready csv for Wealth Engine wealth screenings
 * 
 * @date October, 2023
 **************************************************************************/

List<Account> lstAccounts = [
    SELECT Id,
           (SELECT TREX1__reg_Program__r.Name, TREX1__reg_Course__r.Name, TREX1__Contact__r.FirstName, TREX1__Start_Date__c
              FROM TREX1__Registrations__r
             WHERE Qualifying_Enrollments__c > 0
             ORDER BY TREX1__Start_Date__c DESC)
      FROM Account
     WHERE Id IN (SELECT AccountId FROM Contact WHERE Include_in_Wealth_Screening__c = true)
];

// Headers
String csvString = 'Id,Registrations\n';

Integer rowCount = 0;
for (Account acc : lstAccounts) {

    // Account id
    csvString += acc.Id + ',';

    // Registrations
    if (!acc.TREX1__Registrations__r.isEmpty()) {
        List<String> lstRegs = new List<String>();
        Set<String> setRegs = new Set<String>();
        for (TREX1__Registration__c reg : acc.TREX1__Registrations__r) {
            /*
            String regString = reg.TREX1__reg_Course__r.Name + 
                ' (' + reg.TREX1__Contact__r.FirstName + ' - ' + reg.TREX1__Start_Date__c.format() + ')';
                */
            String regString = reg.TREX1__reg_Program__r.Name + ' (' + reg.TREX1__Contact__r.FirstName + ')';
            //lstRegs.add(regString);
            setRegs.add(regString);
        }
        lstRegs.addAll(setRegs);
        csvString += String.join(lstRegs, '; ');
    } else {
        csvString += '';
    }

    rowCount++;
    if (rowCount < lstAccounts.size()) {
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


